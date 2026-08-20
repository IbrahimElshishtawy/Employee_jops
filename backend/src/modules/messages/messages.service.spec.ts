import { Test, TestingModule } from "@nestjs/testing";
import { MessagesService } from "./messages.service";
import { RealTimeService } from "./realtime.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import { Role } from "@prisma/client";

describe("MessagesService (Phase 06 Messaging Test Suite)", () => {
  let messagesService: MessagesService;
  let realtimeService: RealTimeService;
  let prisma: PrismaService;
  let notificationsService: NotificationsService;

  const mockSenderId = "user-emp-1";
  const mockRecipientId = "user-hr-1";
  const mockOtherUserId = "user-outsider-99";
  const mockConvId = "conv-uuid-1";

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
    },
    conversation: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    conversationParticipant: {
      findUnique: jest.fn(),
      createMany: jest.fn(),
      update: jest.fn(),
    },
    chatMessage: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      count: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrismaService)),
  };

  const mockNotificationsService = {
    sendNotification: jest.fn().mockResolvedValue(true),
  };

  const mockRealTimeService = {
    emitToUsers: jest.fn(),
    emitToConversation: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MessagesService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: RealTimeService, useValue: mockRealTimeService },
      ],
    }).compile();

    messagesService = module.get<MessagesService>(MessagesService);
    prisma = module.get<PrismaService>(PrismaService);
    notificationsService =
      module.get<NotificationsService>(NotificationsService);
    realtimeService = module.get<RealTimeService>(RealTimeService);

    jest.clearAllMocks();
  });

  // ============================================================
  // TEST GROUP 1: CONVERSATION INITIALIZATION & RULES
  // ============================================================
  describe("Conversation Creation & Rules", () => {
    it("1. should start a new Employee ↔ HR conversation with initial message", async () => {
      mockPrismaService.user.findUnique.mockImplementation(({ where }: any) => {
        if (where.id === mockSenderId) {
          return Promise.resolve({
            id: mockSenderId,
            role: Role.EMPLOYEE,
            employeeProfile: { firstName: "Ahmed", lastName: "Ali" },
          });
        }
        if (where.id === mockRecipientId) {
          return Promise.resolve({
            id: mockRecipientId,
            role: Role.HR_ADMIN,
            employeeProfile: { firstName: "Sarah", lastName: "HR" },
          });
        }
        return Promise.resolve(null);
      });

      mockPrismaService.conversation.findFirst.mockResolvedValue(null);
      mockPrismaService.conversation.create.mockResolvedValue({
        id: mockConvId,
        title: "Salary Inquiry",
      });
      mockPrismaService.chatMessage.create.mockResolvedValue({
        id: "msg-1",
        conversationId: mockConvId,
        senderId: mockSenderId,
        content: "Hello HR, I need information about my contract.",
      });

      const result = await messagesService.createConversation(mockSenderId, {
        participantUserId: mockRecipientId,
        title: "Salary Inquiry",
        content: "Hello HR, I need information about my contract.",
      });

      expect(result.id).toBe("msg-1");
      expect(mockPrismaService.conversation.create).toHaveBeenCalled();
      expect(mockRealTimeService.emitToConversation).toHaveBeenCalled();
      expect(mockNotificationsService.sendNotification).toHaveBeenCalled();
    });

    it("2. should reject starting conversation with self", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({ id: mockSenderId });

      await expect(
        messagesService.createConversation(mockSenderId, {
          participantUserId: mockSenderId,
          content: "Talking to myself",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("3. should reject empty or whitespace-only initial message", async () => {
      await expect(
        messagesService.createConversation(mockSenderId, {
          participantUserId: mockRecipientId,
          content: "   ",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("4. should list user conversations with unread badges and snippets", async () => {
      mockPrismaService.conversation.findMany.mockResolvedValue([
        {
          id: mockConvId,
          title: "Inquiry",
          isGroup: false,
          updatedAt: new Date(),
          participants: [
            { userId: mockSenderId, user: { id: mockSenderId } },
            {
              userId: mockRecipientId,
              user: { id: mockRecipientId, email: "hr@cyberwise.com" },
            },
          ],
          messages: [{ id: "msg-1", content: "Last message snippet" }],
        },
      ]);
      mockPrismaService.chatMessage.count.mockResolvedValue(2); // 2 unread

      const result = await messagesService.getUserConversations(mockSenderId);

      expect(result).toHaveLength(1);
      expect(result[0].unreadCount).toBe(2);
      expect(result[0].lastMessage.content).toBe("Last message snippet");
    });
  });

  // ============================================================
  // TEST GROUP 2: MESSAGE SENDING & IDOR PROTECTION
  // ============================================================
  describe("Message Sending & Security", () => {
    it("5. should send message in existing conversation with server-derived sender identity", async () => {
      mockPrismaService.conversationParticipant.findUnique.mockResolvedValue({
        id: "cp-1",
        conversationId: mockConvId,
        userId: mockSenderId,
        conversation: {
          participants: [{ userId: mockSenderId }, { userId: mockRecipientId }],
        },
      });
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockSenderId,
        email: "emp@cyberwise.com",
      });
      mockPrismaService.chatMessage.create.mockResolvedValue({
        id: "msg-2",
        conversationId: mockConvId,
        senderId: mockSenderId,
        content: "Follow up message",
      });

      const res = await messagesService.sendMessage(mockConvId, mockSenderId, {
        content: "Follow up message",
      });

      expect(res.senderId).toBe(mockSenderId);
      expect(mockRealTimeService.emitToConversation).toHaveBeenCalled();
      expect(mockNotificationsService.sendNotification).toHaveBeenCalledWith(
        mockRecipientId,
        expect.any(String),
        expect.stringContaining("Follow up message"),
        expect.any(String),
        expect.any(Object),
      );
    });

    it("6. should reject sending message if user is not a participant in conversation (IDOR)", async () => {
      mockPrismaService.conversationParticipant.findUnique.mockResolvedValue(
        null,
      );

      await expect(
        messagesService.sendMessage(mockConvId, mockOtherUserId, {
          content: "Intruder message",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("7. should reject retrieving messages if user is not a participant (IDOR)", async () => {
      mockPrismaService.conversationParticipant.findUnique.mockResolvedValue(
        null,
      );

      await expect(
        messagesService.getConversationMessages(
          mockConvId,
          mockOtherUserId,
          {},
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it("8. should return paginated message history for authorized participant", async () => {
      mockPrismaService.conversationParticipant.findUnique.mockResolvedValue({
        conversationId: mockConvId,
        userId: mockSenderId,
      });
      mockPrismaService.chatMessage.count.mockResolvedValue(1);
      mockPrismaService.chatMessage.findMany.mockResolvedValue([
        { id: "msg-1", content: "History message", isDeleted: false },
      ]);

      const res = await messagesService.getConversationMessages(
        mockConvId,
        mockSenderId,
        { page: 1, limit: 10 },
      );
      expect(res.data).toHaveLength(1);
      expect(res.meta.total).toBe(1);
    });
  });

  // ============================================================
  // TEST GROUP 3: READ STATE & DELETION
  // ============================================================
  describe("Read State & Message Deletion", () => {
    it("9. should mark conversation messages as read and emit realtime event", async () => {
      mockPrismaService.conversationParticipant.findUnique.mockResolvedValue({
        conversationId: mockConvId,
        userId: mockSenderId,
      });
      mockPrismaService.chatMessage.updateMany.mockResolvedValue({ count: 3 });
      mockPrismaService.conversationParticipant.update.mockResolvedValue({});

      const res = await messagesService.markConversationAsRead(
        mockConvId,
        mockSenderId,
      );

      expect(res.markedCount).toBe(3);
      expect(mockRealTimeService.emitToConversation).toHaveBeenCalledWith(
        mockConvId,
        "messages_read",
        expect.objectContaining({ readByUserId: mockSenderId }),
      );
    });

    it("10. should calculate global unread message count for user", async () => {
      mockPrismaService.chatMessage.count.mockResolvedValue(7);

      const res = await messagesService.getUnreadMessageCount(mockSenderId);
      expect(res.unreadCount).toBe(7);
    });

    it("11. should soft delete message by sender", async () => {
      mockPrismaService.chatMessage.findUnique.mockResolvedValue({
        id: "msg-1",
        conversationId: mockConvId,
        senderId: mockSenderId,
      });
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockSenderId,
        role: Role.EMPLOYEE,
      });
      mockPrismaService.chatMessage.update.mockResolvedValue({
        id: "msg-1",
        isDeleted: true,
      });

      const res = await messagesService.deleteMessage("msg-1", mockSenderId);
      expect(res.message).toContain("deleted successfully");
      expect(mockPrismaService.chatMessage.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ isDeleted: true }),
        }),
      );
    });

    it("12. should prevent unauthorized user from deleting another users message", async () => {
      mockPrismaService.chatMessage.findUnique.mockResolvedValue({
        id: "msg-1",
        senderId: mockSenderId,
      });
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockOtherUserId,
        role: Role.EMPLOYEE,
      });

      await expect(
        messagesService.deleteMessage("msg-1", mockOtherUserId),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
