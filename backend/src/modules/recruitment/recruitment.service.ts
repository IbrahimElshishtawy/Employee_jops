import {
  Injectable,
  NotFoundException,
  ConflictException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateJobOpeningDto } from "./dto/create-job-opening.dto";
import { UpdateJobOpeningDto } from "./dto/update-job-opening.dto";
import { CreateCandidateDto } from "./dto/create-candidate.dto";
import { UpdateCandidateDto } from "./dto/update-candidate.dto";
import { CreateApplicationDto } from "./dto/create-application.dto";
import { UpdateApplicationDto } from "./dto/update-application.dto";
import { CreateInterviewDto } from "./dto/create-interview.dto";
import { UpdateInterviewDto } from "./dto/update-interview.dto";
import { CreateEvaluationDto } from "./dto/create-evaluation.dto";
import { CreateJobOfferDto } from "./dto/create-job-offer.dto";
import { UpdateJobOfferDto } from "./dto/update-job-offer.dto";
import { HireCandidateDto } from "./dto/hire-candidate.dto";
import {
  QueryJobOpeningsDto,
  QueryCandidatesDto,
  QueryApplicationsDto,
  QueryInterviewsDto,
  QueryJobOffersDto,
} from "./dto/query-recruitment.dto";
import {
  ApplicationStatus,
  AuditAction,
  JobOfferStatus,
  OnboardingTaskCategory,
  Prisma,
  Role,
} from "@prisma/client";
import * as argon2 from "argon2";

@Injectable()
export class RecruitmentService {
  constructor(private prisma: PrismaService) {}

  // ============================================================
  // JOB OPENINGS
  // ============================================================

  async createJobOpening(dto: CreateJobOpeningDto, userId?: string) {
    const existing = await this.prisma.jobOpening.findUnique({
      where: { code: dto.code },
    });
    if (existing) {
      throw new ConflictException(
        `Job opening with code '${dto.code}' already exists`,
      );
    }

    const opening = await this.prisma.jobOpening.create({
      data: {
        title: dto.title,
        code: dto.code,
        organizationId: dto.organizationId,
        branchId: dto.branchId,
        departmentId: dto.departmentId,
        positionId: dto.positionId,
        description: dto.description,
        requirements: dto.requirements,
        employmentType: dto.employmentType,
        status: dto.status,
        vacancies: dto.vacancies,
        targetDate: dto.targetDate ? new Date(dto.targetDate) : null,
        minSalary: dto.minSalary ? new Prisma.Decimal(dto.minSalary) : null,
        maxSalary: dto.maxSalary ? new Prisma.Decimal(dto.maxSalary) : null,
        currency: dto.currency || "EGP",
        createdById: userId,
      },
      include: {
        department: true,
        position: true,
        branch: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.JOB_OPENING_CREATED,
        entity: "JobOpening",
        entityId: opening.id,
        payload: { title: dto.title, code: dto.code },
      },
    });

    return opening;
  }

  async getJobOpenings(query: QueryJobOpeningsDto) {
    const {
      skip,
      limit,
      search,
      status,
      departmentId,
      positionId,
      organizationId,
    } = query;

    const where: Prisma.JobOpeningWhereInput = {
      ...(status && { status }),
      ...(departmentId && { departmentId }),
      ...(positionId && { positionId }),
      ...(organizationId && { organizationId }),
      ...(search && {
        OR: [
          { title: { contains: search, mode: "insensitive" } },
          { code: { contains: search, mode: "insensitive" } },
          { description: { contains: search, mode: "insensitive" } },
        ],
      }),
    };

    const [total, data] = await Promise.all([
      this.prisma.jobOpening.count({ where }),
      this.prisma.jobOpening.findMany({
        where,
        skip,
        take: limit,
        include: {
          department: { select: { id: true, name: true, code: true } },
          position: {
            select: { id: true, title: true, code: true, level: true },
          },
          branch: { select: { id: true, name: true, code: true } },
          _count: { select: { applications: true } },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getJobOpeningById(id: string) {
    const opening = await this.prisma.jobOpening.findUnique({
      where: { id },
      include: {
        organization: true,
        branch: true,
        department: true,
        position: true,
        applications: {
          include: {
            candidate: true,
            interviews: true,
            offers: true,
          },
          orderBy: { appliedAt: "desc" },
        },
      },
    });

    if (!opening) {
      throw new NotFoundException(`Job opening #${id} not found`);
    }

    return opening;
  }

  async updateJobOpening(
    id: string,
    dto: UpdateJobOpeningDto,
    userId?: string,
  ) {
    const existing = await this.prisma.jobOpening.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Job opening #${id} not found`);
    }

    if (dto.code && dto.code !== existing.code) {
      const codeConflict = await this.prisma.jobOpening.findUnique({
        where: { code: dto.code },
      });
      if (codeConflict) {
        throw new ConflictException(
          `Job opening code '${dto.code}' already taken`,
        );
      }
    }

    const updated = await this.prisma.jobOpening.update({
      where: { id },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.code && { code: dto.code }),
        ...(dto.organizationId !== undefined && {
          organizationId: dto.organizationId,
        }),
        ...(dto.branchId !== undefined && { branchId: dto.branchId }),
        ...(dto.departmentId !== undefined && {
          departmentId: dto.departmentId,
        }),
        ...(dto.positionId !== undefined && { positionId: dto.positionId }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.requirements !== undefined && {
          requirements: dto.requirements,
        }),
        ...(dto.employmentType && { employmentType: dto.employmentType }),
        ...(dto.status && { status: dto.status }),
        ...(dto.vacancies !== undefined && { vacancies: dto.vacancies }),
        ...(dto.targetDate !== undefined && {
          targetDate: dto.targetDate ? new Date(dto.targetDate) : null,
        }),
        ...(dto.minSalary !== undefined && {
          minSalary: dto.minSalary ? new Prisma.Decimal(dto.minSalary) : null,
        }),
        ...(dto.maxSalary !== undefined && {
          maxSalary: dto.maxSalary ? new Prisma.Decimal(dto.maxSalary) : null,
        }),
        ...(dto.currency && { currency: dto.currency }),
      },
      include: {
        department: true,
        position: true,
        branch: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.JOB_OPENING_UPDATED,
        entity: "JobOpening",
        entityId: id,
        payload: { status: dto.status, title: dto.title },
      },
    });

    return updated;
  }

  async deleteJobOpening(id: string, userId?: string) {
    const existing = await this.prisma.jobOpening.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Job opening #${id} not found`);
    }

    await this.prisma.jobOpening.delete({ where: { id } });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.JOB_OPENING_DELETED,
        entity: "JobOpening",
        entityId: id,
      },
    });

    return { message: "Job opening deleted successfully" };
  }

  // ============================================================
  // CANDIDATES
  // ============================================================

  async createCandidate(dto: CreateCandidateDto, userId?: string) {
    const existing = await this.prisma.candidate.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
    });
    if (existing) {
      throw new ConflictException(
        `Candidate with email '${dto.email}' already exists`,
      );
    }

    const candidate = await this.prisma.candidate.create({
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email.toLowerCase().trim(),
        phone: dto.phone,
        currentTitle: dto.currentTitle,
        experienceYears: dto.experienceYears || 0,
        source: dto.source,
        resumeUrl: dto.resumeUrl,
        skills: dto.skills ? (dto.skills as any) : undefined,
        notes: dto.notes,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CANDIDATE_CREATED,
        entity: "Candidate",
        entityId: candidate.id,
        payload: {
          email: candidate.email,
          name: `${dto.firstName} ${dto.lastName}`,
        },
      },
    });

    return candidate;
  }

  async getCandidates(query: QueryCandidatesDto) {
    const { skip, limit, search, source } = query;

    const where: Prisma.CandidateWhereInput = {
      ...(source && { source }),
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: "insensitive" } },
          { lastName: { contains: search, mode: "insensitive" } },
          { email: { contains: search, mode: "insensitive" } },
          { phone: { contains: search, mode: "insensitive" } },
          { currentTitle: { contains: search, mode: "insensitive" } },
        ],
      }),
    };

    const [total, data] = await Promise.all([
      this.prisma.candidate.count({ where }),
      this.prisma.candidate.findMany({
        where,
        skip,
        take: limit,
        include: {
          _count: { select: { applications: true, offers: true } },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getCandidateById(id: string) {
    const candidate = await this.prisma.candidate.findUnique({
      where: { id },
      include: {
        applications: {
          include: {
            jobOpening: {
              include: { department: true, position: true },
            },
            interviews: {
              include: { evaluations: true },
              orderBy: { scheduledAt: "asc" },
            },
            offers: {
              orderBy: { createdAt: "desc" },
            },
          },
          orderBy: { appliedAt: "desc" },
        },
        offers: {
          include: { position: true, department: true },
          orderBy: { createdAt: "desc" },
        },
      },
    });

    if (!candidate) {
      throw new NotFoundException(`Candidate #${id} not found`);
    }

    return candidate;
  }

  async updateCandidate(id: string, dto: UpdateCandidateDto, userId?: string) {
    const existing = await this.prisma.candidate.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Candidate #${id} not found`);
    }

    if (dto.email && dto.email.toLowerCase().trim() !== existing.email) {
      const emailConflict = await this.prisma.candidate.findUnique({
        where: { email: dto.email.toLowerCase().trim() },
      });
      if (emailConflict) {
        throw new ConflictException(
          `Candidate email '${dto.email}' is already in use`,
        );
      }
    }

    const updated = await this.prisma.candidate.update({
      where: { id },
      data: {
        ...(dto.firstName && { firstName: dto.firstName }),
        ...(dto.lastName && { lastName: dto.lastName }),
        ...(dto.email && { email: dto.email.toLowerCase().trim() }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
        ...(dto.currentTitle !== undefined && {
          currentTitle: dto.currentTitle,
        }),
        ...(dto.experienceYears !== undefined && {
          experienceYears: dto.experienceYears,
        }),
        ...(dto.source && { source: dto.source }),
        ...(dto.resumeUrl !== undefined && { resumeUrl: dto.resumeUrl }),
        ...(dto.skills !== undefined && { skills: dto.skills as any }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CANDIDATE_UPDATED,
        entity: "Candidate",
        entityId: id,
      },
    });

    return updated;
  }

  async deleteCandidate(id: string, userId?: string) {
    const existing = await this.prisma.candidate.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Candidate #${id} not found`);
    }

    await this.prisma.candidate.delete({ where: { id } });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CANDIDATE_DELETED,
        entity: "Candidate",
        entityId: id,
      },
    });

    return { message: "Candidate deleted successfully" };
  }

  // ============================================================
  // JOB APPLICATIONS
  // ============================================================

  async createApplication(dto: CreateApplicationDto, userId?: string) {
    const [opening, candidate] = await Promise.all([
      this.prisma.jobOpening.findUnique({ where: { id: dto.jobOpeningId } }),
      this.prisma.candidate.findUnique({ where: { id: dto.candidateId } }),
    ]);

    if (!opening) {
      throw new NotFoundException(`Job opening #${dto.jobOpeningId} not found`);
    }
    if (!candidate) {
      throw new NotFoundException(`Candidate #${dto.candidateId} not found`);
    }

    const existingApplication = await this.prisma.jobApplication.findUnique({
      where: {
        jobOpeningId_candidateId: {
          jobOpeningId: dto.jobOpeningId,
          candidateId: dto.candidateId,
        },
      },
    });
    if (existingApplication) {
      throw new ConflictException(
        "Candidate has already applied for this job opening",
      );
    }

    const application = await this.prisma.jobApplication.create({
      data: {
        jobOpeningId: dto.jobOpeningId,
        candidateId: dto.candidateId,
        status: dto.status || ApplicationStatus.APPLIED,
        rating: dto.rating || 0,
        stageNotes: dto.stageNotes,
      },
      include: {
        candidate: true,
        jobOpening: {
          include: { department: true, position: true },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.APPLICATION_CREATED,
        entity: "JobApplication",
        entityId: application.id,
        payload: {
          jobOpeningId: dto.jobOpeningId,
          candidateId: dto.candidateId,
        },
      },
    });

    return application;
  }

  async getApplications(query: QueryApplicationsDto) {
    const { skip, limit, jobOpeningId, candidateId, status, search } = query;

    const where: Prisma.JobApplicationWhereInput = {
      ...(jobOpeningId && { jobOpeningId }),
      ...(candidateId && { candidateId }),
      ...(status && { status }),
      ...(search && {
        candidate: {
          OR: [
            { firstName: { contains: search, mode: "insensitive" } },
            { lastName: { contains: search, mode: "insensitive" } },
            { email: { contains: search, mode: "insensitive" } },
          ],
        },
      }),
    };

    const [total, data] = await Promise.all([
      this.prisma.jobApplication.count({ where }),
      this.prisma.jobApplication.findMany({
        where,
        skip,
        take: limit,
        include: {
          candidate: true,
          jobOpening: {
            select: { id: true, title: true, code: true, status: true },
          },
          _count: { select: { interviews: true, offers: true } },
        },
        orderBy: { appliedAt: "desc" },
      }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getApplicationById(id: string) {
    const application = await this.prisma.jobApplication.findUnique({
      where: { id },
      include: {
        candidate: true,
        jobOpening: {
          include: {
            organization: true,
            branch: true,
            department: true,
            position: true,
          },
        },
        interviews: {
          include: {
            evaluations: true,
          },
          orderBy: { scheduledAt: "asc" },
        },
        offers: {
          include: { position: true, department: true },
          orderBy: { createdAt: "desc" },
        },
      },
    });

    if (!application) {
      throw new NotFoundException(`Application #${id} not found`);
    }

    return application;
  }

  async updateApplication(
    id: string,
    dto: UpdateApplicationDto,
    userId?: string,
  ) {
    const application = await this.prisma.jobApplication.findUnique({
      where: { id },
    });
    if (!application) {
      throw new NotFoundException(`Application #${id} not found`);
    }

    const updated = await this.prisma.jobApplication.update({
      where: { id },
      data: {
        ...(dto.status && { status: dto.status }),
        ...(dto.rating !== undefined && { rating: dto.rating }),
        ...(dto.stageNotes !== undefined && { stageNotes: dto.stageNotes }),
        ...(dto.rejectionReason !== undefined && {
          rejectionReason: dto.rejectionReason,
        }),
      },
      include: {
        candidate: true,
        jobOpening: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.APPLICATION_STAGE_CHANGED,
        entity: "JobApplication",
        entityId: id,
        payload: {
          oldStatus: application.status,
          newStatus: dto.status || application.status,
          rating: dto.rating,
        },
      },
    });

    return updated;
  }

  // ============================================================
  // INTERVIEWS & EVALUATIONS
  // ============================================================

  async scheduleInterview(dto: CreateInterviewDto, userId?: string) {
    const application = await this.prisma.jobApplication.findUnique({
      where: { id: dto.applicationId },
    });
    if (!application) {
      throw new NotFoundException(
        `Job application #${dto.applicationId} not found`,
      );
    }

    const interview = await this.prisma.interview.create({
      data: {
        applicationId: dto.applicationId,
        title: dto.title,
        interviewType: dto.interviewType,
        scheduledAt: new Date(dto.scheduledAt),
        durationMinutes: dto.durationMinutes || 30,
        interviewerId: dto.interviewerId || userId,
        locationOrLink: dto.locationOrLink,
        status: dto.status,
        feedbackNotes: dto.feedbackNotes,
      },
      include: {
        application: {
          include: { candidate: true, jobOpening: true },
        },
      },
    });

    // Auto-update application status to INTERVIEWING if APPLIED/SCREENING
    if (
      application.status === ApplicationStatus.APPLIED ||
      application.status === ApplicationStatus.SCREENING
    ) {
      await this.prisma.jobApplication.update({
        where: { id: dto.applicationId },
        data: { status: ApplicationStatus.INTERVIEWING },
      });
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.INTERVIEW_SCHEDULED,
        entity: "Interview",
        entityId: interview.id,
        payload: {
          applicationId: dto.applicationId,
          scheduledAt: dto.scheduledAt,
          interviewType: dto.interviewType,
        },
      },
    });

    return interview;
  }

  async getInterviews(query: QueryInterviewsDto) {
    const { skip, limit, applicationId, interviewerId, status } = query;

    const where: Prisma.InterviewWhereInput = {
      ...(applicationId && { applicationId }),
      ...(interviewerId && { interviewerId }),
      ...(status && { status }),
    };

    const [total, data] = await Promise.all([
      this.prisma.interview.count({ where }),
      this.prisma.interview.findMany({
        where,
        skip,
        take: limit,
        include: {
          application: {
            include: { candidate: true, jobOpening: true },
          },
          evaluations: true,
        },
        orderBy: { scheduledAt: "asc" },
      }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getInterviewById(id: string) {
    const interview = await this.prisma.interview.findUnique({
      where: { id },
      include: {
        application: {
          include: {
            candidate: true,
            jobOpening: {
              include: { department: true, position: true },
            },
          },
        },
        evaluations: true,
      },
    });

    if (!interview) {
      throw new NotFoundException(`Interview #${id} not found`);
    }

    return interview;
  }

  async updateInterview(id: string, dto: UpdateInterviewDto, userId?: string) {
    const existing = await this.prisma.interview.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Interview #${id} not found`);
    }

    const updated = await this.prisma.interview.update({
      where: { id },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.interviewType && { interviewType: dto.interviewType }),
        ...(dto.scheduledAt && { scheduledAt: new Date(dto.scheduledAt) }),
        ...(dto.durationMinutes !== undefined && {
          durationMinutes: dto.durationMinutes,
        }),
        ...(dto.interviewerId !== undefined && {
          interviewerId: dto.interviewerId,
        }),
        ...(dto.locationOrLink !== undefined && {
          locationOrLink: dto.locationOrLink,
        }),
        ...(dto.status && { status: dto.status }),
        ...(dto.feedbackNotes !== undefined && {
          feedbackNotes: dto.feedbackNotes,
        }),
      },
      include: {
        evaluations: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.INTERVIEW_UPDATED,
        entity: "Interview",
        entityId: id,
        payload: { status: dto.status },
      },
    });

    return updated;
  }

  async submitEvaluation(
    interviewId: string,
    dto: CreateEvaluationDto,
    evaluatorId: string,
  ) {
    const interview = await this.prisma.interview.findUnique({
      where: { id: interviewId },
    });
    if (!interview) {
      throw new NotFoundException(`Interview #${interviewId} not found`);
    }

    const evaluation = await this.prisma.interviewEvaluation.upsert({
      where: {
        interviewId_evaluatorId: {
          interviewId,
          evaluatorId,
        },
      },
      create: {
        interviewId,
        evaluatorId,
        rating: dto.rating,
        recommendation: dto.recommendation,
        criteriaScores: dto.criteriaScores
          ? (dto.criteriaScores as any)
          : undefined,
        strengths: dto.strengths,
        weaknesses: dto.weaknesses,
        comments: dto.comments,
      },
      update: {
        rating: dto.rating,
        recommendation: dto.recommendation,
        criteriaScores: dto.criteriaScores
          ? (dto.criteriaScores as any)
          : undefined,
        strengths: dto.strengths,
        weaknesses: dto.weaknesses,
        comments: dto.comments,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: evaluatorId,
        action: AuditAction.INTERVIEW_EVALUATION_SUBMITTED,
        entity: "InterviewEvaluation",
        entityId: evaluation.id,
        payload: {
          interviewId,
          rating: dto.rating,
          recommendation: dto.recommendation,
        },
      },
    });

    return evaluation;
  }

  // ============================================================
  // JOB OFFERS
  // ============================================================

  async createJobOffer(dto: CreateJobOfferDto, userId?: string) {
    const [application, candidate] = await Promise.all([
      this.prisma.jobApplication.findUnique({
        where: { id: dto.applicationId },
        include: { jobOpening: true },
      }),
      this.prisma.candidate.findUnique({
        where: { id: dto.candidateId },
      }),
    ]);

    if (!application) {
      throw new NotFoundException(
        `Job application #${dto.applicationId} not found`,
      );
    }
    if (!candidate) {
      throw new NotFoundException(`Candidate #${dto.candidateId} not found`);
    }

    const positionId = dto.positionId || application.jobOpening.positionId;
    const departmentId =
      dto.departmentId || application.jobOpening.departmentId;

    const offer = await this.prisma.jobOffer.create({
      data: {
        applicationId: dto.applicationId,
        candidateId: dto.candidateId,
        positionId,
        departmentId,
        offeredSalary: new Prisma.Decimal(dto.offeredSalary),
        currency: dto.currency || "EGP",
        benefits: dto.benefits,
        proposedStartDate: new Date(dto.proposedStartDate),
        status: dto.status || JobOfferStatus.DRAFT,
        terms: dto.terms,
        notes: dto.notes,
        createdById: userId,
      },
      include: {
        candidate: true,
        position: true,
        department: true,
      },
    });

    // Move application to OFFERED
    await this.prisma.jobApplication.update({
      where: { id: dto.applicationId },
      data: { status: ApplicationStatus.OFFERED },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.JOB_OFFER_CREATED,
        entity: "JobOffer",
        entityId: offer.id,
        payload: {
          applicationId: dto.applicationId,
          candidateId: dto.candidateId,
          salary: dto.offeredSalary,
        },
      },
    });

    return offer;
  }

  async getJobOffers(query: QueryJobOffersDto) {
    const { skip, limit, applicationId, candidateId, status } = query;

    const where: Prisma.JobOfferWhereInput = {
      ...(applicationId && { applicationId }),
      ...(candidateId && { candidateId }),
      ...(status && { status }),
    };

    const [total, data] = await Promise.all([
      this.prisma.jobOffer.count({ where }),
      this.prisma.jobOffer.findMany({
        where,
        skip,
        take: limit,
        include: {
          candidate: true,
          position: true,
          department: true,
          application: {
            select: { id: true, jobOpening: { select: { title: true } } },
          },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getJobOfferById(id: string) {
    const offer = await this.prisma.jobOffer.findUnique({
      where: { id },
      include: {
        candidate: true,
        position: true,
        department: true,
        application: {
          include: { jobOpening: true },
        },
      },
    });

    if (!offer) {
      throw new NotFoundException(`Job offer #${id} not found`);
    }

    return offer;
  }

  async updateJobOffer(id: string, dto: UpdateJobOfferDto, userId?: string) {
    const existing = await this.prisma.jobOffer.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Job offer #${id} not found`);
    }

    const updated = await this.prisma.jobOffer.update({
      where: { id },
      data: {
        ...(dto.positionId !== undefined && { positionId: dto.positionId }),
        ...(dto.departmentId !== undefined && {
          departmentId: dto.departmentId,
        }),
        ...(dto.offeredSalary !== undefined && {
          offeredSalary: new Prisma.Decimal(dto.offeredSalary),
        }),
        ...(dto.currency && { currency: dto.currency }),
        ...(dto.benefits !== undefined && { benefits: dto.benefits }),
        ...(dto.proposedStartDate && {
          proposedStartDate: new Date(dto.proposedStartDate),
        }),
        ...(dto.status && {
          status: dto.status,
          ...(dto.status === JobOfferStatus.SENT && { sentAt: new Date() }),
          ...(dto.status === JobOfferStatus.ACCEPTED && {
            respondedAt: new Date(),
          }),
          ...(dto.status === JobOfferStatus.REJECTED && {
            respondedAt: new Date(),
          }),
        }),
        ...(dto.terms !== undefined && { terms: dto.terms }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
      include: {
        candidate: true,
        position: true,
        department: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.JOB_OFFER_UPDATED,
        entity: "JobOffer",
        entityId: id,
        payload: { status: dto.status },
      },
    });

    return updated;
  }

  // ============================================================
  // ATOMIC HIRING WORKFLOW
  // ============================================================

  /**
   * Execute atomic hiring process:
   * 1. Validates candidate & application
   * 2. Creates User account & credentials
   * 3. Creates EmployeeProfile linked with Department, Position, Manager, Workplace, Schedule, Salary
   * 4. Updates JobApplication to HIRED and JobOffer to ACCEPTED
   * 5. Automatically initializes OnboardingWorkflow and standard checklist tasks
   * 6. Creates AuditLog
   */
  async hireCandidate(dto: HireCandidateDto, creatorId?: string) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Verify candidate & application
      const candidate = await tx.candidate.findUnique({
        where: { id: dto.candidateId },
      });
      if (!candidate) {
        throw new NotFoundException(`Candidate #${dto.candidateId} not found`);
      }

      const application = await tx.jobApplication.findUnique({
        where: { id: dto.applicationId },
        include: {
          jobOpening: true,
          offers: { orderBy: { createdAt: "desc" }, take: 1 },
        },
      });
      if (!application) {
        throw new NotFoundException(
          `Job application #${dto.applicationId} not found`,
        );
      }

      // 2. Resolve corporate user email & check uniqueness
      const email = (dto.email || candidate.email).toLowerCase().trim();
      const existingUser = await tx.user.findUnique({ where: { email } });
      if (existingUser) {
        throw new ConflictException(
          `A user account with email '${email}' already exists`,
        );
      }

      // 3. Resolve employee code
      const employeeCode =
        dto.employeeCode || `CW-${Math.floor(1000 + Math.random() * 9000)}`;

      const existingCode = await tx.employeeProfile.findUnique({
        where: { employeeCode },
      });
      if (existingCode) {
        throw new ConflictException(
          `Employee code '${employeeCode}' is already registered`,
        );
      }

      // 4. Resolve password hash
      const defaultPassword = dto.password || "CyberWise@2026";
      const passwordHash = await argon2.hash(defaultPassword);

      // 5. Resolve job metadata & associations
      const positionId = dto.positionId || application.jobOpening.positionId;
      const departmentId =
        dto.departmentId || application.jobOpening.departmentId;
      const organizationId =
        dto.organizationId || application.jobOpening.organizationId;
      const branchId = dto.branchId || application.jobOpening.branchId;

      let jobTitle = application.jobOpening.title;
      let departmentName = "General";

      if (positionId) {
        const pos = await tx.position.findUnique({
          where: { id: positionId },
        });
        if (pos) jobTitle = pos.title;
      }
      if (departmentId) {
        const dept = await tx.department.findUnique({
          where: { id: departmentId },
        });
        if (dept) departmentName = dept.name;
      }

      // Resolve salary from offer or dto
      const latestOffer = application.offers[0];
      const baseSalary =
        dto.baseSalary !== undefined
          ? new Prisma.Decimal(dto.baseSalary)
          : latestOffer?.offeredSalary || undefined;

      const hireDate = dto.hireDate ? new Date(dto.hireDate) : new Date();

      // 6. Create User and EmployeeProfile atomically
      const user = await tx.user.create({
        data: {
          email,
          passwordHash,
          role: dto.role || Role.EMPLOYEE,
          employeeProfile: {
            create: {
              employeeCode,
              firstName: candidate.firstName,
              lastName: candidate.lastName,
              phone: candidate.phone,
              jobTitle,
              department: departmentName,
              hireDate,
              baseSalary,
              organizationId,
              branchId,
              departmentId,
              sectionId: dto.sectionId,
              positionId,
              managerId: dto.managerId,
              workplaceId: dto.workplaceId,
              scheduleId: dto.scheduleId,
              isProfileComplete: Boolean(
                candidate.firstName && candidate.lastName && dto.workplaceId,
              ),
            },
          },
        },
        include: {
          employeeProfile: {
            include: {
              organization: true,
              branch: true,
              departmentRel: true,
              position: true,
              workplace: true,
              schedule: true,
              manager: true,
            },
          },
        },
      });

      const employeeProfile = user.employeeProfile!;

      // 7. Update Job Application to HIRED
      await tx.jobApplication.update({
        where: { id: dto.applicationId },
        data: { status: ApplicationStatus.HIRED },
      });

      // 8. Update active Job Offer to ACCEPTED if exists
      if (latestOffer) {
        await tx.jobOffer.update({
          where: { id: latestOffer.id },
          data: {
            status: JobOfferStatus.ACCEPTED,
            respondedAt: new Date(),
          },
        });
      }

      // 9. Initialize Onboarding Workflow if requested
      let onboardingWorkflow: any = null;
      if (dto.initiateOnboarding !== false) {
        onboardingWorkflow = await tx.onboardingWorkflow.create({
          data: {
            employeeId: employeeProfile.id,
            startDate: hireDate,
            targetDate: new Date(hireDate.getTime() + 30 * 24 * 60 * 60 * 1000), // 30 days
            createdById: creatorId,
            tasks: {
              create: [
                {
                  title: "Submit National ID / Passport Copy",
                  description:
                    "Provide verified identification document copy to HR",
                  category: OnboardingTaskCategory.DOCUMENTATION,
                  isMandatory: true,
                  orderIndex: 1,
                },
                {
                  title: "Sign Employment Contract & NDA",
                  description:
                    "Review and physically/digitally sign the corporate employment agreement",
                  category: OnboardingTaskCategory.DOCUMENTATION,
                  isMandatory: true,
                  orderIndex: 2,
                },
                {
                  title: "Workstation & Corporate Credentials Setup",
                  description:
                    "Assign laptop, email accounts, VPN tokens, and developer access",
                  category: OnboardingTaskCategory.IT_SETUP,
                  isMandatory: true,
                  orderIndex: 3,
                },
                {
                  title: "Workplace Geofence & Mobile App Registration",
                  description:
                    "Download CyberWise mobile app and verify GPS/Beacon check-in",
                  category: OnboardingTaskCategory.ORIENTATION,
                  isMandatory: true,
                  orderIndex: 4,
                },
                {
                  title: "Information Security & Compliance Training",
                  description:
                    "Complete mandatory security and data protection awareness modules",
                  category: OnboardingTaskCategory.COMPLIANCE,
                  isMandatory: true,
                  orderIndex: 5,
                },
                {
                  title: "Team & Manager Orientation",
                  description:
                    "Initial 1:1 meeting with reporting manager and squad team introductions",
                  category: OnboardingTaskCategory.ORIENTATION,
                  isMandatory: false,
                  orderIndex: 6,
                },
              ],
            },
          },
          include: {
            tasks: { orderBy: { orderIndex: "asc" } },
          },
        });
      }

      // 10. Audit log hiring execution
      await tx.auditLog.create({
        data: {
          userId: creatorId,
          action: AuditAction.CANDIDATE_HIRED,
          entity: "EmployeeProfile",
          entityId: employeeProfile.id,
          payload: {
            candidateId: dto.candidateId,
            applicationId: dto.applicationId,
            employeeCode,
            email,
            jobTitle,
          },
        },
      });

      return {
        message: "Candidate successfully hired and employee profile created",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
        },
        employeeProfile,
        onboardingWorkflow,
      };
    });
  }
}
