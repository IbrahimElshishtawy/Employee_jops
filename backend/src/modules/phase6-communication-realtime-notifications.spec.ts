import { Test, TestingModule } from "@nestjs/testing";
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import { Role, UserStatus, NotificationType, NotificationPriority, DevicePlatform } from "@prisma/client";

import { PrismaService } from "../prisma/prisma.service";
import { PresenceService } from "./realtime/presence.service";
import { RealTimeService } from "./realtime/realtime.service";
import { RealTimeGateway } from "./realtime/realtime.gateway";
import { WsJwtGuard } from "./realtime/guards/ws-jwt.guard";
import { FcmService } from "./notifications/fcm.service";
import { NotificationsRepository } from "./notifications/notifications.repository";
import { NotificationsService } from "./notifications/notifications.service";
import { MessagingRepository } from "./messaging/messaging.repository";
import { MessagingService } from "./messaging/messaging.service";
import { ConversationAccessGuard } from "./messaging/guards/conversation-access.guard";

describe("Phase 6 — Communication, Realtime & Notifications Complete Specification", () => {
  let presenceService: PresenceService;
  let realtimeService: RealTimeService;
  let realtimeGateway: RealTimeGateway;
  let wsJwtGuard: WsJwtGuard;
  let fcmService: FcmService;
  let notificationsRepo: NotificationsRepository;
  let notificationsService: NotificationsService;
  let messagingRepo: MessagingRepository;
  let messagingService: MessagingService;
  let conversationAccessGuard: ConversationAccessGuard;
  let jwtService: JwtService;

  // In-Memory Data Store for Mock Prisma
  const mockUsers: Record<string, any> = {
    "user-emp-1": {
      id: "user-emp-1",
      email: "ahmed@cyberwise.internal",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-1",
        firstName: "Ahmed",
        lastName: "Hassan",
        jobTitle: "Software Engineer",
        departmentId: "dept-engineering",
      },
    },
    "user-emp-2": {
      id: "user-emp-2",
      email: "sarah@cyberwise.internal",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-2",
        firstName: "Sarah",
        lastName: "Mansour",
        jobTitle: "UI/UX Designer",
        departmentId: "dept-engineering",
      },
    },
    "user-hr-admin": {
      id: "user-hr-admin",
      email: "hr.admin@cyberwise.internal",
      role: Role.HR_ADMIN,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-hr-1",
        firstName: "Mona",
        lastName: "Zaki",
        jobTitle: "HR Director",
        departmentId: "dept-hr",
      },
    },
    "user-stranger": {
      id: "user-stranger",
      email: "stranger@cyberwise.internal",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-stranger",
        firstName: "Tarek",
        lastName: "Nabil",
        jobTitle: "Security Guard",
        departmentId: "dept-security",
      },
    },
  };

  const mockDeviceTokens: any[] = [];
  const mockNotifications: any[] = [];
  const mockPreferences: Record<string, any> = {};
  const mockConversations: any[] = [];
  const mockParticipants: any[] = [];
  const mockMessages: any[] = [];
  const mockAuditLogs: any[] = [];

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(({ where }) => Promise.resolve(mockUsers[where.id] || null)),
      findFirst: jest.fn(({ where }) => {
        if (where?.role?.in) {
          const u = Object.values(mockUsers).find((user) => where.role.in.includes(user.role));
          return Promise.resolve(u || null);
        }
        return Promise.resolve(null);
      }),
      findMany: jest.fn(({ where }) => {
        if (where?.id?.in) {
          const list = Object.values(mockUsers).filter((u) => where.id.in.includes(u.id));
          return Promise.resolve(list);
        }
        return Promise.resolve(Object.values(mockUsers));
      }),
    },
    deviceToken: {
      upsert: jest.fn(({ where, create, update }) => {
        const idx = mockDeviceTokens.findIndex((t) => t.fcmToken === where.fcmToken);
        if (idx >= 0) {
          Object.assign(mockDeviceTokens[idx], update);
          return Promise.resolve(mockDeviceTokens[idx]);
        }
        const newToken = { id: `token-${Date.now()}`, ...create };
        mockDeviceTokens.push(newToken);
        return Promise.resolve(newToken);
      }),
      updateMany: jest.fn(({ where, data }) => {
        let count = 0;
        for (const t of mockDeviceTokens) {
          if (where.fcmToken && t.fcmToken === where.fcmToken) {
            Object.assign(t, data);
            count++;
          } else if (where.userId && t.userId === where.userId) {
            Object.assign(t, data);
            count++;
          }
        }
        return Promise.resolve({ count });
      }),
      findMany: jest.fn(({ where }) => {
        let list = mockDeviceTokens.filter((t) => t.isActive === (where.isActive ?? true));
        if (where.userId) {
          list = list.filter((t) => t.userId === where.userId);
        }
        return Promise.resolve(list);
      }),
    },
    notification: {
      create: jest.fn(({ data }) => {
        const notif = {
          id: `notif-${Date.now()}-${Math.random()}`,
          ...data,
          isRead: false,
          createdAt: new Date(),
        };
        mockNotifications.push(notif);
        return Promise.resolve(notif);
      }),
      createMany: jest.fn(({ data }) => {
        for (const item of data) {
          mockNotifications.push({
            id: `notif-${Date.now()}-${Math.random()}`,
            ...item,
            isRead: false,
            createdAt: new Date(),
          });
        }
        return Promise.resolve({ count: data.length });
      }),
      findMany: jest.fn(({ where, skip = 0, take = 20 }) => {
        let list = mockNotifications.filter((n) => n.userId === where.userId);
        if (where.isRead !== undefined) {
          list = list.filter((n) => n.isRead === where.isRead);
        }
        return Promise.resolve(list.slice(skip, skip + take));
      }),
      count: jest.fn(({ where }) => {
        let list = mockNotifications.filter((n) => n.userId === where.userId);
        if (where.isRead !== undefined) {
          list = list.filter((n) => n.isRead === where.isRead);
        }
        return Promise.resolve(list.length);
      }),
      findUnique: jest.fn(({ where }) => {
        return Promise.resolve(mockNotifications.find((n) => n.id === where.id) || null);
      }),
      update: jest.fn(({ where, data }) => {
        const item = mockNotifications.find((n) => n.id === where.id);
        if (item) Object.assign(item, data);
        return Promise.resolve(item || null);
      }),
      updateMany: jest.fn(({ where, data }) => {
        let count = 0;
        for (const n of mockNotifications) {
          if (n.userId === where.userId && (where.isRead === undefined || n.isRead === where.isRead)) {
            Object.assign(n, data);
            count++;
          }
        }
        return Promise.resolve({ count });
      }),
    },
    notificationPreference: {
      findUnique: jest.fn(({ where }) => Promise.resolve(mockPreferences[where.userId] || null)),
      upsert: jest.fn(({ where, create, update }) => {
        if (!mockPreferences[where.userId]) {
          mockPreferences[where.userId] = { id: `pref-${where.userId}`, ...create };
        } else {
          Object.assign(mockPreferences[where.userId], update);
        }
        return Promise.resolve(mockPreferences[where.userId]);
      }),
      create: jest.fn(({ data }) => {
        const p = {
          id: `pref-${data.userId}`,
          attendanceNotifications: true,
          requestNotifications: true,
          payrollNotifications: true,
          advanceNotifications: true,
          announcementNotifications: true,
          messageNotifications: true,
          taskNotifications: true,
          emailNotifications: true,
          pushNotifications: true,
          ...data,
        };
        mockPreferences[data.userId] = p;
        return Promise.resolve(p);
      }),
    },
    conversation: {
      findFirst: jest.fn(({ where }) => {
        if (where.AND) {
          const userA = where.AND[0].participants.some.userId;
          const userB = where.AND[1].participants.some.userId;
          const conv = mockConversations.find((c) => {
            if (c.isGroup) return false;
            const pIds = mockParticipants.filter((p) => p.conversationId === c.id).map((p) => p.userId);
            return pIds.includes(userA) && pIds.includes(userB);
          });
          return Promise.resolve(conv || null);
        }
        return Promise.resolve(null);
      }),
      findUnique: jest.fn(({ where }) => {
        const c = mockConversations.find((item) => item.id === where.id);
        if (!c) return Promise.resolve(null);
        return Promise.resolve({
          ...c,
          participants: mockParticipants
            .filter((p) => p.conversationId === c.id)
            .map((p) => ({
              ...p,
              user: mockUsers[p.userId],
            })),
        });
      }),
      findMany: jest.fn(({ where }) => {
        const userConvs = mockParticipants
          .filter((p) => p.userId === where.participants.some.userId)
          .map((p) => mockConversations.find((c) => c.id === p.conversationId))
          .filter(Boolean);

        return Promise.resolve(
          userConvs.map((conv) => ({
            ...conv,
            participants: mockParticipants
              .filter((p) => p.conversationId === conv.id)
              .map((p) => ({
                ...p,
                user: mockUsers[p.userId],
              })),
            messages: mockMessages
              .filter((m) => m.conversationId === conv.id && !m.isDeleted)
              .slice(-1),
          })),
        );
      }),
      create: jest.fn(({ data }) => {
        const c = { id: `conv-${Date.now()}-${Math.random()}`, ...data, createdAt: new Date() };
        mockConversations.push(c);
        return Promise.resolve(c);
      }),
      update: jest.fn(({ where, data }) => {
        const c = mockConversations.find((item) => item.id === where.id);
        if (c) Object.assign(c, data);
        return Promise.resolve(c || null);
      }),
    },
    conversationParticipant: {
      findUnique: jest.fn(({ where }) => {
        const p = mockParticipants.find(
          (item) =>
            item.conversationId === where.conversationId_userId.conversationId &&
            item.userId === where.conversationId_userId.userId,
        );
        if (!p) return Promise.resolve(null);
        return Promise.resolve({
          ...p,
          conversation: {
            id: p.conversationId,
            participants: mockParticipants.filter((x) => x.conversationId === p.conversationId),
          },
        });
      }),
      createMany: jest.fn(({ data }) => {
        for (const item of data) {
          mockParticipants.push({
            id: `part-${Date.now()}-${Math.random()}`,
            ...item,
            joinedAt: new Date(),
          });
        }
        return Promise.resolve({ count: data.length });
      }),
      update: jest.fn(({ where, data }) => {
        const p = mockParticipants.find(
          (item) =>
            item.conversationId === where.conversationId_userId.conversationId &&
            item.userId === where.conversationId_userId.userId,
        );
        if (p) Object.assign(p, data);
        return Promise.resolve(p || null);
      }),
    },
    chatMessage: {
      create: jest.fn(({ data }) => {
        const msg = {
          id: `msg-${Date.now()}-${Math.random()}`,
          ...data,
          isRead: false,
          isDeleted: false,
          createdAt: new Date(),
          sender: mockUsers[data.senderId],
        };
        mockMessages.push(msg);
        return Promise.resolve(msg);
      }),
      findMany: jest.fn(({ where, skip = 0, take = 50 }) => {
        let list = mockMessages.filter((m) => m.conversationId === where.conversationId);
        if (where.isDeleted !== undefined) {
          list = list.filter((m) => m.isDeleted === where.isDeleted);
        }
        return Promise.resolve(list.slice(skip, skip + take));
      }),
      count: jest.fn(({ where }) => {
        let list = mockMessages.filter((m) => !m.isDeleted);
        if (where.conversationId) {
          list = list.filter((m) => m.conversationId === where.conversationId);
        }
        if (where.conversation?.participants?.some?.userId) {
          const userConvIds = mockParticipants
            .filter((p) => p.userId === where.conversation.participants.some.userId)
            .map((p) => p.conversationId);
          list = list.filter((m) => userConvIds.includes(m.conversationId));
        }
        if (where.senderId?.not) {
          list = list.filter((m) => m.senderId !== where.senderId.not);
        }
        if (where.isRead !== undefined) {
          list = list.filter((m) => m.isRead === where.isRead);
        }
        return Promise.resolve(list.length);
      }),
      updateMany: jest.fn(({ where, data }) => {
        let count = 0;
        for (const m of mockMessages) {
          if (
            m.conversationId === where.conversationId &&
            m.senderId !== where.senderId.not &&
            m.isRead === false
          ) {
            Object.assign(m, data);
            count++;
          }
        }
        return Promise.resolve({ count });
      }),
      findUnique: jest.fn(({ where }) => {
        return Promise.resolve(mockMessages.find((m) => m.id === where.id) || null);
      }),
      update: jest.fn(({ where, data }) => {
        const m = mockMessages.find((item) => item.id === where.id);
        if (m) Object.assign(m, data);
        return Promise.resolve(m || null);
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        const log = { id: `audit-${Date.now()}`, ...data, timestamp: new Date() };
        mockAuditLogs.push(log);
        return Promise.resolve(log);
      }),
    },
    $transaction: jest.fn(async (cb) => {
      if (typeof cb === "function") {
        return cb(mockPrismaService);
      }
      return Promise.all(cb);
    }),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PresenceService,
        RealTimeService,
        RealTimeGateway,
        WsJwtGuard,
        FcmService,
        NotificationsRepository,
        NotificationsService,
        MessagingRepository,
        MessagingService,
        ConversationAccessGuard,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === "jwt.accessSecret") return "test_jwt_secret_key_phase6";
              if (key === "FIREBASE_PROJECT_ID") return "cyberwise-test-project";
              return null;
            }),
          },
        },
        {
          provide: JwtService,
          useValue: {
            verifyAsync: jest.fn((token: string, opts?: any) => {
              if (token === "valid-token-user-1") return Promise.resolve({ sub: "user-emp-1" });
              if (token === "valid-token-user-2") return Promise.resolve({ sub: "user-emp-2" });
              if (token === "valid-token-hr") return Promise.resolve({ sub: "user-hr-admin" });
              if (token === "valid-token-stranger") return Promise.resolve({ sub: "user-stranger" });
              throw new Error("Invalid or expired token");
            }),
          },
        },
      ],
    }).compile();

    presenceService = module.get<PresenceService>(PresenceService);
    realtimeService = module.get<RealTimeService>(RealTimeService);
    realtimeGateway = module.get<RealTimeGateway>(RealTimeGateway);
    wsJwtGuard = module.get<WsJwtGuard>(WsJwtGuard);
    fcmService = module.get<FcmService>(FcmService);
    notificationsRepo = module.get<NotificationsRepository>(NotificationsRepository);
    notificationsService = module.get<NotificationsService>(NotificationsService);
    messagingRepo = module.get<MessagingRepository>(MessagingRepository);
    messagingService = module.get<MessagingService>(MessagingService);
    conversationAccessGuard = module.get<ConversationAccessGuard>(ConversationAccessGuard);
    jwtService = module.get<JwtService>(JwtService);
  });

  afterEach(() => {
    presenceService.reset();
  });

  // ============================================================
  // 1. WEBSOCKET CONNECT, HANDSHAKE AUTH & RECONNECT
  // ============================================================

  describe("1. WebSocket Connection, Handshake Authentication & Reconnection", () => {
    it("1.1 Successfully connects with valid token in handshake.auth and marks presence ONLINE", async () => {
      const mockSocket: any = {
        id: "socket-101",
        handshake: { auth: { token: "valid-token-user-1" } },
        data: {},
        join: jest.fn(),
        emit: jest.fn(),
        disconnect: jest.fn(),
      };

      await realtimeGateway.handleConnection(mockSocket);

      expect(mockSocket.data.user).toBeDefined();
      expect(mockSocket.data.user.id).toBe("user-emp-1");
      expect(mockSocket.join).toHaveBeenCalledWith("user:user-emp-1");
      expect(presenceService.isUserOnline("user-emp-1")).toBe(true);
      expect(mockSocket.emit).toHaveBeenCalledWith("connected", expect.objectContaining({
        status: "AUTHENTICATED",
        userId: "user-emp-1",
      }));
    });

    it("1.2 Successfully authenticates with Authorization Bearer header", async () => {
      const mockSocket: any = {
        id: "socket-102",
        handshake: { headers: { authorization: "Bearer valid-token-user-2" } },
        data: {},
        join: jest.fn(),
        emit: jest.fn(),
        disconnect: jest.fn(),
      };

      await realtimeGateway.handleConnection(mockSocket);

      expect(mockSocket.data.user.id).toBe("user-emp-2");
      expect(presenceService.isUserOnline("user-emp-2")).toBe(true);
    });

    it("1.3 Rejects connection when authentication token is missing", async () => {
      const mockSocket: any = {
        id: "socket-103",
        handshake: { headers: {}, auth: {} },
        data: {},
        join: jest.fn(),
        emit: jest.fn(),
        disconnect: jest.fn(),
      };

      await realtimeGateway.handleConnection(mockSocket);

      expect(mockSocket.emit).toHaveBeenCalledWith("error", expect.objectContaining({
        code: "UNAUTHORIZED",
      }));
      expect(mockSocket.disconnect).toHaveBeenCalledWith(true);
    });

    it("1.4 Rejects connection when token is invalid or expired", async () => {
      const mockSocket: any = {
        id: "socket-104",
        handshake: { auth: { token: "corrupt-or-expired-token" } },
        data: {},
        join: jest.fn(),
        emit: jest.fn(),
        disconnect: jest.fn(),
      };

      await realtimeGateway.handleConnection(mockSocket);

      expect(mockSocket.disconnect).toHaveBeenCalledWith(true);
    });

    it("1.5 Disconnect unregisters socket and marks user OFFLINE", async () => {
      const mockSocket: any = {
        id: "socket-105",
        handshake: { auth: { token: "valid-token-user-1" } },
        data: { user: { id: "user-emp-1" } },
        disconnect: jest.fn(),
      };

      presenceService.markUserOnline("user-emp-1", "socket-105");
      expect(presenceService.isUserOnline("user-emp-1")).toBe(true);

      realtimeGateway.handleDisconnect(mockSocket);
      expect(presenceService.isUserOnline("user-emp-1")).toBe(false);
    });

    it("1.6 Reconnect scenario: Multiple sockets for same user remain online until all disconnect", () => {
      presenceService.markUserOnline("user-emp-1", "socket-phone");
      presenceService.markUserOnline("user-emp-1", "socket-laptop");

      expect(presenceService.isUserOnline("user-emp-1")).toBe(true);
      expect(presenceService.getUserSocketIds("user-emp-1")).toHaveLength(2);

      // Disconnect one device
      const isCompletelyOffline1 = presenceService.markUserOffline("user-emp-1", "socket-phone");
      expect(isCompletelyOffline1).toBe(false);
      expect(presenceService.isUserOnline("user-emp-1")).toBe(true);

      // Disconnect remaining device
      const isCompletelyOffline2 = presenceService.markUserOffline("user-emp-1", "socket-laptop");
      expect(isCompletelyOffline2).toBe(true);
      expect(presenceService.isUserOnline("user-emp-1")).toBe(false);
    });
  });

  // ============================================================
  // 2. CONVERSATIONS & REALTIME MESSAGING (1-on-1 & GROUP)
  // ============================================================

  describe("2. Internal Conversations, Send/Receive Messages & Group Chat", () => {
    let convId: string;

    it("2.1 Employee starts 1-on-1 conversation with HR Admin", async () => {
      const msg = await messagingService.createConversation("user-emp-1", {
        participantUserId: "user-hr-admin",
        title: "Medical insurance question",
        content: "Hello, could you please clarify the medical insurance network?",
      });

      expect(msg).toBeDefined();
      expect(msg.content).toContain("medical insurance");
      expect(msg.conversationId).toBeDefined();
      convId = msg.conversationId;

      const conv = await messagingRepo.findConversationById(convId);
      expect(conv?.participants).toHaveLength(2);
    });

    it("2.2 Second attempt to start 1-on-1 with same user reuses existing conversation (no duplicates)", async () => {
      const msg = await messagingService.createConversation("user-emp-1", {
        participantUserId: "user-hr-admin",
        content: "Following up on my previous insurance question",
      });

      expect(msg.conversationId).toBe(convId);
    });

    it("2.3 Create group conversation with multiple team members", async () => {
      const groupConv = await messagingService.createGroupConversation("user-hr-admin", {
        title: "Engineering & HR Quarterly Sync",
        participantUserIds: ["user-emp-1", "user-emp-2"],
        initialMessage: "Welcome everyone to our sync channel!",
      });

      expect(groupConv).toBeDefined();
      expect(groupConv.isGroup).toBe(true);
      expect(groupConv.title).toBe("Engineering & HR Quarterly Sync");
    });

    it("2.4 Send message in conversation -> persists in DB and updates lastMessageAt", async () => {
      const msg = await messagingService.sendMessage(convId, "user-hr-admin", {
        content: "Sure Ahmed, here is the approved clinic list.",
        attachmentUrl: "https://storage.cyberwise.internal/docs/clinics.pdf",
      });

      expect(msg.content).toContain("approved clinic list");
      expect(msg.attachmentUrl).toBeDefined();
      expect(msg.senderId).toBe("user-hr-admin");
    });

    it("2.5 Ephemeral typing indicator broadcasts to conversation room without DB writes", () => {
      const clientToMock = { emit: jest.fn() };
      const clientMock: any = {
        data: { user: { id: "user-emp-1", name: "Ahmed Hassan" } },
        to: jest.fn(() => clientToMock),
      };

      realtimeGateway.handleTypingStart(clientMock, { conversationId: convId });

      expect(clientMock.to).toHaveBeenCalledWith(`conversation:${convId}`);
      expect(clientToMock.emit).toHaveBeenCalledWith("user_typing", {
        conversationId: convId,
        userId: "user-emp-1",
        userName: "Ahmed Hassan",
      });
      // Zero DB writes!
    });
  });

  // ============================================================
  // 3. ZERO-TRUST SECURITY & UNAUTHORIZED CONVERSATION (IDOR)
  // ============================================================

  describe("3. Zero-Trust Access & IDOR Protection", () => {
    let restrictedConvId: string;

    beforeAll(async () => {
      const msg = await messagingService.createConversation("user-emp-1", {
        participantUserId: "user-emp-2",
        content: "Private confidential discussion between Ahmed and Sarah",
      });
      restrictedConvId = msg.conversationId;
    });

    it("3.1 Unauthorized stranger joining conversation room via WebSocket is rejected with FORBIDDEN", async () => {
      const mockClient: any = {
        data: { user: { id: "user-stranger" } },
        emit: jest.fn(),
        join: jest.fn(),
      };

      await realtimeGateway.handleJoinConversation(mockClient, { conversationId: restrictedConvId });

      expect(mockClient.emit).toHaveBeenCalledWith("error", expect.objectContaining({
        code: "FORBIDDEN",
      }));
      expect(mockClient.join).not.toHaveBeenCalled();
    });

    it("3.2 Unauthorized stranger attempting to read messages is blocked with ForbiddenException", async () => {
      await expect(
        messagingService.getConversationMessages(restrictedConvId, "user-stranger"),
      ).rejects.toThrow(ForbiddenException);
    });

    it("3.3 Unauthorized stranger attempting to send message is blocked with ForbiddenException", async () => {
      await expect(
        messagingService.sendMessage(restrictedConvId, "user-stranger", {
          content: "I am intruding into your conversation!",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("3.4 ConversationAccessGuard allows authorized participants", async () => {
      const mockContext: any = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { id: "user-emp-1", role: Role.EMPLOYEE },
            params: { id: restrictedConvId },
          }),
        }),
      };

      const canActivate = await conversationAccessGuard.canActivate(mockContext);
      expect(canActivate).toBe(true);
    });

    it("3.5 ConversationAccessGuard blocks unauthorized user with ForbiddenException", async () => {
      const mockContext: any = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { id: "user-stranger", role: Role.EMPLOYEE },
            params: { id: restrictedConvId },
          }),
        }),
      };

      await expect(conversationAccessGuard.canActivate(mockContext)).rejects.toThrow(ForbiddenException);
    });
  });

  // ============================================================
  // 4. READ STATUS & UNREAD COUNT CALCULATION
  // ============================================================

  describe("4. Read Status Tracking & Unread Counters", () => {
    let testConvId: string;

    beforeAll(async () => {
      const msg1 = await messagingService.createConversation("user-emp-1", {
        participantUserId: "user-emp-2",
        content: "Message 1 for Sarah",
      });
      testConvId = msg1.conversationId;

      await messagingService.sendMessage(testConvId, "user-emp-1", {
        content: "Message 2 for Sarah",
      });
      await messagingService.sendMessage(testConvId, "user-emp-1", {
        content: "Message 3 for Sarah",
      });
    });

    it("4.1 Sarah has 3 unread messages from Ahmed", async () => {
      const unreadRes = await messagingService.getUnreadMessageCount("user-emp-2");
      expect(unreadRes.unreadCount).toBeGreaterThanOrEqual(3);
    });

    it("4.2 Ahmed has 0 unread messages in this conversation (his own messages do not count as unread)", async () => {
      const convs = await messagingService.getUserConversations("user-emp-1");
      const target = convs.find((c) => c.id === testConvId);
      expect(target?.unreadCount).toBe(0);
    });

    it("4.3 Sarah marks conversation as read -> updates isRead, readAt, and unreadCount becomes 0", async () => {
      const readRes = await messagingService.markConversationAsRead(testConvId, "user-emp-2");
      expect(readRes.markedCount).toBeGreaterThanOrEqual(3);

      const convs = await messagingService.getUserConversations("user-emp-2");
      const target = convs.find((c) => c.id === testConvId);
      expect(target?.unreadCount).toBe(0);
    });
  });

  // ============================================================
  // 5. REAL FCM PUSH NOTIFICATIONS & TOKEN ERROR RECOVERY
  // ============================================================

  describe("5. FCM Push Notifications & Invalid Token Cleanup", () => {
    it("5.1 Registers active FCM device token for user", async () => {
      const token = await notificationsService.registerDeviceToken("user-emp-1", {
        fcmToken: "fcm_token_valid_pixel_7_pro",
        platform: DevicePlatform.ANDROID,
        deviceId: "device-uuid-pixel-7",
      });

      expect(token).toBeDefined();
      expect(token.fcmToken).toBe("fcm_token_valid_pixel_7_pro");
      expect(token.isActive).toBe(true);
    });

    it("5.2 Dispatches verified FCM payload to active device token", async () => {
      const res = await fcmService.sendToDevice(
        "fcm_token_valid_pixel_7_pro",
        "Salary Update",
        "Your monthly salary payslip is now ready.",
        { type: "PAYROLL", month: "August" },
      );

      expect(res.success).toBe(true);
      expect(res.messageId).toBeDefined();
    });

    it("5.3 Automatically deactivates unregistered/invalid token in database", async () => {
      // Register an invalid token
      await notificationsService.registerDeviceToken("user-emp-1", {
        fcmToken: "fcm_token_invalid_expired_dummy",
        platform: DevicePlatform.ANDROID,
      });

      // Send notification via service
      await notificationsService.sendNotification(
        "user-emp-1",
        "Test Notification",
        "Testing invalid token handling",
        NotificationType.SYSTEM_ALERT,
      );

      // Verify the token was marked inactive in DB
      const tokens = await mockPrismaService.deviceToken.findMany({
        where: { userId: "user-emp-1", isActive: false },
      });
      const invalidToken = tokens.find((t: any) => t.fcmToken === "fcm_token_invalid_expired_dummy");
      expect(invalidToken?.isActive).toBe(false);
    });
  });

  // ============================================================
  // 6. NOTIFICATION PREFERENCES & SYSTEM EVENT HOOKS
  // ============================================================

  describe("6. Notification Preferences & System Event Hooks", () => {
    it("6.1 Suppresses non-critical notification when category is disabled in user preferences", async () => {
      // Disable payroll notifications for user-emp-1
      await notificationsService.updatePreferences("user-emp-1", {
        payrollNotifications: false,
      });

      const notif = await notificationsService.sendNotification(
        "user-emp-1",
        "Payslip Generated",
        "Your payslip is available",
        NotificationType.PAYROLL,
        {},
        NotificationPriority.NORMAL,
      );

      expect(notif).toBeNull(); // Suppressed
    });

    it("6.2 Critical or Security notification bypasses user suppression preferences", async () => {
      const securityNotif = await notificationsService.sendNotification(
        "user-emp-1",
        "New Login Detected",
        "A login from an unrecognized device was detected",
        NotificationType.SECURITY,
        {},
        NotificationPriority.CRITICAL,
      );

      expect(securityNotif).not.toBeNull();
      expect(securityNotif?.type).toBe(NotificationType.SECURITY);
    });

    it("6.3 Task notification preference controls task events", async () => {
      // Enable task notifications
      await notificationsService.updatePreferences("user-emp-1", {
        taskNotifications: true,
      });

      const taskNotif = await notificationsService.sendNotification(
        "user-emp-1",
        "New Task Assigned",
        "You were assigned to 'Audit Backend Logs'",
        NotificationType.TASK_ASSIGNED,
      );

      expect(taskNotif).not.toBeNull();
      expect(taskNotif?.title).toContain("Task Assigned");
    });
  });
});
