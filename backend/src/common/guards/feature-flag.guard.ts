import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { FEATURE_FLAG_KEY } from "../decorators/feature-flag.decorator";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../redis/redis.service";

@Injectable()
export class FeatureFlagGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const flagKey = this.reflector.getAllAndOverride<string>(FEATURE_FLAG_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!flagKey) {
      return true;
    }

    const isEnabled = await this.checkFeatureFlag(flagKey);

    if (!isEnabled) {
      throw new ForbiddenException(
        `Feature '${flagKey}' is currently disabled by system configuration`,
      );
    }

    return true;
  }

  private async checkFeatureFlag(flagKey: string): Promise<boolean> {
    const cacheKey = `feature_flag:${flagKey}`;
    const cached = await this.redis.get(cacheKey);

    if (cached !== null) {
      return cached === "true";
    }

    const flag = await this.prisma.featureFlag.findUnique({
      where: { key: flagKey },
    });

    const isEnabled = flag?.isEnabled ?? false;

    // Cache flag state for 60 seconds
    await this.redis.set(cacheKey, String(isEnabled), 60);

    return isEnabled;
  }
}
