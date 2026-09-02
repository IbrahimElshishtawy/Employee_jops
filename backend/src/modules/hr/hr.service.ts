import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { HrEmployeeQueryDto } from "./dto/hr-query.dto";
import { UpdateEmployeeAssignmentDto } from "./dto/update-employee-assignment.dto";
import { CreateEmployeeDocumentDto } from "./dto/create-employee-document.dto";
import { UpdateEmployeeDocumentDto } from "./dto/update-employee-document.dto";
import { VerifyEmployeeDocumentDto } from "./dto/verify-employee-document.dto";
import { AuditAction, Prisma } from "@prisma/client";

@Injectable()
export class HrService {
  constructor(private prisma: PrismaService) {}

  /**
   * Paginated HR search across employees with organization & hierarchy filters
   */
  async getEmployees(query: HrEmployeeQueryDto) {
    const {
      skip,
      limit,
      search,
      organizationId,
      branchId,
      departmentId,
      positionId,
      workplaceId,
      isOnboarded,
      isProfileComplete,
    } = query;

    const where: Prisma.EmployeeProfileWhereInput = {
      ...(organizationId && { organizationId }),
      ...(branchId && { branchId }),
      ...(departmentId && { departmentId }),
      ...(positionId && { positionId }),
      ...(workplaceId && { workplaceId }),
      ...(isProfileComplete !== undefined && { isProfileComplete }),
      ...(isOnboarded !== undefined && {
        onboardingCompletedAt: isOnboarded ? { not: null } : null,
      }),
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: "insensitive" } },
          { lastName: { contains: search, mode: "insensitive" } },
          { employeeCode: { contains: search, mode: "insensitive" } },
          { department: { contains: search, mode: "insensitive" } },
          { jobTitle: { contains: search, mode: "insensitive" } },
        ],
      }),
    };

    const [total, rawData] = await Promise.all([
      this.prisma.employeeProfile.count({ where }),
      this.prisma.employeeProfile.findMany({
        where,
        skip,
        take: limit,
        select: {
          id: true,
          userId: true,
          employeeCode: true,
          firstName: true,
          lastName: true,
          phone: true,
          nationalId: true,
          gender: true,
          avatarUrl: true,
          jobTitle: true,
          department: true,
          hireDate: true,
          baseSalary: true,
          isProfileComplete: true,
          onboardingCompletedAt: true,
          createdAt: true,
          user: {
            select: {
              email: true,
              role: true,
              status: true,
            },
          },
          organization: {
            select: { id: true, name: true, code: true },
          },
          branch: {
            select: { id: true, name: true, code: true },
          },
          departmentRel: {
            select: { id: true, name: true, code: true },
          },
          section: {
            select: { id: true, name: true, code: true },
          },
          position: {
            select: { id: true, title: true, code: true, level: true },
          },
          workplace: {
            select: { id: true, name: true, code: true },
          },
          schedule: {
            select: { id: true, name: true, startTime: true, endTime: true },
          },
          manager: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              employeeCode: true,
            },
          },
          onboardingWorkflow: {
            select: {
              id: true,
              status: true,
              progressPercentage: true,
              completedAt: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    const data = rawData.map((e) => ({
      ...e,
      nationalId: this.maskNationalId(e.nationalId),
    }));

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Detailed HR employee profile lookup
   */
  async getEmployeeById(id: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            role: true,
            status: true,
            createdAt: true,
          },
        },
        organization: true,
        branch: true,
        departmentRel: true,
        section: true,
        position: true,
        workplace: true,
        schedule: true,
        manager: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            employeeCode: true,
            jobTitle: true,
          },
        },
        directReports: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            employeeCode: true,
            jobTitle: true,
          },
        },
        documents: {
          orderBy: { createdAt: "desc" },
        },
        onboardingWorkflow: {
          include: {
            tasks: {
              orderBy: { orderIndex: "asc" },
            },
          },
        },
      },
    });

    if (!employee) {
      throw new NotFoundException(`Employee profile #${id} not found`);
    }

    return {
      ...employee,
      nationalId: this.maskNationalId(employee.nationalId),
    };
  }

  /**
   * Reassign employee organizational hierarchy, position, workplace, and schedule
   */
  async updateEmployeeAssignment(
    id: string,
    dto: UpdateEmployeeAssignmentDto,
    updaterId?: string,
  ) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id },
    });
    if (!employee) {
      throw new NotFoundException(`Employee profile #${id} not found`);
    }

    if (dto.managerId && dto.managerId === id) {
      throw new BadRequestException("An employee cannot be their own manager");
    }

    // Auto-sync position title or department name if provided or resolved
    let resolvedJobTitle = dto.jobTitle;
    let resolvedDepartment = dto.department;

    if (dto.positionId && !resolvedJobTitle) {
      const position = await this.prisma.position.findUnique({
        where: { id: dto.positionId },
      });
      if (position) {
        resolvedJobTitle = position.title;
      }
    }

    if (dto.departmentId && !resolvedDepartment) {
      const dept = await this.prisma.department.findUnique({
        where: { id: dto.departmentId },
      });
      if (dept) {
        resolvedDepartment = dept.name;
      }
    }

    const updated = await this.prisma.employeeProfile.update({
      where: { id },
      data: {
        ...(dto.organizationId !== undefined && {
          organizationId: dto.organizationId,
        }),
        ...(dto.branchId !== undefined && { branchId: dto.branchId }),
        ...(dto.departmentId !== undefined && {
          departmentId: dto.departmentId,
        }),
        ...(dto.sectionId !== undefined && { sectionId: dto.sectionId }),
        ...(dto.positionId !== undefined && { positionId: dto.positionId }),
        ...(dto.managerId !== undefined && { managerId: dto.managerId }),
        ...(dto.workplaceId !== undefined && { workplaceId: dto.workplaceId }),
        ...(dto.scheduleId !== undefined && { scheduleId: dto.scheduleId }),
        ...(resolvedJobTitle && { jobTitle: resolvedJobTitle }),
        ...(resolvedDepartment && { department: resolvedDepartment }),
      },
      include: {
        organization: true,
        branch: true,
        departmentRel: true,
        section: true,
        position: true,
        workplace: true,
        schedule: true,
        manager: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            employeeCode: true,
          },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterId,
        action: AuditAction.EMPLOYEE_ASSIGNMENT_UPDATED,
        entity: "EmployeeProfile",
        entityId: id,
        payload: {
          organizationId: dto.organizationId,
          branchId: dto.branchId,
          departmentId: dto.departmentId,
          positionId: dto.positionId,
          workplaceId: dto.workplaceId,
          scheduleId: dto.scheduleId,
          managerId: dto.managerId,
        },
      },
    });

    return {
      ...updated,
      nationalId: this.maskNationalId(updated.nationalId),
    };
  }

  /**
   * Add document metadata for employee
   */
  async addEmployeeDocument(
    employeeId: string,
    dto: CreateEmployeeDocumentDto,
    creatorId?: string,
  ) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: employeeId },
    });
    if (!employee) {
      throw new NotFoundException(`Employee profile #${employeeId} not found`);
    }

    const document = await this.prisma.employeeDocument.create({
      data: {
        employeeId,
        documentType: dto.documentType,
        title: dto.title,
        documentNumber: dto.documentNumber,
        issueDate: dto.issueDate ? new Date(dto.issueDate) : null,
        expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
        fileUrl: dto.fileUrl,
        fileSize: dto.fileSize,
        mimeType: dto.mimeType,
        notes: dto.notes,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorId,
        action: AuditAction.EMPLOYEE_DOCUMENT_UPLOADED,
        entity: "EmployeeDocument",
        entityId: document.id,
        payload: {
          employeeId,
          documentType: dto.documentType,
          title: dto.title,
        },
      },
    });

    return document;
  }

  /**
   * List all documents for an employee
   */
  async getEmployeeDocuments(employeeId: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: employeeId },
    });
    if (!employee) {
      throw new NotFoundException(`Employee profile #${employeeId} not found`);
    }

    return this.prisma.employeeDocument.findMany({
      where: { employeeId },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Verify document metadata (HR Admin / Manager action)
   */
  async verifyEmployeeDocument(
    documentId: string,
    dto: VerifyEmployeeDocumentDto,
    verifierId: string,
  ) {
    const document = await this.prisma.employeeDocument.findUnique({
      where: { id: documentId },
    });
    if (!document) {
      throw new NotFoundException(`Document #${documentId} not found`);
    }

    const updated = await this.prisma.employeeDocument.update({
      where: { id: documentId },
      data: {
        isVerified: dto.isVerified,
        verifiedById: dto.isVerified ? verifierId : null,
        verifiedAt: dto.isVerified ? new Date() : null,
        ...(dto.notes && { notes: dto.notes }),
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: verifierId,
        action: AuditAction.EMPLOYEE_DOCUMENT_VERIFIED,
        entity: "EmployeeDocument",
        entityId: documentId,
        payload: { isVerified: dto.isVerified },
      },
    });

    return updated;
  }

  /**
   * Update document metadata
   */
  async updateEmployeeDocument(
    documentId: string,
    dto: UpdateEmployeeDocumentDto,
    updaterId?: string,
  ) {
    const document = await this.prisma.employeeDocument.findUnique({
      where: { id: documentId },
    });
    if (!document) {
      throw new NotFoundException(`Document #${documentId} not found`);
    }

    const updated = await this.prisma.employeeDocument.update({
      where: { id: documentId },
      data: {
        ...(dto.documentType && { documentType: dto.documentType }),
        ...(dto.title && { title: dto.title }),
        ...(dto.documentNumber !== undefined && {
          documentNumber: dto.documentNumber,
        }),
        ...(dto.issueDate !== undefined && {
          issueDate: dto.issueDate ? new Date(dto.issueDate) : null,
        }),
        ...(dto.expiryDate !== undefined && {
          expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
        }),
        ...(dto.fileUrl !== undefined && { fileUrl: dto.fileUrl }),
        ...(dto.fileSize !== undefined && { fileSize: dto.fileSize }),
        ...(dto.mimeType !== undefined && { mimeType: dto.mimeType }),
        ...(dto.isVerified !== undefined && { isVerified: dto.isVerified }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterId,
        action: AuditAction.UPDATE,
        entity: "EmployeeDocument",
        entityId: documentId,
      },
    });

    return updated;
  }

  /**
   * Delete document metadata
   */
  async deleteEmployeeDocument(documentId: string, deleterId?: string) {
    const document = await this.prisma.employeeDocument.findUnique({
      where: { id: documentId },
    });
    if (!document) {
      throw new NotFoundException(`Document #${documentId} not found`);
    }

    await this.prisma.employeeDocument.delete({
      where: { id: documentId },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterId,
        action: AuditAction.EMPLOYEE_DOCUMENT_DELETED,
        entity: "EmployeeDocument",
        entityId: documentId,
      },
    });

    return { message: "Document metadata deleted successfully" };
  }

  private maskNationalId(nationalId?: string | null): string | undefined {
    if (!nationalId) return undefined;
    if (nationalId.length <= 4) return "****";
    const last4 = nationalId.slice(-4);
    return `${"*".repeat(nationalId.length - 4)}${last4}`;
  }
}
