import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateLostFoundItemDto, ClaimLostFoundItemDto, QueryLostFoundDto } from "./dto";
import { Prisma, LostFoundStatus } from "@prisma/client";

@Injectable()
export class LostFoundRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateItemNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.lostFoundItem.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `LF-${today}-${seq}`;
  }

  async createItem(
    finderProfileId: string,
    dto: CreateLostFoundItemDto,
    itemNumber: string,
  ) {
    return this.prisma.lostFoundItem.create({
      data: {
        itemNumber,
        itemName: dto.itemName,
        description: dto.description,
        category: dto.category || "GENERAL",
        locationFound: dto.locationFound,
        foundById: finderProfileId,
        foundDate: dto.foundDate ? new Date(dto.foundDate) : new Date(),
        status: LostFoundStatus.FOUND,
        storageLocation: dto.storageLocation,
        images: dto.images || [],
      },
      include: {
        foundBy: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async findItems(query: QueryLostFoundDto) {
    const { page = 1, limit = 20, search, status, category } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.LostFoundItemWhereInput = {};
    if (status) where.status = status;
    if (category) where.category = category;
    if (search) {
      where.OR = [
        { itemName: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { itemNumber: { contains: search, mode: "insensitive" } },
        { locationFound: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.lostFoundItem.count({ where }),
      this.prisma.lostFoundItem.findMany({
        where,
        skip,
        take: limit,
        orderBy: { foundDate: "desc" },
        include: {
          foundBy: {
            select: { id: true, firstName: true, lastName: true },
          },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findItemById(id: string) {
    return this.prisma.lostFoundItem.findUnique({
      where: { id },
      include: {
        foundBy: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async claimItem(id: string, dto: ClaimLostFoundItemDto) {
    return this.prisma.lostFoundItem.update({
      where: { id },
      data: {
        status: LostFoundStatus.CLAIMED,
        claimantName: dto.claimantName,
        claimantPhone: dto.claimantPhone,
        claimantNationalId: dto.claimantNationalId,
        returnedAt: new Date(),
      },
      include: { foundBy: true },
    });
  }

  async updateItemStatus(id: string, status: LostFoundStatus) {
    return this.prisma.lostFoundItem.update({
      where: { id },
      data: { status },
    });
  }
}
