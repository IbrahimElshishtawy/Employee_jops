import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateRequestDto } from './dto/create-request.dto';
import { RequestStatus, AuditAction, NotificationType } from '@prisma/client';

@Injectable()
export class RequestsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateRequestDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new BadRequestException('Employee profile required to submit requests');
    }

    const employeeId = user.employeeProfile.id;

    const request = await this.prisma.request.create({
      data: {
        employeeId,
        type: dto.type,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        startTime: dto.startTime,
        endTime: dto.endTime,
        reason: dto.reason,
        attachmentUrl: dto.attachmentUrl,
        status: RequestStatus.PENDING,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: 'Request',
        entityId: request.id,
        payload: { type: dto.type, startDate: dto.startDate, endDate: dto.endDate },
      },
    });

    return request;
  }

  async findMyRequests(employeeProfileId: string) {
    return this.prisma.request.findMany({
      where: { employeeId: employeeProfileId },
      orderBy: { createdAt: 'desc' },
      include: { approvalSteps: true },
    });
  }

  async findAll(status?: RequestStatus) {
    return this.prisma.request.findMany({
      where: status ? { status } : {},
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
          },
        },
        approvalSteps: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async processRequest(
    requestId: string,
    action: 'APPROVE' | 'REJECT',
    approverUserId: string,
    comment?: string,
  ) {
    const request = await this.prisma.request.findUnique({
      where: { id: requestId },
      include: { employee: { include: { user: true } } },
    });

    if (!request) {
      throw new NotFoundException('Request not found');
    }

    const newStatus =
      action === 'APPROVE' ? RequestStatus.APPROVED : RequestStatus.REJECTED;

    const updated = await this.prisma.request.update({
      where: { id: requestId },
      data: {
        status: newStatus,
        approvalSteps: {
          create: {
            approverId: approverUserId,
            status: newStatus,
            comment,
            actionDate: new Date(),
          },
        },
      },
    });

    // Notify employee
    await this.prisma.notification.create({
      data: {
        userId: request.employee.user.id,
        title: `Request ${action === 'APPROVE' ? 'Approved' : 'Rejected'}`,
        body: `Your ${request.type.replace('_', ' ')} request has been ${newStatus.toLowerCase()}.`,
        type: NotificationType.REQUEST_STATUS_UPDATE,
        data: { requestId: request.id, status: newStatus },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: approverUserId,
        action: action === 'APPROVE' ? AuditAction.APPROVE : AuditAction.REJECT,
        entity: 'Request',
        entityId: requestId,
        payload: { comment, newStatus },
      },
    });

    return updated;
  }
}
