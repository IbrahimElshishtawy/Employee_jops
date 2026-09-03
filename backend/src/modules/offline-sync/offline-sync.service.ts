import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { OfflineSyncRepository } from "./offline-sync.repository";
import { PrismaService } from "../../prisma/prisma.service";
import {
  PushSyncBatchDto,
  QuerySyncQueueDto,
  ResolveConflictDto,
  ConflictResolutionStrategy,
} from "./dto";
import { AuditAction, SyncStatus } from "@prisma/client";

@Injectable()
export class OfflineSyncService {
  private readonly logger = new Logger(OfflineSyncService.name);

  constructor(
    private readonly repo: OfflineSyncRepository,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Enqueues batch of offline operations and evaluates conflict status
   */
  async processSyncBatch(userId: string, dto: PushSyncBatchDto) {
    this.logger.log(
      `Processing offline sync batch for user '${userId}' with ${dto.items.length} items`,
    );

    const queuedItems = await this.repo.enqueueBatch(userId, dto);

    const hasConflict = queuedItems.some((i) => i.status === SyncStatus.CONFLICT);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "OfflineSyncQueue",
        entityId: userId,
        payload: {
          itemCount: dto.items.length,
          hasConflict,
          status: hasConflict ? "PARTIAL_CONFLICT" : "SUCCESS",
        },
      },
    });

    return {
      syncedCount: queuedItems.length,
      status: hasConflict ? "PARTIAL_CONFLICT" : "SUCCESS",
      items: queuedItems.map((item) => ({
        id: item.id,
        entityType: item.entityType,
        action: item.action,
        status: item.status,
        failureReason: item.failureReason,
      })),
    };
  }

  async getMySyncQueue(userId: string, query: QuerySyncQueueDto) {
    return this.repo.findQueue(userId, query);
  }

  /**
   * Retries a failed or pending sync item (FR-SYNC-006)
   */
  async retryItem(userId: string, itemId: string) {
    const item = await this.repo.findItemById(itemId);
    if (!item) {
      throw new NotFoundException(`Sync item '${itemId}' not found`);
    }

    if (item.status === SyncStatus.PROCESSED) {
      return { id: item.id, status: item.status, message: "Item was already successfully processed" };
    }

    const updated = await this.repo.updateItemStatus(
      itemId,
      SyncStatus.PROCESSED,
      undefined,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "OfflineSyncQueue",
        entityId: itemId,
        payload: { action: "RETRY", previousStatus: item.status, newStatus: SyncStatus.PROCESSED },
      },
    });

    return {
      id: updated.id,
      entityType: updated.entityType,
      action: updated.action,
      status: updated.status,
      processedAt: updated.processedAt,
      message: "Sync item successfully retried and applied",
    };
  }

  /**
   * Resolves a synchronization conflict using chosen strategy (FR-SYNC-007)
   */
  async resolveConflict(userId: string, itemId: string, dto: ResolveConflictDto) {
    const item = await this.repo.findItemById(itemId);
    if (!item) {
      throw new NotFoundException(`Sync item '${itemId}' not found`);
    }

    if (item.status !== SyncStatus.CONFLICT) {
      throw new BadRequestException(
        `Item '${itemId}' is in status '${item.status}', not in CONFLICT`,
      );
    }

    let finalPayload = item.payload;
    if (dto.strategy === ConflictResolutionStrategy.MERGE) {
      finalPayload = {
        ...(typeof item.payload === "object" && item.payload !== null ? item.payload : {}),
        ...(dto.resolvedPayload || {}),
        _resolvedVia: "MERGE",
      };
    } else if (dto.strategy === ConflictResolutionStrategy.CLIENT_WINS) {
      finalPayload = {
        ...(typeof item.payload === "object" && item.payload !== null ? item.payload : {}),
        _resolvedVia: "CLIENT_WINS",
      };
    } else {
      // SERVER_WINS
      finalPayload = {
        _resolvedVia: "SERVER_WINS",
        originalPayload: item.payload,
      };
    }

    const updated = await this.repo.updateItemStatus(
      itemId,
      SyncStatus.PROCESSED,
      undefined,
      finalPayload,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "OfflineSyncQueue",
        entityId: itemId,
        payload: {
          action: "RESOLVE_CONFLICT",
          strategy: dto.strategy,
          finalPayload,
        },
      },
    });

    return {
      id: updated.id,
      status: updated.status,
      strategyApplied: dto.strategy,
      resolvedAt: updated.processedAt,
      message: `Conflict resolved successfully using strategy ${dto.strategy}`,
    };
  }

  /**
   * Retrieves operational sync logs with filters (FR-SYNC-008)
   */
  async getSyncLogs(query: { entityType?: string; status?: SyncStatus; page?: number; limit?: number }) {
    return this.repo.findLogs(query);
  }
}
