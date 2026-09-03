import {
  Injectable,
  Logger,
} from "@nestjs/common";
import { OfflineSyncRepository } from "./offline-sync.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { PushSyncBatchDto, QuerySyncQueueDto } from "./dto";
import { AuditAction, SyncQueueStatus } from "@prisma/client";

@Injectable()
export class OfflineSyncService {
  private readonly logger = new Logger(OfflineSyncService.name);

  constructor(
    private readonly repo: OfflineSyncRepository,
    private readonly prisma: PrismaService,
  ) {}

  async processSyncBatch(userId: string, dto: PushSyncBatchDto) {
    this.logger.log(
      `Processing offline sync batch for user '${userId}' from device '${dto.deviceId}' with ${dto.items.length} items`,
    );

    const queuedItems = await this.repo.enqueueBatch(userId, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "OfflineSyncQueue",
        entityId: dto.deviceId,
        payload: {
          itemCount: dto.items.length,
          deviceId: dto.deviceId,
          status: SyncQueueStatus.PROCESSED,
        },
      },
    });

    return {
      syncedCount: queuedItems.length,
      status: "SUCCESS",
      items: queuedItems.map((item) => ({
        id: item.id,
        entityType: item.entityType,
        entityId: item.entityId,
        status: item.status,
      })),
    };
  }

  async getMySyncQueue(userId: string, query: QuerySyncQueueDto) {
    return this.repo.findQueue(userId, query);
  }
}
