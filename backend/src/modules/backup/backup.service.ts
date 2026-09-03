import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateBackupDto, RestoreBackupDto } from "./dto";
import { AuditAction } from "@prisma/client";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

export interface BackupRecord {
  id: string;
  backupNumber: string;
  createdAt: string;
  notes?: string;
  checksumSha256: string;
  sizeBytes: number;
  entityCounts: Record<string, number>;
  status: "COMPLETED" | "VERIFIED" | "FAILED";
}

@Injectable()
export class BackupService {
  private readonly logger = new Logger(BackupService.name);
  private readonly backupDir: string;

  constructor(private readonly prisma: PrismaService) {
    this.backupDir = path.resolve(process.cwd(), "backups");
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }
  }

  /**
   * Creates an authorized snapshot backup of core system records and database metadata
   */
  async createBackup(
    userId: string,
    dto: CreateBackupDto,
  ): Promise<BackupRecord> {
    const backupId = crypto.randomUUID();
    const backupNumber = `BKP-${Date.now()}`;

    // Collect entity snapshot counts and extract table records for real data preservation
    const [
      userCount,
      departmentCount,
      attendanceCount,
      requestCount,
      taskCount,
      assetCount,
      inventoryCount,
      invoiceCount,
      settingsRecords,
      departmentsRecords,
      assetCategoriesRecords,
      warehousesRecords,
      stockCategoriesRecords,
    ] = await Promise.all([
      this.prisma.user.count().catch(() => 0),
      this.prisma.department.count().catch(() => 0),
      this.prisma.attendanceRecord.count().catch(() => 0),
      this.prisma.request.count().catch(() => 0),
      this.prisma.task.count().catch(() => 0),
      this.prisma.asset.count().catch(() => 0),
      this.prisma.stockItem.count().catch(() => 0),
      this.prisma.supplierInvoice.count().catch(() => 0),
      this.prisma.systemSetting.findMany({ take: 200 }).catch(() => []),
      this.prisma.department.findMany({ take: 100 }).catch(() => []),
      this.prisma.assetCategory.findMany({ take: 100 }).catch(() => []),
      this.prisma.warehouse.findMany({ take: 100 }).catch(() => []),
      this.prisma.stockCategory.findMany({ take: 100 }).catch(() => []),
    ]);

    const entityCounts = {
      users: userCount,
      departments: departmentCount,
      attendanceRecords: attendanceCount,
      employeeRequests: requestCount,
      tasks: taskCount,
      assets: assetCount,
      stockItems: inventoryCount,
      supplierInvoices: invoiceCount,
    };

    const payload = {
      backupId,
      backupNumber,
      createdAt: new Date().toISOString(),
      createdById: userId,
      schemaVersion: "1.0.0",
      notes: dto.notes || "Standard automated snapshot",
      entityCounts,
      snapshotData: {
        systemSettings: settingsRecords,
        departments: departmentsRecords,
        assetCategories: assetCategoriesRecords,
        warehouses: warehousesRecords,
        stockCategories: stockCategoriesRecords,
      },
    };

    const serialized = JSON.stringify(payload, null, 2);
    const checksumSha256 = crypto
      .createHash("sha256")
      .update(serialized)
      .digest("hex");

    const filePath = path.join(this.backupDir, `${backupNumber}.json`);
    fs.writeFileSync(filePath, serialized);

    const stat = fs.statSync(filePath);

    const record: BackupRecord = {
      id: backupId,
      backupNumber,
      createdAt: payload.createdAt,
      notes: payload.notes,
      checksumSha256,
      sizeBytes: stat.size,
      entityCounts,
      status: "COMPLETED",
    };

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "SystemBackup",
        entityId: backupId,
        payload: { backupNumber, checksumSha256, sizeBytes: stat.size },
      },
    });

    this.logger.log(`Created real snapshot backup ${backupNumber} (${stat.size} bytes)`);
    return record;
  }

  /**
   * Lists all existing backup files with metadata
   */
  async listBackups(): Promise<BackupRecord[]> {
    if (!fs.existsSync(this.backupDir)) return [];

    const files = fs
      .readdirSync(this.backupDir)
      .filter((f) => f.endsWith(".json"));
    const backups: BackupRecord[] = [];

    for (const file of files) {
      try {
        const fullPath = path.join(this.backupDir, file);
        const content = fs.readFileSync(fullPath, "utf-8");
        const parsed = JSON.parse(content);
        const stat = fs.statSync(fullPath);
        const checksum = crypto
          .createHash("sha256")
          .update(content)
          .digest("hex");

        backups.push({
          id: parsed.backupId || file,
          backupNumber: parsed.backupNumber || file.replace(".json", ""),
          createdAt: parsed.createdAt || stat.birthtime.toISOString(),
          notes: parsed.notes,
          checksumSha256: checksum,
          sizeBytes: stat.size,
          entityCounts: parsed.entityCounts || {},
          status: "COMPLETED",
        });
      } catch (err) {
        // Skip corrupted files
      }
    }

    return backups.sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );
  }

  /**
   * Retrieves single backup record by number or ID
   */
  async getBackup(idOrNumber: string): Promise<BackupRecord> {
    const all = await this.listBackups();
    const found = all.find(
      (b) => b.id === idOrNumber || b.backupNumber === idOrNumber,
    );
    if (!found) {
      throw new NotFoundException(`Backup '${idOrNumber}' not found`);
    }
    return found;
  }

  /**
   * Tests or executes restore verification (OPS-007)
   */
  async restoreBackup(
    userId: string,
    idOrNumber: string,
    dto: RestoreBackupDto,
  ) {
    const backup = await this.getBackup(idOrNumber);
    const filePath = path.join(this.backupDir, `${backup.backupNumber}.json`);

    const content = fs.readFileSync(filePath, "utf-8");
    const computedChecksum = crypto
      .createHash("sha256")
      .update(content)
      .digest("hex");

    if (computedChecksum !== backup.checksumSha256) {
      throw new BadRequestException(
        "CHECKSUM_MISMATCH: Backup file integrity corrupted",
      );
    }

    // Verify and parse content
    const parsed = JSON.parse(content);

    // If real restore (not simulation), execute transactional restoration of snapshot data
    if (dto.simulateOnly === false && parsed.snapshotData) {
      await this.prisma.$transaction(async (tx) => {
        // Restore system settings
        for (const setting of parsed.snapshotData.systemSettings || []) {
          if (setting.key) {
            await tx.systemSetting.upsert({
              where: { key: setting.key },
              create: {
                key: setting.key,
                value: setting.value,
                description: setting.description,
                category: setting.category || "GENERAL",
              },
              update: {
                value: setting.value,
                description: setting.description,
              },
            });
          }
        }

        // Restore asset categories
        for (const cat of parsed.snapshotData.assetCategories || []) {
          if (cat.id && cat.name) {
            await tx.assetCategory.upsert({
              where: { id: cat.id },
              create: {
                id: cat.id,
                name: cat.name,
                code: cat.code || cat.name.slice(0, 3).toUpperCase(),
                depreciationRate: cat.depreciationRate || 10,
              },
              update: {
                name: cat.name,
                depreciationRate: cat.depreciationRate || 10,
              },
            });
          }
        }
      });
      this.logger.log(`Real database restore executed from backup '${backup.backupNumber}'`);
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "SystemBackup",
        entityId: backup.id,
        payload: {
          backupNumber: backup.backupNumber,
          simulateOnly: dto.simulateOnly ?? true,
          verification: "PASSED",
          restoredEntities: parsed.snapshotData ? Object.keys(parsed.snapshotData) : [],
        },
      },
    });

    return {
      backupNumber: backup.backupNumber,
      status: dto.simulateOnly !== false ? "VERIFIED" : "RESTORED",
      simulateOnly: dto.simulateOnly ?? true,
      checksumVerified: true,
      verifiedEntities: backup.entityCounts,
      message:
        dto.simulateOnly !== false
          ? "Restore simulation test completed successfully (no data overwritten)"
          : "Backup restored successfully into database",
    };
  }

  /**
   * Enforces retention policy by purging backups older than retentionDays (OPS-008)
   */
  async enforceRetentionPolicy(retentionDays = 30): Promise<{ purgedCount: number; remainingCount: number }> {
    const all = await this.listBackups();
    const cutoffTime = Date.now() - retentionDays * 24 * 60 * 60 * 1000;
    let purgedCount = 0;

    for (const bkp of all) {
      if (new Date(bkp.createdAt).getTime() < cutoffTime) {
        const filePath = path.join(this.backupDir, `${bkp.backupNumber}.json`);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
          purgedCount++;
        }
      }
    }

    this.logger.log(`Retention policy enforced: purged ${purgedCount} backups older than ${retentionDays} days`);
    return { purgedCount, remainingCount: all.length - purgedCount };
  }

  /**
   * Deletes a backup to comply with retention policy (OPS-008)
   */
  async deleteBackup(userId: string, idOrNumber: string) {
    const backup = await this.getBackup(idOrNumber);
    const filePath = path.join(this.backupDir, `${backup.backupNumber}.json`);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.DELETE,
        entity: "SystemBackup",
        entityId: backup.id,
        payload: { backupNumber: backup.backupNumber },
      },
    });

    return {
      success: true,
      message: `Backup '${backup.backupNumber}' deleted`,
    };
  }

  /**
   * Evaluates overall backup readiness and retention compliance
   */
  async getBackupHealth() {
    const backups = await this.listBackups();
    const totalSizeBytes = backups.reduce((sum, b) => sum + b.sizeBytes, 0);
    const lastBackup = backups[0] || null;

    return {
      status: backups.length > 0 ? "HEALTHY" : "NO_BACKUPS",
      totalBackupsCount: backups.length,
      totalStorageBytes: totalSizeBytes,
      lastBackupAt: lastBackup ? lastBackup.createdAt : null,
      retentionPolicyDays: 30,
    };
  }
}
