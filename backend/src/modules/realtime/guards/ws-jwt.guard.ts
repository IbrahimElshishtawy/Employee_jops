import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  Logger,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { Socket } from "socket.io";
import { PrismaService } from "../../../prisma/prisma.service";
import { UserStatus } from "@prisma/client";

@Injectable()
export class WsJwtGuard implements CanActivate {
  private readonly logger = new Logger(WsJwtGuard.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const client: Socket = context.switchToWs().getClient<Socket>();
      const user = await this.authenticateSocket(client);
      client.data.user = user;
      return true;
    } catch (err: any) {
      this.logger.warn(`[WsJwtGuard] Authentication failed: ${err.message}`);
      throw new UnauthorizedException(
        err.message || "Unauthorized WebSocket access",
      );
    }
  }

  /**
   * Helper method that authenticates a socket directly during connection handshake.
   */
  async authenticateSocket(client: Socket): Promise<any> {
    const token = this.extractToken(client);
    if (!token) {
      throw new UnauthorizedException(
        "Missing authentication token in handshake",
      );
    }

    const secret =
      this.configService.get<string>("jwt.accessSecret") ||
      process.env.JWT_ACCESS_SECRET ||
      "development_insecure_access_secret_key_32bytes_minimum";

    let payload: any;
    try {
      payload = await this.jwtService.verifyAsync(token, { secret });
    } catch (jwtErr: any) {
      throw new UnauthorizedException(
        `Invalid or expired token: ${jwtErr.message}`,
      );
    }

    if (!payload || !payload.sub) {
      throw new UnauthorizedException("Malformed token payload");
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        role: true,
        status: true,
        employeeProfile: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            departmentId: true,
          },
        },
      },
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
      departmentId: user.employeeProfile?.departmentId,
      name: user.employeeProfile
        ? `${user.employeeProfile.firstName} ${user.employeeProfile.lastName}`
        : user.email,
    };
  }

  private extractToken(client: Socket): string | null {
    // 1. Handshake auth object (standard Socket.io v4 client: { auth: { token: '...' } })
    if (client.handshake?.auth?.token) {
      return this.cleanBearerToken(client.handshake.auth.token);
    }

    // 2. Handshake headers (Authorization: Bearer <token>)
    const authHeader = client.handshake?.headers?.authorization;
    if (authHeader && typeof authHeader === "string") {
      return this.cleanBearerToken(authHeader);
    }

    // 3. Query param (?token=<token>)
    const queryToken = client.handshake?.query?.token;
    if (queryToken && typeof queryToken === "string") {
      return this.cleanBearerToken(queryToken);
    }

    return null;
  }

  private cleanBearerToken(rawToken: string): string {
    return rawToken.startsWith("Bearer ")
      ? rawToken.slice(7).trim()
      : rawToken.trim();
  }
}
