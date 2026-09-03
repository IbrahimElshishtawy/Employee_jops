import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { KeysRepository } from "./keys.repository";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateKeyDto,
  QueryKeysDto,
  AssignKeyDto,
  ReturnKeyDto,
  LogKeyAccessDto,
} from "./dto";
import { AuditAction, KeyAssignmentStatus } from "@prisma/client";

@Injectable()
export class KeysService {
  private readonly logger = new Logger(KeysService.name);

  constructor(
    private readonly repo: KeysRepository,
    private readonly prisma: PrismaService,
  ) {}

  async createKey(userId: string, dto: CreateKeyDto) {
    const existing = await this.repo.findKeyByCode(dto.keyCode);
    if (existing) {
      throw new ConflictException(`Key with code '${dto.keyCode}' already exists`);
    }

    const key = await this.repo.createKey(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "PhysicalKey",
        entityId: key.id,
        payload: { keyCode: key.keyCode, name: key.name, keyType: key.keyType },
      },
    });

    return key;
  }

  async findKeys(query: QueryKeysDto) {
    return this.repo.findKeys(query);
  }

  async findKeyById(id: string) {
    const key = await this.repo.findKeyById(id);
    if (!key) {
      throw new NotFoundException(`Physical key '${id}' not found`);
    }
    return key;
  }

  async assignKey(keyId: string, userId: string, dto: AssignKeyDto) {
    const key = await this.findKeyById(keyId);

    if (key.availableCopies <= 0) {
      throw new BadRequestException(
        `No available copies left for key '${key.keyCode}' (${key.name})`,
      );
    }

    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
    });
    if (!employee) {
      throw new NotFoundException(`Employee profile '${dto.employeeId}' not found`);
    }

    const assignment = await this.repo.assignKey(keyId, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "KeyAssignment",
        entityId: assignment.id,
        payload: {
          keyId,
          keyCode: key.keyCode,
          employeeId: dto.employeeId,
          assignedAt: assignment.assignedAt,
        },
      },
    });

    return assignment;
  }

  async returnKey(assignmentId: string, userId: string, dto: ReturnKeyDto) {
    const assignment = await this.repo.findAssignmentById(assignmentId);
    if (!assignment) {
      throw new NotFoundException(`Key assignment '${assignmentId}' not found`);
    }

    if (assignment.status !== KeyAssignmentStatus.ACTIVE) {
      throw new BadRequestException(
        `Assignment '${assignmentId}' is already ${assignment.status}`,
      );
    }

    const result = await this.repo.returnKey(assignmentId, assignment.keyId, dto.notes);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "KeyAssignment",
        entityId: assignmentId,
        payload: {
          keyId: assignment.keyId,
          status: KeyAssignmentStatus.RETURNED,
          returnedAt: result.returnedAt,
        },
      },
    });

    return result;
  }

  async logAccess(keyId: string, userId: string, dto: LogKeyAccessDto) {
    await this.findKeyById(keyId);

    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
    });
    if (!employee) {
      throw new NotFoundException(`Employee profile '${dto.employeeId}' not found`);
    }

    return this.repo.logAccess(keyId, dto);
  }
}
