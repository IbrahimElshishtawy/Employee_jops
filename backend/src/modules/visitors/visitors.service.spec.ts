import { Test, TestingModule } from "@nestjs/testing";
import { VisitorsService } from "./visitors.service";
import { VisitorsRepository } from "./visitors.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { NotFoundException, BadRequestException } from "@nestjs/common";
import { VisitorStatus } from "@prisma/client";

describe("VisitorsService", () => {
  let service: VisitorsService;
  let repo: jest.Mocked<VisitorsRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      generateVisitorNumber: jest.fn().mockResolvedValue("VIS-20260903-0001"),
      checkInVisitor: jest.fn(),
      checkOutVisitor: jest.fn(),
      findVisitorById: jest.fn(),
      findVisitors: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendInAppNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VisitorsService,
        { provide: VisitorsRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<VisitorsService>(VisitorsService);
    repo = module.get(VisitorsRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
  });

  describe("checkInVisitor", () => {
    it("should throw NotFoundException if host employee does not exist", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue(null);

      await expect(
        service.checkInVisitor("user-1", {
          fullName: "John Doe",
          phone: "123",
          purpose: "Meeting",
          hostEmployeeId: "host-1",
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it("should check in visitor, notify host, and log audit", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue({
        id: "host-1",
        user: { id: "user-host-1" },
      });
      repo.checkInVisitor.mockResolvedValue({
        id: "vis-1",
        visitorNumber: "VIS-20260903-0001",
        fullName: "John Doe",
      } as any);

      const result = await service.checkInVisitor("user-1", {
        fullName: "John Doe",
        phone: "123",
        purpose: "Meeting",
        hostEmployeeId: "host-1",
      });

      expect(result.id).toBe("vis-1");
      expect(notifications.sendInAppNotification).toHaveBeenCalled();
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("checkOutVisitor", () => {
    it("should check out visitor successfully", async () => {
      repo.findVisitorById.mockResolvedValue({
        id: "vis-1",
        status: VisitorStatus.CHECKED_IN,
      } as any);
      repo.checkOutVisitor.mockResolvedValue({
        id: "vis-1",
        status: VisitorStatus.CHECKED_OUT,
        checkOutTime: new Date(),
      } as any);

      const result = await service.checkOutVisitor("vis-1", "user-1", {});
      expect(result.status).toBe(VisitorStatus.CHECKED_OUT);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
