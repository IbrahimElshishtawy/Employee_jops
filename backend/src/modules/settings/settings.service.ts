import {
  Injectable,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../../common/redis/redis.service";
import {
  SetSystemSettingDto,
  QuerySettingsDto,
  CreateFeatureFlagDto,
  UpdateFeatureFlagDto,
} from "./dto";
import { AuditAction, Prisma } from "@prisma/client";

@Injectable()
export class SettingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  // ==========================================
  // 1. SYSTEM SETTINGS
  // ==========================================

  /**
   * Type-safe setting getter with Redis caching
   */
  async getSetting<T = any>(key: string, defaultValue?: T): Promise<T> {
    const cacheKey = `setting:${key}`;
    const cached = await this.redis.get(cacheKey);

    if (cached !== null) {
      try {
        return JSON.parse(cached) as T;
      } catch {
        return cached as unknown as T;
      }
    }

    const setting = await this.prisma.systemSetting.findUnique({
      where: { key },
    });

    if (!setting) {
      return defaultValue as T;
    }

    await this.redis.set(cacheKey, JSON.stringify(setting.value), 300);

    return setting.value as T;
  }

  /**
   * Set or update a system setting (Upsert with cache invalidation)
   */
  async setSetting(dto: SetSystemSettingDto, updaterUserId?: string) {
    const setting = await this.prisma.systemSetting.upsert({
      where: { key: dto.key },
      update: {
        value: dto.value,
        category: dto.category,
        isPublic: dto.isPublic,
        description: dto.description,
        organizationId: dto.organizationId,
      },
      create: {
        key: dto.key,
        value: dto.value,
        category: dto.category,
        isPublic: dto.isPublic ?? false,
        description: dto.description,
        organizationId: dto.organizationId,
      },
    });

    // Invalidate setting cache
    await this.redis.del(`setting:${dto.key}`);

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.SETTING_UPDATED,
        entity: "SystemSetting",
        entityId: setting.id,
        payload: { key: setting.key, value: setting.value },
      },
    });

    return setting;
  }

  async getAllSettings(query: QuerySettingsDto) {
    const { skip, limit, search, category, organizationId } = query;

    const where: Prisma.SystemSettingWhereInput = {
      ...(category ? { category } : {}),
      ...(organizationId ? { organizationId } : {}),
      ...(search
        ? {
            OR: [
              { key: { contains: search, mode: "insensitive" } },
              { description: { contains: search, mode: "insensitive" } },
            ],
          }
        : {}),
    };

    const [total, data] = await Promise.all([
      this.prisma.systemSetting.count({ where }),
      this.prisma.systemSetting.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ category: "asc" }, { key: "asc" }],
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

  /**
   * Returns all public settings for initial app configuration
   */
  async getPublicSettings() {
    const settings = await this.prisma.systemSetting.findMany({
      where: { isPublic: true },
      select: {
        key: true,
        value: true,
        category: true,
      },
    });

    const mapped: Record<string, any> = {};
    for (const s of settings) {
      mapped[s.key] = s.value;
    }

    return mapped;
  }

  async deleteSetting(key: string, deleterUserId?: string) {
    const setting = await this.prisma.systemSetting.findUnique({
      where: { key },
    });

    if (!setting) {
      throw new NotFoundException(`Setting '${key}' not found`);
    }

    await this.prisma.systemSetting.delete({ where: { key } });
    await this.redis.del(`setting:${key}`);

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.SETTING_DELETED,
        entity: "SystemSetting",
        entityId: setting.id,
        payload: { key },
      },
    });

    return { message: `Setting '${key}' deleted successfully` };
  }

  // ==========================================
  // 2. FEATURE FLAGS
  // ==========================================

  async createFeatureFlag(dto: CreateFeatureFlagDto, creatorUserId?: string) {
    const existing = await this.prisma.featureFlag.findUnique({
      where: { key: dto.key },
    });

    if (existing) {
      throw new ConflictException(
        `Feature flag '${dto.key}' already exists`,
      );
    }

    const flag = await this.prisma.featureFlag.create({
      data: {
        key: dto.key,
        isEnabled: dto.isEnabled,
        description: dto.description,
        rolloutPercentage: dto.rolloutPercentage ?? 100,
        rules: dto.rules,
        organizationId: dto.organizationId,
      },
    });

    await this.redis.set(`feature_flag:${dto.key}`, String(dto.isEnabled), 60);

    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.FEATURE_FLAG_CREATED,
        entity: "FeatureFlag",
        entityId: flag.id,
        payload: { key: flag.key, isEnabled: flag.isEnabled },
      },
    });

    return flag;
  }

  async updateFeatureFlag(
    key: string,
    dto: UpdateFeatureFlagDto,
    updaterUserId?: string,
  ) {
    const flag = await this.prisma.featureFlag.findUnique({ where: { key } });
    if (!flag) {
      throw new NotFoundException(`Feature flag '${key}' not found`);
    }

    const updated = await this.prisma.featureFlag.update({
      where: { key },
      data: {
        isEnabled: dto.isEnabled,
        description: dto.description,
        rolloutPercentage: dto.rolloutPercentage,
        rules: dto.rules,
      },
    });

    // Invalidate / update Redis cache
    if (dto.isEnabled !== undefined) {
      await this.redis.set(
        `feature_flag:${key}`,
        String(updated.isEnabled),
        60,
      );
    }

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.FEATURE_FLAG_UPDATED,
        entity: "FeatureFlag",
        entityId: updated.id,
        payload: { key, isEnabled: updated.isEnabled },
      },
    });

    return updated;
  }

  async getFeatureFlags(organizationId?: string) {
    return this.prisma.featureFlag.findMany({
      where: organizationId ? { organizationId } : {},
      orderBy: { key: "asc" },
    });
  }

  /**
   * Fast evaluation of feature flag
   */
  async isFeatureEnabled(key: string): Promise<boolean> {
    const cacheKey = `feature_flag:${key}`;
    const cached = await this.redis.get(cacheKey);

    if (cached !== null) {
      return cached === "true";
    }

    const flag = await this.prisma.featureFlag.findUnique({
      where: { key },
    });

    const isEnabled = flag?.isEnabled ?? false;
    await this.redis.set(cacheKey, String(isEnabled), 60);

    return isEnabled;
  }
}
