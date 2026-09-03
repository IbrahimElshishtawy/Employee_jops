import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { PushSyncBatchDto, QuerySyncQueueDto } from "./dto";
import { Prisma, SyncQueueStatus } from "@prisma/client";

@Injectable()
export class OfflineSyncRepository {
  constructor(private readonly prisma: PrismaService) {}

  async enqueueBatch(userId: string, dto: PushSyncBatchDto) {
    return this.prisma.$transaction(
      dto.items.map((item) =>
        this.prisma.offlineSyncQueue.create({
          data: {
            userId,
            deviceId: dto.deviceId,
            entityType: item.entityType,
            entityId: item.entityId,
            operation: item.operation,
            payload: item.payload,
            clientTimestamp: new Date(item.clientTimestamp),
            status: SyncQueueStatus.PROCESSED, // Mark processed in batch or simulate successful ingestion
            processedAt: new Date(),
          },
        }),
      ),
    );
  }

  async findQueue(userId: string, query: QuerySyncQueueDto) {
    const { page = 1, limit = 50, status, deviceId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.OfflineSyncQueueWhereInput = { userId };
    if (status) where.status = status;
    if (deviceId) where.deviceId = deviceId;

    const [total, items] = await Promise.all([
      this.prisma.offlineSyncQueue.count({ where }),
      this.prisma.offlineSyncQueue.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateItemStatus(id: string, status: SyncQueueStatus, errorMessage?: string) {
    return this.prisma.offlineSyncQueue.update({
      where: { id },
      data: {
        status,
        errorMessage,
        processedAt: new Date(),
      },
    });
  }
}
