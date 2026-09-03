import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateIncidentDto,
  UpdateIncidentDto,
  AddInvestigationDto,
  AddCorrectiveActionDto,
  QueryIncidentsDto,
} from "./dto";
import { Prisma, IncidentStatus } from "@prisma/client";

@Injectable()
export class IncidentsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateIncidentNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.safetyIncident.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `INC-${today}-${seq}`;
  }

  async createIncident(
    reporterProfileId: string,
    dto: CreateIncidentDto,
    incidentNumber: string,
  ) {
    return this.prisma.safetyIncident.create({
      data: {
        incidentNumber,
        title: dto.title,
        description: dto.description,
        type: dto.type,
        severity: dto.severity,
        location: dto.location,
        incidentDate: dto.incidentDate ? new Date(dto.incidentDate) : new Date(),
        reporterId: reporterProfileId,
        departmentId: dto.departmentId,
        evidenceUrls: dto.evidenceUrls || [],
        status: IncidentStatus.REPORTED,
      },
      include: {
        department: true,
        reporter: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async findIncidents(query: QueryIncidentsDto) {
    const { page = 1, limit = 20, search, type, severity, status, departmentId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.SafetyIncidentWhereInput = {};
    if (type) where.type = type;
    if (severity) where.severity = severity;
    if (status) where.status = status;
    if (departmentId) where.departmentId = departmentId;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { location: { contains: search, mode: "insensitive" } },
        { incidentNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.safetyIncident.count({ where }),
      this.prisma.safetyIncident.findMany({
        where,
        skip,
        take: limit,
        orderBy: { incidentDate: "desc" },
        include: {
          department: true,
          reporter: {
            include: { user: { select: { email: true } } },
          },
          _count: { select: { investigations: true, correctiveActions: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findIncidentById(id: string) {
    return this.prisma.safetyIncident.findUnique({
      where: { id },
      include: {
        department: true,
        reporter: {
          include: { user: { select: { email: true } } },
        },
        investigations: {
          include: {
            investigator: {
              include: { user: { select: { email: true } } },
            },
          },
        },
        correctiveActions: {
          include: {
            assignedTo: {
              include: { user: { select: { email: true } } },
            },
          },
        },
      },
    });
  }

  async updateIncident(id: string, dto: UpdateIncidentDto) {
    const data: Prisma.SafetyIncidentUpdateInput = {};
    if (dto.status !== undefined) data.status = dto.status;
    if (dto.severity !== undefined) data.severity = dto.severity;

    return this.prisma.safetyIncident.update({
      where: { id },
      data,
      include: { department: true, reporter: true },
    });
  }

  async addInvestigation(incidentId: string, investigatorProfileId: string, dto: AddInvestigationDto) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Create investigation
      const investigation = await tx.incidentInvestigation.create({
        data: {
          incidentId,
          investigatorId: investigatorProfileId,
          findings: dto.findings,
          rootCause: dto.rootCause,
          recommendations: dto.recommendations,
          completedAt: new Date(),
        },
        include: { investigator: true },
      });

      // 2. Advance incident status to ACTION_REQUIRED
      await tx.safetyIncident.update({
        where: { id: incidentId },
        data: { status: IncidentStatus.ACTION_REQUIRED },
      });

      return investigation;
    });
  }

  async addCorrectiveAction(incidentId: string, dto: AddCorrectiveActionDto) {
    return this.prisma.incidentCorrectiveAction.create({
      data: {
        incidentId,
        actionTitle: dto.actionTitle,
        description: dto.description,
        assignedToId: dto.assignedToId,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        status: "PENDING",
      },
      include: {
        assignedTo: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }

  async resolveCorrectiveAction(actionId: string, resolutionNotes?: string) {
    return this.prisma.incidentCorrectiveAction.update({
      where: { id: actionId },
      data: {
        status: "COMPLETED",
        completedAt: new Date(),
        resolutionNotes,
      },
    });
  }
}
