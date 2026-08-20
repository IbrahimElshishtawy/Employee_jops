import { Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PassportStrategy } from "@nestjs/passport";
import { ExtractJwt, Strategy } from "passport-jwt";
import { PrismaService } from "../../../prisma/prisma.service";
import { JwtPayload } from "../../../common/interfaces/jwt-payload.interface";
import { CurrentUser } from "../../../common/interfaces/current-user.interface";
import { UserStatus } from "@prisma/client";

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, "jwt") {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        configService.get<string>("jwt.accessSecret") || "default_secret",
    });
  }

  async validate(payload: JwtPayload): Promise<CurrentUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { employeeProfile: { select: { id: true } } },
    });

    if (!user) {
      throw new UnauthorizedException("User account no longer exists");
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException(
        `User account is ${user.status.toLowerCase()}`,
      );
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      employeeProfileId: user.employeeProfile?.id,
    };
  }
}
