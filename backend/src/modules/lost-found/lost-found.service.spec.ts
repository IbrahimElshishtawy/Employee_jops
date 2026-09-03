import { Test, TestingModule } from "@nestjs/testing";
import { LostFoundService } from "./lost-found.service";
import { LostFoundRepository } from "./lost-found.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { BadRequestException } from "@nestjs/common";
import { LostFoundStatus, UserStatus } from "@prisma/client";

describe("LostFoundService", () => {
  let service: LostFoundService;
  let repo: jest.Mocked<LostFoundRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      generateItemNumber: jest.fn().mockResolvedValue("LF-20260903-0001"),
      createItem: jest.fn(),
      findItems: jest.fn(),
      findItemById: jest.fn(),
      claimItem: jest.fn(),
      updateItemStatus: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LostFoundService,
        { provide: LostFoundRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<LostFoundService>(LostFoundService);
    repo = module.get(LostFoundRepository);
    prisma = module.get(PrismaService);
  });

  describe("createItem", () => {
    it("should throw BadRequestException if finder profile is missing or inactive", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue(null);

      await expect(
        service.createItem("user-1", {
          itemName: "Sunglasses",
          description: "Black RayBan",
          locationFound: "Lobby",
          storageLocation: "Drawer 1",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should create lost found item and log audit", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        user: { status: UserStatus.ACTIVE },
      });
      repo.createItem.mockResolvedValue({
        id: "lf-1",
        itemNumber: "LF-20260903-0001",
        itemName: "Sunglasses",
      } as any);

      const result = await service.createItem("user-1", {
        itemName: "Sunglasses",
        description: "Black RayBan",
        locationFound: "Lobby",
        storageLocation: "Drawer 1",
      });

      expect(result.id).toBe("lf-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("claimItem", () => {
    it("should throw BadRequestException if item is not in FOUND status", async () => {
      repo.findItemById.mockResolvedValue({
        id: "lf-1",
        status: LostFoundStatus.CLAIMED,
      } as any);

      await expect(
        service.claimItem("lf-1", "user-1", {
          claimantName: "John",
          claimantPhone: "123",
          claimantNationalId: "456",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should claim item successfully when in FOUND status", async () => {
      repo.findItemById.mockResolvedValue({
        id: "lf-1",
        status: LostFoundStatus.FOUND,
      } as any);
      repo.claimItem.mockResolvedValue({
        id: "lf-1",
        status: LostFoundStatus.CLAIMED,
      } as any);

      const result = await service.claimItem("lf-1", "user-1", {
        claimantName: "John",
        claimantPhone: "123",
        claimantNationalId: "456",
      });

      expect(result.status).toBe(LostFoundStatus.CLAIMED);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
