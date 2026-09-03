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
      department: {
        count: jest.fn().mockResolvedValue(5),
        findMany: jest.fn().mockResolvedValue([{ id: "dept-1", name: "Front Office" }]),
      },
      attendanceRecord: { count: jest.fn().mockResolvedValue(100) },
      request: { count: jest.fn().mockResolvedValue(20) },
      task: { count: jest.fn().mockResolvedValue(15) },
      asset: { count: jest.fn().mockResolvedValue(50) },
      stockItem: { count: jest.fn().mockResolvedValue(30) },
      supplierInvoice: { count: jest.fn().mockResolvedValue(8) },
      systemSetting: {
        findMany: jest.fn().mockResolvedValue([{ key: "SITE_NAME", value: "CyberWise" }]),
        upsert: jest.fn().mockResolvedValue({ key: "SITE_NAME" }),
      },
      assetCategory: {
        findMany: jest.fn().mockResolvedValue([{ id: "cat-1", name: "HVAC", code: "HVC" }]),
        upsert: jest.fn().mockResolvedValue({ id: "cat-1" }),
      },
      warehouse: { findMany: jest.fn().mockResolvedValue([]) },
      stockCategory: { findMany: jest.fn().mockResolvedValue([]) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
      $transaction: jest.fn().mockImplementation((fn) => fn(prisma)),
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
    const simulateRestore = await service.restoreBackup(
      "user-super-admin",
      backup.backupNumber,
      {
        simulateOnly: true,
      },
    );
    expect(simulateRestore.status).toBe("VERIFIED");
    expect(simulateRestore.checksumVerified).toBe(true);

    // Verify real restore passes (OPS-007)
    const realRestore = await service.restoreBackup(
      "user-super-admin",
      backup.backupNumber,
      {
        simulateOnly: false,
      },
    );
    expect(realRestore.status).toBe("RESTORED");
    expect(realRestore.simulateOnly).toBe(false);

    // Retention policy enforcement (OPS-008)
    const retention = await service.enforceRetentionPolicy(30);
    expect(retention).toBeDefined();

    // Delete backup (OPS-008)
    const del = await service.deleteBackup(
      "user-super-admin",
      backup.backupNumber,
    );
    expect(del.success).toBe(true);
  });
});
