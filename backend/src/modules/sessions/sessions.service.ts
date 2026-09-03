import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { SessionsRepository } from "./sessions.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { RegisterDeviceSessionDto } from "./dto";
import { AuditAction } from "@prisma/client";

@Injectable()
export class SessionsService {
  private readonly logger = new Logger(SessionsService.name);

  constructor(
    private readonly repo: SessionsRepository,
    private readonly prisma: PrismaService,
  ) {}

  async registerDeviceSession(userId: string, dto: RegisterDeviceSessionDto) {
    const session = await this.repo.registerOrUpdateSession(userId, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "UserDeviceSession",
        entityId: session.id,
        payload: { deviceId: dto.deviceId, deviceName: dto.deviceName },
      },
    });

    return session;
  }

  async getMyActiveSessions(userId: string) {
    return this.repo.findActiveSessionsByUser(userId);
  }

  async terminateSession(userId: string, sessionId: string) {
    const session = await this.repo.findSessionById(sessionId);
    if (!session) throw new NotFoundException(`Session '${sessionId}' not found`);

    if (session.userId !== userId) {
      throw new ForbiddenException("Cannot terminate session belonging to another user");
    }

    const updated = await this.repo.terminateSession(sessionId);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.DELETE,
        entity: "UserDeviceSession",
        entityId: sessionId,
        payload: { deviceId: session.deviceId },
      },
    });

    return updated;
  }

  async terminateAllOtherSessions(userId: string, currentSessionId: string) {
    const result = await this.repo.terminateAllOtherSessions(currentSessionId, userId);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.DELETE,
        entity: "UserDeviceSession",
        entityId: currentSessionId,
        payload: { message: "Terminated all other sessions", count: result.count },
      },
    });

    return result;
  }
}
