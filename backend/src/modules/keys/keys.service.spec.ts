import { Test, TestingModule } from "@nestjs/testing";
import { KeysService } from "./keys.service";
import { KeysRepository } from "./keys.repository";
import { PrismaService } from "../../prisma/prisma.service";
import {
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { KeyAssignmentStatus } from "@prisma/client";

describe("KeysService", () => {
  let service: KeysService;
  let repo: jest.Mocked<KeysRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      createKey: jest.fn(),
      findKeyById: jest.fn(),
      findKeyByCode: jest.fn(),
      findKeys: jest.fn(),
      assignKey: jest.fn(),
      findAssignmentById: jest.fn(),
      returnKey: jest.fn(),
      logAccess: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: {
        findUnique: jest.fn(),
      },
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: "audit-1" }),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        KeysService,
        { provide: KeysRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<KeysService>(KeysService);
    repo = module.get(KeysRepository);
    prisma = module.get(PrismaService);
  });

  describe("createKey", () => {
    it("should throw ConflictException if keyCode exists", async () => {
      repo.findKeyByCode.mockResolvedValue({ id: "key-1" } as any);

      await expect(
        service.createKey("user-1", { keyCode: "KEY-101", name: "Room 101" }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create physical key and log audit", async () => {
      repo.findKeyByCode.mockResolvedValue(null);
      repo.createKey.mockResolvedValue({
        id: "key-1",
        keyCode: "KEY-101",
        name: "Room 101",
        keyType: "ROOM",
      } as any);

      const result = await service.createKey("user-1", {
        keyCode: "KEY-101",
        name: "Room 101",
      });

      expect(result.id).toBe("key-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("assignKey", () => {
    it("should throw BadRequestException if availableCopies <= 0", async () => {
      repo.findKeyById.mockResolvedValue({
        id: "key-1",
        keyCode: "KEY-101",
        availableCopies: 0,
      } as any);

      await expect(
        service.assignKey("key-1", "user-1", { employeeId: "emp-1" }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should assign key and decrement copies when available", async () => {
      repo.findKeyById.mockResolvedValue({
        id: "key-1",
        keyCode: "KEY-101",
        availableCopies: 2,
      } as any);
      prisma.employeeProfile.findUnique.mockResolvedValue({ id: "emp-1" });
      repo.assignKey.mockResolvedValue({
        id: "assign-1",
        assignedAt: new Date(),
      } as any);

      const result = await service.assignKey("key-1", "user-1", {
        employeeId: "emp-1",
      });
      expect(result.id).toBe("assign-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("returnKey", () => {
    it("should return key successfully and log audit", async () => {
      repo.findAssignmentById.mockResolvedValue({
        id: "assign-1",
        keyId: "key-1",
        status: KeyAssignmentStatus.ACTIVE,
      } as any);
      repo.returnKey.mockResolvedValue({
        id: "assign-1",
        status: KeyAssignmentStatus.RETURNED,
        returnedAt: new Date(),
      } as any);

      const result = await service.returnKey("assign-1", "user-1", {
        notes: "All good",
      });
      expect(result.status).toBe(KeyAssignmentStatus.RETURNED);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
