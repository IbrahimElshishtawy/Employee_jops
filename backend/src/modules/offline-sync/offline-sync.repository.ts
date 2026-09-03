import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { PushSyncBatchDto, QuerySyncQueueDto } from "./dto";
import { Prisma, SyncStatus } from "@prisma/client";

@Injectable()
export class OfflineSyncRepository {
  constructor(private readonly prisma: PrismaService) {}

  async enqueueBatch(userId: string, dto: PushSyncBatchDto) {
    return this.prisma.$transaction(
      dto.items.map((item) =>
        this.prisma.offlineSyncQueue.create({
          data: {
            userId,
            entityType: item.entityType,
            action: item.action,
            payload: item.payload,
            clientTimestamp: new Date(item.clientTimestamp),
            status: SyncStatus.PROCESSED,
            processedAt: new Date(),
          },
        }),
      ),
    );
  }

  async findQueue(userId: string, query: QuerySyncQueueDto) {
    const { page = 1, limit = 50, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.OfflineSyncQueueWhereInput = { userId };
    if (status) where.status = status;

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

  async updateItemStatus(id: string, status: SyncStatus, failureReason?: string) {
    return this.prisma.offlineSyncQueue.update({
      where: { id },
      data: {
        status,
        failureReason,
        processedAt: new Date(),
      },
    });
  }
}
