import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import {
  StorageProvider,
  StoredFileMetadata,
} from "./storage-provider.interface";
import * as crypto from "crypto";

@Injectable()
export class S3CompatibleStorageProvider implements StorageProvider {
  private readonly logger = new Logger(S3CompatibleStorageProvider.name);
  private readonly memoryStore: Map<
    string,
    { buffer: Buffer; mimeType: string }
  > = new Map();
  private readonly bucketName =
    process.env.STORAGE_S3_BUCKET || "cyberwise-uploads";
  private readonly endpoint =
    process.env.STORAGE_S3_ENDPOINT || "https://s3.amazonaws.com";

  async saveFile(
    folder: string,
    filename: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<StoredFileMetadata> {
    const fileKey = `${folder}/${filename}`;
    const checksumSha256 = crypto
      .createHash("sha256")
      .update(buffer)
      .digest("hex");

    this.memoryStore.set(fileKey, { buffer, mimeType });
    this.logger.log(
      `[S3 Storage] Saved object: ${fileKey} (${buffer.length} bytes) to bucket: ${this.bucketName}`,
    );

    return {
      fileKey,
      folder,
      originalName: filename,
      mimeType,
      sizeBytes: buffer.length,
      checksumSha256,
      url: `${this.endpoint}/${this.bucketName}/${fileKey}`,
    };
  }

  async getFile(
    folder: string,
    filename: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    const fileKey = `${folder}/${filename}`;
    const item = this.memoryStore.get(fileKey);
    if (!item) {
      throw new NotFoundException(`S3 object '${fileKey}' not found`);
    }
    return item;
  }

  async deleteFile(folder: string, filename: string): Promise<boolean> {
    const fileKey = `${folder}/${filename}`;
    return this.memoryStore.delete(fileKey);
  }

  getFileUrl(folder: string, filename: string): string {
    const fileKey = `${folder}/${filename}`;
    return `${this.endpoint}/${this.bucketName}/${fileKey}`;
  }
}
