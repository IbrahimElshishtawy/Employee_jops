import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { AssetsRepository } from "./assets.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateAssetDto, UpdateAssetDto, CreateAssetCategoryDto, QueryAssetsDto } from "./dto";
import { AuditAction, AssetStatus } from "@prisma/client";

@Injectable()
export class AssetsService {
  private readonly logger = new Logger(AssetsService.name);

  constructor(
    private readonly repo: AssetsRepository,
    private readonly prisma: PrismaService,
  ) {}

  // ============================================================
  // CATEGORIES
  // ============================================================

  async createCategory(userId: string, dto: CreateAssetCategoryDto) {
    const existing = await this.repo.findCategoryByCode(dto.code);
    if (existing) {
      throw new ConflictException(`Asset category with code '${dto.code}' already exists`);
    }

    const category = await this.repo.createCategory(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "AssetCategory",
        entityId: category.id,
        payload: { name: category.name, code: category.code },
      },
    });

    return category;
  }

  async getCategories() {
    return this.repo.findCategories();
  }

  // ============================================================
  // ASSETS
  // ============================================================

  async createAsset(userId: string, dto: CreateAssetDto) {
    const existingCode = await this.repo.findAssetByCode(dto.assetCode);
    if (existingCode) {
      throw new ConflictException(`Asset with code '${dto.assetCode}' already exists`);
    }

    const category = await this.repo.findCategoryById(dto.categoryId);
    if (!category) {
      throw new NotFoundException(`Asset category '${dto.categoryId}' not found`);
    }

    if (dto.departmentId) {
      const department = await this.prisma.department.findUnique({
        where: { id: dto.departmentId },
      });
      if (!department) {
        throw new NotFoundException(`Department '${dto.departmentId}' not found`);
      }
    }

    if (dto.assignedToId) {
      const employee = await this.prisma.employeeProfile.findUnique({
        where: { id: dto.assignedToId },
      });
      if (!employee) {
        throw new NotFoundException(`Employee profile '${dto.assignedToId}' not found`);
      }
    }

    const asset = await this.repo.createAsset(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "Asset",
        entityId: asset.id,
        payload: { assetCode: asset.assetCode, name: asset.name, status: asset.status },
      },
    });

    return asset;
  }

  async findAll(query: QueryAssetsDto) {
    return this.repo.findAssets(query);
  }

  async findOne(id: string) {
    const asset = await this.repo.findAssetById(id);
    if (!asset) {
      throw new NotFoundException(`Asset with ID '${id}' not found`);
    }
    return asset;
  }

  async updateAsset(id: string, userId: string, dto: UpdateAssetDto) {
    const current = await this.findOne(id);

    if (dto.categoryId) {
      const category = await this.repo.findCategoryById(dto.categoryId);
      if (!category) {
        throw new NotFoundException(`Category '${dto.categoryId}' not found`);
      }
    }

    const updated = await this.repo.updateAsset(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "Asset",
        entityId: id,
        payload: {
          previousStatus: current.status,
          newStatus: updated.status,
          changes: JSON.parse(JSON.stringify(dto)),
        },
      },
    });

    return updated;
  }

  async calculateDepreciation(id: string) {
    const asset = await this.findOne(id);

    if (!asset.purchaseCost || !asset.purchaseDate) {
      throw new BadRequestException("Asset purchase cost and purchase date are required to calculate depreciation");
    }

    const cost = Number(asset.purchaseCost);
    const purchaseTime = new Date(asset.purchaseDate).getTime();
    const nowTime = new Date().getTime();
    const elapsedMonths = Math.max(0, (nowTime - purchaseTime) / (1000 * 60 * 60 * 24 * 30.4375));

    let currentBookValue = cost;

    if (asset.category.usefulLifeMonths && asset.category.usefulLifeMonths > 0) {
      const monthlyDepreciation = cost / asset.category.usefulLifeMonths;
      const totalDepreciation = monthlyDepreciation * elapsedMonths;
      currentBookValue = Math.max(0, cost - totalDepreciation);
    } else if (asset.category.depreciationRate) {
      const annualRate = Number(asset.category.depreciationRate) / 100;
      const monthlyRate = annualRate / 12;
      const totalDepreciation = cost * monthlyRate * elapsedMonths;
      currentBookValue = Math.max(0, cost - totalDepreciation);
    }

    const roundedValue = Math.round(currentBookValue * 100) / 100;
    await this.repo.updateCurrentBookValue(id, roundedValue);

    return {
      assetId: id,
      purchaseCost: cost,
      elapsedMonths: Math.floor(elapsedMonths),
      currentBookValue: roundedValue,
      accumulatedDepreciation: Math.round((cost - roundedValue) * 100) / 100,
    };
  }

  async deleteAsset(id: string, userId: string) {
    await this.findOne(id);
    await this.repo.deleteAsset(id);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.DELETE,
        entity: "Asset",
        entityId: id,
        payload: { deletedAt: new Date() },
      },
    });

    return { success: true, message: `Asset '${id}' deleted successfully` };
  }
}
