import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateTrainingCourseDto,
  CreateTrainingSessionDto,
  IssueCertificateDto,
  QueryTrainingCoursesDto,
  QueryTrainingSessionsDto,
} from "./dto";
import { Prisma, EnrollmentStatus } from "@prisma/client";

@Injectable()
export class TrainingRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateCertificateNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.employeeCertificate.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `CERT-${today}-${seq}`;
  }

  // ============================================================
  // COURSES
  // ============================================================

  async createCourse(dto: CreateTrainingCourseDto) {
    return this.prisma.trainingCourse.create({
      data: {
        code: dto.code,
        title: dto.title,
        description: dto.description,
        category: dto.category,
        isMandatory: dto.isMandatory || false,
        durationHours: new Prisma.Decimal(dto.durationHours),
        validityMonths: dto.validityMonths,
        isActive: true,
      },
    });
  }

  async findCourses(query: QueryTrainingCoursesDto) {
    const { page = 1, limit = 20, search, category } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.TrainingCourseWhereInput = {};
    if (category) where.category = category;
    if (search) {
      where.OR = [
        { code: { contains: search, mode: "insensitive" } },
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.trainingCourse.count({ where }),
      this.prisma.trainingCourse.findMany({
        where,
        skip,
        take: limit,
        orderBy: { code: "asc" },
        include: {
          _count: { select: { sessions: true, certificates: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findCourseById(id: string) {
    return this.prisma.trainingCourse.findUnique({
      where: { id },
      include: {
        sessions: {
          orderBy: { startDate: "desc" },
          take: 5,
        },
      },
    });
  }

  async findCourseByCode(code: string) {
    return this.prisma.trainingCourse.findUnique({
      where: { code },
    });
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  async createSession(dto: CreateTrainingSessionDto) {
    return this.prisma.trainingSession.create({
      data: {
        courseId: dto.courseId,
        trainerName: dto.trainerName,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        location: dto.location,
        maxParticipants: dto.maxParticipants || 25,
      },
      include: { course: true },
    });
  }

  async findSessions(query: QueryTrainingSessionsDto) {
    const { page = 1, limit = 20, courseId, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.TrainingSessionWhereInput = {};
    if (courseId) where.courseId = courseId;
    if (status) where.status = status;

    const [total, items] = await Promise.all([
      this.prisma.trainingSession.count({ where }),
      this.prisma.trainingSession.findMany({
        where,
        skip,
        take: limit,
        orderBy: { startDate: "desc" },
        include: {
          course: true,
          _count: { select: { enrollments: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findSessionById(id: string) {
    return this.prisma.trainingSession.findUnique({
      where: { id },
      include: {
        course: true,
        enrollments: {
          include: {
            employee: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                employeeCode: true,
              },
            },
          },
        },
      },
    });
  }

  // ============================================================
  // ENROLLMENTS
  // ============================================================

  async enrollEmployee(sessionId: string, employeeId: string) {
    return this.prisma.trainingEnrollment.create({
      data: {
        sessionId,
        employeeId,
        status: EnrollmentStatus.ENROLLED,
      },
      include: {
        session: { include: { course: true } },
        employee: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }

  async findEnrollment(sessionId: string, employeeId: string) {
    return this.prisma.trainingEnrollment.findFirst({
      where: { sessionId, employeeId },
    });
  }

  async updateEnrollment(id: string, status: EnrollmentStatus, score?: number) {
    return this.prisma.trainingEnrollment.update({
      where: { id },
      data: {
        status,
        score: score !== undefined ? new Prisma.Decimal(score) : undefined,
      },
    });
  }

  // ============================================================
  // CERTIFICATES
  // ============================================================

  async issueCertificate(dto: IssueCertificateDto, certificateNumber: string) {
    return this.prisma.employeeCertificate.create({
      data: {
        certificateNumber,
        employeeId: dto.employeeId,
        courseId: dto.courseId,
        title: dto.title,
        issueDate: new Date(),
        expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
        certificateUrl: dto.certificateUrl,
      },
      include: {
        employee: { select: { id: true, firstName: true, lastName: true } },
        course: true,
      },
    });
  }

  async findCertificates(employeeId?: string) {
    return this.prisma.employeeCertificate.findMany({
      where: employeeId ? { employeeId } : undefined,
      orderBy: { issueDate: "desc" },
      include: {
        employee: { select: { id: true, firstName: true, lastName: true } },
        course: true,
      },
    });
  }
}
