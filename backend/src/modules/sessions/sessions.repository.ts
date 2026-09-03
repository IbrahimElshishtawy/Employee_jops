import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { RegisterDeviceSessionDto } from "./dto";
import { DevicePlatform } from "@prisma/client";

@Injectable()
export class SessionsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async registerOrUpdateSession(userId: string, dto: RegisterDeviceSessionDto) {
    const existing = await this.prisma.userDeviceSession.findUnique({
      where: { sessionToken: dto.sessionToken },
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30-day session expiry

    if (existing) {
      return this.prisma.userDeviceSession.update({
        where: { id: existing.id },
        data: {
          devicePlatform: dto.devicePlatform || existing.devicePlatform,
          deviceModel: dto.deviceModel || existing.deviceModel,
          osVersion: dto.osVersion || existing.osVersion,
          appVersion: dto.appVersion || existing.appVersion,
          ipAddress: dto.ipAddress || existing.ipAddress,
          userAgent: dto.userAgent || existing.userAgent,
          isActive: true,
          lastActiveAt: new Date(),
          expiresAt,
        },
      });
    }

    return this.prisma.userDeviceSession.create({
      data: {
        userId,
        sessionToken: dto.sessionToken,
        devicePlatform: dto.devicePlatform || DevicePlatform.ANDROID,
        deviceModel: dto.deviceModel,
        osVersion: dto.osVersion,
        appVersion: dto.appVersion,
        ipAddress: dto.ipAddress,
        userAgent: dto.userAgent,
        isActive: true,
        lastActiveAt: new Date(),
        expiresAt,
      },
    });
  }

  async findActiveSessionsByUser(userId: string) {
    return this.prisma.userDeviceSession.findMany({
      where: { userId, isActive: true },
      orderBy: { lastActiveAt: "desc" },
    });
  }

  async findSessionById(id: string) {
    return this.prisma.userDeviceSession.findUnique({
      where: { id },
    });
  }

  async terminateSession(id: string) {
    return this.prisma.userDeviceSession.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async terminateAllOtherSessions(currentSessionId: string, userId: string) {
    return this.prisma.userDeviceSession.updateMany({
      where: {
        userId,
        id: { not: currentSessionId },
        isActive: true,
      },
      data: { isActive: false },
    });
  }
}
