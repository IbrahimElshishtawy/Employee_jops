import {
  Injectable,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreatePermissionDto, QueryPermissionsDto } from "./dto";
import { AuditAction, Prisma } from "@prisma/client";

@Injectable()
export class PermissionsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreatePermissionDto, creatorUserId?: string) {
    const existing = await this.prisma.permission.findUnique({
      where: { slug: dto.slug },
    });

    if (existing) {
      throw new ConflictException(
        `Permission with slug '${dto.slug}' already exists`,
      );
    }

    const permission = await this.prisma.permission.create({
      data: {
        slug: dto.slug,
        action: dto.action,
        subject: dto.subject,
        description: dto.description,
        module: dto.module,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.PERMISSION_CREATED,
        entity: "Permission",
        entityId: permission.id,
        payload: { slug: permission.slug, module: permission.module },
      },
    });

    return permission;
  }

  async findAll(query: QueryPermissionsDto) {
    const { skip, limit, search, module, action, subject } = query;

    const where: Prisma.PermissionWhereInput = {
      ...(module ? { module } : {}),
      ...(action ? { action } : {}),
      ...(subject ? { subject } : {}),
      ...(search
        ? {
            OR: [
              { slug: { contains: search, mode: "insensitive" } },
              { description: { contains: search, mode: "insensitive" } },
              { module: { contains: search, mode: "insensitive" } },
            ],
          }
        : {}),
    };

    const [total, data] = await Promise.all([
      this.prisma.permission.count({ where }),
      this.prisma.permission.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ module: "asc" }, { slug: "asc" }],
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
    const permission = await this.prisma.permission.findFirst({
      where: {
        OR: [{ id }, { slug: id }],
      },
    });

    if (!permission) {
      throw new NotFoundException(`Permission '${id}' not found`);
    }

    return permission;
  }

  /**
   * Returns all system permissions cataloged and grouped by module
   */
  async getGroupedByModule() {
    const permissions = await this.prisma.permission.findMany({
      orderBy: [{ module: "asc" }, { slug: "asc" }],
    });

    const grouped: Record<string, typeof permissions> = {};

    for (const perm of permissions) {
      if (!grouped[perm.module]) {
        grouped[perm.module] = [];
      }
      grouped[perm.module].push(perm);
    }

    return grouped;
  }
}
