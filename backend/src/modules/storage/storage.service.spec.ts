import { Test, TestingModule } from "@nestjs/testing";
import { StorageService } from "./storage.service";
import { PrismaService } from "../../prisma/prisma.service";
import { ConfigService } from "@nestjs/config";
import { BadRequestException } from "@nestjs/common";

describe("StorageService", () => {
  let service: StorageService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: "audit-1" }),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StorageService,
        { provide: PrismaService, useValue: prisma },
        {
          provide: ConfigService,
          useValue: { get: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<StorageService>(StorageService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  it("should reject disallowed MIME type", async () => {
    await expect(
      service.uploadFile("user-1", {
        originalName: "malicious.exe",
        mimeType: "application/x-msdownload",
        base64Content: Buffer.from("test").toString("base64"),
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it("should reject disallowed file extension", async () => {
    await expect(
      service.uploadFile("user-1", {
        originalName: "script.sh",
        mimeType: "text/plain",
        base64Content: Buffer.from("echo hi").toString("base64"),
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it("should upload and store an image successfully", async () => {
    const rawData = "sample image data";
    const base64 = Buffer.from(rawData).toString("base64");

    const result = await service.uploadFile("user-1", {
      originalName: "room-inspection.jpg",
      mimeType: "image/jpeg",
      base64Content: base64,
      folder: "inspections",
    });

    expect(result).toBeDefined();
    expect(result.fileUrl).toContain("/uploads/inspections/");
    expect(result.storedFilename).toContain(".jpg");
    expect(result.mimeType).toBe("image/jpeg");
    expect(prisma.auditLog.create).toHaveBeenCalled();

    // Clean up created file
    const delResult = await service.deleteFile(
      "user-1",
      "inspections",
      result.storedFilename,
    );
    expect(delResult.success).toBe(true);
  });
});
