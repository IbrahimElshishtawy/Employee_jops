import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import {
  CreateAnnouncementDto,
  UpdateAnnouncementDto,
  QueryAnnouncementsDto,
} from './dto';
import {
  AnnouncementStatus,
  AnnouncementTarget,
  AuditAction,
  NotificationType,
  Role,
  UserStatus,
  Prisma,
} from '@prisma/client';

@Injectable()
export class AnnouncementsService {
  private readonly logger = new Logger(AnnouncementsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createAnnouncement(dto: CreateAnnouncementDto, createdById: string) {
    if (dto.targetType === AnnouncementTarget.DEPARTMENT && !dto.targetDepartment) {
      throw new BadRequestException('targetDepartment is required when targetType is DEPARTMENT');
    }
    if (dto.targetType === AnnouncementTarget.WORKPLACE && !dto.targetWorkplaceId) {
      throw new BadRequestException('targetWorkplaceId is required when targetType is WORKPLACE');
    }

    const announcement = await this.prisma.announcement.create({
      data: {
        title: dto.title,
        body: dto.body,
        priority: dto.priority,
        targetType: dto.targetType,
        targetDepartment: dto.targetDepartment,
        targetWorkplaceId: dto.targetWorkplaceId,
        targetEmployeeIds: dto.targetEmployeeIds ? dto.targetEmployeeIds : undefined,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : undefined,
        status: dto.publishNow ? AnnouncementStatus.PUBLISHED : AnnouncementStatus.DRAFT,
        publishedAt: dto.publishNow ? new Date() : undefined,
        createdById,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: createdById,
        action: AuditAction.ANNOUNCEMENT_CREATED,
        entity: 'Announcement',
        entityId: announcement.id,
        payload: { title: dto.title, targetType: dto.targetType, status: announcement.status },
      },
    });

    if (dto.publishNow) {
      await this.broadcastAnnouncement(announcement);
    }

    return announcement;
  }

  async publishAnnouncement(id: string, publishedByUserId: string) {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
    });

    if (!announcement) {
      throw new NotFoundException('Announcement not found');
    }

    if (announcement.status === AnnouncementStatus.PUBLISHED) {
      throw new BadRequestException('Announcement is already published');
    }

    const updated = await this.prisma.announcement.update({
      where: { id },
      data: {
        status: AnnouncementStatus.PUBLISHED,
        publishedAt: new Date(),
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: publishedByUserId,
        action: AuditAction.ANNOUNCEMENT_PUBLISHED,
        entity: 'Announcement',
        entityId: id,
        payload: { title: announcement.title },
      },
    });

    await this.broadcastAnnouncement(updated);

    return updated;
  }

  async cancelAnnouncement(id: string, cancelledByUserId: string) {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
    });

    if (!announcement) {
      throw new NotFoundException('Announcement not found');
    }

    const updated = await this.prisma.announcement.update({
      where: { id },
      data: { status: AnnouncementStatus.CANCELLED },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: cancelledByUserId,
        action: AuditAction.ANNOUNCEMENT_CANCELLED,
        entity: 'Announcement',
        entityId: id,
      },
    });

    return updated;
  }

  private async broadcastAnnouncement(announcement: any) {
    try {
      // Resolve target users based on audience
      const targetUserIds = await this.resolveTargetUserIds(announcement);

      if (targetUserIds.length > 0) {
        await this.notificationsService.sendBatchNotifications(
          targetUserIds,
          `Announcement: ${announcement.title}`,
          announcement.body.length > 150 ? `${announcement.body.slice(0, 147)}...` : announcement.body,
          NotificationType.ANNOUNCEMENT,
          { announcementId: announcement.id },
          announcement.priority,
        );
      }
    } catch (err: any) {
      this.logger.error(`Failed to broadcast announcement notifications: ${err?.message || err}`);
    }
  }

  private async resolveTargetUserIds(announcement: any): Promise<string[]> {
    let whereClause: Prisma.UserWhereInput = {
      status: UserStatus.ACTIVE,
    };

    if (announcement.targetType === AnnouncementTarget.DEPARTMENT && announcement.targetDepartment) {
      whereClause.employeeProfile = { department: announcement.targetDepartment };
    } else if (announcement.targetType === AnnouncementTarget.WORKPLACE && announcement.targetWorkplaceId) {
      whereClause.employeeProfile = { workplaceId: announcement.targetWorkplaceId };
    } else if (announcement.targetType === AnnouncementTarget.EMPLOYEES && announcement.targetEmployeeIds) {
      const empIds = announcement.targetEmployeeIds as string[];
      whereClause.employeeProfile = { id: { in: empIds } };
    }

    const users = await this.prisma.user.findMany({
      where: whereClause,
      select: { id: true },
    });

    return users.map((u) => u.id);
  }

  async getAnnouncements(
    currentUser: { id: string; role: Role; employeeProfileId?: string },
    query: QueryAnnouncementsDto = {},
  ) {
    const { page = 1, limit = 10, status, targetType, department } = query;
    const skip = (page - 1) * limit;

    const isHr = ([Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER] as Role[]).includes(currentUser.role);

    const where: Prisma.AnnouncementWhereInput = {};

    if (isHr) {
      if (status) where.status = status;
      if (targetType) where.targetType = targetType;
      if (department) where.targetDepartment = department;
    } else {
      // Normal employee: only sees active published announcements
      where.status = AnnouncementStatus.PUBLISHED;

      const employee = currentUser.employeeProfileId
        ? await this.prisma.employeeProfile.findUnique({
            where: { id: currentUser.employeeProfileId },
          })
        : null;

      where.OR = [
        { targetType: AnnouncementTarget.ALL },
        ...(employee?.department
          ? [{ targetType: AnnouncementTarget.DEPARTMENT, targetDepartment: employee.department }]
          : []),
        ...(employee?.workplaceId
          ? [{ targetType: AnnouncementTarget.WORKPLACE, targetWorkplaceId: employee.workplaceId }]
          : []),
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.announcement.count({ where }),
      this.prisma.announcement.findMany({
        where,
        skip,
        take: limit,
        orderBy: { publishedAt: 'desc' },
        include: {
          reads: {
            where: { userId: currentUser.id },
            select: { readAt: true },
          },
        },
      }),
    ]);

    const formattedData = data.map((ann) => ({
      ...ann,
      isRead: ann.reads.length > 0,
      readAt: ann.reads[0]?.readAt || null,
      reads: undefined,
    }));

    return {
      data: formattedData,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getAnnouncementDetails(id: string, currentUserId: string) {
    const announcement = await this.prisma.announcement.findUnique({
      where: { id },
      include: {
        reads: {
          where: { userId: currentUserId },
        },
      },
    });

    if (!announcement) {
      throw new NotFoundException('Announcement not found');
    }

    // Auto mark as read
    if (announcement.reads.length === 0) {
      await this.markAsRead(id, currentUserId);
    }

    return {
      ...announcement,
      isRead: true,
    };
  }

  async markAsRead(announcementId: string, userId: string) {
    return this.prisma.announcementRead.upsert({
      where: {
        announcementId_userId: {
          announcementId,
          userId,
        },
      },
      update: { readAt: new Date() },
      create: {
        announcementId,
        userId,
      },
    });
  }
}
