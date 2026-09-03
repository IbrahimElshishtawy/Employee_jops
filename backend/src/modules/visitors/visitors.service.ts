import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { VisitorsRepository } from "./visitors.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { CheckInVisitorDto, CheckOutVisitorDto, QueryVisitorsDto } from "./dto";
import { AuditAction, VisitorStatus, NotificationType } from "@prisma/client";

@Injectable()
export class VisitorsService {
  private readonly logger = new Logger(VisitorsService.name);

  constructor(
    private readonly repo: VisitorsRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async checkInVisitor(userId: string, dto: CheckInVisitorDto) {
    const host = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.hostEmployeeId },
      include: { user: true },
    });

    if (!host) {
      throw new NotFoundException(
        `Host employee '${dto.hostEmployeeId}' not found`,
      );
    }

    const visitorNumber = await this.repo.generateVisitorNumber();
    const visitor = await this.repo.checkInVisitor(dto, visitorNumber);

    // Notify host employee
    if (host.user?.id) {
      await this.notificationsService
        .sendNotification(
          host.user.id,
          "Visitor Arrival",
          `${dto.fullName} (${dto.company || "Guest"}) has checked in to meet you. Purpose: ${dto.purpose}`,
          NotificationType.GENERAL_ANNOUNCEMENT,
          { visitorId: visitor.id, visitorNumber },
        )
        .catch(() => {});
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "VisitorLog",
        entityId: visitor.id,
        payload: {
          visitorNumber,
          fullName: visitor.fullName,
          hostEmployeeId: dto.hostEmployeeId,
        },
      },
    });

    return visitor;
  }

  async checkOutVisitor(id: string, userId: string, dto: CheckOutVisitorDto) {
    const visitor = await this.repo.findVisitorById(id);
    if (!visitor)
      throw new NotFoundException(`Visitor record '${id}' not found`);

    if (visitor.status !== VisitorStatus.CHECKED_IN) {
      throw new BadRequestException(
        `Visitor '${id}' is already ${visitor.status}`,
      );
    }

    const updated = await this.repo.checkOutVisitor(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "VisitorLog",
        entityId: id,
        payload: {
          status: VisitorStatus.CHECKED_OUT,
          checkOutTime: updated.checkOutTime,
        },
      },
    });

    return updated;
  }

  async findVisitors(query: QueryVisitorsDto) {
    return this.repo.findVisitors(query);
  }

  async findVisitorById(id: string) {
    const visitor = await this.repo.findVisitorById(id);
    if (!visitor)
      throw new NotFoundException(`Visitor record '${id}' not found`);
    return visitor;
  }
}
