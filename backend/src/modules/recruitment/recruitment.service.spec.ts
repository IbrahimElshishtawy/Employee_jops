import { Test, TestingModule } from "@nestjs/testing";
import { RecruitmentService } from "./recruitment.service";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictException, NotFoundException } from "@nestjs/common";
import {
  ApplicationStatus,
  CandidateSource,
  EmploymentType,
  InterviewRecommendation,
  InterviewStatus,
  InterviewType,
  JobOfferStatus,
  JobOpeningStatus,
  Role,
} from "@prisma/client";

describe("RecruitmentService", () => {
  let service: RecruitmentService;

  const mockPrismaService: any = {
    jobOpening: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    candidate: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    jobApplication: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    interview: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    interviewEvaluation: {
      upsert: jest.fn(),
    },
    jobOffer: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    employeeProfile: {
      findUnique: jest.fn(),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({ id: "audit-1" }),
    },
    $transaction: jest.fn((callback) => callback(mockPrismaService)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RecruitmentService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<RecruitmentService>(RecruitmentService);
    jest.clearAllMocks();
  });

  describe("Job Openings Lifecycle", () => {
    it("should create job opening successfully", async () => {
      mockPrismaService.jobOpening.findUnique.mockResolvedValue(null);
      mockPrismaService.jobOpening.create.mockResolvedValue({
        id: "opening-1",
        title: "Senior Backend Engineer",
        code: "ENG-01",
      });

      const result = await service.createJobOpening(
        {
          title: "Senior Backend Engineer",
          code: "ENG-01",
          employmentType: EmploymentType.FULL_TIME,
        },
        "user-1",
      );

      expect(result.id).toBe("opening-1");
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should throw ConflictException on duplicate job opening code", async () => {
      mockPrismaService.jobOpening.findUnique.mockResolvedValue({
        id: "opening-1",
        code: "ENG-01",
      });

      await expect(
        service.createJobOpening(
          { title: "Any", code: "ENG-01" },
          "user-1",
        ),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe("Candidate Management", () => {
    it("should create candidate profile", async () => {
      mockPrismaService.candidate.findUnique.mockResolvedValue(null);
      mockPrismaService.candidate.create.mockResolvedValue({
        id: "cand-1",
        email: "cand@test.com",
        firstName: "Karim",
        lastName: "Mahmoud",
      });

      const result = await service.createCandidate(
        {
          firstName: "Karim",
          lastName: "Mahmoud",
          email: "cand@test.com",
          source: CandidateSource.LINKEDIN,
        },
        "user-1",
      );

      expect(result.id).toBe("cand-1");
    });

    it("should throw ConflictException if candidate email exists", async () => {
      mockPrismaService.candidate.findUnique.mockResolvedValue({
        id: "cand-1",
        email: "cand@test.com",
      });

      await expect(
        service.createCandidate(
          {
            firstName: "Karim",
            lastName: "Mahmoud",
            email: "cand@test.com",
          },
          "user-1",
        ),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe("Applications & Interviews", () => {
    it("should create application for candidate", async () => {
      mockPrismaService.jobOpening.findUnique.mockResolvedValue({
        id: "opening-1",
      });
      mockPrismaService.candidate.findUnique.mockResolvedValue({
        id: "cand-1",
      });
      mockPrismaService.jobApplication.findUnique.mockResolvedValue(null);
      mockPrismaService.jobApplication.create.mockResolvedValue({
        id: "app-1",
        jobOpeningId: "opening-1",
        candidateId: "cand-1",
        status: ApplicationStatus.APPLIED,
      });

      const result = await service.createApplication(
        {
          jobOpeningId: "opening-1",
          candidateId: "cand-1",
        },
        "user-1",
      );

      expect(result.id).toBe("app-1");
    });

    it("should schedule interview and auto-transition application to INTERVIEWING", async () => {
      mockPrismaService.jobApplication.findUnique.mockResolvedValue({
        id: "app-1",
        status: ApplicationStatus.APPLIED,
      });
      mockPrismaService.interview.create.mockResolvedValue({
        id: "int-1",
        applicationId: "app-1",
        title: "Tech Screen",
        status: InterviewStatus.SCHEDULED,
      });

      const result = await service.scheduleInterview(
        {
          applicationId: "app-1",
          title: "Tech Screen",
          interviewType: InterviewType.TECHNICAL,
          scheduledAt: new Date().toISOString(),
        },
        "user-1",
      );

      expect(result.id).toBe("int-1");
      expect(mockPrismaService.jobApplication.update).toHaveBeenCalledWith({
        where: { id: "app-1" },
        data: { status: ApplicationStatus.INTERVIEWING },
      });
    });

    it("should submit scorecard evaluation", async () => {
      mockPrismaService.interview.findUnique.mockResolvedValue({
        id: "int-1",
      });
      mockPrismaService.interviewEvaluation.upsert.mockResolvedValue({
        id: "eval-1",
        interviewId: "int-1",
        rating: 5,
        recommendation: InterviewRecommendation.STRONG_HIRE,
      });

      const result = await service.submitEvaluation(
        "int-1",
        {
          rating: 5,
          recommendation: InterviewRecommendation.STRONG_HIRE,
          comments: "Excellent candidate",
        },
        "evaluator-1",
      );

      expect(result.rating).toBe(5);
    });
  });

  describe("Atomic Hiring Workflow", () => {
    it("should atomically hire candidate and trigger onboarding workflow", async () => {
      mockPrismaService.candidate.findUnique.mockResolvedValue({
        id: "cand-1",
        firstName: "Hany",
        lastName: "Adel",
        email: "hany@test.com",
        phone: "+201011112222",
      });
      mockPrismaService.jobApplication.findUnique.mockResolvedValue({
        id: "app-1",
        jobOpening: {
          id: "opening-1",
          title: "Senior Backend Developer",
          departmentId: "dept-1",
          positionId: "pos-1",
          organizationId: "org-1",
          branchId: "branch-1",
        },
        offers: [
          {
            id: "offer-1",
            offeredSalary: 35000,
            status: JobOfferStatus.SENT,
          },
        ],
      });
      mockPrismaService.user.findUnique.mockResolvedValue(null);
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue(null);
      mockPrismaService.user.create.mockResolvedValue({
        id: "user-new",
        email: "hany@test.com",
        role: Role.EMPLOYEE,
        employeeProfile: {
          id: "profile-new",
          employeeCode: "CW-5555",
          firstName: "Hany",
          lastName: "Adel",
        },
      });
      mockPrismaService.onboardingWorkflow = {
        create: jest.fn().mockResolvedValue({
          id: "wf-1",
          employeeId: "profile-new",
          tasks: [{ id: "task-1" }, { id: "task-2" }],
        }),
      };

      const result = await service.hireCandidate(
        {
          candidateId: "cand-1",
          applicationId: "app-1",
        },
        "admin-1",
      );

      expect(result.user.id).toBe("user-new");
      expect(result.employeeProfile.id).toBe("profile-new");
      expect(mockPrismaService.jobApplication.update).toHaveBeenCalledWith({
        where: { id: "app-1" },
        data: { status: ApplicationStatus.HIRED },
      });
    });
  });
});
