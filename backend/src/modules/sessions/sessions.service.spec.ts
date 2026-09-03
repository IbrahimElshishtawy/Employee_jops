import { Test, TestingModule } from "@nestjs/testing";
import { SessionsService } from "./sessions.service";
import { SessionsRepository } from "./sessions.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ForbiddenException, NotFoundException } from "@nestjs/common";

describe("SessionsService", () => {
  let service: SessionsService;
  let repo: jest.Mocked<SessionsRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      registerOrUpdateSession: jest.fn(),
      findActiveSessionsByUser: jest.fn(),
      findSessionById: jest.fn(),
      terminateSession: jest.fn(),
      terminateAllOtherSessions: jest.fn(),
    };

    const mockPrisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SessionsService,
        { provide: SessionsRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<SessionsService>(SessionsService);
    repo = module.get(SessionsRepository);
    prisma = module.get(PrismaService);
  });

  describe("registerDeviceSession", () => {
    it("should register session and log audit", async () => {
      repo.registerOrUpdateSession.mockResolvedValue({
        id: "sess-1",
        deviceId: "dev-1",
        deviceName: "iPhone",
      } as any);

      const result = await service.registerDeviceSession("user-1", {
        deviceId: "dev-1",
        deviceName: "iPhone",
      });

      expect(result.id).toBe("sess-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("terminateSession", () => {
    it("should throw ForbiddenException if session belongs to another user", async () => {
      repo.findSessionById.mockResolvedValue({
        id: "sess-1",
        userId: "other-user",
      } as any);

      await expect(
        service.terminateSession("user-1", "sess-1"),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should terminate session and log audit", async () => {
      repo.findSessionById.mockResolvedValue({
        id: "sess-1",
        userId: "user-1",
        deviceId: "dev-1",
      } as any);
      repo.terminateSession.mockResolvedValue({ id: "sess-1", isActive: false } as any);

      const result = await service.terminateSession("user-1", "sess-1");
      expect(result.isActive).toBe(false);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
