import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Logger,
  Optional,
  Inject,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PrismaService } from "../../prisma/prisma.service";
import { UploadFileDto, UploadResultDto } from "./dto";
import { AuditAction } from "@prisma/client";
import { StorageProvider } from "./providers/storage-provider.interface";
import { LocalStorageProvider } from "./providers/local-storage.provider";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "application/pdf",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.ms-excel",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "text/plain",
  "text/csv",
]);

const ALLOWED_EXTENSIONS = new Set([
  "jpg",
  "jpeg",
  "png",
  "webp",
  "gif",
  "pdf",
  "doc",
  "docx",
  "xls",
  "xlsx",
  "txt",
  "csv",
]);

const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly uploadRootDir: string;

  private readonly provider: StorageProvider;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Optional() @Inject("STORAGE_PROVIDER") customProvider?: StorageProvider,
  ) {
    this.provider = customProvider || new LocalStorageProvider();
    this.uploadRootDir = path.resolve(process.cwd(), "uploads");
    if (!fs.existsSync(this.uploadRootDir)) {
      fs.mkdirSync(this.uploadRootDir, { recursive: true });
    }
  }

  /**
   * Uploads and stores a file with validation, hashing, and audit logging
   */
  async uploadFile(
    userId: string,
    dto: UploadFileDto,
  ): Promise<UploadResultDto> {
    const ext = path.extname(dto.originalName).replace(".", "").toLowerCase();
    const mime = dto.mimeType.toLowerCase();

    // Security check: strictly reject SVG/HTML files to prevent Stored XSS
    if (
      ext === "svg" ||
      ext === "html" ||
      ext === "htm" ||
      ext === "xml" ||
      mime.includes("svg") ||
      mime.includes("html")
    ) {
      throw new BadRequestException(
        "FILE_XSS_PREVENTED: SVG and HTML files are strictly prohibited for security",
      );
    }

    // 1. Validate MIME type
    if (!ALLOWED_MIME_TYPES.has(mime)) {
      throw new BadRequestException(
        `FILE_MIME_DISALLOWED: '${dto.mimeType}' is not an allowed file type`,
      );
    }

    // 2. Validate file extension
    if (!ext || !ALLOWED_EXTENSIONS.has(ext)) {
      throw new BadRequestException(
        `FILE_EXT_DISALLOWED: File extension '.${ext}' is not permitted`,
      );
    }

    // 3. Decode base64 buffer
    let rawBase64 = dto.base64Content;
    if (rawBase64.includes(";base64,")) {
      rawBase64 = rawBase64.split(";base64,")[1];
    }

    const buffer = Buffer.from(rawBase64, "base64");
    if (buffer.length === 0) {
      throw new BadRequestException("FILE_EMPTY: Uploaded content is empty");
    }

    if (buffer.length > MAX_FILE_SIZE_BYTES) {
      throw new BadRequestException(
        `FILE_TOO_LARGE: Size (${buffer.length} bytes) exceeds limit (${MAX_FILE_SIZE_BYTES} bytes)`,
      );
    }

    // 4. Sanitize target folder
    const safeFolder = (dto.folder || "general")
      .replace(/[^a-zA-Z0-9_-]/g, "")
      .substring(0, 32);

    // 5. Generate UUID-based collision-free filename
    const fileId = crypto.randomUUID();
    const storedFilename = `${fileId}.${ext}`;

    // 6. Delegate to StorageProvider (Local or S3)
    const stored = await this.provider.saveFile(
      safeFolder,
      storedFilename,
      buffer,
      dto.mimeType,
    );

    // 7. Audit log
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "StorageFile",
        entityId: fileId,
        payload: {
          originalName: dto.originalName,
          storedFilename,
          folder: safeFolder,
          mimeType: dto.mimeType,
          sizeBytes: stored.sizeBytes,
          checksumSha256: stored.checksumSha256,
          url: stored.url,
        },
      },
    });

    this.logger.log(
      `File stored: ${stored.fileKey} (${stored.sizeBytes} bytes, sha256:${stored.checksumSha256.slice(0, 8)})`,
    );

    return {
      fileId,
      originalName: dto.originalName,
      storedFilename,
      folder: safeFolder,
      fileUrl: stored.url,
      mimeType: dto.mimeType,
      sizeBytes: stored.sizeBytes,
      fileSize: stored.sizeBytes,
      checksumSha256: stored.checksumSha256,
      url: stored.url,
      uploadedAt: new Date().toISOString(),
    };
  }

  /**
   * Retrieves file metadata and verifies existence
   */
  async getFileMetadata(folder: string, filename: string) {
    const safeFolder = folder.replace(/[^a-zA-Z0-9_-]/g, "");
    const safeFilename = path.basename(filename);
    const filePath = path.join(this.uploadRootDir, safeFolder, safeFilename);

    if (!fs.existsSync(filePath)) {
      throw new NotFoundException(
        `File '${safeFolder}/${safeFilename}' not found`,
      );
    }

    const stat = fs.statSync(filePath);
    return {
      filename: safeFilename,
      folder: safeFolder,
      fileUrl: `/uploads/${safeFolder}/${safeFilename}`,
      fileSize: stat.size,
      createdAt: stat.birthtime,
      modifiedAt: stat.mtime,
    };
  }

  /**
   * Deletes a stored file
   */
  async deleteFile(userId: string, folder: string, filename: string) {
    const meta = await this.getFileMetadata(folder, filename);
    const filePath = path.join(this.uploadRootDir, meta.folder, meta.filename);

    fs.unlinkSync(filePath);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.DELETE,
        entity: "StorageFile",
        entityId: meta.filename,
        payload: { folder: meta.folder, filename: meta.filename },
      },
    });

    return {
      success: true,
      message: `File '${meta.filename}' removed successfully`,
    };
  }
}
