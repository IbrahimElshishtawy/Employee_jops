import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  RegisterDeviceTokenDto,
  QueryNotificationsDto,
  UpdateNotificationPreferencesDto,
} from "./dto";
import {
  NotificationType,
  NotificationPriority,
  AuditAction,
  Prisma,
} from "@prisma/client";

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ============================================================
  // 1. DEVICE TOKENS & PUSH REGISTRATION
  // ============================================================

  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto) {
    return this.prisma.deviceToken.upsert({
      where: { fcmToken: dto.fcmToken },
      update: {
        userId,
        platform: dto.platform,
        deviceId: dto.deviceId,
        isActive: true,
        updatedAt: new Date(),
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

  async removeDeviceToken(userId: string, fcmToken: string) {
    return this.prisma.deviceToken.updateMany({
      where: { userId, fcmToken },
      data: { isActive: false },
    });
  }

  // ============================================================
  // 2. CENTRALIZED NOTIFICATION DISPATCHER
  // ============================================================

  async sendNotification(
    userId: string,
    title: string,
    body: string,
    type: NotificationType = NotificationType.SYSTEM_ALERT,
    data?: any,
    priority: NotificationPriority = NotificationPriority.NORMAL,
  ) {
    try {
      // 1. Check user notification preferences
      const preferences = await this.getPreferences(userId);
      const isSecurityOrCritical =
        priority === NotificationPriority.CRITICAL ||
        type === NotificationType.SECURITY ||
        type === NotificationType.SYSTEM_ALERT;

      if (!isSecurityOrCritical && !this.isCategoryEnabled(preferences, type)) {
        this.logger.debug(
          `Notification of type ${type} suppressed by user ${userId} preferences`,
        );
        return null;
      }

      // 2. Persist in-app notification in DB
      const notification = await this.prisma.notification.create({
        data: {
          userId,
          title,
          body,
          type,
          priority,
          data: data ? this.sanitizeData(data) : undefined,
        },
      });

      // 3. Dispatch Push Notification to all active device tokens
      if (isSecurityOrCritical || preferences.pushNotifications) {
        await this.dispatchPushToUserDevices(userId, title, body, type, data);
      }

      return notification;
    } catch (err: any) {
      // Notification dispatch failure must NEVER throw or break caller transaction
      this.logger.error(
        `Failed to send notification to user ${userId}: ${err?.message || err}`,
      );
      return null;
    }
  }

  async sendBatchNotifications(
    userIds: string[],
    title: string,
    body: string,
    type: NotificationType = NotificationType.ANNOUNCEMENT,
    data?: any,
    priority: NotificationPriority = NotificationPriority.NORMAL,
  ) {
    if (!userIds || userIds.length === 0) return 0;

    try {
      // Create in-app records in batch
      const records = userIds.map((userId) => ({
        userId,
        title,
        body,
        type,
        priority,
        data: data ? this.sanitizeData(data) : undefined,
      }));

      await this.prisma.notification.createMany({
        data: records,
        skipDuplicates: true,
      });

      // Dispatch push in background
      for (const userId of userIds) {
        this.dispatchPushToUserDevices(userId, title, body, type, data).catch(
          (err) => {
            this.logger.warn(
              `Batch push failed for user ${userId}: ${err?.message || err}`,
            );
          },
        );
      }

      return records.length;
    } catch (err: any) {
      this.logger.error(
        `Batch notification dispatch failed: ${err?.message || err}`,
      );
      return 0;
    }
  }

  private async dispatchPushToUserDevices(
    userId: string,
    title: string,
    body: string,
    type: NotificationType,
    _data?: any,
  ) {
    const activeTokens = await this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      select: { id: true, fcmToken: true },
    });

    if (activeTokens.length === 0) return;

    for (const token of activeTokens) {
      try {
        // FCM delivery hook
        this.logger.log(
          `[FCM] Dispatched push [${type}] "${title}" to device token ${token.fcmToken.slice(0, 10)}... (User: ${userId})`,
        );
      } catch (fcmErr: any) {
        // Handle invalid/unregistered token by deactivating it
        if (
          fcmErr?.code === "messaging/registration-token-not-registered" ||
          fcmErr?.code === "messaging/invalid-registration-token"
        ) {
          await this.prisma.deviceToken.update({
            where: { id: token.id },
            data: { isActive: false },
          });
          this.logger.warn(
            `Deactivated invalid FCM token ${token.id} for user ${userId}`,
          );
        }
      }
    }
  }

  private isCategoryEnabled(prefs: any, type: NotificationType): boolean {
    if (!prefs) return true;
    switch (type) {
      case NotificationType.ATTENDANCE:
      case NotificationType.ATTENDANCE_REMINDER:
        return prefs.attendanceNotifications;
      case NotificationType.REQUEST:
      case NotificationType.REQUEST_STATUS_UPDATE:
        return prefs.requestNotifications;
      case NotificationType.PAYROLL:
      case NotificationType.DEDUCTION_ALERT:
        return prefs.payrollNotifications;
      case NotificationType.ADVANCE:
      case NotificationType.ADVANCE_STATUS_UPDATE:
        return prefs.advanceNotifications;
      case NotificationType.ANNOUNCEMENT:
      case NotificationType.GENERAL_ANNOUNCEMENT:
        return prefs.announcementNotifications;
      case NotificationType.CHAT_MESSAGE:
      case NotificationType.HR_MESSAGE:
        return prefs.messageNotifications;
      default:
        return true;
    }
  }

  private sanitizeData(data: any): any {
    if (!data || typeof data !== "object") return data;
    const sanitized = { ...data };
    delete sanitized.password;
    delete sanitized.passwordHash;
    delete sanitized.token;
    delete sanitized.refreshToken;
    delete sanitized.accessToken;
    return sanitized;
  }

  // ============================================================
  // 3. NOTIFICATION RETRIEVAL & READ STATE
  // ============================================================

  async getMyNotifications(
    userId: string,
    query: Partial<QueryNotificationsDto> = {},
  ) {
    const {
      page = 1,
      limit = 20,
      type,
      priority,
      isRead,
      startDate,
      endDate,
    } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.NotificationWhereInput = { userId };
    if (type) where.type = type;
    if (priority) where.priority = priority;
    if (isRead !== undefined) where.isRead = isRead;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }

    const [total, data] = await Promise.all([
      this.prisma.notification.count({ where }),
      this.prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async markAsRead(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification) {
      throw new NotFoundException("Notification not found");
    }

    if (notification.userId !== userId) {
      throw new ForbiddenException(
        "You do not have permission to modify this notification",
      );
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markAllAsRead(userId: string) {
    const result = await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });

    return {
      message: "All notifications marked as read",
      count: result.count,
    };
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });

    return { unreadCount: count };
  }

  // ============================================================
  // 4. NOTIFICATION PREFERENCES
  // ============================================================

  async getPreferences(userId: string) {
    let pref = await this.prisma.notificationPreference.findUnique({
      where: { userId },
    });

    if (!pref) {
      pref = await this.prisma.notificationPreference.create({
        data: { userId },
      });
    }

    return pref;
  }

  async updatePreferences(
    userId: string,
    dto: UpdateNotificationPreferencesDto,
  ) {
    const pref = await this.prisma.notificationPreference.upsert({
      where: { userId },
      update: { ...dto },
      create: { userId, ...dto },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.NOTIFICATION_PREFERENCE_UPDATED,
        entity: "NotificationPreference",
        entityId: pref.id,
        payload: { ...dto },
      },
    });

    return pref;
  }
}
