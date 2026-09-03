import { Test, TestingModule } from "@nestjs/testing";
import { TrainingService } from "./training.service";
import { TrainingRepository } from "./training.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { EnrollmentStatus } from "@prisma/client";

describe("TrainingService", () => {
  let service: TrainingService;
  let repo: jest.Mocked<TrainingRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      generateCertificateNumber: jest
        .fn()
        .mockResolvedValue("CERT-20260903-0001"),
      createCourse: jest.fn(),
      findCourses: jest.fn(),
      findCourseById: jest.fn(),
      findCourseByCode: jest.fn(),
      createSession: jest.fn(),
      findSessions: jest.fn(),
      findSessionById: jest.fn(),
      enrollEmployee: jest.fn(),
      findEnrollment: jest.fn(),
      updateEnrollment: jest.fn(),
      issueCertificate: jest.fn(),
      findCertificates: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TrainingService,
        { provide: TrainingRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<TrainingService>(TrainingService);
    repo = module.get(TrainingRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
  });

  describe("createCourse", () => {
    it("should throw ConflictException if course code exists", async () => {
      repo.findCourseByCode.mockResolvedValue({ id: "crs-1" } as any);

      await expect(
        service.createCourse("user-1", {
          code: "CRS-01",
          title: "Safety",
          description: "Desc",
          durationHours: 2,
        }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create course and log audit", async () => {
      repo.findCourseByCode.mockResolvedValue(null);
      repo.createCourse.mockResolvedValue({
        id: "crs-1",
        code: "CRS-01",
        title: "Safety",
      } as any);

      const result = await service.createCourse("user-1", {
        code: "CRS-01",
        title: "Safety",
        description: "Desc",
        durationHours: 2,
      });

      expect(result.id).toBe("crs-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("enrollEmployee", () => {
    it("should throw BadRequestException if session is at full capacity", async () => {
      repo.findSessionById.mockResolvedValue({
        id: "sess-1",
        maxParticipants: 1,
        enrollments: [{ id: "enr-1" }],
      } as any);

      await expect(
        service.enrollEmployee("sess-1", "user-1", { employeeId: "emp-2" }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should enroll employee, notify, and log audit", async () => {
      repo.findSessionById.mockResolvedValue({
        id: "sess-1",
        courseId: "crs-1",
        startDate: new Date(),
        maxParticipants: 10,
        enrollments: [],
        course: { title: "Safety" },
      } as any);
      prisma.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        user: { id: "user-emp-1" },
      });
      repo.findEnrollment.mockResolvedValue(null);
      repo.enrollEmployee.mockResolvedValue({
        id: "enr-1",
        sessionId: "sess-1",
        employeeId: "emp-1",
        status: EnrollmentStatus.ENROLLED,
      } as any);

      const result = await service.enrollEmployee("sess-1", "user-1", {
        employeeId: "emp-1",
      });
      expect(result.id).toBe("enr-1");
      expect(notifications.sendNotification).toHaveBeenCalled();
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
