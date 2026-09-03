import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { LostFoundRepository } from "./lost-found.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateLostFoundItemDto, ClaimLostFoundItemDto, QueryLostFoundDto } from "./dto";
import { AuditAction, LostFoundStatus, UserStatus } from "@prisma/client";

@Injectable()
export class LostFoundService {
  private readonly logger = new Logger(LostFoundService.name);

  constructor(
    private readonly repo: LostFoundRepository,
    private readonly prisma: PrismaService,
  ) {}

  async createItem(userId: string, dto: CreateLostFoundItemDto) {
    const finder = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!finder || finder.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException("Active employee profile required to register a found item");
    }

    const itemNumber = await this.repo.generateItemNumber();
    const item = await this.repo.createItem(finder.id, dto, itemNumber);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "LostFoundItem",
        entityId: item.id,
        payload: { itemNumber, itemName: item.itemName, locationFound: item.locationFound },
      },
    });

    return item;
  }

  async findItems(query: QueryLostFoundDto) {
    return this.repo.findItems(query);
  }

  async findItemById(id: string) {
    const item = await this.repo.findItemById(id);
    if (!item) throw new NotFoundException(`Lost & found item '${id}' not found`);
    return item;
  }

  async claimItem(id: string, userId: string, dto: ClaimLostFoundItemDto) {
    const item = await this.findItemById(id);

    if (item.status !== LostFoundStatus.FOUND) {
      throw new BadRequestException(`Item '${id}' is already marked as ${item.status}`);
    }

    const updated = await this.repo.claimItem(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "LostFoundItem",
        entityId: id,
        payload: {
          status: LostFoundStatus.CLAIMED,
          claimantName: dto.claimantName,
          claimantPhone: dto.claimantPhone,
        },
      },
    });

    return updated;
  }

  async updateItemStatus(id: string, userId: string, status: LostFoundStatus) {
    await this.findItemById(id);
    const updated = await this.repo.updateItemStatus(id, status);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "LostFoundItem",
        entityId: id,
        payload: { status },
      },
    });

    return updated;
  }
}
