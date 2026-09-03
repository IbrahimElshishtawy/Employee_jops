import { Test, TestingModule } from "@nestjs/testing";
import { AssetsService } from "./assets.service";
import { AssetsRepository } from "./assets.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictException, NotFoundException, BadRequestException } from "@nestjs/common";
import { AssetStatus } from "@prisma/client";

describe("AssetsService", () => {
  let service: AssetsService;
  let repo: jest.Mocked<AssetsRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      findCategories: jest.fn(),
      createCategory: jest.fn(),
      findCategoryById: jest.fn(),
      findCategoryByCode: jest.fn(),
      createAsset: jest.fn(),
      findAssetById: jest.fn(),
      findAssetByCode: jest.fn(),
      findAssets: jest.fn(),
      updateAsset: jest.fn(),
      updateCurrentBookValue: jest.fn(),
      deleteAsset: jest.fn(),
    };

    const mockPrisma = {
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: "audit-1" }),
      },
      department: {
        findUnique: jest.fn(),
      },
      employeeProfile: {
        findUnique: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AssetsService,
        { provide: AssetsRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<AssetsService>(AssetsService);
    repo = module.get(AssetsRepository);
    prisma = module.get(PrismaService);
  });

  describe("createCategory", () => {
    it("should throw ConflictException if category code exists", async () => {
      repo.findCategoryByCode.mockResolvedValue({ id: "cat-1", code: "IT", name: "IT" } as any);

      await expect(
        service.createCategory("user-1", { name: "IT", code: "IT" }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create category and log audit", async () => {
      repo.findCategoryByCode.mockResolvedValue(null);
      repo.createCategory.mockResolvedValue({ id: "cat-1", code: "IT", name: "IT" } as any);

      const result = await service.createCategory("user-1", { name: "IT", code: "IT" });
      expect(result.id).toBe("cat-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createAsset", () => {
    it("should throw ConflictException if asset code exists", async () => {
      repo.findAssetByCode.mockResolvedValue({ id: "ast-1" } as any);

      await expect(
        service.createAsset("user-1", { assetCode: "AST-01", name: "Laptop", categoryId: "cat-1" }),
      ).rejects.toThrow(ConflictException);
    });

    it("should throw NotFoundException if category does not exist", async () => {
      repo.findAssetByCode.mockResolvedValue(null);
      repo.findCategoryById.mockResolvedValue(null);

      await expect(
        service.createAsset("user-1", { assetCode: "AST-01", name: "Laptop", categoryId: "cat-1" }),
      ).rejects.toThrow(NotFoundException);
    });

    it("should create asset successfully", async () => {
      repo.findAssetByCode.mockResolvedValue(null);
      repo.findCategoryById.mockResolvedValue({ id: "cat-1" } as any);
      repo.createAsset.mockResolvedValue({
        id: "ast-1",
        assetCode: "AST-01",
        name: "Laptop",
        status: AssetStatus.ACTIVE,
      } as any);

      const result = await service.createAsset("user-1", {
        assetCode: "AST-01",
        name: "Laptop",
        categoryId: "cat-1",
      });

      expect(result.id).toBe("ast-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("calculateDepreciation", () => {
    it("should calculate straight-line depreciation correctly", async () => {
      const pastDate = new Date();
      pastDate.setMonth(pastDate.getMonth() - 12);

      repo.findAssetById.mockResolvedValue({
        id: "ast-1",
        purchaseCost: 12000,
        purchaseDate: pastDate,
        category: { usefulLifeMonths: 60 },
      } as any);

      const result = await service.calculateDepreciation("ast-1");
      expect(result.assetId).toBe("ast-1");
      expect(result.purchaseCost).toBe(12000);
      expect(result.elapsedMonths).toBeGreaterThanOrEqual(11);
      expect(result.currentBookValue).toBeLessThan(12000);
      expect(repo.updateCurrentBookValue).toHaveBeenCalled();
    });

    it("should throw BadRequestException if cost or date is missing", async () => {
      repo.findAssetById.mockResolvedValue({
        id: "ast-1",
        purchaseCost: null,
        purchaseDate: null,
      } as any);

      await expect(service.calculateDepreciation("ast-1")).rejects.toThrow(BadRequestException);
    });
  });
});
