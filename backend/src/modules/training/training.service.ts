import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { TrainingRepository } from "./training.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateTrainingCourseDto,
  CreateTrainingSessionDto,
  EnrollEmployeeDto,
  UpdateEnrollmentDto,
  IssueCertificateDto,
  QueryTrainingCoursesDto,
  QueryTrainingSessionsDto,
} from "./dto";
import {
  AuditAction,
  EnrollmentStatus,
  NotificationType,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class TrainingService {
  private readonly logger = new Logger(TrainingService.name);

  constructor(
    private readonly repo: TrainingRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // COURSES
  // ============================================================

  async createCourse(userId: string, dto: CreateTrainingCourseDto) {
    const existing = await this.repo.findCourseByCode(dto.code);
    if (existing) {
      throw new ConflictException(
        `Course with code '${dto.code}' already exists`,
      );
    }

    const course = await this.repo.createCourse(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "TrainingCourse",
        entityId: course.id,
        payload: {
          code: course.code,
          title: course.title,
          category: course.category,
        },
      },
    });

    return course;
  }

  async findCourses(query: QueryTrainingCoursesDto) {
    return this.repo.findCourses(query);
  }

  async findCourseById(id: string) {
    const course = await this.repo.findCourseById(id);
    if (!course)
      throw new NotFoundException(`Training course '${id}' not found`);
    return course;
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  async createSession(userId: string, dto: CreateTrainingSessionDto) {
    const course = await this.findCourseById(dto.courseId);

    const session = await this.repo.createSession(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "TrainingSession",
        entityId: session.id,
        payload: {
          courseId: dto.courseId,
          courseTitle: course.title,
          startDate: session.startDate,
        },
      },
    });

    return session;
  }

  async findSessions(query: QueryTrainingSessionsDto) {
    return this.repo.findSessions(query);
  }

  async findSessionById(id: string) {
    const session = await this.repo.findSessionById(id);
    if (!session)
      throw new NotFoundException(`Training session '${id}' not found`);
    return session;
  }

  // ============================================================
  // ENROLLMENTS
  // ============================================================

  async enrollEmployee(
    sessionId: string,
    userId: string,
    dto: EnrollEmployeeDto,
  ) {
    const session = await this.findSessionById(sessionId);

    // Check capacity
    if (
      session.maxParticipants &&
      session.enrollments.length >= session.maxParticipants
    ) {
      throw new BadRequestException("Session is already at full capacity");
    }

    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { user: true },
    });
    if (!employee)
      throw new NotFoundException(`Employee '${dto.employeeId}' not found`);

    const existing = await this.repo.findEnrollment(sessionId, dto.employeeId);
    if (existing) {
      throw new ConflictException(
        `Employee is already enrolled in this session`,
      );
    }

    const enrollment = await this.repo.enrollEmployee(
      sessionId,
      dto.employeeId,
    );

    // Notify employee
    if (employee.user?.id) {
      await this.notificationsService
        .sendNotification(
          employee.user.id,
          "Enrolled in Training Session",
          `You have been enrolled in '${session.course.title}' scheduled on ${session.startDate.toISOString().slice(0, 10)}.`,
          NotificationType.GENERAL_ANNOUNCEMENT,
          { sessionId, courseId: session.courseId },
        )
        .catch(() => {});
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "TrainingEnrollment",
        entityId: enrollment.id,
        payload: { sessionId, employeeId: dto.employeeId },
      },
    });

    return enrollment;
  }

  async updateEnrollment(id: string, userId: string, dto: UpdateEnrollmentDto) {
    const updated = await this.repo.updateEnrollment(id, dto.status, dto.score);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "TrainingEnrollment",
        entityId: id,
        payload: { status: dto.status, score: dto.score },
      },
    });

    return updated;
  }

  // ============================================================
  // CERTIFICATES
  // ============================================================

  async issueCertificate(userId: string, dto: IssueCertificateDto) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { user: true },
    });
    if (!employee)
      throw new NotFoundException(`Employee '${dto.employeeId}' not found`);

    const certNumber = await this.repo.generateCertificateNumber();
    const certificate = await this.repo.issueCertificate(dto, certNumber);

    // Notify employee
    if (employee.user?.id) {
      await this.notificationsService
        .sendNotification(
          employee.user.id,
          "Certificate Issued!",
          `Congratulations! Your certificate '${dto.title}' (${certNumber}) has been issued.`,
          NotificationType.GENERAL_ANNOUNCEMENT,
          { certificateId: certificate.id, certNumber },
        )
        .catch(() => {});
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "EmployeeCertificate",
        entityId: certificate.id,
        payload: {
          certificateNumber: certNumber,
          employeeId: dto.employeeId,
          title: dto.title,
        },
      },
    });

    return certificate;
  }

  async findCertificates(employeeId?: string) {
    return this.repo.findCertificates(employeeId);
  }
}
