import { Test, TestingModule } from "@nestjs/testing";
import { NotificationsService } from "./notifications.service";
import { AnnouncementsService } from "./announcements.service";
import { PrismaService } from "../../prisma/prisma.service";
import { ForbiddenException, BadRequestException } from "@nestjs/common";
import {
  NotificationType,
  NotificationPriority,
  AnnouncementStatus,
  AnnouncementTarget,
  DevicePlatform,
  Role,
} from "@prisma/client";

describe("NotificationsService & AnnouncementsService (Phase 06 Full Test Suite)", () => {
  let notificationsService: NotificationsService;
  let announcementsService: AnnouncementsService;

  const mockUserId = "user-test-uuid-1";
  const mockOtherUserId = "user-other-uuid-2";
  const mockHrUserId = "hr-admin-uuid-1";

  const mockPrismaService: any = {
    notification: {
      create: jest.fn(),
      createMany: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      count: jest.fn(),
    },
    notificationPreference: {
      findUnique: jest.fn(),
      create: jest.fn(),
      upsert: jest.fn(),
    },
    deviceToken: {
      findMany: jest.fn(),
      upsert: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    announcement: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    announcementRead: {
      upsert: jest.fn(),
    },
    user: {
      findMany: jest.fn(),
    },
    employeeProfile: {
      findUnique: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        AnnouncementsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    notificationsService =
      module.get<NotificationsService>(NotificationsService);
    announcementsService =
      module.get<AnnouncementsService>(AnnouncementsService);

    jest.clearAllMocks();
  });

  // ============================================================
  // TEST GROUP 1: NOTIFICATION LIFECYCLE & READ STATES
  // ============================================================
  describe("Notification Dispatch & Lifecycle", () => {
    it("1. should persist in-app notification in database", async () => {
      mockPrismaService.notificationPreference.findUnique.mockResolvedValue(
        null,
      );
      mockPrismaService.notificationPreference.create.mockResolvedValue({
        userId: mockUserId,
        attendanceNotifications: true,
        pushNotifications: true,
      });
      mockPrismaService.notification.create.mockResolvedValue({
        id: "notif-1",
        userId: mockUserId,
        title: "Check-in Verified",
        body: "You successfully clocked in at HQ",
        type: NotificationType.ATTENDANCE,
        priority: NotificationPriority.NORMAL,
      });
      mockPrismaService.deviceToken.findMany.mockResolvedValue([]);

      const result = await notificationsService.sendNotification(
        mockUserId,
        "Check-in Verified",
        "You successfully clocked in at HQ",
        NotificationType.ATTENDANCE,
      );

      expect(result?.id).toBe("notif-1");
      expect(mockPrismaService.notification.create).toHaveBeenCalled();
    });

    it("2. should retrieve paginated notifications for current user", async () => {
      mockPrismaService.notification.count.mockResolvedValue(1);
      mockPrismaService.notification.findMany.mockResolvedValue([
        { id: "notif-1", userId: mockUserId, title: "Test alert" },
      ]);

      const result = await notificationsService.getMyNotifications(mockUserId, {
        page: 1,
        limit: 10,
      });
      expect(result.data).toHaveLength(1);
      expect(result.meta.total).toBe(1);
      expect(mockPrismaService.notification.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: mockUserId } }),
      );
    });

    it("3. should mark single notification as read with ownership verification (IDOR protection)", async () => {
      mockPrismaService.notification.findUnique.mockResolvedValue({
        id: "notif-1",
        userId: mockUserId,
        isRead: false,
      });
      mockPrismaService.notification.update.mockResolvedValue({
        id: "notif-1",
        isRead: true,
      });

      const res = await notificationsService.markAsRead("notif-1", mockUserId);
      expect(res.isRead).toBe(true);

      // Other user marking should throw ForbiddenException
      mockPrismaService.notification.findUnique.mockResolvedValue({
        id: "notif-1",
        userId: mockOtherUserId,
      });
      await expect(
        notificationsService.markAsRead("notif-1", mockUserId),
      ).rejects.toThrow(ForbiddenException);
    });

    it("4. should mark all notifications as read in bulk for current user only", async () => {
      mockPrismaService.notification.updateMany.mockResolvedValue({ count: 5 });

      const res = await notificationsService.markAllAsRead(mockUserId);
      expect(res.count).toBe(5);
      expect(mockPrismaService.notification.updateMany).toHaveBeenCalledWith({
        where: { userId: mockUserId, isRead: false },
        data: expect.objectContaining({ isRead: true }),
      });
    });

    it("5. should calculate unread notification count accurately", async () => {
      mockPrismaService.notification.count.mockResolvedValue(3);

      const res = await notificationsService.getUnreadCount(mockUserId);
      expect(res.unreadCount).toBe(3);
    });
  });

  // ============================================================
  // TEST GROUP 2: MULTI-DEVICE PUSH & PREFERENCES
  // ============================================================
  describe("Device Tokens & Notification Preferences", () => {
    it("6. should register multi-platform device tokens for a user", async () => {
      mockPrismaService.deviceToken.upsert.mockResolvedValue({
        id: "dev-1",
        userId: mockUserId,
        fcmToken: "fcm-token-android-1",
        platform: DevicePlatform.ANDROID,
      });

      const res = await notificationsService.registerDeviceToken(mockUserId, {
        fcmToken: "fcm-token-android-1",
        platform: DevicePlatform.ANDROID,
      });

      expect(res.fcmToken).toBe("fcm-token-android-1");
    });

    it("7. should deactivate device token on logout", async () => {
      mockPrismaService.deviceToken.updateMany.mockResolvedValue({ count: 1 });

      await notificationsService.removeDeviceToken(
        mockUserId,
        "fcm-token-android-1",
      );
      expect(mockPrismaService.deviceToken.updateMany).toHaveBeenCalledWith({
        where: { userId: mockUserId, fcmToken: "fcm-token-android-1" },
        data: { isActive: false },
      });
    });

    it("8. should respect user preferences when category is disabled", async () => {
      mockPrismaService.notificationPreference.findUnique.mockResolvedValue({
        userId: mockUserId,
        payrollNotifications: false, // Payroll alerts disabled
      });

      const res = await notificationsService.sendNotification(
        mockUserId,
        "Payslip Ready",
        "August payslip generated",
        NotificationType.PAYROLL,
        {},
        NotificationPriority.NORMAL,
      );

      // Suppressed
      expect(res).toBeNull();
      expect(mockPrismaService.notification.create).not.toHaveBeenCalled();
    });

    it("9. should override user preferences for critical security notifications", async () => {
      mockPrismaService.notificationPreference.findUnique.mockResolvedValue({
        userId: mockUserId,
        attendanceNotifications: false,
      });
      mockPrismaService.notification.create.mockResolvedValue({
        id: "sec-notif-1",
        type: NotificationType.SECURITY,
      });
      mockPrismaService.deviceToken.findMany.mockResolvedValue([]);

      const res = await notificationsService.sendNotification(
        mockUserId,
        "Security Alert",
        "Suspicious login attempt detected",
        NotificationType.SECURITY,
        {},
        NotificationPriority.CRITICAL,
      );

      expect(res).toBeDefined();
      expect(mockPrismaService.notification.create).toHaveBeenCalled();
    });

    it("10. should update user preferences and create audit log", async () => {
      mockPrismaService.notificationPreference.upsert.mockResolvedValue({
        id: "pref-1",
        userId: mockUserId,
        pushNotifications: false,
      });

      const res = await notificationsService.updatePreferences(mockUserId, {
        pushNotifications: false,
      });

      expect(res.pushNotifications).toBe(false);
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });
  });

  // ============================================================
  // TEST GROUP 3: HR ANNOUNCEMENTS & TARGETING
  // ============================================================
  describe("HR Announcements & Audience Targeting", () => {
    it("11. should create announcement in DRAFT mode", async () => {
      mockPrismaService.announcement.create.mockResolvedValue({
        id: "ann-1",
        title: "Office Relocation",
        status: AnnouncementStatus.DRAFT,
      });

      const res = await announcementsService.createAnnouncement(
        {
          title: "Office Relocation",
          body: "We are moving to building B next month",
          targetType: AnnouncementTarget.ALL,
        },
        mockHrUserId,
      );

      expect(res.status).toBe(AnnouncementStatus.DRAFT);
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("12. should publish announcement and broadcast batch notifications to targeted audience", async () => {
      mockPrismaService.announcement.findUnique.mockResolvedValue({
        id: "ann-1",
        title: "Holiday Schedule",
        body: "Upcoming Eid holiday details",
        priority: NotificationPriority.NORMAL,
        targetType: AnnouncementTarget.DEPARTMENT,
        targetDepartment: "Engineering",
        status: AnnouncementStatus.DRAFT,
      });
      mockPrismaService.announcement.update.mockResolvedValue({
        id: "ann-1",
        status: AnnouncementStatus.PUBLISHED,
      });
      mockPrismaService.user.findMany.mockResolvedValue([
        { id: "user-eng-1" },
        { id: "user-eng-2" },
      ]);
      mockPrismaService.notification.createMany.mockResolvedValue({ count: 2 });
      mockPrismaService.deviceToken.findMany.mockResolvedValue([]);

      const res = await announcementsService.publishAnnouncement(
        "ann-1",
        mockHrUserId,
      );

      expect(res.status).toBe(AnnouncementStatus.PUBLISHED);
      expect(mockPrismaService.notification.createMany).toHaveBeenCalled();
    });

    it("13. should prevent duplicate publishing of already published announcement", async () => {
      mockPrismaService.announcement.findUnique.mockResolvedValue({
        id: "ann-1",
        status: AnnouncementStatus.PUBLISHED,
      });

      await expect(
        announcementsService.publishAnnouncement("ann-1", mockHrUserId),
      ).rejects.toThrow(BadRequestException);
    });

    it("14. should filter announcements visible to employee department", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        department: "Engineering",
        workplaceId: "wp-1",
      });
      mockPrismaService.announcement.count.mockResolvedValue(1);
      mockPrismaService.announcement.findMany.mockResolvedValue([
        {
          id: "ann-1",
          title: "Tech Talk",
          reads: [{ readAt: new Date() }],
        },
      ]);

      const res = await announcementsService.getAnnouncements(
        { id: mockUserId, role: Role.EMPLOYEE, employeeProfileId: "emp-1" },
        {},
      );

      expect(res.data[0].isRead).toBe(true);
    });

    it("15. should mark announcement as read by employee", async () => {
      mockPrismaService.announcementRead.upsert.mockResolvedValue({
        announcementId: "ann-1",
        userId: mockUserId,
      });

      const res = await announcementsService.markAsRead("ann-1", mockUserId);
      expect(res.announcementId).toBe("ann-1");
    });
  });
});
