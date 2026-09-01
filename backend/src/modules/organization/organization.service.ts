import {
  Injectable,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateOrganizationDto,
  UpdateOrganizationDto,
  CreateBranchDto,
  UpdateBranchDto,
  CreateDepartmentDto,
  UpdateDepartmentDto,
  CreateSectionDto,
  UpdateSectionDto,
  CreatePositionDto,
  UpdatePositionDto,
} from "./dto";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";
import { AuditAction, Prisma } from "@prisma/client";

@Injectable()
export class OrganizationService {
  constructor(private readonly prisma: PrismaService) {}

  // ==========================================
  // 1. ORGANIZATION MANAGEMENT
  // ==========================================

  async createOrganization(dto: CreateOrganizationDto, creatorUserId?: string) {
    const existing = await this.prisma.organization.findUnique({
      where: { code: dto.code.toUpperCase().trim() },
    });
    if (existing) {
      throw new ConflictException(
        `Organization with code '${dto.code}' already exists`,
      );
    }

    const org = await this.prisma.organization.create({
      data: {
        name: dto.name,
        code: dto.code.toUpperCase().trim(),
        logoUrl: dto.logoUrl,
        taxNumber: dto.taxNumber,
        commercialRegister: dto.commercialRegister,
        description: dto.description,
        address: dto.address,
        phone: dto.phone,
        email: dto.email,
        currency: dto.currency || "EGP",
        timezone: dto.timezone || "Africa/Cairo",
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.ORGANIZATION_CREATED,
        entity: "Organization",
        entityId: org.id,
        payload: { name: org.name, code: org.code },
      },
    });

    return org;
  }

  async findAllOrganizations(query: PaginationQueryDto) {
    const { skip, limit, search } = query;
    const where: Prisma.OrganizationWhereInput = search
      ? {
          OR: [
            { name: { contains: search, mode: "insensitive" } },
            { code: { contains: search, mode: "insensitive" } },
          ],
        }
      : {};

    const [total, data] = await Promise.all([
      this.prisma.organization.count({ where }),
      this.prisma.organization.findMany({
        where,
        skip,
        take: limit,
        include: {
          _count: {
            select: {
              branches: true,
              departments: true,
              positions: true,
              employees: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

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

  async findOrganizationById(id: string) {
    const org = await this.prisma.organization.findFirst({
      where: {
        OR: [{ id }, { code: id }],
      },
      include: {
        branches: true,
        departments: {
          include: {
            headOfDepartment: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                jobTitle: true,
              },
            },
            sections: true,
          },
        },
        positions: true,
        _count: {
          select: {
            employees: true,
          },
        },
      },
    });

    if (!org) {
      throw new NotFoundException(`Organization '${id}' not found`);
    }

    return org;
  }

  async updateOrganization(
    id: string,
    dto: UpdateOrganizationDto,
    updaterUserId?: string,
  ) {
    const org = await this.findOrganizationById(id);

    const updated = await this.prisma.organization.update({
      where: { id: org.id },
      data: dto,
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.ORGANIZATION_UPDATED,
        entity: "Organization",
        entityId: updated.id,
      },
    });

    return updated;
  }

  async deleteOrganization(id: string, deleterUserId?: string) {
    const org = await this.findOrganizationById(id);

    await this.prisma.organization.delete({
      where: { id: org.id },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.ORGANIZATION_DELETED,
        entity: "Organization",
        entityId: org.id,
        payload: { code: org.code },
      },
    });

    return { message: `Organization '${org.name}' deleted successfully` };
  }

  // ==========================================
  // 2. BRANCH / HOTEL MANAGEMENT
  // ==========================================

  async createBranch(dto: CreateBranchDto, creatorUserId?: string) {
    const existing = await this.prisma.branch.findUnique({
      where: { code: dto.code.toUpperCase().trim() },
    });
    if (existing) {
      throw new ConflictException(
        `Branch with code '${dto.code}' already exists`,
      );
    }

    const branch = await this.prisma.branch.create({
      data: {
        organizationId: dto.organizationId,
        name: dto.name,
        code: dto.code.toUpperCase().trim(),
        type: dto.type,
        address: dto.address,
        city: dto.city,
        country: dto.country || "Egypt",
        phone: dto.phone,
        email: dto.email,
        latitude: dto.latitude,
        longitude: dto.longitude,
        radiusMeters: dto.radiusMeters || 100,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.BRANCH_CREATED,
        entity: "Branch",
        entityId: branch.id,
        payload: { name: branch.name, code: branch.code },
      },
    });

    return branch;
  }

  async findAllBranches(query: PaginationQueryDto, organizationId?: string) {
    const { skip, limit, search } = query;
    const where: Prisma.BranchWhereInput = {
      ...(organizationId ? { organizationId } : {}),
      ...(search
        ? {
            OR: [
              { name: { contains: search, mode: "insensitive" } },
              { code: { contains: search, mode: "insensitive" } },
              { city: { contains: search, mode: "insensitive" } },
            ],
          }
        : {}),
    };

    const [total, data] = await Promise.all([
      this.prisma.branch.count({ where }),
      this.prisma.branch.findMany({
        where,
        skip,
        take: limit,
        include: {
          organization: { select: { id: true, name: true, code: true } },
          _count: { select: { departments: true, employees: true } },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

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

  async findBranchById(id: string) {
    const branch = await this.prisma.branch.findFirst({
      where: {
        OR: [{ id }, { code: id }],
      },
      include: {
        organization: true,
        departments: {
          include: {
            headOfDepartment: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                jobTitle: true,
              },
            },
          },
        },
        employees: {
          take: 50,
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
          },
        },
      },
    });

    if (!branch) {
      throw new NotFoundException(`Branch '${id}' not found`);
    }

    return branch;
  }

  async updateBranch(
    id: string,
    dto: UpdateBranchDto,
    updaterUserId?: string,
  ) {
    const branch = await this.findBranchById(id);

    const updated = await this.prisma.branch.update({
      where: { id: branch.id },
      data: dto,
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.BRANCH_UPDATED,
        entity: "Branch",
        entityId: updated.id,
      },
    });

    return updated;
  }

  async deleteBranch(id: string, deleterUserId?: string) {
    const branch = await this.findBranchById(id);

    await this.prisma.branch.delete({
      where: { id: branch.id },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.BRANCH_DELETED,
        entity: "Branch",
        entityId: branch.id,
        payload: { code: branch.code },
      },
    });

    return { message: `Branch '${branch.name}' deleted successfully` };
  }

  // ==========================================
  // 3. DEPARTMENT MANAGEMENT
  // ==========================================

  async createDepartment(dto: CreateDepartmentDto, creatorUserId?: string) {
    const existing = await this.prisma.department.findUnique({
      where: { code: dto.code.toUpperCase().trim() },
    });
    if (existing) {
      throw new ConflictException(
        `Department with code '${dto.code}' already exists`,
      );
    }

    const department = await this.prisma.department.create({
      data: {
        organizationId: dto.organizationId,
        branchId: dto.branchId,
        parentDepartmentId: dto.parentDepartmentId,
        headOfDepartmentId: dto.headOfDepartmentId,
        name: dto.name,
        code: dto.code.toUpperCase().trim(),
        description: dto.description,
      },
      include: {
        parentDepartment: true,
        headOfDepartment: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
          },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.DEPARTMENT_CREATED,
        entity: "Department",
        entityId: department.id,
        payload: { name: department.name, code: department.code },
      },
    });

    return department;
  }

  async findAllDepartments(
    query: PaginationQueryDto,
    organizationId?: string,
    branchId?: string,
  ) {
    const { skip, limit, search } = query;
    const where: Prisma.DepartmentWhereInput = {
      ...(organizationId ? { organizationId } : {}),
      ...(branchId ? { branchId } : {}),
      ...(search
        ? {
            OR: [
              { name: { contains: search, mode: "insensitive" } },
              { code: { contains: search, mode: "insensitive" } },
            ],
          }
        : {}),
    };

    const [total, data] = await Promise.all([
      this.prisma.department.count({ where }),
      this.prisma.department.findMany({
        where,
        skip,
        take: limit,
        include: {
          branch: { select: { id: true, name: true, code: true } },
          parentDepartment: { select: { id: true, name: true, code: true } },
          headOfDepartment: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              jobTitle: true,
            },
          },
          _count: {
            select: {
              sections: true,
              positions: true,
              employees: true,
              subDepartments: true,
            },
          },
        },
        orderBy: { name: "asc" },
      }),
    ]);

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

  async findDepartmentById(id: string) {
    const dept = await this.prisma.department.findFirst({
      where: {
        OR: [{ id }, { code: id }],
      },
      include: {
        organization: true,
        branch: true,
        parentDepartment: true,
        subDepartments: true,
        headOfDepartment: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            phone: true,
          },
        },
        sections: {
          include: {
            headOfSection: {
              select: { id: true, firstName: true, lastName: true },
            },
            _count: { select: { positions: true, employees: true } },
          },
        },
        positions: true,
      },
    });

    if (!dept) {
      throw new NotFoundException(`Department '${id}' not found`);
    }

    return dept;
  }

  async updateDepartment(
    id: string,
    dto: UpdateDepartmentDto,
    updaterUserId?: string,
  ) {
    const dept = await this.findDepartmentById(id);

    const updated = await this.prisma.department.update({
      where: { id: dept.id },
      data: dto,
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.DEPARTMENT_UPDATED,
        entity: "Department",
        entityId: updated.id,
      },
    });

    return updated;
  }

  async deleteDepartment(id: string, deleterUserId?: string) {
    const dept = await this.findDepartmentById(id);

    await this.prisma.department.delete({
      where: { id: dept.id },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.DEPARTMENT_DELETED,
        entity: "Department",
        entityId: dept.id,
        payload: { code: dept.code },
      },
    });

    return { message: `Department '${dept.name}' deleted successfully` };
  }

  // ==========================================
  // 4. SECTION MANAGEMENT
  // ==========================================

  async createSection(dto: CreateSectionDto, creatorUserId?: string) {
    const existing = await this.prisma.section.findUnique({
      where: { code: dto.code.toUpperCase().trim() },
    });
    if (existing) {
      throw new ConflictException(
        `Section with code '${dto.code}' already exists`,
      );
    }

    const section = await this.prisma.section.create({
      data: {
        departmentId: dto.departmentId,
        headOfSectionId: dto.headOfSectionId,
        name: dto.name,
        code: dto.code.toUpperCase().trim(),
        description: dto.description,
      },
      include: {
        department: true,
        headOfSection: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.SECTION_CREATED,
        entity: "Section",
        entityId: section.id,
        payload: { name: section.name, code: section.code },
      },
    });

    return section;
  }

  async findAllSections(departmentId?: string) {
    return this.prisma.section.findMany({
      where: departmentId ? { departmentId } : {},
      include: {
        department: { select: { id: true, name: true, code: true } },
        headOfSection: {
          select: { id: true, firstName: true, lastName: true },
        },
        _count: { select: { positions: true, employees: true } },
      },
      orderBy: { name: "asc" },
    });
  }

  async findSectionById(id: string) {
    const sec = await this.prisma.section.findFirst({
      where: {
        OR: [{ id }, { code: id }],
      },
      include: {
        department: true,
        headOfSection: true,
        positions: true,
      },
    });

    if (!sec) {
      throw new NotFoundException(`Section '${id}' not found`);
    }

    return sec;
  }

  async updateSection(
    id: string,
    dto: UpdateSectionDto,
    updaterUserId?: string,
  ) {
    const sec = await this.findSectionById(id);

    const updated = await this.prisma.section.update({
      where: { id: sec.id },
      data: dto,
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.SECTION_UPDATED,
        entity: "Section",
        entityId: updated.id,
      },
    });

    return updated;
  }

  async deleteSection(id: string, deleterUserId?: string) {
    const sec = await this.findSectionById(id);

    await this.prisma.section.delete({
      where: { id: sec.id },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.SECTION_DELETED,
        entity: "Section",
        entityId: sec.id,
        payload: { code: sec.code },
      },
    });

    return { message: `Section '${sec.name}' deleted successfully` };
  }

  // ==========================================
  // 5. POSITION MANAGEMENT
  // ==========================================

  async createPosition(dto: CreatePositionDto, creatorUserId?: string) {
    const existing = await this.prisma.position.findUnique({
      where: { code: dto.code.toUpperCase().trim() },
    });
    if (existing) {
      throw new ConflictException(
        `Position with code '${dto.code}' already exists`,
      );
    }

    const position = await this.prisma.position.create({
      data: {
        organizationId: dto.organizationId,
        departmentId: dto.departmentId,
        sectionId: dto.sectionId,
        title: dto.title,
        code: dto.code.toUpperCase().trim(),
        level: dto.level,
        minSalary: dto.minSalary ? new Prisma.Decimal(dto.minSalary) : undefined,
        maxSalary: dto.maxSalary ? new Prisma.Decimal(dto.maxSalary) : undefined,
        description: dto.description,
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        section: { select: { id: true, name: true, code: true } },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.POSITION_CREATED,
        entity: "Position",
        entityId: position.id,
        payload: { title: position.title, code: position.code },
      },
    });

    return position;
  }

  async findAllPositions(organizationId?: string, departmentId?: string) {
    return this.prisma.position.findMany({
      where: {
        ...(organizationId ? { organizationId } : {}),
        ...(departmentId ? { departmentId } : {}),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        section: { select: { id: true, name: true, code: true } },
        _count: { select: { employees: true } },
      },
      orderBy: [{ departmentId: "asc" }, { title: "asc" }],
    });
  }

  async findPositionById(id: string) {
    const pos = await this.prisma.position.findFirst({
      where: {
        OR: [{ id }, { code: id }],
      },
      include: {
        organization: true,
        department: true,
        section: true,
        employees: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!pos) {
      throw new NotFoundException(`Position '${id}' not found`);
    }

    return pos;
  }

  async updatePosition(
    id: string,
    dto: UpdatePositionDto,
    updaterUserId?: string,
  ) {
    const pos = await this.findPositionById(id);

    const updated = await this.prisma.position.update({
      where: { id: pos.id },
      data: {
        title: dto.title,
        level: dto.level,
        minSalary: dto.minSalary
          ? new Prisma.Decimal(dto.minSalary)
          : undefined,
        maxSalary: dto.maxSalary
          ? new Prisma.Decimal(dto.maxSalary)
          : undefined,
        description: dto.description,
        departmentId: dto.departmentId,
        sectionId: dto.sectionId,
        isActive: dto.isActive,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.POSITION_UPDATED,
        entity: "Position",
        entityId: updated.id,
      },
    });

    return updated;
  }

  async deletePosition(id: string, deleterUserId?: string) {
    const pos = await this.findPositionById(id);

    await this.prisma.position.delete({
      where: { id: pos.id },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.POSITION_DELETED,
        entity: "Position",
        entityId: pos.id,
        payload: { code: pos.code },
      },
    });

    return { message: `Position '${pos.title}' deleted successfully` };
  }

  // ==========================================
  // 6. HIERARCHY, ORG CHART & REPORTING TREE
  // ==========================================

  /**
   * Complete Enterprise Organization Tree Aggregation
   */
  async getOrganizationHierarchy(organizationId?: string) {
    const org = await this.prisma.organization.findFirst({
      where: organizationId ? { id: organizationId } : { isActive: true },
      include: {
        branches: {
          where: { isActive: true },
          include: {
            departments: {
              where: { isActive: true, parentDepartmentId: null },
              include: {
                headOfDepartment: {
                  select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    jobTitle: true,
                  },
                },
                subDepartments: {
                  where: { isActive: true },
                  include: {
                    headOfDepartment: {
                      select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        jobTitle: true,
                      },
                    },
                    sections: {
                      where: { isActive: true },
                      include: {
                        headOfSection: {
                          select: {
                            id: true,
                            firstName: true,
                            lastName: true,
                            jobTitle: true,
                          },
                        },
                        positions: {
                          where: { isActive: true },
                          include: {
                            _count: { select: { employees: true } },
                          },
                        },
                      },
                    },
                  },
                },
                sections: {
                  where: { isActive: true },
                  include: {
                    headOfSection: {
                      select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        jobTitle: true,
                      },
                    },
                    positions: {
                      where: { isActive: true },
                      include: {
                        _count: { select: { employees: true } },
                      },
                    },
                  },
                },
                positions: {
                  where: { isActive: true },
                  include: {
                    _count: { select: { employees: true } },
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!org) {
      throw new NotFoundException("Organization hierarchy not found");
    }

    return org;
  }

  /**
   * Calculates upstream managers and downstream direct reports for an employee
   */
  async getEmployeeReportingHierarchy(employeeProfileId: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: employeeProfileId },
      include: {
        manager: {
          include: {
            manager: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                jobTitle: true,
                department: true,
              },
            },
          },
        },
        directReports: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            avatarUrl: true,
          },
        },
        departmentRel: {
          select: { id: true, name: true, code: true },
        },
        position: {
          select: { id: true, title: true, level: true },
        },
      },
    });

    if (!employee) {
      throw new NotFoundException(
        `Employee '${employeeProfileId}' not found`,
      );
    }

    // Build chain of command upstream
    const managementChain = [];
    if (employee.manager) {
      managementChain.push({
        id: employee.manager.id,
        firstName: employee.manager.firstName,
        lastName: employee.manager.lastName,
        jobTitle: employee.manager.jobTitle,
        level: 1,
      });

      if (employee.manager.manager) {
        managementChain.push({
          id: employee.manager.manager.id,
          firstName: employee.manager.manager.firstName,
          lastName: employee.manager.manager.lastName,
          jobTitle: employee.manager.manager.jobTitle,
          level: 2,
        });
      }
    }

    return {
      employee: {
        id: employee.id,
        employeeCode: employee.employeeCode,
        firstName: employee.firstName,
        lastName: employee.lastName,
        jobTitle: employee.jobTitle,
        department: employee.department,
        departmentRel: employee.departmentRel,
        position: employee.position,
      },
      managementChain,
      directReports: employee.directReports,
      totalDirectReports: employee.directReports.length,
    };
  }
}
