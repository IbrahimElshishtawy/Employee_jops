import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { DepartmentOperationsRepository } from "./department-operations.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ServiceRequestsService } from "../service-requests/service-requests.service";
import {
  QueryDepartmentOperationsDto,
  DepartmentTriageRequestDto,
  DepartmentReportQueryDto,
} from "./dto";
import { AuditAction, Role } from "@prisma/client";
import { CsvExporterUtil } from "../reports/utils/csv-exporter.util";

@Injectable()
export class DepartmentOperationsService {
  private readonly logger = new Logger(DepartmentOperationsService.name);

  constructor(
    private readonly repo: DepartmentOperationsRepository,
    private readonly prisma: PrismaService,
    private readonly serviceRequestsService: ServiceRequestsService,
  ) {}

  // ============================================================
  // 1. DEPARTMENT OVERVIEW TELEMETRY
  // ============================================================

  async getOverview(actorUserId: string, query: QueryDepartmentOperationsDto) {
    const department = await this.prisma.department.findUnique({
      where: { id: query.departmentId },
    });

    if (!department) {
      throw new NotFoundException(`Department ${query.departmentId} not found`);
    }

    const overview = await this.repo.getDepartmentOverview(
      query.departmentId,
      query.date,
      query.workplaceId,
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.DEPARTMENT_OPERATION_LOGGED,
        entity: "DepartmentOperations",
        entityId: query.departmentId,
        payload: {
          action: "OVERVIEW_ACCESSED",
          date: query.date || new Date().toISOString(),
        },
      },
    });

    return overview;
  }

  // ============================================================
  // 2. TRIAGE & ESCALATE SERVICE REQUEST
  // ============================================================

  async triageServiceRequest(
    actorUserId: string,
    dto: DepartmentTriageRequestDto,
  ) {
    // 1. Assign technician via ServiceRequestsService
    const assigned = await this.serviceRequestsService.assignServiceRequest(
      dto.serviceRequestId,
      actorUserId,
      {
        assignedToId: dto.assignedToId,
        dueDate: dto.dueDate,
        notes: dto.notes,
      },
    );

    // 2. Update priority if specified
    if (dto.priority && dto.priority !== assigned.priority) {
      await this.prisma.serviceRequest.update({
        where: { id: dto.serviceRequestId },
        data: { priority: dto.priority },
      });
    }

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.DEPARTMENT_OPERATION_LOGGED,
        entity: "DepartmentOperations",
        entityId: assigned.departmentId,
        payload: {
          action: "TRIAGE_SERVICE_REQUEST",
          serviceRequestId: dto.serviceRequestId,
          assignedToId: dto.assignedToId,
          priority: dto.priority || assigned.priority,
        },
      },
    });

    return this.prisma.serviceRequest.findUnique({
      where: { id: dto.serviceRequestId },
      include: {
        assignedTo: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
  }

  // ============================================================
  // 3. DEPARTMENT OPERATIONAL KPIS & REPORT
  // ============================================================

  async getOperationalReport(
    actorUserId: string,
    dto: DepartmentReportQueryDto,
  ) {
    const department = await this.prisma.department.findUnique({
      where: { id: dto.departmentId },
    });

    if (!department) {
      throw new NotFoundException(`Department ${dto.departmentId} not found`);
    }

    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);
    endDate.setHours(23, 59, 59, 999);

    if (startDate > endDate) {
      throw new BadRequestException("Start date cannot be after end date");
    }

    const kpiData = await this.repo.getDepartmentKPIs(
      dto.departmentId,
      startDate,
      endDate,
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.DEPARTMENT_OPERATION_LOGGED,
        entity: "DepartmentOperations",
        entityId: dto.departmentId,
        payload: {
          action: "REPORT_ACCESSED",
          startDate: dto.startDate,
          endDate: dto.endDate,
        },
      },
    });

    if (dto.exportCsv) {
      const headers = [
        { key: "employeeId", label: "Employee ID" },
        { key: "name", label: "Employee Name" },
        { key: "jobTitle", label: "Job Title" },
        { key: "activeTasksCount", label: "Active Tasks" },
        { key: "activeServiceRequestsCount", label: "Active Service Requests" },
        { key: "totalActiveItems", label: "Total Active Items" },
      ];

      return CsvExporterUtil.generateCsv(headers, kpiData.workloadDistribution);
    }

    return {
      department: {
        id: department.id,
        name: department.name,
        code: department.code,
      },
      ...kpiData,
    };
  }
}
