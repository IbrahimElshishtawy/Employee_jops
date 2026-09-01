import {
  Injectable,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../../common/redis/redis.service";
import {
  CreateRoleDto,
  UpdateRoleDto,
  SyncRolePermissionsDto,
  AssignUserRolesDto,
} from "./dto";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";
import { AuditAction, Prisma } from "@prisma/client";

@Injectable()
export class RolesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async create(dto: CreateRoleDto, creatorUserId?: string) {
    const existing = await this.prisma.roleRecord.findUnique({
      where: { slug: dto.slug.toLowerCase().trim() },
    });

    if (existing) {
      throw new ConflictException(
        `Role with slug '${dto.slug}' already exists`,
      );
    }

    // Resolve permissions if slugs provided
    let permissionConnects: { permissionId: string }[] = [];
    if (dto.permissionSlugs && dto.permissionSlugs.length > 0) {
      const foundPermissions = await this.prisma.permission.findMany({
        where: {
          OR: [
            { slug: { in: dto.permissionSlugs } },
            { id: { in: dto.permissionSlugs } },
          ],
        },
        select: { id: true },
      });
      permissionConnects = foundPermissions.map((p) => ({
        permissionId: p.id,
      }));
    }

    const role = await this.prisma.roleRecord.create({
      data: {
        name: dto.name,
        slug: dto.slug.toLowerCase().trim(),
        description: dto.description,
        organizationId: dto.organizationId,
        isSystem: false,
        rolePermissions: {
          create: permissionConnects,
        },
      },
      include: {
        rolePermissions: {
          include: {
            permission: true,
          },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.ROLE_CREATED,
        entity: "RoleRecord",
        entityId: role.id,
        payload: { name: role.name, slug: role.slug },
      },
    });

    return role;
  }

  async findAll(query: PaginationQueryDto) {
    const { skip, limit, search } = query;

    const where: Prisma.RoleRecordWhereInput = search
      ? {
          OR: [
            { name: { contains: search, mode: "insensitive" } },
            { slug: { contains: search, mode: "insensitive" } },
            { description: { contains: search, mode: "insensitive" } },
          ],
        }
      : {};

    const [total, data] = await Promise.all([
      this.prisma.roleRecord.count({ where }),
      this.prisma.roleRecord.findMany({
        where,
        skip,
        take: limit,
        include: {
          rolePermissions: {
            include: {
              permission: true,
            },
          },
          _count: {
            select: {
              userRoles: true,
            },
          },
        },
        orderBy: [{ isSystem: "desc" }, { name: "asc" }],
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

  async findOne(id: string) {
    const role = await this.prisma.roleRecord.findFirst({
      where: {
        OR: [{ id }, { slug: id }],
      },
      include: {
        rolePermissions: {
          include: {
            permission: true,
          },
        },
        userRoles: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                role: true,
                employeeProfile: {
                  select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    employeeCode: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!role) {
      throw new NotFoundException(`Role '${id}' not found`);
    }

    return role;
  }

  async update(id: string, dto: UpdateRoleDto, updaterUserId?: string) {
    const role = await this.findOne(id);

    const updated = await this.prisma.roleRecord.update({
      where: { id: role.id },
      data: {
        name: dto.name,
        description: dto.description,
        isActive: dto.isActive,
      },
      include: {
        rolePermissions: {
          include: {
            permission: true,
          },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.ROLE_UPDATED,
        entity: "RoleRecord",
        entityId: updated.id,
      },
    });

    return updated;
  }

  async remove(id: string, deleterUserId?: string) {
    const role = await this.findOne(id);

    if (role.isSystem) {
      throw new BadRequestException(
        `System role '${role.slug}' cannot be deleted as it is critical to system integrity`,
      );
    }

    // Invalidate cache for users assigned to this role
    for (const ur of role.userRoles) {
      await this.invalidateUserPermissionsCache(ur.userId);
    }

    await this.prisma.roleRecord.delete({
      where: { id: role.id },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.ROLE_DELETED,
        entity: "RoleRecord",
        entityId: role.id,
        payload: { slug: role.slug },
      },
    });

    return { message: `Role '${role.name}' deleted successfully` };
  }

  /**
   * Syncs the complete permission set for a role (atomic replacement)
   */
  async syncRolePermissions(
    roleId: string,
    dto: SyncRolePermissionsDto,
    updaterUserId?: string,
  ) {
    const role = await this.findOne(roleId);

    // Resolve target permission records
    const permissions = await this.prisma.permission.findMany({
      where: {
        OR: [
          { slug: { in: dto.permissionSlugs } },
          { id: { in: dto.permissionSlugs } },
        ],
      },
      select: { id: true, slug: true },
    });

    // Execute atomic role-permission sync in a transaction
    await this.prisma.$transaction(async (tx) => {
      await tx.rolePermission.deleteMany({
        where: { roleId: role.id },
      });

      if (permissions.length > 0) {
        await tx.rolePermission.createMany({
          data: permissions.map((p) => ({
            roleId: role.id,
            permissionId: p.id,
          })),
        });
      }
    });

    // Invalidate Redis cache for all users holding this role
    const assignedUsers = await this.prisma.userRole.findMany({
      where: { roleId: role.id },
      select: { userId: true },
    });

    for (const u of assignedUsers) {
      await this.invalidateUserPermissionsCache(u.userId);
    }

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.ROLE_PERMISSIONS_SYNCED,
        entity: "RoleRecord",
        entityId: role.id,
        payload: {
          roleSlug: role.slug,
          permissionCount: permissions.length,
          permissions: permissions.map((p) => p.slug),
        },
      },
    });

    return this.findOne(role.id);
  }

  /**
   * Assigns roles to a user
   */
  async assignRolesToUser(dto: AssignUserRolesDto, assignerUserId?: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: dto.userId },
    });

    if (!user) {
      throw new NotFoundException(`User '${dto.userId}' not found`);
    }

    const roles = await this.prisma.roleRecord.findMany({
      where: {
        OR: [{ slug: { in: dto.roleSlugs } }, { id: { in: dto.roleSlugs } }],
      },
      select: { id: true, slug: true },
    });

    if (roles.length === 0 && dto.roleSlugs.length > 0) {
      throw new BadRequestException("None of the specified roles were found");
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.userRole.deleteMany({
        where: { userId: user.id },
      });

      if (roles.length > 0) {
        await tx.userRole.createMany({
          data: roles.map((r) => ({
            userId: user.id,
            roleId: r.id,
            assignedById: assignerUserId,
          })),
        });
      }
    });

    await this.invalidateUserPermissionsCache(user.id);

    await this.prisma.auditLog.create({
      data: {
        userId: assignerUserId,
        action: AuditAction.ROLE_ASSIGNED,
        entity: "UserRole",
        entityId: user.id,
        payload: {
          targetUserId: user.id,
          assignedRoles: roles.map((r) => r.slug),
        },
      },
    });

    return this.getUserRolesAndPermissions(user.id);
  }

  /**
   * Gets a user's assigned roles and aggregated permissions
   */
  async getUserRolesAndPermissions(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException(`User '${userId}' not found`);
    }

    const roles = user.userRoles.map((ur) => ({
      id: ur.role.id,
      name: ur.role.name,
      slug: ur.role.slug,
      isSystem: ur.role.isSystem,
      assignedAt: ur.assignedAt,
    }));

    const permissionsSet = new Set<string>();
    for (const ur of user.userRoles) {
      if (ur.role.isActive) {
        for (const rp of ur.role.rolePermissions) {
          if (rp.permission?.slug) {
            permissionsSet.add(rp.permission.slug);
          }
        }
      }
    }

    return {
      userId: user.id,
      email: user.email,
      systemRole: user.role,
      roles,
      permissions: Array.from(permissionsSet),
    };
  }

  private async invalidateUserPermissionsCache(userId: string) {
    const cacheKey = `user:permissions:${userId}`;
    await this.redis.del(cacheKey);
  }
}
