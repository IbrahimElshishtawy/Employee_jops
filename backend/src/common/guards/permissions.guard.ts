import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { Role } from "@prisma/client";
import { PERMISSIONS_KEY } from "../decorators/permissions.decorator";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../redis/redis.service";

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest();
    if (!user || !user.id) {
      throw new ForbiddenException(
        "Access denied: User not authenticated or identity missing",
      );
    }

    // SUPER_ADMIN bypasses all granular permission checks
    if (user.role === Role.SUPER_ADMIN) {
      return true;
    }

    const userPermissions = await this.getUserPermissions(user.id);

    const hasAll = requiredPermissions.every((perm) =>
      userPermissions.includes(perm),
    );

    if (!hasAll) {
      throw new ForbiddenException(
        `Access denied: Missing required permission(s) [${requiredPermissions.join(", ")}]`,
      );
    }

    return true;
  }

  /**
   * Resolves aggregated permissions for a user with Redis caching (5-minute TTL)
   */
  async getUserPermissions(userId: string): Promise<string[]> {
    const cacheKey = `user:permissions:${userId}`;
    const cached = await this.redis.get(cacheKey);

    if (cached) {
      try {
        return JSON.parse(cached);
      } catch {
        // Fallback to DB
      }
    }

    // Query DB for user roles and their associated permissions
    const userWithRoles = await this.prisma.user.findUnique({
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

    const permissionsSet = new Set<string>();

    if (userWithRoles?.userRoles) {
      for (const userRole of userWithRoles.userRoles) {
        if (userRole.role.isActive) {
          for (const rp of userRole.role.rolePermissions) {
            if (rp.permission?.slug) {
              permissionsSet.add(rp.permission.slug);
            }
          }
        }
      }
    }

    const permissions = Array.from(permissionsSet);

    // Cache permissions for 300 seconds (5 minutes)
    await this.redis.set(cacheKey, JSON.stringify(permissions), 300);

    return permissions;
  }
}
