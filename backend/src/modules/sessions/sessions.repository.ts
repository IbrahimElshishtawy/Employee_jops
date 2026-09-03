import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { RegisterDeviceSessionDto } from "./dto";

@Injectable()
export class SessionsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async registerOrUpdateSession(userId: string, dto: RegisterDeviceSessionDto) {
    const existing = await this.prisma.userDeviceSession.findFirst({
      where: { userId, deviceId: dto.deviceId },
    });

    if (existing) {
      return this.prisma.userDeviceSession.update({
        where: { id: existing.id },
        data: {
          deviceName: dto.deviceName || existing.deviceName,
          deviceType: dto.deviceType || existing.deviceType,
          osVersion: dto.osVersion || existing.osVersion,
          appVersion: dto.appVersion || existing.appVersion,
          ipAddress: dto.ipAddress || existing.ipAddress,
          fcmToken: dto.fcmToken || existing.fcmToken,
          isActive: true,
          lastActiveAt: new Date(),
        },
      });
    }

    return this.prisma.userDeviceSession.create({
      data: {
        userId,
        deviceId: dto.deviceId,
        deviceName: dto.deviceName,
        deviceType: dto.deviceType || "MOBILE",
        osVersion: dto.osVersion,
        appVersion: dto.appVersion,
        ipAddress: dto.ipAddress,
        fcmToken: dto.fcmToken,
        isActive: true,
        lastActiveAt: new Date(),
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
