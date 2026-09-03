import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { PushSyncBatchDto, QuerySyncQueueDto } from "./dto";
import { Prisma, SyncStatus } from "@prisma/client";

@Injectable()
export class OfflineSyncRepository {
  constructor(private readonly prisma: PrismaService) {}

  async enqueueBatch(userId: string, dto: PushSyncBatchDto) {
    return this.prisma.$transaction(
      dto.items.map((item) => {
        // Detect potential timestamp conflict: if item payload has serverConflict flag
        const isConflict = Boolean((item.payload as any)?.hasConflict);
        return this.prisma.offlineSyncQueue.create({
          data: {
            userId,
            entityType: item.entityType,
            action: item.action,
            payload: item.payload,
            clientTimestamp: new Date(item.clientTimestamp),
            status: isConflict ? SyncStatus.CONFLICT : SyncStatus.PROCESSED,
            failureReason: isConflict
              ? "Concurrent modification conflict detected"
              : null,
            processedAt: isConflict ? null : new Date(),
          },
        });
      }),
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

  async findItemById(id: string) {
    return this.prisma.offlineSyncQueue.findUnique({
      where: { id },
    });
  }

  async updateItemStatus(
    id: string,
    status: SyncStatus,
    failureReason?: string,
    payload?: any,
  ) {
    return this.prisma.offlineSyncQueue.update({
      where: { id },
      data: {
        status,
        failureReason,
        ...(payload ? { payload } : {}),
        processedAt: new Date(),
      },
    });
  }

  async findLogs(query: {
    entityType?: string;
    status?: SyncStatus;
    page?: number;
    limit?: number;
  }) {
    const { page = 1, limit = 50, entityType, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.OfflineSyncQueueWhereInput = {};
    if (entityType) where.entityType = entityType;
    if (status) where.status = status;

    const [total, items] = await Promise.all([
      this.prisma.offlineSyncQueue.count({ where }),
      this.prisma.offlineSyncQueue.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          user: {
            select: { id: true, email: true, role: true },
          },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }
}
