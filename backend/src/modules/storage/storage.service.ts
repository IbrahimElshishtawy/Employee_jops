import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Logger,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PrismaService } from "../../prisma/prisma.service";
import { UploadFileDto, UploadResultDto } from "./dto";
import { AuditAction } from "@prisma/client";
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

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
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
    // 1. Validate MIME type
    if (!ALLOWED_MIME_TYPES.has(dto.mimeType.toLowerCase())) {
      throw new BadRequestException(
        `FILE_MIME_DISALLOWED: '${dto.mimeType}' is not an allowed file type`,
      );
    }

    // 2. Validate file extension
    const ext = path.extname(dto.originalName).replace(".", "").toLowerCase();
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

    // 4. Compute SHA-256 checksum
    const checksumSha256 = crypto
      .createHash("sha256")
      .update(buffer)
      .digest("hex");

    // 5. Sanitize target folder
    const safeFolder = (dto.folder || "general")
      .replace(/[^a-zA-Z0-9_-]/g, "")
      .substring(0, 32);
    const targetDir = path.join(this.uploadRootDir, safeFolder);
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    // 6. Generate UUID-based collision-free filename
    const fileId = crypto.randomUUID();
    const storedFilename = `${fileId}.${ext}`;
    const destinationPath = path.join(targetDir, storedFilename);

    fs.writeFileSync(destinationPath, buffer);

    const fileUrl = `/uploads/${safeFolder}/${storedFilename}`;

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
          fileUrl,
          mimeType: dto.mimeType,
          fileSize: buffer.length,
          checksumSha256,
        },
      },
    });

    this.logger.log(
      `User ${userId} uploaded file ${storedFilename} (${buffer.length} bytes)`,
    );

    return {
      fileId,
      originalName: dto.originalName,
      storedFilename,
      fileUrl,
      mimeType: dto.mimeType,
      fileSize: buffer.length,
      checksumSha256,
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
