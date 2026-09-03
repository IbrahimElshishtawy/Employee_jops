import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateAssetDto, UpdateAssetDto, CreateAssetCategoryDto, QueryAssetsDto } from "./dto";
import { Prisma } from "@prisma/client";

@Injectable()
export class AssetsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Category Operations
  async createCategory(dto: CreateAssetCategoryDto) {
    return this.prisma.assetCategory.create({
      data: {
        name: dto.name,
        code: dto.code,
        description: dto.description,
        usefulLifeMonths: dto.usefulLifeMonths,
        depreciationRate: dto.depreciationRate !== undefined ? new Prisma.Decimal(dto.depreciationRate) : null,
      },
    });
  }

  async findCategories() {
    return this.prisma.assetCategory.findMany({
      include: {
        _count: {
          select: { assets: true },
        },
      },
      orderBy: { name: "asc" },
    });
  }

  async findCategoryById(id: string) {
    return this.prisma.assetCategory.findUnique({
      where: { id },
    });
  }

  async findCategoryByCode(code: string) {
    return this.prisma.assetCategory.findUnique({
      where: { code },
    });
  }

  // Asset Operations
  async createAsset(dto: CreateAssetDto) {
    return this.prisma.asset.create({
      data: {
        assetCode: dto.assetCode,
        name: dto.name,
        description: dto.description,
        categoryId: dto.categoryId,
        serialNumber: dto.serialNumber,
        barcode: dto.barcode,
        purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : null,
        purchaseCost: dto.purchaseCost !== undefined ? new Prisma.Decimal(dto.purchaseCost) : null,
        currentBookValue: dto.purchaseCost !== undefined ? new Prisma.Decimal(dto.purchaseCost) : null,
        location: dto.location,
        status: dto.status,
        departmentId: dto.departmentId,
        assignedToId: dto.assignedToId,
        warrantyExpiry: dto.warrantyExpiry ? new Date(dto.warrantyExpiry) : null,
        metadata: dto.metadata,
      },
      include: {
        category: true,
        department: true,
        assignedTo: {
          include: { user: { select: { email: true, role: true } } },
        },
      },
    });
  }

  async findAssetById(id: string) {
    return this.prisma.asset.findUnique({
      where: { id },
      include: {
        category: true,
        department: true,
        assignedTo: {
          include: { user: { select: { email: true, role: true } } },
        },
        maintenanceRequests: {
          take: 10,
          orderBy: { createdAt: "desc" },
        },
      },
    });
  }

  async findAssetByCode(assetCode: string) {
    return this.prisma.asset.findUnique({
      where: { assetCode },
    });
  }

  async findAssets(query: QueryAssetsDto) {
    const { page = 1, limit = 20, search, status, categoryId, departmentId, assignedToId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.AssetWhereInput = {};

    if (status) {
      where.status = status;
    }
    if (categoryId) {
      where.categoryId = categoryId;
    }
    if (departmentId) {
      where.departmentId = departmentId;
    }
    if (assignedToId) {
      where.assignedToId = assignedToId;
    }
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { assetCode: { contains: search, mode: "insensitive" } },
        { serialNumber: { contains: search, mode: "insensitive" } },
        { barcode: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.asset.count({ where }),
      this.prisma.asset.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          category: true,
          department: true,
          assignedTo: {
            include: { user: { select: { email: true } } },
          },
        },
      }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateAsset(id: string, dto: UpdateAssetDto) {
    const data: Prisma.AssetUpdateInput = {};

    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.serialNumber !== undefined) data.serialNumber = dto.serialNumber;
    if (dto.barcode !== undefined) data.barcode = dto.barcode;
    if (dto.location !== undefined) data.location = dto.location;
    if (dto.status !== undefined) data.status = dto.status;
    if (dto.metadata !== undefined) data.metadata = dto.metadata;
    if (dto.purchaseDate !== undefined) data.purchaseDate = dto.purchaseDate ? new Date(dto.purchaseDate) : null;
    if (dto.purchaseCost !== undefined) data.purchaseCost = dto.purchaseCost !== null ? new Prisma.Decimal(dto.purchaseCost) : null;
    if (dto.warrantyExpiry !== undefined) data.warrantyExpiry = dto.warrantyExpiry ? new Date(dto.warrantyExpiry) : null;

    if (dto.categoryId !== undefined) {
      data.category = { connect: { id: dto.categoryId } };
    }
    if (dto.departmentId !== undefined) {
      data.department = dto.departmentId ? { connect: { id: dto.departmentId } } : { disconnect: true };
    }
    if (dto.assignedToId !== undefined) {
      data.assignedTo = dto.assignedToId ? { connect: { id: dto.assignedToId } } : { disconnect: true };
    }

    return this.prisma.asset.update({
      where: { id },
      data,
      include: {
        category: true,
        department: true,
        assignedTo: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async updateCurrentBookValue(id: string, currentBookValue: number) {
    return this.prisma.asset.update({
      where: { id },
      data: { currentBookValue: new Prisma.Decimal(currentBookValue) },
    });
  }

  async deleteAsset(id: string) {
    return this.prisma.asset.delete({
      where: { id },
    });
  }
}
