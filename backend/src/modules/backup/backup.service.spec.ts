import { Test, TestingModule } from "@nestjs/testing";
import { BackupService } from "./backup.service";
import { PrismaService } from "../../prisma/prisma.service";
import { BadRequestException } from "@nestjs/common";

describe("BackupService", () => {
  let service: BackupService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      user: { count: jest.fn().mockResolvedValue(10) },
      department: { count: jest.fn().mockResolvedValue(5) },
      attendanceRecord: { count: jest.fn().mockResolvedValue(100) },
      request: { count: jest.fn().mockResolvedValue(20) },
      task: { count: jest.fn().mockResolvedValue(15) },
      asset: { count: jest.fn().mockResolvedValue(50) },
      stockItem: { count: jest.fn().mockResolvedValue(30) },
      supplierInvoice: { count: jest.fn().mockResolvedValue(8) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [BackupService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<BackupService>(BackupService);
  });

  it("should create backup and compute checksum (OPS-006)", async () => {
    const backup = await service.createBackup("user-super-admin", {
      notes: "Test snapshot",
    });

    expect(backup).toBeDefined();
    expect(backup.backupNumber).toContain("BKP-");
    expect(backup.checksumSha256).toBeDefined();
    expect(backup.entityCounts.users).toBe(10);
    expect(prisma.auditLog.create).toHaveBeenCalled();

    // Verify listBackups sees it
    const list = await service.listBackups();
    expect(list.length).toBeGreaterThanOrEqual(1);

    // Verify simulate restore passes (OPS-007)
    const restore = await service.restoreBackup(
      "user-super-admin",
      backup.backupNumber,
      {
        simulateOnly: true,
      },
    );
    expect(restore.status).toBe("VERIFIED");
    expect(restore.checksumVerified).toBe(true);

    // Delete backup (OPS-008)
    const del = await service.deleteBackup(
      "user-super-admin",
      backup.backupNumber,
    );
    expect(del.success).toBe(true);
  });
});
