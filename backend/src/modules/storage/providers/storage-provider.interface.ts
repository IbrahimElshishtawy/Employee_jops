export interface StoredFileMetadata {
  fileKey: string;
  folder: string;
  originalName: string;
  mimeType: string;
  sizeBytes: number;
  checksumSha256: string;
  url: string;
}

export interface StorageProvider {
  saveFile(
    folder: string,
    filename: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<StoredFileMetadata>;

  getFile(
    folder: string,
    filename: string,
  ): Promise<{ buffer: Buffer; mimeType: string }>;

  deleteFile(folder: string, filename: string): Promise<boolean>;

  getFileUrl(folder: string, filename: string): string;
}
