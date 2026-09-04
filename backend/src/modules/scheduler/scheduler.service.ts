import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { DistributedLockService } from "./distributed-lock.service";
import { OfflineSyncService } from "../offline-sync/offline-sync.service";
import { TaskStatus, SyncStatus, NotificationType } from "@prisma/client";
import * as fs from "fs";
import * as path from "path";

export interface ScheduledJobInfo {
  name: string;
  description: string;
  intervalSeconds: number;
  lastRunAt: string | null;
  lastStatus: "IDLE" | "SUCCESS" | "FAILED" | "SKIPPED";
  lastError: string | null;
  totalExecutions: number;
  fn: () => Promise<any>;
}

@Injectable()
export class SchedulerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(SchedulerService.name);
  private timers: NodeJS.Timeout[] = [];
  private jobs: Map<string, ScheduledJobInfo> = new Map();

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly lockService: DistributedLockService,
    private readonly offlineSyncService: OfflineSyncService,
  ) {
    this.registerJob({
      name: "task-overdue-checker",
      description:
        "Identifies tasks past due date and transitions status to OVERDUE",
      intervalSeconds: 300, // Every 5 minutes
      fn: () => this.checkOverdueTasks(),
    });

    this.registerJob({
      name: "session-cleanup",
      description:
        "Purges expired and deactivated hardware sessions older than 30 days",
      intervalSeconds: 3600, // Hourly
      fn: () => this.cleanupExpiredSessions(),
    });

    this.registerJob({
      name: "offline-sync-retry",
      description:
        "Retries pending and queued offline actions from mobile sync",
      intervalSeconds: 120, // Every 2 minutes
      fn: () => this.processPendingSyncQueue(),
    });

    this.registerJob({
      name: "attendance-reconciliation",
      description: "Flags unclosed attendance sessions from previous days",
      intervalSeconds: 1800, // Every 30 minutes
      fn: () => this.reconcileUnclosedAttendance(),
    });

    this.registerJob({
      name: "backup-retention-cleanup",
      description: "Purges backup archives older than 30 days retention policy",
      intervalSeconds: 86400, // Daily
      fn: () => this.cleanupOldBackups(),
    });

    this.registerJob({
      name: "inventory-low-stock-alert",
      description: "Audits warehouse inventory and triggers reorder warnings",
      intervalSeconds: 3600, // Hourly
      fn: () => this.checkLowStockItems(),
    });
  }

  onModuleInit() {
    // Only launch background timers in non-test runtime
    if (process.env.NODE_ENV !== "test") {
      for (const [name, job] of this.jobs.entries()) {
        const timer = setInterval(async () => {
          await this.executeJob(name);
        }, job.intervalSeconds * 1000);
        timer.unref(); // Ensure process can exit gracefully
        this.timers.push(timer);
      }
      this.logger.log(
        `Background scheduler initialized with ${this.jobs.size} jobs`,
      );
    }
  }

  onModuleDestroy() {
    for (const timer of this.timers) {
      clearInterval(timer);
    }
    this.timers = [];
  }

  private registerJob(config: {
    name: string;
    description: string;
    intervalSeconds: number;
    fn: () => Promise<any>;
  }) {
    this.jobs.set(config.name, {
      ...config,
      lastRunAt: null,
      lastStatus: "IDLE",
      lastError: null,
      totalExecutions: 0,
    });
  }

  async listJobs() {
    return Array.from(this.jobs.values()).map((j) => ({
      name: j.name,
      description: j.description,
      intervalSeconds: j.intervalSeconds,
      lastRunAt: j.lastRunAt,
      lastStatus: j.lastStatus,
      lastError: j.lastError,
      totalExecutions: j.totalExecutions,
    }));
  }

  async executeJob(name: string) {
    const job = this.jobs.get(name);
    if (!job) {
      throw new NotFoundException(`Job '${name}' not found`);
    }

    const start = Date.now();
    const lockTtlMs = Math.max(30000, job.intervalSeconds * 1000);

    const lockExecution = await this.lockService.withLock(
      `scheduler:${name}`,
      lockTtlMs,
      async () => {
        this.logger.debug(`Starting background job '${name}'`);
        const result = await job.fn();
        job.lastRunAt = new Date().toISOString();
        job.lastStatus = "SUCCESS";
        job.lastError = null;
        job.totalExecutions++;
        this.logger.debug(
          `Job '${name}' finished in ${Date.now() - start}ms: ${JSON.stringify(result)}`,
        );
        return result;
      },
    );

    if (!lockExecution.executed) {
      this.logger.log(
        `Job '${name}' execution skipped: locked by another active instance`,
      );
      job.lastStatus = "SKIPPED";
      return {
        job: name,
        status: "SKIPPED",
        reason: "LOCKED_BY_ANOTHER_INSTANCE",
        durationMs: Date.now() - start,
      };
    }

    return {
      job: name,
      status: "SUCCESS",
      durationMs: Date.now() - start,
      result: lockExecution.result,
    };
  }

  // ============================================================
  // JOB 1: Task Overdue Checker
  // ============================================================
  async checkOverdueTasks() {
    const now = new Date();
    const overdueTasks = await this.prisma.task
      .findMany({
        where: {
          dueDate: { lt: now },
          status: {
            in: [TaskStatus.TODO, TaskStatus.ACCEPTED, TaskStatus.IN_PROGRESS],
          },
        },
        include: {
          assignee: {
            select: { userId: true },
          },
        },
      })
      .catch(() => []);

    let updatedCount = 0;
    for (const task of overdueTasks) {
      await this.prisma.task
        .update({
          where: { id: task.id },
          data: { status: TaskStatus.OVERDUE },
        })
        .catch(() => null);

      if (task.assignee?.userId) {
        await this.notificationsService
          .sendNotification(
            task.assignee.userId,
            "Task Overdue",
            `Task '${task.title}' is overdue. Please complete or update status.`,
            NotificationType.TASK_ASSIGNED,
          )
          .catch(() => null);
      }
      updatedCount++;
    }

    return { processed: overdueTasks.length, updated: updatedCount };
  }

  // ============================================================
  // JOB 2: Session Cleanup
  // ============================================================
  async cleanupExpiredSessions() {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const result = await this.prisma.userDeviceSession
      .deleteMany({
        where: {
          OR: [
            { expiresAt: { lt: thirtyDaysAgo } },
            { isActive: false, updatedAt: { lt: thirtyDaysAgo } },
          ],
        },
      })
      .catch(() => ({ count: 0 }));

    return { purgedSessions: result.count };
  }

  // ============================================================
  // JOB 3: Offline Sync Retry
  // ============================================================
  async processPendingSyncQueue() {
    const pendingItems = await this.prisma.offlineSyncQueue
      .findMany({
        where: {
          status: { in: [SyncStatus.PENDING, SyncStatus.FAILED] },
        },
        take: 50,
        orderBy: { createdAt: "asc" },
      })
      .catch(() => []);

    let processedCount = 0;
    let failedCount = 0;

    for (const item of pendingItems) {
      const payloadObj =
        typeof item.payload === "object" && item.payload !== null
          ? (item.payload as any)
          : {};
      const retryAttempts = (payloadObj._retryAttempts || 0) + 1;
      const MAX_RETRIES = 5;

      if (retryAttempts > MAX_RETRIES) {
        await this.prisma.offlineSyncQueue
          .update({
            where: { id: item.id },
            data: {
              status: SyncStatus.FAILED,
              failureReason: `Max retry limit (${MAX_RETRIES}) reached`,
            },
          })
          .catch(() => null);
        failedCount++;
        continue;
      }

      const result = await this.offlineSyncService.applyEntityOperation(
        item.userId,
        {
          entityType: item.entityType,
          action: item.action,
          entityId: payloadObj.id || payloadObj.taskId,
          payload: { ...payloadObj, _retryAttempts: retryAttempts },
          clientTimestamp: item.clientTimestamp,
        },
      );

      await this.prisma.offlineSyncQueue
        .update({
          where: { id: item.id },
          data: {
            status: result.status,
            failureReason: result.failureReason || null,
            processedAt:
              result.status === SyncStatus.PROCESSED ? new Date() : null,
            payload: { ...payloadObj, _retryAttempts: retryAttempts },
          },
        })
        .catch(() => null);

      if (result.status === SyncStatus.PROCESSED) {
        processedCount++;
      } else {
        failedCount++;
      }
    }

    return {
      pendingFound: pendingItems.length,
      processed: processedCount,
      failed: failedCount,
    };
  }

  // ============================================================
  // JOB 4: Attendance Reconciliation
  // ============================================================
  async reconcileUnclosedAttendance() {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(23, 59, 59, 999);

    const openSessions = await this.prisma.attendanceRecord
      .findMany({
        where: {
          date: { lt: yesterday },
          checkOutTime: null,
        },
        take: 100,
      })
      .catch(() => []);

    return { openSessionsCount: openSessions.length };
  }

  // ============================================================
  // JOB 5: Backup Retention Policy Enforcement
  // ============================================================
  async cleanupOldBackups() {
    const backupDir = path.resolve(process.cwd(), "backups");
    if (!fs.existsSync(backupDir)) return { purgedCount: 0 };

    const retentionDays = 30;
    const cutoffTime = Date.now() - retentionDays * 24 * 60 * 60 * 1000;
    const files = fs.readdirSync(backupDir).filter((f) => f.endsWith(".json"));
    let purgedCount = 0;

    for (const file of files) {
      try {
        const fullPath = path.join(backupDir, file);
        const stat = fs.statSync(fullPath);
        if (stat.mtimeMs < cutoffTime) {
          fs.unlinkSync(fullPath);
          purgedCount++;
        }
      } catch (err) {
        // Skip inaccessible files
      }
    }

    return { purgedCount, retentionDays };
  }

  // ============================================================
  // JOB 6: Inventory Low Stock Alert
  // ============================================================
  async checkLowStockItems() {
    const items = await this.prisma.stockItem
      .findMany({
        where: { isActive: true },
        take: 100,
      })
      .catch(() => []);

    const lowStock = items.filter(
      (item: any) => item.quantityOnHand <= item.reorderLevel,
    );
    return { lowStockItemsCount: lowStock.length };
  }
}
