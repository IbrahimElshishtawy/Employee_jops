import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { NotificationsRepository } from "./notifications.repository";
import { FcmService } from "./fcm.service";
import { RealTimeService } from "../realtime/realtime.service";
import {
  RegisterDeviceTokenDto,
  QueryNotificationsDto,
  UpdateNotificationPreferencesDto,
} from "./dto";
import {
  NotificationType,
  NotificationPriority,
  AuditAction,
} from "@prisma/client";
import { PrismaService } from "../../prisma/prisma.service";

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly notificationsRepo: NotificationsRepository,
    private readonly fcmService: FcmService,
    private readonly realtimeService: RealTimeService,
    private readonly prisma: PrismaService,
  ) {}

  // ============================================================
  // 1. DEVICE TOKENS & PUSH REGISTRATION
  // ============================================================

  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto) {
    return this.notificationsRepo.upsertDeviceToken(userId, dto);
  }

  async removeDeviceToken(userId: string, fcmToken: string) {
    return this.notificationsRepo.deactivateDeviceToken(fcmToken);
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

      // 2. Persist in-app notification in DB via repository
      const notification = await this.notificationsRepo.createNotification({
        userId,
        title,
        body,
        type,
        priority,
        data: data ? this.sanitizeData(data) : undefined,
      });

      // 3. Emit real-time WebSocket event to user's private room: "user:{userId}"
      this.realtimeService.emitToUser(userId, "new_notification", notification);

      // 4. Dispatch Push Notification to all active device tokens via real FCM
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

      await this.notificationsRepo.createBatchNotifications(records);

      // Dispatch RealTime event & Push in background
      for (const userId of userIds) {
        this.realtimeService.emitToUser(userId, "new_notification", {
          userId,
          title,
          body,
          type,
          priority,
          data,
          createdAt: new Date(),
        });

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
    data?: any,
  ) {
    const activeTokens =
      await this.notificationsRepo.findActiveTokensForUser(userId);

    if (activeTokens.length === 0) return;

    for (const token of activeTokens) {
      try {
        const res = await this.fcmService.sendToDevice(
          token.fcmToken,
          title,
          body,
          {
            type,
            ...(data || {}),
          },
        );

        if (!res.success && res.isTokenInvalid) {
          // Deactivate invalid / unregistered device token in DB
          await this.notificationsRepo.deactivateDeviceToken(token.fcmToken);
          this.logger.warn(
            `Deactivated invalid FCM token ${token.id} for user ${userId}`,
          );
        }
      } catch (fcmErr: any) {
        this.logger.warn(
          `FCM delivery exception for user ${userId}: ${fcmErr?.message || fcmErr}`,
        );
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
      case NotificationType.TASK_ASSIGNED:
      case NotificationType.TASK_STATUS_UPDATE:
      case NotificationType.TASK_REPORT_SUBMITTED:
      case NotificationType.TASK_REPORT_REVIEWED:
        return prefs.taskNotifications !== false;
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
    return this.notificationsRepo.findUserNotifications(
      userId,
      query as QueryNotificationsDto,
    );
  }

  async markAsRead(notificationId: string, userId: string) {
    const notification =
      await this.notificationsRepo.findNotificationById(notificationId);

    if (!notification) {
      throw new NotFoundException("Notification not found");
    }

    if (notification.userId !== userId) {
      throw new ForbiddenException(
        "You do not have permission to modify this notification",
      );
    }

    await this.notificationsRepo.markAsRead(notificationId, userId);
    return { ...notification, isRead: true, readAt: new Date() };
  }

  async markAllAsRead(userId: string) {
    const result = await this.notificationsRepo.markAllAsRead(userId);

    return {
      message: "All notifications marked as read",
      count: result.count,
    };
  }

  async getUnreadCount(userId: string) {
    const count = await this.notificationsRepo.countUnread(userId);
    return { unreadCount: count };
  }

  // ============================================================
  // 4. NOTIFICATION PREFERENCES
  // ============================================================

  async getPreferences(userId: string) {
    let pref = await this.notificationsRepo.findUserPreferences(userId);

    if (!pref) {
      pref = await this.notificationsRepo.upsertUserPreferences(userId, {
        attendanceNotifications: true,
        requestNotifications: true,
        payrollNotifications: true,
        advanceNotifications: true,
        announcementNotifications: true,
        messageNotifications: true,
        emailNotifications: true,
        pushNotifications: true,
      });
    }

    return pref;
  }

  async updatePreferences(
    userId: string,
    dto: UpdateNotificationPreferencesDto,
  ) {
    const pref = await this.notificationsRepo.upsertUserPreferences(
      userId,
      dto,
    );

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
