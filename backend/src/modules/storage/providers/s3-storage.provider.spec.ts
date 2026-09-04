import { S3CompatibleStorageProvider } from "./s3-storage.provider";

describe("S3CompatibleStorageProvider", () => {
  let provider: S3CompatibleStorageProvider;

  beforeEach(() => {
    delete process.env.STORAGE_S3_ACCESS_KEY;
    delete process.env.STORAGE_S3_SECRET_KEY;
    provider = new S3CompatibleStorageProvider();
  });

  it("should report unverified status when credentials are not configured", () => {
    const status = provider.getStatus();
    expect(status.configured).toBe(false);
    expect(status.status).toBe("CODE_VERIFIED_EXTERNAL_UNVERIFIED");
    expect(status.message).toContain("CODE VERIFIED");
  });

  it("should save, retrieve, check existence, and delete file in unverified fallback store", async () => {
    const file = await provider.saveFile(
      "avatars",
      "test.png",
      Buffer.from("fake-png-content"),
      "image/png",
    );

    expect(file.fileKey).toBe("avatars/test.png");
    expect(file.sizeBytes).toBe(16);

    const exists = await provider.existsFile("avatars", "test.png");
    expect(exists).toBe(true);

    const retrieved = await provider.getFile("avatars", "test.png");
    expect(retrieved.buffer.toString()).toBe("fake-png-content");
    expect(retrieved.mimeType).toBe("image/png");

    const deleted = await provider.deleteFile("avatars", "test.png");
    expect(deleted).toBe(true);

    const existsAfter = await provider.existsFile("avatars", "test.png");
    expect(existsAfter).toBe(false);
  });

  it("should generate signed URL with expiry", async () => {
    const url = await provider.getSignedUrl("documents", "policy.pdf", 1800);
    expect(url).toContain("expires=");
    expect(url).toContain("sig=");
  });
});
