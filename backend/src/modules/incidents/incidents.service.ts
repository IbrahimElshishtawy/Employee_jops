import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { IncidentsRepository } from "./incidents.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateIncidentDto,
  UpdateIncidentDto,
  AddInvestigationDto,
  AddCorrectiveActionDto,
  QueryIncidentsDto,
} from "./dto";
import { AuditAction, IncidentSeverity, UserStatus } from "@prisma/client";

@Injectable()
export class IncidentsService {
  private readonly logger = new Logger(IncidentsService.name);

  constructor(
    private readonly repo: IncidentsRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createIncident(userId: string, dto: CreateIncidentDto) {
    const reporter = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!reporter || reporter.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException(
        "Active employee profile required to report an incident",
      );
    }

    if (dto.departmentId) {
      const dept = await this.prisma.department.findUnique({
        where: { id: dto.departmentId },
      });
      if (!dept)
        throw new NotFoundException(
          `Department '${dto.departmentId}' not found`,
        );
    }

    const incidentNumber = await this.repo.generateIncidentNumber();
    const incident = await this.repo.createIncident(
      reporter.id,
      dto,
      incidentNumber,
    );

    // If critical or high severity, log alert
    if (
      dto.severity === IncidentSeverity.CRITICAL ||
      dto.severity === IncidentSeverity.HIGH
    ) {
      this.logger.warn(
        `High-severity incident reported: ${incidentNumber} - ${dto.title}`,
      );
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "SafetyIncident",
        entityId: incident.id,
        payload: {
          incidentNumber,
          title: incident.title,
          severity: incident.severity,
        },
      },
    });

    return incident;
  }

  async findIncidents(query: QueryIncidentsDto) {
    return this.repo.findIncidents(query);
  }

  async findIncidentById(id: string) {
    const incident = await this.repo.findIncidentById(id);
    if (!incident) throw new NotFoundException(`Incident '${id}' not found`);
    return incident;
  }

  async updateIncident(id: string, userId: string, dto: UpdateIncidentDto) {
    await this.findIncidentById(id);
    const updated = await this.repo.updateIncident(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "SafetyIncident",
        entityId: id,
        payload: {
          changes: JSON.parse(JSON.stringify(dto)),
          newStatus: updated.status,
        },
      },
    });

    return updated;
  }

  async addInvestigation(
    incidentId: string,
    userId: string,
    dto: AddInvestigationDto,
  ) {
    await this.findIncidentById(incidentId);

    const investigator = await this.prisma.employeeProfile.findUnique({
      where: { userId },
    });
    if (!investigator) {
      throw new BadRequestException(
        "Employee profile required to submit investigation",
      );
    }

    const investigation = await this.repo.addInvestigation(
      incidentId,
      investigator.id,
      dto,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "IncidentInvestigation",
        entityId: investigation.id,
        payload: { incidentId, rootCause: dto.rootCause },
      },
    });

    return investigation;
  }

  async addCorrectiveAction(
    incidentId: string,
    userId: string,
    dto: AddCorrectiveActionDto,
  ) {
    await this.findIncidentById(incidentId);

    if (dto.assignedToId) {
      const assignee = await this.prisma.employeeProfile.findUnique({
        where: { id: dto.assignedToId },
      });
      if (!assignee) {
        throw new NotFoundException(
          `Assignee employee '${dto.assignedToId}' not found`,
        );
      }
    }

    const action = await this.repo.addCorrectiveAction(incidentId, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "IncidentCorrectiveAction",
        entityId: action.id,
        payload: {
          incidentId,
          actionTitle: dto.actionTitle,
          assignedToId: dto.assignedToId,
        },
      },
    });

    return action;
  }

  async resolveCorrectiveAction(
    actionId: string,
    userId: string,
    resolutionNotes?: string,
  ) {
    const updated = await this.repo.resolveCorrectiveAction(
      actionId,
      resolutionNotes,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "IncidentCorrectiveAction",
        entityId: actionId,
        payload: { status: "COMPLETED", resolutionNotes },
      },
    });

    return updated;
  }
}
