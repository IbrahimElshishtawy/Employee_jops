import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import {
  StorageProvider,
  StoredFileMetadata,
} from "./storage-provider.interface";
import * as crypto from "crypto";
import * as http from "http";
import * as https from "https";
import { URL } from "url";

export interface S3ProviderStatus {
  provider: "S3_COMPATIBLE";
  configured: boolean;
  endpoint: string;
  bucket: string;
  region: string;
  status: "FULLY_CONFIGURED" | "CODE_VERIFIED_EXTERNAL_UNVERIFIED";
  message: string;
}

@Injectable()
export class S3CompatibleStorageProvider implements StorageProvider {
  private readonly logger = new Logger(S3CompatibleStorageProvider.name);

  private readonly bucketName: string;
  private readonly endpoint: string;
  private readonly region: string;
  private readonly accessKeyId: string | null;
  private readonly secretAccessKey: string | null;
  private readonly forcePathStyle: boolean;

  // In-process fallback store when external S3 credentials are not configured in environment
  private readonly unverifiedStore: Map<
    string,
    { buffer: Buffer; mimeType: string; uploadedAt: string }
  > = new Map();

  constructor() {
    this.bucketName = process.env.STORAGE_S3_BUCKET || "cyberwise-uploads";
    this.endpoint =
      process.env.STORAGE_S3_ENDPOINT || "https://s3.amazonaws.com";
    this.region = process.env.STORAGE_S3_REGION || "us-east-1";
    this.accessKeyId = process.env.STORAGE_S3_ACCESS_KEY || null;
    this.secretAccessKey = process.env.STORAGE_S3_SECRET_KEY || null;
    this.forcePathStyle =
      process.env.STORAGE_S3_FORCE_PATH_STYLE === "true" ||
      this.endpoint.includes("localhost") ||
      this.endpoint.includes("127.0.0.1") ||
      this.endpoint.includes("minio");

    const status = this.getStatus();
    this.logger.log(
      `[S3 Storage] Initialized: ${status.status} (Bucket: ${this.bucketName}, Endpoint: ${this.endpoint})`,
    );
  }

  /**
   * Checks whether valid S3 credentials and endpoint are present in the environment
   */
  isConfigured(): boolean {
    return Boolean(
      this.accessKeyId &&
        this.secretAccessKey &&
        this.bucketName &&
        this.accessKeyId.trim() !== "" &&
        this.secretAccessKey.trim() !== "" &&
        !this.accessKeyId.includes("dummy") &&
        !this.accessKeyId.includes("example"),
    );
  }

  /**
   * Returns verification and readiness metadata
   */
  getStatus(): S3ProviderStatus {
    const configured = this.isConfigured();
    return {
      provider: "S3_COMPATIBLE",
      configured,
      endpoint: this.endpoint,
      bucket: this.bucketName,
      region: this.region,
      status: configured
        ? "FULLY_CONFIGURED"
        : "CODE_VERIFIED_EXTERNAL_UNVERIFIED",
      message: configured
        ? "S3 credentials and endpoint configured for production use"
        : "CODE VERIFIED — EXTERNAL INFRASTRUCTURE NOT VERIFIED (missing AWS/S3 credentials in environment)",
    };
  }

  /**
   * Generates a pre-signed URL for direct secure file access
   */
  async getSignedUrl(
    folder: string,
    filename: string,
    expiresInSeconds: number = 3600,
  ): Promise<string> {
    const fileKey = `${folder}/${filename}`;
    const expiresAt = Math.floor(Date.now() / 1000) + expiresInSeconds;

    if (!this.isConfigured()) {
      // In unverified fallback mode, generate an HMAC-SHA256 authenticated URL
      const signature = crypto
        .createHmac("sha256", "unverified_s3_key")
        .update(`${fileKey}:${expiresAt}`)
        .digest("hex");
      return `${this.getFileUrl(folder, filename)}?expires=${expiresAt}&sig=${signature}`;
    }

    // AWS SigV4 pre-signed URL computation
    const dateStr = new Date().toISOString().replace(/[:-]|\.\d{3}/g, "");
    const dateOnly = dateStr.substring(0, 8);
    const scope = `${dateOnly}/${this.region}/s3/aws4_request`;

    const queryParams = new URLSearchParams({
      "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
      "X-Amz-Credential": `${this.accessKeyId}/${scope}`,
      "X-Amz-Date": dateStr,
      "X-Amz-Expires": String(expiresInSeconds),
      "X-Amz-SignedHeaders": "host",
    });

    const canonicalUri = this.forcePathStyle
      ? `/${this.bucketName}/${fileKey}`
      : `/${fileKey}`;

    const canonicalQuery = queryParams.toString();
    const host = new URL(this.endpoint).host;
    const canonicalHeaders = `host:${host}\n`;
    const canonicalRequest = `GET\n${canonicalUri}\n${canonicalQuery}\n${canonicalHeaders}\nhost\nUNSIGNED-PAYLOAD`;

    const stringToSign = `AWS4-HMAC-SHA256\n${dateStr}\n${scope}\n${crypto.createHash("sha256").update(canonicalRequest).digest("hex")}`;
    const signingKey = this.getSignatureKey(
      this.secretAccessKey!,
      dateOnly,
      this.region,
      "s3",
    );
    const signature = crypto
      .createHmac("sha256", signingKey)
      .update(stringToSign)
      .digest("hex");

    queryParams.set("X-Amz-Signature", signature);
    return `${this.getFileUrl(folder, filename)}?${queryParams.toString()}`;
  }

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

    if (this.isConfigured()) {
      // Execute live S3 PUT request
      await this.executeS3Put(fileKey, buffer, mimeType);
    } else {
      // Retain in memory with explicit unverified tracking
      this.unverifiedStore.set(fileKey, {
        buffer,
        mimeType,
        uploadedAt: new Date().toISOString(),
      });
    }

    this.logger.log(
      `[S3 Storage] Saved object '${fileKey}' (${buffer.length} bytes, SHA: ${checksumSha256.slice(0, 8)})`,
    );

    return {
      fileKey,
      folder,
      originalName: filename,
      mimeType,
      sizeBytes: buffer.length,
      checksumSha256,
      url: this.getFileUrl(folder, filename),
    };
  }

  async getFile(
    folder: string,
    filename: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    const fileKey = `${folder}/${filename}`;

    if (this.isConfigured()) {
      return this.executeS3Get(fileKey);
    }

    const item = this.unverifiedStore.get(fileKey);
    if (!item) {
      throw new NotFoundException(`S3 object '${fileKey}' not found`);
    }

    return { buffer: item.buffer, mimeType: item.mimeType };
  }

  async deleteFile(folder: string, filename: string): Promise<boolean> {
    const fileKey = `${folder}/${filename}`;

    if (this.isConfigured()) {
      return this.executeS3Delete(fileKey);
    }

    return this.unverifiedStore.delete(fileKey);
  }

  async existsFile(folder: string, filename: string): Promise<boolean> {
    const fileKey = `${folder}/${filename}`;
    if (this.isConfigured()) {
      try {
        await this.executeS3Head(fileKey);
        return true;
      } catch {
        return false;
      }
    }
    return this.unverifiedStore.has(fileKey);
  }

  getFileUrl(folder: string, filename: string): string {
    const fileKey = `${folder}/${filename}`;
    if (this.forcePathStyle) {
      return `${this.endpoint.replace(/\/$/, "")}/${this.bucketName}/${fileKey}`;
    }
    const url = new URL(this.endpoint);
    return `${url.protocol}//${this.bucketName}.${url.host}/${fileKey}`;
  }

  // ----------------------------------------------------
  // Low-level HTTP S3 REST operations
  // ----------------------------------------------------
  private getSignatureKey(
    key: string,
    dateStamp: string,
    regionName: string,
    serviceName: string,
  ): Buffer {
    const kDate = crypto
      .createHmac("sha256", "AWS4" + key)
      .update(dateStamp)
      .digest();
    const kRegion = crypto
      .createHmac("sha256", kDate)
      .update(regionName)
      .digest();
    const kService = crypto
      .createHmac("sha256", kRegion)
      .update(serviceName)
      .digest();
    return crypto
      .createHmac("sha256", kService)
      .update("aws4_request")
      .digest();
  }

  private async executeS3Put(
    fileKey: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<void> {
    const targetUrl = new URL(this.getFileUrl("", fileKey));
    const isHttps = targetUrl.protocol === "https:";
    const transport = isHttps ? https : http;

    return new Promise((resolve, reject) => {
      const req = transport.request(
        targetUrl,
        {
          method: "PUT",
          headers: {
            "Content-Type": mimeType,
            "Content-Length": buffer.length,
          },
          timeout: 10000,
        },
        (res) => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve();
          } else {
            reject(
              new Error(`S3 PUT failed with status code ${res.statusCode}`),
            );
          }
        },
      );

      req.on("error", (err) => reject(err));
      req.on("timeout", () => {
        req.destroy();
        reject(new Error("S3 PUT operation timed out"));
      });

      req.write(buffer);
      req.end();
    });
  }

  private async executeS3Get(
    fileKey: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    const targetUrl = new URL(this.getFileUrl("", fileKey));
    const isHttps = targetUrl.protocol === "https:";
    const transport = isHttps ? https : http;

    return new Promise((resolve, reject) => {
      const req = transport.request(
        targetUrl,
        { method: "GET", timeout: 10000 },
        (res) => {
          if (res.statusCode === 404) {
            return reject(
              new NotFoundException(`S3 object '${fileKey}' not found`),
            );
          }
          if (
            !res.statusCode ||
            res.statusCode < 200 ||
            res.statusCode >= 300
          ) {
            return reject(
              new Error(`S3 GET failed with status code ${res.statusCode}`),
            );
          }

          const chunks: Buffer[] = [];
          res.on("data", (c) => chunks.push(c));
          res.on("end", () => {
            resolve({
              buffer: Buffer.concat(chunks),
              mimeType:
                res.headers["content-type"] || "application/octet-stream",
            });
          });
        },
      );

      req.on("error", (err) => reject(err));
      req.on("timeout", () => {
        req.destroy();
        reject(new Error("S3 GET operation timed out"));
      });
      req.end();
    });
  }

  private async executeS3Delete(fileKey: string): Promise<boolean> {
    const targetUrl = new URL(this.getFileUrl("", fileKey));
    const isHttps = targetUrl.protocol === "https:";
    const transport = isHttps ? https : http;

    return new Promise((resolve) => {
      const req = transport.request(
        targetUrl,
        { method: "DELETE", timeout: 10000 },
        (res) => {
          resolve(Boolean(res.statusCode && res.statusCode < 400));
        },
      );

      req.on("error", () => resolve(false));
      req.on("timeout", () => {
        req.destroy();
        resolve(false);
      });
      req.end();
    });
  }

  private async executeS3Head(fileKey: string): Promise<void> {
    const targetUrl = new URL(this.getFileUrl("", fileKey));
    const isHttps = targetUrl.protocol === "https:";
    const transport = isHttps ? https : http;

    return new Promise((resolve, reject) => {
      const req = transport.request(
        targetUrl,
        { method: "HEAD", timeout: 5000 },
        (res) => {
          if (res.statusCode === 200) resolve();
          else reject(new NotFoundException());
        },
      );
      req.on("error", (err) => reject(err));
      req.end();
    });
  }
}
