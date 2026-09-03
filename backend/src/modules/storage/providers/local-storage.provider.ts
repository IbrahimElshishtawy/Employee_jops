import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import {
  StorageProvider,
  StoredFileMetadata,
} from "./storage-provider.interface";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

@Injectable()
export class LocalStorageProvider implements StorageProvider {
  private readonly logger = new Logger(LocalStorageProvider.name);
  private readonly rootDir: string;

  constructor() {
    this.rootDir = path.resolve(process.cwd(), "uploads");
    if (!fs.existsSync(this.rootDir)) {
      fs.mkdirSync(this.rootDir, { recursive: true });
    }
  }

  async saveFile(
    folder: string,
    filename: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<StoredFileMetadata> {
    const targetDir = path.join(this.rootDir, folder);
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const filePath = path.join(targetDir, filename);
    fs.writeFileSync(filePath, buffer);

    const checksumSha256 = crypto
      .createHash("sha256")
      .update(buffer)
      .digest("hex");

    return {
      fileKey: `${folder}/${filename}`,
      folder,
      originalName: filename,
      mimeType,
      sizeBytes: buffer.length,
      checksumSha256,
      url: `/uploads/${folder}/${filename}`,
    };
  }

  async getFile(
    folder: string,
    filename: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    const filePath = path.join(this.rootDir, folder, filename);
    if (!fs.existsSync(filePath)) {
      throw new NotFoundException(
        `File '${folder}/${filename}' not found on storage`,
      );
    }

    const buffer = fs.readFileSync(filePath);
    return { buffer, mimeType: "application/octet-stream" };
  }

  async deleteFile(folder: string, filename: string): Promise<boolean> {
    const filePath = path.join(this.rootDir, folder, filename);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      return true;
    }
    return false;
  }

  getFileUrl(folder: string, filename: string): string {
    return `/uploads/${folder}/${filename}`;
  }
}
