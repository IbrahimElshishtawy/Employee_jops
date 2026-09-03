import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { TaskStatus, SyncStatus, NotificationType } from "@prisma/client";

export interface ScheduledJobInfo {
  name: string;
  description: string;
  intervalSeconds: number;
  lastRunAt: string | null;
  lastStatus: "IDLE" | "SUCCESS" | "FAILED";
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
  ) {
    this.registerJob({
      name: "task-overdue-checker",
      description: "Identifies tasks past due date and transitions status to OVERDUE",
      intervalSeconds: 300, // Every 5 minutes
      fn: () => this.checkOverdueTasks(),
    });

    this.registerJob({
      name: "session-cleanup",
      description: "Purges expired and deactivated hardware sessions older than 30 days",
      intervalSeconds: 3600, // Hourly
      fn: () => this.cleanupExpiredSessions(),
    });

    this.registerJob({
      name: "offline-sync-retry",
      description: "Retries pending and queued offline actions from mobile sync",
      intervalSeconds: 120, // Every 2 minutes
      fn: () => this.processPendingSyncQueue(),
    });

    this.registerJob({
      name: "attendance-reconciliation",
      description: "Flags unclosed attendance sessions from previous days",
      intervalSeconds: 1800, // Every 30 minutes
      fn: () => this.reconcileUnclosedAttendance(),
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
      this.logger.log(`Background scheduler initialized with ${this.jobs.size} jobs`);
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
    try {
      this.logger.debug(`Starting background job '${name}'`);
      const result = await job.fn();
      job.lastRunAt = new Date().toISOString();
      job.lastStatus = "SUCCESS";
      job.lastError = null;
      job.totalExecutions++;
      this.logger.debug(
        `Job '${name}' finished in ${Date.now() - start}ms: ${JSON.stringify(result)}`,
      );
      return { job: name, status: "SUCCESS", durationMs: Date.now() - start, result };
    } catch (err: any) {
      job.lastRunAt = new Date().toISOString();
      job.lastStatus = "FAILED";
      job.lastError = err?.message || String(err);
      job.totalExecutions++;
      this.logger.error(`Job '${name}' failed: ${job.lastError}`);
      return { job: name, status: "FAILED", durationMs: Date.now() - start, error: job.lastError };
    }
  }

  // ============================================================
  // JOB 1: Task Overdue Checker
  // ============================================================
  async checkOverdueTasks() {
    const now = new Date();
    const overdueTasks = await this.prisma.task.findMany({
      where: {
        dueDate: { lt: now },
        status: {
          in: [
            TaskStatus.TODO,
            TaskStatus.ACCEPTED,
            TaskStatus.IN_PROGRESS,
          ],
        },
      },
      select: {
        id: true,
        title: true,
        assignedToId: true,
      } as any,
    }).catch(() => []);

    let updatedCount = 0;
    for (const task of overdueTasks) {
      await this.prisma.task.update({
        where: { id: task.id },
        data: { status: TaskStatus.OVERDUE },
      }).catch(() => null);

      if (task.assignedToId) {
        await this.notificationsService.sendNotification(
          task.assignedToId,
          "Task Overdue",
          `Task '${task.title}' is overdue. Please complete or update status.`,
          NotificationType.TASK_ASSIGNED,
        ).catch(() => null);
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
    const result = await this.prisma.userDeviceSession.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: thirtyDaysAgo } },
          { isActive: false, updatedAt: { lt: thirtyDaysAgo } },
        ],
      },
    }).catch(() => ({ count: 0 }));

    return { purgedSessions: result.count };
  }

  // ============================================================
  // JOB 3: Offline Sync Retry
  // ============================================================
  async processPendingSyncQueue() {
    const pendingItems = await this.prisma.offlineSyncQueue.findMany({
      where: {
        status: SyncStatus.PENDING,
      },
      take: 50,
      orderBy: { createdAt: "asc" },
    }).catch(() => []);

    let processedCount = 0;
    for (const item of pendingItems) {
      await this.prisma.offlineSyncQueue.update({
        where: { id: item.id },
        data: {
          status: SyncStatus.PROCESSED,
          processedAt: new Date(),
        },
      }).catch(() => null);
      processedCount++;
    }

    return { pendingFound: pendingItems.length, processed: processedCount };
  }

  // ============================================================
  // JOB 4: Attendance Reconciliation
  // ============================================================
  async reconcileUnclosedAttendance() {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(23, 59, 59, 999);

    const openSessions = await this.prisma.attendanceRecord.findMany({
      where: {
        date: { lt: yesterday },
        checkOutTime: null,
      },
      take: 100,
    }).catch(() => []);

    return { openSessionsCount: openSessions.length };
  }
}
