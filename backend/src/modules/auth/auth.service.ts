import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { UserStatus, AuditAction } from '@prisma/client';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

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
          },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException(`Account is ${user.status.toLowerCase()}`);
    }

    const isPasswordValid = await argon2.verify(user.passwordHash, dto.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

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
        entity: 'User',
        entityId: user.id,
        ipAddress: meta?.ipAddress,
        userAgent: meta?.userAgent,
      },
    });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresIn: 15 * 60, // 15 mins
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
        employeeProfileId: user.employeeProfile?.id,
        employeeCode: user.employeeProfile?.employeeCode,
        firstName: user.employeeProfile?.firstName,
        lastName: user.employeeProfile?.lastName,
        jobTitle: user.employeeProfile?.jobTitle,
        department: user.employeeProfile?.department,
        avatarUrl: user.employeeProfile?.avatarUrl,
        workplaceId: user.employeeProfile?.workplaceId,
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

    if (!existingToken || existingToken.revokedAt) {
      throw new UnauthorizedException('Invalid or revoked refresh token');
    }

    if (new Date() > existingToken.expiresAt) {
      throw new UnauthorizedException('Refresh token has expired');
    }

    if (existingToken.user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('User account is inactive');
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
    await this.storeRefreshToken(existingToken.user.id, newTokens.refreshToken, meta);

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
        entity: 'User',
        entityId: userId,
      },
    });
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isMatch = await argon2.verify(user.passwordHash, dto.oldPassword);
    if (!isMatch) {
      throw new BadRequestException('Current password does not match');
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
        entity: 'User',
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
      throw new NotFoundException('User profile not found');
    }

    return user;
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

    const accessSecret = this.configService.get<string>('jwt.accessSecret') || 'default_secret';
    const accessExpiration = this.configService.get<string>('jwt.accessExpiration') || '15m';

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: accessSecret,
      expiresIn: accessExpiration,
    });

    const rawRefreshToken = crypto.randomBytes(40).toString('hex');

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
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
