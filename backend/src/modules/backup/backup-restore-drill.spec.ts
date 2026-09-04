import { Test, TestingModule } from "@nestjs/testing";
import { BackupService } from "./backup.service";
import { PrismaService } from "../../prisma/prisma.service";
import { BadRequestException } from "@nestjs/common";
import * as fs from "fs";
import * as path from "path";

describe("Backup & Disaster Recovery Drill Verification (Phase 3)", () => {
  let service: BackupService;
  let mockPrisma: any;
  const testBackupDir = path.resolve(process.cwd(), "backups");

  beforeEach(async () => {
    mockPrisma = {
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: "audit-drill-1" }),
      },
      user: { count: jest.fn().mockResolvedValue(120) },
      department: {
        count: jest.fn().mockResolvedValue(12),
        findMany: jest.fn().mockResolvedValue([
          { id: "dept-1", name: "Front Office", code: "FOFF", status: "ACTIVE" },
          { id: "dept-2", name: "Housekeeping", code: "HKPG", status: "ACTIVE" },
        ]),
        upsert: jest.fn().mockResolvedValue({ id: "dept-1" }),
      },
      attendanceRecord: { count: jest.fn().mockResolvedValue(450) },
      request: { count: jest.fn().mockResolvedValue(85) },
      task: { count: jest.fn().mockResolvedValue(210) },
      asset: { count: jest.fn().mockResolvedValue(150) },
      stockItem: { count: jest.fn().mockResolvedValue(600) },
      supplierInvoice: { count: jest.fn().mockResolvedValue(40) },
      incidentReport: { count: jest.fn().mockResolvedValue(5) },
      shiftHandover: { count: jest.fn().mockResolvedValue(30) },
      systemSetting: {
        findMany: jest.fn().mockResolvedValue([
          { key: "HOTEL_NAME", value: "CyberWise Grand", category: "GENERAL" },
          { key: "JWT_SECRET", value: "super_secret_value", category: "SECURITY" },
        ]),
        upsert: jest.fn().mockResolvedValue({ key: "HOTEL_NAME" }),
      },
      assetCategory: {
        findMany: jest.fn().mockResolvedValue([
          { id: "cat-1", name: "HVAC", code: "HVAC", depreciationRate: 15 },
        ]),
        upsert: jest.fn().mockResolvedValue({ id: "cat-1" }),
      },
      warehouse: {
        findMany: jest.fn().mockResolvedValue([
          { id: "wh-1", name: "Main Store", code: "MAIN", isActive: true },
        ]),
        upsert: jest.fn().mockResolvedValue({ id: "wh-1" }),
      },
      stockCategory: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn(),
      },
      workplace: {
        findMany: jest.fn().mockResolvedValue([
          { id: "wp-1", name: "HQ", code: "HQ01", radiusMeters: 100, isActive: true },
        ]),
        upsert: jest.fn().mockResolvedValue({ id: "wp-1" }),
      },
      shift: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn(),
      },
      chartOfAccount: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn(),
      },
      $transaction: jest.fn().mockImplementation(async (callback) => {
        return callback(mockPrisma);
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BackupService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<BackupService>(BackupService);
  });

  it("Step 1: Backup Creation & Secret Redaction Drill", async () => {
    const start = Date.now();
    const backup = await service.createBackup("admin-1", {
      notes: "Production Drill Baseline",
    });
    const duration = Date.now() - start;

    expect(backup.backupNumber).toBeDefined();
    expect(backup.checksumSha256).toHaveLength(64);
    expect(backup.sizeBytes).toBeGreaterThan(500);
    expect(backup.secretsExcluded).toBe(true);
    expect(backup.backupType).toBe("LOGICAL_APPLICATION_SNAPSHOT");

    // Read the created backup file to verify secret redaction
    const filePath = path.join(testBackupDir, `${backup.backupNumber}.json`);
    const content = fs.readFileSync(filePath, "utf-8");
    const parsed = JSON.parse(content);

    // Verify secret values are redacted
    const jwtSetting = parsed.snapshotData.systemSettings.find(
      (s: any) => s.key === "JWT_SECRET",
    );
    expect(jwtSetting.value).toBe("[REDACTED_SECRET]");

    // Telemetry metrics
    console.log(`[Drill Metric] Backup duration: ${duration}ms, Size: ${backup.sizeBytes} bytes`);
  });

  it("Step 2: Corrupted Backup Detection Drill", async () => {
    const backup = await service.createBackup("admin-1", {
      notes: "Tamper Detection Test",
    });

    const filePath = path.join(testBackupDir, `${backup.backupNumber}.json`);
    const originalContent = fs.readFileSync(filePath, "utf-8");

    // Tamper with the file contents
    fs.writeFileSync(filePath, originalContent.replace("CyberWise Grand", "HACKED_HOTEL"));

    // Attempting restore must fail with CHECKSUM_MISMATCH
    await expect(
      service.restoreBackup("admin-1", backup.backupNumber, { simulateOnly: true }),
    ).rejects.toThrow(BadRequestException);

    // Restore original file for cleanup
    fs.writeFileSync(filePath, originalContent);
  });

  it("Step 3: Dry-Run Restore Simulation Drill (RTO Assessment)", async () => {
    const backup = await service.createBackup("admin-1", {
      notes: "Simulation Test",
    });

    const start = Date.now();
    const simResult = await service.restoreBackup("admin-1", backup.backupNumber, {
      simulateOnly: true,
    });
    const duration = Date.now() - start;

    expect(simResult.status).toBe("VERIFIED");
    expect(simResult.simulateOnly).toBe(true);
    expect(simResult.integrity).toBe("CHECKSUM_VALID");
    expect(simResult.entitiesRestored).toHaveLength(0); // Zero database mutations in simulation
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();

    console.log(`[Drill Metric] Dry-run restore simulation duration: ${duration}ms (RTO check: < 2000ms)`);
  });

  it("Step 4: Real Transactional Restore Execution Drill", async () => {
    const backup = await service.createBackup("admin-1", {
      notes: "Transactional Restore Test",
    });

    const start = Date.now();
    const restoreResult = await service.restoreBackup("admin-1", backup.backupNumber, {
      simulateOnly: false,
    });
    const duration = Date.now() - start;

    expect(restoreResult.status).toBe("VERIFIED");
    expect(restoreResult.simulateOnly).toBe(false);
    expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
    expect(mockPrisma.department.upsert).toHaveBeenCalled();
    expect(mockPrisma.workplace.upsert).toHaveBeenCalled();
    expect(mockPrisma.systemSetting.upsert).toHaveBeenCalled();

    console.log(`[Drill Metric] Real transactional restore execution duration: ${duration}ms`);
  });
});
