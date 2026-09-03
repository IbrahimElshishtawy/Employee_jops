import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  NotificationType,
  NotificationPriority,
  DevicePlatform,
  Prisma,
} from "@prisma/client";
import {
  RegisterDeviceTokenDto,
  QueryNotificationsDto,
  UpdateNotificationPreferencesDto,
} from "./dto";

@Injectable()
export class NotificationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // ============================================================
  // DEVICE TOKENS
  // ============================================================

  async upsertDeviceToken(userId: string, dto: RegisterDeviceTokenDto) {
    return this.prisma.deviceToken.upsert({
      where: { fcmToken: dto.fcmToken },
      create: {
        userId,
        fcmToken: dto.fcmToken,
        platform: dto.platform || DevicePlatform.ANDROID,
        deviceId: dto.deviceId,
        isActive: true,
      },
      update: {
        userId,
        platform: dto.platform || DevicePlatform.ANDROID,
        deviceId: dto.deviceId,
        isActive: true,
        updatedAt: new Date(),
      },
    });
  }

  async deactivateDeviceToken(fcmToken: string) {
    return this.prisma.deviceToken.updateMany({
      where: { fcmToken },
      data: { isActive: false },
    });
  }

  async findActiveTokensForUser(userId: string) {
    return this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      select: { id: true, fcmToken: true },
    });
  }

  async findActiveTokensForUsers(userIds: string[]) {
    return this.prisma.deviceToken.findMany({
      where: { userId: { in: userIds }, isActive: true },
      select: { id: true, fcmToken: true, userId: true },
    });
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  async createNotification(data: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    priority?: NotificationPriority;
    data?: any;
  }) {
    return this.prisma.notification.create({
      data: {
        userId: data.userId,
        title: data.title,
        body: data.body,
        type: data.type,
        priority: data.priority || NotificationPriority.NORMAL,
        data: data.data || Prisma.JsonNull,
      },
    });
  }

  async createBatchNotifications(notificationsData: any[]) {
    return this.prisma.notification.createMany({
      data: notificationsData,
    });
  }

  async findUserNotifications(userId: string, query: QueryNotificationsDto) {
    const { page = 1, limit = 20, isRead, type } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.NotificationWhereInput = { userId };
    if (isRead !== undefined) {
      where.isRead = isRead;
    }
    if (type) {
      where.type = type;
    }

    const [total, notifications] = await Promise.all([
      this.prisma.notification.count({ where }),
      this.prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      data: notifications,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async countUnread(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }

  async findNotificationById(id: string) {
    return this.prisma.notification.findUnique({
      where: { id },
    });
  }

  async markAsRead(id: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id, userId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  // ============================================================
  // PREFERENCES
  // ============================================================

  async findUserPreferences(userId: string) {
    return this.prisma.notificationPreference.findUnique({
      where: { userId },
    });
  }

  async upsertUserPreferences(
    userId: string,
    dto: UpdateNotificationPreferencesDto,
  ) {
    return this.prisma.notificationPreference.upsert({
      where: { userId },
      create: {
        userId,
        ...dto,
      },
      update: {
        ...dto,
        updatedAt: new Date(),
      },
    });
  }
}
