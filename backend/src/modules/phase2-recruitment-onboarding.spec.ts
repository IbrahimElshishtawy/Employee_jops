import { Test, TestingModule } from "@nestjs/testing";
import { RecruitmentService } from "./recruitment/recruitment.service";
import { OnboardingService } from "./onboarding/onboarding.service";
import { HrService } from "./hr/hr.service";
import { PrismaService } from "../prisma/prisma.service";
import {
  ApplicationStatus,
  CandidateSource,
  EmployeeDocumentType,
  EmploymentType,
  InterviewRecommendation,
  InterviewStatus,
  InterviewType,
  JobOfferStatus,
  JobOpeningStatus,
  OnboardingStatus,
  OnboardingTaskCategory,
  Role,
} from "@prisma/client";

describe("Phase 2 — Full HR, Recruitment & Onboarding Integration Journey", () => {
  let recruitmentService: RecruitmentService;
  let onboardingService: OnboardingService;
  let hrService: HrService;

  // In-memory mock database state
  const db = {
    organizations: [
      { id: "org-1", name: "CyberWise Hospitality", code: "CW-CORP" },
    ],
    branches: [
      { id: "branch-1", organizationId: "org-1", name: "Cairo HQ", code: "GNH-HQ" },
    ],
    departments: [
      { id: "dept-1", organizationId: "org-1", name: "Engineering", code: "ENG" },
    ],
    positions: [
      { id: "pos-1", organizationId: "org-1", title: "Principal Architect", code: "POS-ARCH" },
    ],
    workplaces: [
      { id: "wp-1", name: "HQ Geofence", code: "HQ-MAIN" },
    ],
    schedules: [
      { id: "sch-1", name: "Standard Shift", workingDays: [0, 1, 2, 3, 4] },
    ],
    jobOpenings: [] as any[],
    candidates: [] as any[],
    applications: [] as any[],
    interviews: [] as any[],
    evaluations: [] as any[],
    offers: [] as any[],
    users: [] as any[],
    employeeProfiles: [] as any[],
    onboardingWorkflows: [] as any[],
    onboardingTasks: [] as any[],
    documents: [] as any[],
    auditLogs: [] as any[],
  };

  const mockPrismaService: any = {
    organization: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.organizations.find((o) => o.id === where.id || o.code === where.code) || null),
      ),
    },
    branch: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.branches.find((b) => b.id === where.id || b.code === where.code) || null),
      ),
    },
    department: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.departments.find((d) => d.id === where.id || d.code === where.code) || null),
      ),
    },
    position: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.positions.find((p) => p.id === where.id || p.code === where.code) || null),
      ),
    },
    workplace: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.workplaces.find((w) => w.id === where.id || w.code === where.code) || null),
      ),
    },
    schedule: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.schedules.find((s) => s.id === where.id) || null),
      ),
    },
    jobOpening: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.jobOpenings.find((j) => j.id === where.id || j.code === where.code) || null),
      ),
      create: jest.fn(({ data }) => {
        const item = { id: `opening-${db.jobOpenings.length + 1}`, ...data, createdAt: new Date() };
        db.jobOpenings.push(item);
        return Promise.resolve(item);
      }),
      findMany: jest.fn(() => Promise.resolve(db.jobOpenings)),
      count: jest.fn(() => Promise.resolve(db.jobOpenings.length)),
    },
    candidate: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.candidates.find((c) => c.id === where.id || c.email === where.email) || null),
      ),
      create: jest.fn(({ data }) => {
        const item = { id: `cand-${db.candidates.length + 1}`, ...data, createdAt: new Date() };
        db.candidates.push(item);
        return Promise.resolve(item);
      }),
      findMany: jest.fn(() => Promise.resolve(db.candidates)),
      count: jest.fn(() => Promise.resolve(db.candidates.length)),
    },
    jobApplication: {
      findUnique: jest.fn(({ where }) => {
        if (where.jobOpeningId_candidateId) {
          const { jobOpeningId, candidateId } = where.jobOpeningId_candidateId;
          return Promise.resolve(
            db.applications.find((a) => a.jobOpeningId === jobOpeningId && a.candidateId === candidateId) || null,
          );
        }
        const app = db.applications.find((a) => a.id === where.id);
        if (!app) return Promise.resolve(null);
        const opening = db.jobOpenings.find((o) => o.id === app.jobOpeningId);
        const offers = db.offers.filter((o) => o.applicationId === app.id);
        return Promise.resolve({ ...app, jobOpening: opening, offers });
      }),
      create: jest.fn(({ data }) => {
        const item = { id: `app-${db.applications.length + 1}`, ...data, appliedAt: new Date(), createdAt: new Date() };
        db.applications.push(item);
        return Promise.resolve(item);
      }),
      update: jest.fn(({ where, data }) => {
        const app = db.applications.find((a) => a.id === where.id);
        if (app) Object.assign(app, data);
        return Promise.resolve(app);
      }),
      findMany: jest.fn(() => Promise.resolve(db.applications)),
      count: jest.fn(() => Promise.resolve(db.applications.length)),
    },
    interview: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.interviews.find((i) => i.id === where.id) || null),
      ),
      create: jest.fn(({ data }) => {
        const item = { id: `int-${db.interviews.length + 1}`, ...data, createdAt: new Date() };
        db.interviews.push(item);
        return Promise.resolve(item);
      }),
      findMany: jest.fn(() => Promise.resolve(db.interviews)),
      count: jest.fn(() => Promise.resolve(db.interviews.length)),
    },
    interviewEvaluation: {
      upsert: jest.fn(({ create }) => {
        const item = { id: `eval-${db.evaluations.length + 1}`, ...create };
        db.evaluations.push(item);
        return Promise.resolve(item);
      }),
    },
    jobOffer: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.offers.find((o) => o.id === where.id) || null),
      ),
      create: jest.fn(({ data }) => {
        const item = { id: `offer-${db.offers.length + 1}`, ...data, createdAt: new Date() };
        db.offers.push(item);
        return Promise.resolve(item);
      }),
      update: jest.fn(({ where, data }) => {
        const offer = db.offers.find((o) => o.id === where.id);
        if (offer) Object.assign(offer, data);
        return Promise.resolve(offer);
      }),
    },
    user: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.users.find((u) => u.id === where.id || u.email === where.email) || null),
      ),
      create: jest.fn(({ data }) => {
        const userId = `user-${db.users.length + 1}`;
        const profileId = `profile-${db.employeeProfiles.length + 1}`;
        const profileData = data.employeeProfile.create;
        const profile = { id: profileId, userId, ...profileData, createdAt: new Date() };
        const user = { id: userId, email: data.email, role: data.role, employeeProfile: profile };
        db.users.push(user);
        db.employeeProfiles.push(profile);
        return Promise.resolve(user);
      }),
    },
    employeeProfile: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.employeeProfiles.find((p) => p.id === where.id || p.userId === where.userId || p.employeeCode === where.employeeCode) || null),
      ),
      update: jest.fn(({ where, data }) => {
        const profile = db.employeeProfiles.find((p) => p.id === where.id);
        if (profile) Object.assign(profile, data);
        return Promise.resolve(profile);
      }),
      findMany: jest.fn(() => Promise.resolve(db.employeeProfiles)),
      count: jest.fn(() => Promise.resolve(db.employeeProfiles.length)),
    },
    onboardingWorkflow: {
      findUnique: jest.fn(({ where }) => {
        const wf = db.onboardingWorkflows.find((w) => w.id === where.id || w.employeeId === where.employeeId);
        if (!wf) return Promise.resolve(null);
        const tasks = db.onboardingTasks.filter((t) => t.workflowId === wf.id);
        return Promise.resolve({ ...wf, tasks });
      }),
      create: jest.fn(({ data }) => {
        const wfId = `wf-${db.onboardingWorkflows.length + 1}`;
        const tasks = (data.tasks?.create || []).map((t: any, idx: number) => ({
          id: `task-${db.onboardingTasks.length + idx + 1}`,
          workflowId: wfId,
          ...t,
          isCompleted: false,
        }));
        db.onboardingTasks.push(...tasks);
        const wf = {
          id: wfId,
          employeeId: data.employeeId,
          status: data.status,
          startDate: data.startDate,
          targetDate: data.targetDate,
          progressPercentage: 0,
          tasks,
        };
        db.onboardingWorkflows.push(wf);
        return Promise.resolve(wf);
      }),
      update: jest.fn(({ where, data }) => {
        const wf = db.onboardingWorkflows.find((w) => w.id === where.id);
        if (wf) Object.assign(wf, data);
        return Promise.resolve(wf);
      }),
      findMany: jest.fn(() => Promise.resolve(db.onboardingWorkflows)),
      count: jest.fn(() => Promise.resolve(db.onboardingWorkflows.length)),
    },
    onboardingTask: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.onboardingTasks.find((t) => t.id === where.id) || null),
      ),
      findMany: jest.fn(({ where }) =>
        Promise.resolve(db.onboardingTasks.filter((t) => t.workflowId === where.workflowId)),
      ),
      create: jest.fn(({ data }) => {
        const task = { id: `task-${db.onboardingTasks.length + 1}`, ...data };
        db.onboardingTasks.push(task);
        return Promise.resolve(task);
      }),
      update: jest.fn(({ where, data }) => {
        const task = db.onboardingTasks.find((t) => t.id === where.id);
        if (task) Object.assign(task, data);
        return Promise.resolve(task);
      }),
      updateMany: jest.fn(({ where, data }) => {
        const tasks = db.onboardingTasks.filter((t) => t.workflowId === where.workflowId);
        tasks.forEach((t) => Object.assign(t, data));
        return Promise.resolve({ count: tasks.length });
      }),
    },
    employeeDocument: {
      create: jest.fn(({ data }) => {
        const doc = { id: `doc-${db.documents.length + 1}`, ...data, isVerified: false, createdAt: new Date() };
        db.documents.push(doc);
        return Promise.resolve(doc);
      }),
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(db.documents.find((d) => d.id === where.id) || null),
      ),
      findMany: jest.fn(({ where }) =>
        Promise.resolve(db.documents.filter((d) => d.employeeId === where.employeeId)),
      ),
      update: jest.fn(({ where, data }) => {
        const doc = db.documents.find((d) => d.id === where.id);
        if (doc) Object.assign(doc, data);
        return Promise.resolve(doc);
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        const log = { id: `audit-${db.auditLogs.length + 1}`, ...data, createdAt: new Date() };
        db.auditLogs.push(log);
        return Promise.resolve(log);
      }),
    },
    $transaction: jest.fn((callback) => callback(mockPrismaService)),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RecruitmentService,
        OnboardingService,
        HrService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    recruitmentService = module.get<RecruitmentService>(RecruitmentService);
    onboardingService = module.get<OnboardingService>(OnboardingService);
    hrService = module.get<HrService>(HrService);
  });

  it("Step 1: HR opens a requisition (Job Opening)", async () => {
    const opening = await recruitmentService.createJobOpening(
      {
        title: "Principal Cloud Architect",
        code: "ENG-ARCH-01",
        organizationId: "org-1",
        branchId: "branch-1",
        departmentId: "dept-1",
        positionId: "pos-1",
        employmentType: EmploymentType.FULL_TIME,
        status: JobOpeningStatus.OPEN,
        vacancies: 1,
        minSalary: 50000,
        maxSalary: 75000,
      },
      "hr-manager-user",
    );

    expect(opening.id).toBeDefined();
    expect(opening.code).toBe("ENG-ARCH-01");
  });

  it("Step 2: Candidate submits talent application", async () => {
    const candidate = await recruitmentService.createCandidate(
      {
        firstName: "Mostafa",
        lastName: "Mahmoud",
        email: "mostafa.architect@example.com",
        phone: "+201099887766",
        currentTitle: "Lead Architect",
        experienceYears: 10,
        source: CandidateSource.LINKEDIN,
        skills: ["NestJS", "PostgreSQL", "Cloud Architecture", "System Design"],
      },
      "recruiter-user",
    );

    expect(candidate.id).toBeDefined();

    const application = await recruitmentService.createApplication(
      {
        jobOpeningId: db.jobOpenings[0].id,
        candidateId: candidate.id,
        status: ApplicationStatus.APPLIED,
        rating: 5,
        stageNotes: "Candidate has top tier enterprise qualifications",
      },
      "recruiter-user",
    );

    expect(application.id).toBeDefined();
    expect(application.status).toBe(ApplicationStatus.APPLIED);
  });

  it("Step 3: Technical interview is scheduled and evaluated", async () => {
    const interview = await recruitmentService.scheduleInterview(
      {
        applicationId: db.applications[0].id,
        title: "System Design & Architecture Deep Dive",
        interviewType: InterviewType.TECHNICAL,
        scheduledAt: new Date().toISOString(),
        durationMinutes: 60,
        locationOrLink: "https://meet.google.com/xyz-arch",
      },
      "interviewer-lead",
    );

    expect(interview.id).toBeDefined();

    // Application should have automatically transitioned to INTERVIEWING
    expect(db.applications[0].status).toBe(ApplicationStatus.INTERVIEWING);

    const evaluation = await recruitmentService.submitEvaluation(
      interview.id,
      {
        rating: 5,
        recommendation: InterviewRecommendation.STRONG_HIRE,
        strengths: "Flawless distributed systems knowledge and high performance caching strategies",
        comments: "Unanimous hire recommendation for the Architecture lead role",
      },
      "interviewer-lead",
    );

    expect(evaluation.rating).toBe(5);
    expect(evaluation.recommendation).toBe(InterviewRecommendation.STRONG_HIRE);
  });

  it("Step 4: Formal job offer is issued and accepted", async () => {
    const offer = await recruitmentService.createJobOffer(
      {
        applicationId: db.applications[0].id,
        candidateId: db.candidates[0].id,
        positionId: "pos-1",
        departmentId: "dept-1",
        offeredSalary: 70000,
        currency: "EGP",
        proposedStartDate: "2026-10-01",
        status: JobOfferStatus.SENT,
        terms: "3 months probation, medical & family insurance coverage",
      },
      "hr-manager-user",
    );

    expect(offer.id).toBeDefined();
    expect(db.applications[0].status).toBe(ApplicationStatus.OFFERED);
  });

  it("Step 5: Atomic Hiring execution (Creates User, Profile & Onboarding Workflow)", async () => {
    const hiringResult = await recruitmentService.hireCandidate(
      {
        candidateId: db.candidates[0].id,
        applicationId: db.applications[0].id,
        email: "mostafa.mahmoud@cyberwise.com",
        password: "CorporateSecurePassword@2026",
        role: Role.EMPLOYEE,
        organizationId: "org-1",
        branchId: "branch-1",
        departmentId: "dept-1",
        positionId: "pos-1",
        workplaceId: "wp-1",
        scheduleId: "sch-1",
        initiateOnboarding: true,
      },
      "hr-director-user",
    );

    expect(hiringResult.user.email).toBe("mostafa.mahmoud@cyberwise.com");
    expect(hiringResult.employeeProfile.employeeCode).toBeDefined();
    expect(hiringResult.onboardingWorkflow).toBeDefined();
    expect(hiringResult.onboardingWorkflow.tasks.length).toBe(6);

    // Verify application status changed to HIRED
    expect(db.applications[0].status).toBe(ApplicationStatus.HIRED);
    // Verify offer status changed to ACCEPTED
    expect(db.offers[0].status).toBe(JobOfferStatus.ACCEPTED);
  });

  it("Step 6: HR uploads employee document metadata and verifies it", async () => {
    const employeeId = db.employeeProfiles[0].id;

    const document = await hrService.addEmployeeDocument(
      employeeId,
      {
        documentType: EmployeeDocumentType.NATIONAL_ID,
        title: "National Identity Card (Verified Copy)",
        documentNumber: "29801011234567",
        fileUrl: "https://storage.cyberwise.io/documents/nat_id_mostafa.pdf",
      },
      "hr-manager-user",
    );

    expect(document.id).toBeDefined();
    expect(document.isVerified).toBe(false);

    const verifiedDoc = await hrService.verifyEmployeeDocument(
      document.id,
      { isVerified: true, notes: "Verified in person against original ID card" },
      "hr-manager-user",
    );

    expect(verifiedDoc.isVerified).toBe(true);
    expect(verifiedDoc.verifiedById).toBe("hr-manager-user");
  });

  it("Step 7: Employee completes onboarding tasks sequentially until 100% completion", async () => {
    const workflowId = db.onboardingWorkflows[0].id;
    const tasks = db.onboardingTasks.filter((t) => t.workflowId === workflowId);

    expect(tasks.length).toBe(6);

    // Complete task 1
    const res1 = await onboardingService.completeTask(
      tasks[0].id,
      { isCompleted: true, notes: "National ID copy received and verified" },
      "hr-user",
    );
    expect(res1.workflow.progressPercentage).toBeGreaterThan(0);
    expect(res1.workflow.status).toBe(OnboardingStatus.IN_PROGRESS);

    // Complete remaining tasks
    for (let i = 1; i < tasks.length; i++) {
      await onboardingService.completeTask(
        tasks[i].id,
        { isCompleted: true },
        "employee-user",
      );
    }

    // Finalize workflow
    const finalized = await onboardingService.finalizeWorkflow(workflowId, "hr-user");
    expect(finalized.status).toBe(OnboardingStatus.COMPLETED);
    expect(finalized.progressPercentage).toBe(100);

    // Verify employee profile onboarding was completed and unlocked
    const employee = await hrService.getEmployeeById(db.employeeProfiles[0].id);
    expect(employee.isProfileComplete).toBe(true);
    expect(employee.onboardingCompletedAt).toBeDefined();
  });
});
