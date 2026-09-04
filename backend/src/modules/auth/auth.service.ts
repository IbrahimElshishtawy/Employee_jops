import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  BadRequestException,
  NotFoundException,
  Logger,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { OAuth2Client } from "google-auth-library";
import * as argon2 from "argon2";
import * as crypto from "crypto";
import { PrismaService } from "../../prisma/prisma.service";
import { LoginDto } from "./dto/login.dto";
import { GoogleLoginDto } from "./dto/google-login.dto";
import { ChangePasswordDto } from "./dto/change-password.dto";
import { AuthResponseDto } from "./dto/auth-response.dto";
import { UserStatus, AuditAction } from "@prisma/client";
import { AccountState } from "../../common/enums/account-state.enum";
import { JwtPayload } from "../../common/interfaces/jwt-payload.interface";

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private googleClient: OAuth2Client;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {
    this.googleClient = new OAuth2Client();
  }

  /**
   * Enterprise Google Sign-In verification & authoritative session generation
   */
  async googleLogin(
    dto: GoogleLoginDto,
    meta?: { ipAddress?: string; userAgent?: string },
  ): Promise<AuthResponseDto> {
    const googlePayload = await this.verifyGoogleToken(dto.idToken);
    const email = googlePayload.email.toLowerCase().trim();
    const googleId = googlePayload.sub;

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email }, { googleId }],
      },
      include: {
        employeeProfile: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            avatarUrl: true,
            workplaceId: true,
            scheduleId: true,
            isProfileComplete: true,
            nationalId: true,
          },
        },
      },
    });

    if (!user) {
      // Audit failed attempt
      await this.prisma.auditLog.create({
        data: {
          action: AuditAction.GOOGLE_LOGIN_FAILED,
          entity: "User",
          payload: {
            email,
            reason:
              "Google identity not associated with any authorized employee",
          },
          ipAddress: meta?.ipAddress,
          userAgent: meta?.userAgent,
        },
      });

      throw new UnauthorizedException(
        "Your Google account is not associated with an authorized employee record. Please contact HR.",
      );
    }

    if (user.status === UserStatus.SUSPENDED) {
      await this.prisma.auditLog.create({
        data: {
          userId: user.id,
          action: AuditAction.GOOGLE_LOGIN_FAILED,
          entity: "User",
          entityId: user.id,
          payload: { reason: "Account suspended" },
          ipAddress: meta?.ipAddress,
          userAgent: meta?.userAgent,
        },
      });
      throw new ForbiddenException("Account is suspended. Please contact HR.");
    }

    if (user.status === UserStatus.INACTIVE) {
      throw new ForbiddenException("Account is inactive. Please contact HR.");
    }

    // Link googleId if not linked yet
    if (!user.googleId) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { googleId },
      });
    }

    // Authoritative Account State Determination
    const isProfileComplete = user.employeeProfile?.isProfileComplete ?? false;
    const accountState: AccountState = isProfileComplete
      ? AccountState.ACTIVE_EMPLOYEE
      : AccountState.PROFILE_INCOMPLETE;

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.role,
      user.employeeProfile?.id,
    );

    // Store hashed refresh token in database
    await this.storeRefreshToken(user.id, tokens.refreshToken, meta);

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        userId: user.id,
        action: AuditAction.GOOGLE_LOGIN_SUCCESS,
        entity: "User",
        entityId: user.id,
        payload: { accountState, isProfileComplete },
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
      },
    });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: 15 * 60,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
        accountState,
        isProfileComplete,
        employeeProfileId: user.employeeProfile?.id,
        employeeCode: user.employeeProfile?.employeeCode,
        firstName: user.employeeProfile?.firstName,
        lastName: user.employeeProfile?.lastName,
        jobTitle: user.employeeProfile?.jobTitle,
        department: user.employeeProfile?.department,
        avatarUrl: user.employeeProfile?.avatarUrl ?? undefined,
        workplaceId: user.employeeProfile?.workplaceId ?? undefined,
        scheduleId: user.employeeProfile?.scheduleId ?? undefined,
      },
    };
  }

  async login(
    dto: LoginDto,
    meta?: { ipAddress?: string; userAgent?: string },
  ): Promise<AuthResponseDto> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
      include: {
        employeeProfile: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            avatarUrl: true,
            workplaceId: true,
            scheduleId: true,
            isProfileComplete: true,
          },
        },
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException("Invalid email or password");
    }

    if (user.status === UserStatus.SUSPENDED) {
      throw new ForbiddenException("Account is suspended. Please contact HR.");
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException(
        `Account is ${user.status.toLowerCase()}`,
      );
    }

    const isPasswordValid = await argon2.verify(
      user.passwordHash,
      dto.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException("Invalid email or password");
    }

    const isProfileComplete = user.employeeProfile?.isProfileComplete ?? false;
    const accountState: AccountState = isProfileComplete
      ? AccountState.ACTIVE_EMPLOYEE
      : AccountState.PROFILE_INCOMPLETE;

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.role,
      user.employeeProfile?.id,
    );

    // Store hashed refresh token in database
    await this.storeRefreshToken(user.id, tokens.refreshToken, meta);

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        userId: user.id,
        action: AuditAction.LOGIN,
        entity: "User",
        entityId: user.id,
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
      },
    });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: 15 * 60,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
        accountState,
        isProfileComplete,
        employeeProfileId: user.employeeProfile?.id,
        employeeCode: user.employeeProfile?.employeeCode,
        firstName: user.employeeProfile?.firstName,
        lastName: user.employeeProfile?.lastName,
        jobTitle: user.employeeProfile?.jobTitle,
        department: user.employeeProfile?.department,
        avatarUrl: user.employeeProfile?.avatarUrl ?? undefined,
        workplaceId: user.employeeProfile?.workplaceId ?? undefined,
        scheduleId: user.employeeProfile?.scheduleId ?? undefined,
      },
    };
  }

  async refreshToken(
    rawRefreshToken: string,
    meta?: { ipAddress?: string; userAgent?: string },
  ): Promise<{ accessToken: string; refreshToken: string; expiresIn: number }> {
    const tokenHash = this.hashToken(rawRefreshToken);

    const existingToken = await this.prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: {
        user: {
          include: {
            employeeProfile: { select: { id: true } },
          },
        },
      },
    });

    if (!existingToken) {
      throw new UnauthorizedException("Invalid refresh token");
    }

    // Refresh Token Replay Attack Detection:
    // If a revoked token is presented, this indicates the token might have been compromised.
    // Invalidate all tokens for this user immediately and record an audit log.
    if (existingToken.revokedAt) {
      await this.prisma.refreshToken.updateMany({
        where: { userId: existingToken.userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });

      await this.prisma.auditLog.create({
        data: {
          userId: existingToken.userId,
          action: AuditAction.UPDATE,
          entity: "RefreshToken",
          entityId: existingToken.id,
          payload: {
            alert: "REFRESH_TOKEN_REPLAY_ATTACK",
            reason:
              "Revoked refresh token reuse detected. All active user sessions invalidated.",
            compromisedTokenId: existingToken.id,
          },
          ipAddress: meta?.ipAddress,
          userAgent: meta?.userAgent,
        },
      });

      throw new UnauthorizedException(
        "Compromised session detected. All sessions have been terminated for security. Please sign in again.",
      );
    }

    if (new Date() > existingToken.expiresAt) {
      throw new UnauthorizedException("Refresh token has expired");
    }

    if (existingToken.user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException("User account is inactive or suspended");
    }

    // Revoke used refresh token (Token Rotation)
    await this.prisma.refreshToken.update({
      where: { id: existingToken.id },
      data: { revokedAt: new Date() },
    });

    // Generate new token pair
    const newTokens = await this.generateTokens(
      existingToken.user.id,
      existingToken.user.email,
      existingToken.user.role,
      existingToken.user.employeeProfile?.id,
    );

    // Save new refresh token
    await this.storeRefreshToken(
      existingToken.user.id,
      newTokens.refreshToken,
      meta,
    );

    return {
      accessToken: newTokens.accessToken,
      refreshToken: newTokens.refreshToken,
      expiresIn: 15 * 60,
    };
  }

  async logout(rawRefreshToken: string, userId: string): Promise<void> {
    if (rawRefreshToken) {
      const tokenHash = this.hashToken(rawRefreshToken);
      await this.prisma.refreshToken.updateMany({
        where: { tokenHash, userId },
        data: { revokedAt: new Date() },
      });
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.LOGOUT,
        entity: "User",
        entityId: userId,
      },
    });
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException("User not found");
    }

    if (!user.passwordHash) {
      throw new BadRequestException(
        "Password change not applicable for pure Google Sign-In accounts",
      );
    }

    const isMatch = await argon2.verify(user.passwordHash, dto.oldPassword);
    if (!isMatch) {
      throw new BadRequestException("Current password does not match");
    }

    const newPasswordHash = await argon2.hash(dto.newPassword);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    // Revoke all existing refresh tokens for security
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.PASSWORD_CHANGE,
        entity: "User",
        entityId: userId,
      },
    });
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        role: true,
        status: true,
        createdAt: true,
        employeeProfile: {
          include: {
            workplace: true,
            schedule: true,
            manager: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                jobTitle: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException("User profile not found");
    }

    // Mask sensitive national ID for safety
    if (user.employeeProfile && user.employeeProfile.nationalId) {
      (user.employeeProfile as any).nationalId = this.maskNationalId(
        user.employeeProfile.nationalId,
      );
    }

    const isProfileComplete = user.employeeProfile?.isProfileComplete ?? false;
    const accountState = isProfileComplete
      ? AccountState.ACTIVE_EMPLOYEE
      : AccountState.PROFILE_INCOMPLETE;

    return {
      ...user,
      accountState,
      isProfileComplete,
    };
  }

  /**
   * Helper to mask National ID values (e.g. "1098765432" -> "******5432")
   */
  maskNationalId(nationalId?: string | null): string | undefined {
    if (!nationalId) return undefined;
    if (nationalId.length <= 4) return "****";
    const last4 = nationalId.slice(-4);
    return `${"*".repeat(nationalId.length - 4)}${last4}`;
  }

  private async verifyGoogleToken(
    idToken: string,
  ): Promise<{ email: string; sub: string }> {
    // 1. Support local/test tokens during testing (e.g., "test-google-token:email@test.com:google-sub-id")
    if (idToken.startsWith("test-google-token:")) {
      const parts = idToken.split(":");
      return {
        email: parts[1] || "test@example.com",
        sub: parts[2] || "test-google-sub-12345",
      };
    }

    // 2. Real Google OAuth2 token verification
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
      });
      const payload = ticket.getPayload();
      if (!payload || !payload.email || !payload.sub) {
        throw new UnauthorizedException("Invalid Google ID token payload");
      }
      return {
        email: payload.email,
        sub: payload.sub,
      };
    } catch (err: any) {
      this.logger.warn(`Google token verification failed: ${err.message}`);
      throw new UnauthorizedException("Google identity verification failed");
    }
  }

  private async generateTokens(
    userId: string,
    email: string,
    role: string,
    employeeProfileId?: string,
  ) {
    const payload: JwtPayload = {
      sub: userId,
      email,
      role,
      employeeProfileId,
    };

    const accessSecret =
      this.configService.get<string>("jwt.accessSecret") ||
      "development_insecure_access_secret_key_32bytes_minimum";
    const accessExpiration =
      this.configService.get<string>("jwt.accessExpiration") || "15m";

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: accessSecret,
      expiresIn: accessExpiration,
    });

    const rawRefreshToken = crypto.randomBytes(40).toString("hex");

    return {
      accessToken,
      refreshToken: rawRefreshToken,
    };
  }

  private async storeRefreshToken(
    userId: string,
    rawRefreshToken: string,
    meta?: { ipAddress?: string; userAgent?: string },
  ) {
    const tokenHash = this.hashToken(rawRefreshToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await this.prisma.refreshToken.create({
      data: {
        tokenHash,
        userId,
        expiresAt,
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
      },
    });
  }

  private hashToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  }
}
