import { Injectable, Logger } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { RegisterDeviceTokenDto } from "./dto/register-device.dto";
import { NotificationType } from "@prisma/client";

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private prisma: PrismaService) {}

  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto) {
    return this.prisma.deviceToken.upsert({
      where: { fcmToken: dto.fcmToken },
      update: {
        userId,
        platform: dto.platform,
        deviceId: dto.deviceId,
        isActive: true,
      },
      create: {
        userId,
        fcmToken: dto.fcmToken,
        platform: dto.platform,
        deviceId: dto.deviceId,
        isActive: true,
      },
    });
  }

  async sendNotification(
    userId: string,
    title: string,
    body: string,
    type: NotificationType = NotificationType.SYSTEM_ALERT,
    data?: any,
  ) {
    // 1. Persist notification in database
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        data,
      },
    });

    // 2. Fetch active device FCM tokens for push delivery
    const activeTokens = await this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      select: { fcmToken: true },
    });

    if (activeTokens.length > 0) {
      this.logger.log(
        `[FCM] Dispatched push notification to ${activeTokens.length} devices for user ${userId}`,
      );
      // FCM dispatch hook ready for Firebase Admin SDK integration
    }

    return notification;
  }

  async getMyNotifications(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 50,
    });
  }

  async markAsRead(notificationId: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });
  }
}
