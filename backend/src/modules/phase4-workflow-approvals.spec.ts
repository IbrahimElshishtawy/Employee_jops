import { Test, TestingModule } from "@nestjs/testing";
import { WorkflowService } from "./workflow/workflow.service";
import { WorkflowRepository } from "./workflow/workflow.repository";
import { ApprovalsService } from "./approvals/approvals.service";
import { ApprovalsRepository } from "./approvals/approvals.repository";
import { RequestsService } from "./requests/requests.service";
import { RequestsRepository } from "./requests/requests.repository";
import { PrismaService } from "../prisma/prisma.service";
import { NotificationsService } from "./notifications/notifications.service";
import {
  ApproverType,
  AttendanceStatus,
  AuditAction,
  RequestStatus,
  RequestType,
  Role,
  UserStatus,
  WorkflowAction,
} from "@prisma/client";
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";

describe("Phase 4 — Workflow, Requests & Approvals Engine Complete Specification", () => {
  let workflowService: WorkflowService;
  let approvalsService: ApprovalsService;
  let requestsService: RequestsService;
  let prismaService: any;
  let notificationsService: any;

  // In-Memory Database Stores
  let mockWorkflows: any[] = [];
  let mockWorkflowSteps: any[] = [];
  let mockDelegations: any[] = [];
  let mockRequests: any[] = [];
  let mockApprovalSteps: any[] = [];
  let mockLeaveBalances: any[] = [];
  let mockAttendanceRecords: any[] = [];
  let mockAuditLogs: any[] = [];
  let mockNotifications: any[] = [];

  // Users Fixtures
  const mockUsers: Record<string, any> = {
    "user-emp": {
      id: "user-emp",
      email: "engineer@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-100",
        userId: "user-emp",
        employeeCode: "CW-100",
        firstName: "Tariq",
        lastName: "Salem",
        department: "Engineering",
        departmentId: "dept-eng",
        managerId: "emp-manager",
        manager: {
          id: "emp-manager",
          userId: "user-manager",
          firstName: "Zaid",
          lastName: "Manager",
          user: { id: "user-manager", email: "manager@cyberwise.test" },
        },
        departmentRel: {
          id: "dept-eng",
          name: "Engineering",
          headOfDepartmentId: "emp-hod",
          headOfDepartment: {
            id: "emp-hod",
            userId: "user-hod",
            firstName: "Hassan",
            lastName: "HOD",
            user: { id: "user-hod", email: "hod@cyberwise.test" },
          },
        },
      },
    },
    "user-manager": {
      id: "user-manager",
      email: "manager@cyberwise.test",
      role: Role.SUPERVISOR,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-manager",
        userId: "user-manager",
        employeeCode: "CW-050",
        firstName: "Zaid",
        lastName: "Manager",
        department: "Engineering",
        departmentId: "dept-eng",
      },
    },
    "user-hod": {
      id: "user-hod",
      email: "hod@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-hod",
        userId: "user-hod",
        employeeCode: "CW-020",
        firstName: "Hassan",
        lastName: "HOD",
        department: "Engineering",
        departmentId: "dept-eng",
      },
    },
    "user-hr-manager": {
      id: "user-hr-manager",
      email: "hrmanager@cyberwise.test",
      role: Role.HR_MANAGER,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-hrm",
        userId: "user-hr-manager",
        employeeCode: "CW-010",
        firstName: "Nadia",
        lastName: "HR",
        department: "Human Resources",
        departmentId: "dept-hr",
      },
    },
    "user-super-admin": {
      id: "user-super-admin",
      email: "admin@cyberwise.test",
      role: Role.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-admin",
        userId: "user-super-admin",
        employeeCode: "CW-001",
        firstName: "CEO",
        lastName: "Admin",
      },
    },
    "user-delegate": {
      id: "user-delegate",
      email: "delegate@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-delegate",
        userId: "user-delegate",
        employeeCode: "CW-055",
        firstName: "Faris",
        lastName: "Delegate",
        department: "Engineering",
        departmentId: "dept-eng",
      },
    },
    "user-stranger": {
      id: "user-stranger",
      email: "stranger@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-stranger",
        userId: "user-stranger",
        employeeCode: "CW-999",
        firstName: "Random",
        lastName: "Person",
        department: "Marketing",
      },
    },
    "user-inactive": {
      id: "user-inactive",
      email: "inactive@cyberwise.test",
      role: Role.SUPERVISOR,
      status: UserStatus.SUSPENDED,
      employeeProfile: {
        id: "emp-inactive",
        userId: "user-inactive",
        employeeCode: "CW-000",
        firstName: "Suspended",
        lastName: "Supervisor",
      },
    },
  };

  beforeEach(async () => {
    mockWorkflows = [];
    mockWorkflowSteps = [];
    mockDelegations = [];
    mockRequests = [];
    mockApprovalSteps = [];
    mockLeaveBalances = [
      {
        id: "bal-1",
        employeeId: "emp-100",
        leaveType: RequestType.ANNUAL_LEAVE,
        year: 2026,
        totalDays: 21,
        usedDays: 0,
        pendingDays: 0,
        remainingDays: 21,
      },
    ];
    mockAttendanceRecords = [];
    mockAuditLogs = [];
    mockNotifications = [];

    prismaService = {
      user: {
        findUnique: jest.fn(({ where }) => {
          const u =
            mockUsers[where.id] ||
            Object.values(mockUsers).find((u) => u.email === where.email);
          return Promise.resolve(u || null);
        }),
      },
      workflowDefinition: {
        findMany: jest.fn(({ where, include, orderBy }) => {
          let list = [...mockWorkflows];
          if (where?.isActive !== undefined)
            list = list.filter((w) => w.isActive === where.isActive);
          if (where?.requestType)
            list = list.filter(
              (w) => !w.requestType || w.requestType === where.requestType,
            );
          if (where?.departmentId)
            list = list.filter(
              (w) => !w.departmentId || w.departmentId === where.departmentId,
            );
          if (where?.role)
            list = list.filter((w) => !w.role || w.role === where.role);

          const priorityOrder = Array.isArray(orderBy)
            ? orderBy.find((o) => o.priority)?.priority
            : orderBy?.priority;
          if (priorityOrder === "desc") {
            list.sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
          }

          if (include?.steps) {
            list = list.map((w) => ({
              ...w,
              steps: mockWorkflowSteps
                .filter((s) => s.workflowId === w.id)
                .sort((a, b) => a.stepOrder - b.stepOrder),
            }));
          }
          return Promise.resolve(list);
        }),
        findUnique: jest.fn(({ where }) => {
          const w = mockWorkflows.find((item) => item.id === where.id);
          if (!w) return Promise.resolve(null);
          const steps = mockWorkflowSteps
            .filter((s) => s.workflowId === w.id)
            .sort((a, b) => a.stepOrder - b.stepOrder);
          return Promise.resolve({ ...w, steps });
        }),
        create: jest.fn(({ data }) => {
          const { steps, ...wfData } = data;
          const newWf = {
            id: `wf-${mockWorkflows.length + 1}`,
            isActive: true,
            priority: 0,
            createdAt: new Date(),
            updatedAt: new Date(),
            ...wfData,
          };
          mockWorkflows.push(newWf);
          if (steps?.create) {
            steps.create.forEach((s: any, idx: number) => {
              mockWorkflowSteps.push({
                id: `step-def-${mockWorkflowSteps.length + 1}`,
                workflowId: newWf.id,
                stepOrder: s.stepOrder ?? idx + 1,
                ...s,
              });
            });
          }
          const finalSteps = mockWorkflowSteps.filter(
            (s) => s.workflowId === newWf.id,
          );
          return Promise.resolve({ ...newWf, steps: finalSteps });
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockWorkflows.findIndex((w) => w.id === where.id);
          if (idx === -1) throw new NotFoundException("Workflow not found");
          mockWorkflows[idx] = {
            ...mockWorkflows[idx],
            ...data,
            updatedAt: new Date(),
          };
          const steps = mockWorkflowSteps.filter(
            (s) => s.workflowId === where.id,
          );
          return Promise.resolve({ ...mockWorkflows[idx], steps });
        }),
        delete: jest.fn(({ where }) => {
          const idx = mockWorkflows.findIndex((w) => w.id === where.id);
          if (idx === -1) throw new NotFoundException("Workflow not found");
          const deleted = mockWorkflows.splice(idx, 1)[0];
          mockWorkflowSteps = mockWorkflowSteps.filter(
            (s) => s.workflowId !== where.id,
          );
          return Promise.resolve(deleted);
        }),
        count: jest.fn(() => Promise.resolve(mockWorkflows.length)),
      },
      workflowStepDefinition: {
        deleteMany: jest.fn(({ where }) => {
          mockWorkflowSteps = mockWorkflowSteps.filter(
            (s) => s.workflowId !== where.workflowId,
          );
          return Promise.resolve({ count: 1 });
        }),
        createMany: jest.fn(({ data }) => {
          data.forEach((s: any) =>
            mockWorkflowSteps.push({ id: `step-def-${Date.now()}`, ...s }),
          );
          return Promise.resolve({ count: data.length });
        }),
      },
      approvalDelegation: {
        findMany: jest.fn(({ where, include }) => {
          let list = [...mockDelegations];
          if (where?.delegateId)
            list = list.filter((d) => d.delegateId === where.delegateId);
          if (where?.delegatorId)
            list = list.filter((d) => d.delegatorId === where.delegatorId);
          if (where?.isActive !== undefined)
            list = list.filter((d) => d.isActive === where.isActive);
          if (where?.startDate?.lte && where?.endDate?.gte) {
            const now = where.startDate.lte;
            list = list.filter(
              (d) => new Date(d.startDate) <= now && new Date(d.endDate) >= now,
            );
          }
          if (include?.delegator) {
            list = list.map((d) => ({
              ...d,
              delegator: mockUsers[d.delegatorId] || {
                id: d.delegatorId,
                email: "delegator@test.com",
              },
              delegate: mockUsers[d.delegateId] || {
                id: d.delegateId,
                email: "delegate@test.com",
              },
            }));
          }
          return Promise.resolve(list);
        }),
        findUnique: jest.fn(({ where }) => {
          return Promise.resolve(
            mockDelegations.find((d) => d.id === where.id) || null,
          );
        }),
        create: jest.fn(({ data }) => {
          const newDel = {
            id: `del-${mockDelegations.length + 1}`,
            isActive: true,
            createdAt: new Date(),
            ...data,
          };
          mockDelegations.push(newDel);
          return Promise.resolve(newDel);
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockDelegations.findIndex((d) => d.id === where.id);
          if (idx === -1) throw new NotFoundException("Delegation not found");
          mockDelegations[idx] = { ...mockDelegations[idx], ...data };
          return Promise.resolve(mockDelegations[idx]);
        }),
      },
      approvalStep: {
        findFirst: jest.fn(({ where }) => {
          return Promise.resolve(
            mockApprovalSteps.find(
              (s) =>
                s.requestId === where.requestId &&
                s.stepOrder === where.stepOrder,
            ) || null,
          );
        }),
        findMany: jest.fn(({ where }) => {
          return Promise.resolve(
            mockApprovalSteps.filter(
              (s) => !where?.requestId || s.requestId === where.requestId,
            ),
          );
        }),
        create: jest.fn(({ data }) => {
          const step = {
            id: `step-${mockApprovalSteps.length + 1}`,
            createdAt: new Date(),
            ...data,
          };
          mockApprovalSteps.push(step);
          return Promise.resolve(step);
        }),
      },
      request: {
        findUnique: jest.fn(({ where }) => {
          const req = mockRequests.find(
            (r) =>
              r.id === where.id ||
              (where.idempotencyKey &&
                r.idempotencyKey === where.idempotencyKey),
          );
          if (!req) return Promise.resolve(null);
          const empUser = Object.values(mockUsers).find(
            (u) => u.employeeProfile?.id === req.employeeId,
          );
          const wf = mockWorkflows.find((w) => w.id === req.workflowId);
          const wfSteps = wf
            ? mockWorkflowSteps
                .filter((s) => s.workflowId === wf.id)
                .sort((a, b) => a.stepOrder - b.stepOrder)
            : [];
          const appSteps = mockApprovalSteps.filter(
            (s) => s.requestId === req.id,
          );

          return Promise.resolve({
            ...req,
            employee: empUser
              ? {
                  ...empUser.employeeProfile,
                  user: { id: empUser.id, email: empUser.email },
                }
              : null,
            workflow: wf ? { ...wf, steps: wfSteps } : null,
            approvalSteps: appSteps,
          });
        }),
        findFirst: jest.fn(({ where }) => {
          return Promise.resolve(
            mockRequests.find(
              (r) =>
                r.employeeId === where.employeeId &&
                r.status === where.status &&
                r.startDate <= where.startDate?.lte &&
                r.endDate >= where.endDate?.gte,
            ) || null,
          );
        }),
        findMany: jest.fn(({ where, skip = 0, take = 10 }) => {
          let list = [...mockRequests];
          if (where?.status)
            list = list.filter((r) => r.status === where.status);
          if (where?.type) list = list.filter((r) => r.type === where.type);
          if (where?.employeeId)
            list = list.filter((r) => r.employeeId === where.employeeId);

          return Promise.resolve(
            list.slice(skip, skip + take).map((r) => {
              const empUser = Object.values(mockUsers).find(
                (u) => u.employeeProfile?.id === r.employeeId,
              );
              return {
                ...r,
                employee: empUser?.employeeProfile || null,
                approvalSteps: mockApprovalSteps.filter(
                  (s) => s.requestId === r.id,
                ),
              };
            }),
          );
        }),
        count: jest.fn(({ where }) => {
          let list = [...mockRequests];
          if (where?.status)
            list = list.filter((r) => r.status === where.status);
          if (where?.employeeId)
            list = list.filter((r) => r.employeeId === where.employeeId);
          return Promise.resolve(list.length);
        }),
        create: jest.fn(({ data }) => {
          const newReq = {
            id: `req-${mockRequests.length + 1}`,
            status: RequestStatus.PENDING,
            currentStepOrder: 1,
            totalSteps: 1,
            createdAt: new Date(),
            updatedAt: new Date(),
            ...data,
          };
          mockRequests.push(newReq);
          return Promise.resolve(newReq);
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockRequests.findIndex((r) => r.id === where.id);
          if (idx === -1) throw new NotFoundException("Request not found");
          mockRequests[idx] = {
            ...mockRequests[idx],
            ...data,
            updatedAt: new Date(),
          };
          return Promise.resolve(mockRequests[idx]);
        }),
      },
      leaveBalance: {
        findUnique: jest.fn(({ where }) => {
          if (where.employeeId_leaveType_year) {
            const { employeeId, leaveType, year } =
              where.employeeId_leaveType_year;
            return Promise.resolve(
              mockLeaveBalances.find(
                (b) =>
                  b.employeeId === employeeId &&
                  b.leaveType === leaveType &&
                  b.year === year,
              ) || null,
            );
          }
          return Promise.resolve(null);
        }),
        create: jest.fn(({ data }) => {
          const newBal = { id: `bal-${mockLeaveBalances.length + 1}`, ...data };
          mockLeaveBalances.push(newBal);
          return Promise.resolve(newBal);
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockLeaveBalances.findIndex((b) => b.id === where.id);
          if (idx !== -1) {
            mockLeaveBalances[idx] = { ...mockLeaveBalances[idx], ...data };
            return Promise.resolve(mockLeaveBalances[idx]);
          }
          return Promise.resolve(null);
        }),
        upsert: jest.fn(({ where, update, create }) => {
          const { employeeId, leaveType, year } =
            where.employeeId_leaveType_year;
          const existing = mockLeaveBalances.find(
            (b) =>
              b.employeeId === employeeId &&
              b.leaveType === leaveType &&
              b.year === year,
          );
          if (existing) {
            if (update.usedDays?.increment)
              existing.usedDays += update.usedDays.increment;
            if (update.remainingDays?.decrement)
              existing.remainingDays -= update.remainingDays.decrement;
            return Promise.resolve(existing);
          }
          const newBal = {
            id: `bal-${mockLeaveBalances.length + 1}`,
            ...create,
          };
          mockLeaveBalances.push(newBal);
          return Promise.resolve(newBal);
        }),
      },
      attendanceRecord: {
        findUnique: jest.fn(({ where }) => {
          return Promise.resolve(
            mockAttendanceRecords.find(
              (a) =>
                a.employeeId === where.employeeId_date?.employeeId &&
                a.date?.toISOString() ===
                  where.employeeId_date?.date?.toISOString(),
            ) || null,
          );
        }),
        upsert: jest.fn(({ where, update, create }) => {
          const idx = mockAttendanceRecords.findIndex(
            (a) =>
              a.employeeId === where.employeeId_date?.employeeId &&
              a.date?.toISOString() ===
                where.employeeId_date?.date?.toISOString(),
          );
          if (idx !== -1) {
            mockAttendanceRecords[idx] = {
              ...mockAttendanceRecords[idx],
              ...update,
            };
            return Promise.resolve(mockAttendanceRecords[idx]);
          }
          const newAtt = {
            id: `att-${mockAttendanceRecords.length + 1}`,
            ...create,
          };
          mockAttendanceRecords.push(newAtt);
          return Promise.resolve(newAtt);
        }),
      },
      auditLog: {
        create: jest.fn(({ data }) => {
          const log = {
            id: `audit-${mockAuditLogs.length + 1}`,
            createdAt: new Date(),
            ...data,
          };
          mockAuditLogs.push(log);
          return Promise.resolve(log);
        }),
      },
      $transaction: jest.fn((callback) => callback(prismaService)),
    };

    notificationsService = {
      sendNotification: jest.fn((userId, title, body, type, data) => {
        const notif = {
          id: `notif-${mockNotifications.length + 1}`,
          userId,
          title,
          body,
          type,
          data,
        };
        mockNotifications.push(notif);
        return Promise.resolve(notif);
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WorkflowService,
        WorkflowRepository,
        ApprovalsService,
        ApprovalsRepository,
        RequestsService,
        RequestsRepository,
        { provide: PrismaService, useValue: prismaService },
        { provide: NotificationsService, useValue: notificationsService },
      ],
    }).compile();

    workflowService = module.get<WorkflowService>(WorkflowService);
    approvalsService = module.get<ApprovalsService>(ApprovalsService);
    requestsService = module.get<RequestsService>(RequestsService);
  });

  // =========================================================================
  // 1. WORKFLOW DEFINITIONS & MATCHING ENGINE
  // =========================================================================
  describe("1. Workflow Definitions & Rule Matching", () => {
    it("1.1 Creates a multi-level workflow definition with ordered steps", async () => {
      const wf = await workflowService.create(
        {
          name: "Engineering Leave Approval Pipeline",
          description: "3-tier approval for engineering department",
          requestType: RequestType.ANNUAL_LEAVE,
          departmentId: "dept-eng",
          minDays: 1,
          maxDays: 30,
          priority: 10,
          isActive: true,
          steps: [
            {
              stepOrder: 1,
              name: "Direct Manager Approval",
              approverType: ApproverType.DIRECT_MANAGER,
              isMandatory: true,
              canDelegate: true,
            },
            {
              stepOrder: 2,
              name: "Head of Department Approval",
              approverType: ApproverType.HEAD_OF_DEPARTMENT,
              isMandatory: true,
              canDelegate: true,
            },
            {
              stepOrder: 3,
              name: "HR Manager Sign-off",
              approverType: ApproverType.SPECIFIC_ROLE,
              role: Role.HR_MANAGER,
              isMandatory: true,
              canDelegate: false,
            },
          ],
        },
        "user-super-admin",
      );

      expect(wf).toBeDefined();
      expect(wf.name).toBe("Engineering Leave Approval Pipeline");
      expect((wf as any).steps.length).toBe(3);
      expect((wf as any).steps[0].stepOrder).toBe(1);
      expect((wf as any).steps[1].stepOrder).toBe(2);
      expect((wf as any).steps[2].stepOrder).toBe(3);
    });

    it("1.2 Rejects workflow creation with duplicate step orders", async () => {
      await expect(
        workflowService.create({
          name: "Invalid Duplicate Steps",
          steps: [
            {
              stepOrder: 1,
              name: "Step 1",
              approverType: ApproverType.DIRECT_MANAGER,
            },
            {
              stepOrder: 1,
              name: "Step 1 Duplicate",
              approverType: ApproverType.HEAD_OF_DEPARTMENT,
            },
          ],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("1.3 Rejects SPECIFIC_ROLE step without role or SPECIFIC_USER without userId", async () => {
      await expect(
        workflowService.create({
          name: "Missing Role",
          steps: [
            {
              stepOrder: 1,
              name: "Role Step",
              approverType: ApproverType.SPECIFIC_ROLE,
            },
          ],
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        workflowService.create({
          name: "Missing User",
          steps: [
            {
              stepOrder: 1,
              name: "User Step",
              approverType: ApproverType.SPECIFIC_USER,
            },
          ],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("1.4 Rule Matcher selects the highest-priority matching workflow", async () => {
      // 1. Generic Workflow (priority 0)
      await workflowService.create({
        name: "Default Annual Leave Workflow",
        requestType: RequestType.ANNUAL_LEAVE,
        priority: 0,
        steps: [
          {
            stepOrder: 1,
            name: "Manager",
            approverType: ApproverType.DIRECT_MANAGER,
          },
        ],
      });

      // 2. Specific Engineering Workflow (priority 10)
      await workflowService.create({
        name: "Engineering 3-Tier Workflow",
        requestType: RequestType.ANNUAL_LEAVE,
        departmentId: "dept-eng",
        priority: 10,
        steps: [
          {
            stepOrder: 1,
            name: "Manager",
            approverType: ApproverType.DIRECT_MANAGER,
          },
          {
            stepOrder: 2,
            name: "HOD",
            approverType: ApproverType.HEAD_OF_DEPARTMENT,
          },
        ],
      });

      const matched = await workflowService.matchWorkflow({
        requestType: RequestType.ANNUAL_LEAVE,
        departmentId: "dept-eng",
        role: Role.EMPLOYEE,
        days: 3,
      });

      expect(matched.workflowName).toBe("Engineering 3-Tier Workflow");
      expect(matched.totalSteps).toBe(2);
    });

    it("1.5 Falls back to system default workflow when no rule matches", async () => {
      const matched = await workflowService.matchWorkflow({
        requestType: RequestType.DOCUMENT_REQUEST,
        departmentId: "dept-sales",
        role: Role.EMPLOYEE,
      });

      expect(matched.workflowId).toBeNull();
      expect(matched.totalSteps).toBe(1);
      expect(matched.steps[0].approverType).toBe(ApproverType.DIRECT_MANAGER);
    });
  });

  // =========================================================================
  // 2. REQUEST SUBMISSION & MULTI-LEVEL APPROVAL FLOW
  // =========================================================================
  describe("2. Request Submission & Multi-Level Sequential Approval", () => {
    let multiLevelWorkflowId: string;

    beforeEach(async () => {
      const wf = await workflowService.create({
        name: "Engineering Multi-Level Pipeline",
        requestType: RequestType.ANNUAL_LEAVE,
        departmentId: "dept-eng",
        priority: 10,
        steps: [
          {
            stepOrder: 1,
            name: "Direct Manager",
            approverType: ApproverType.DIRECT_MANAGER,
          },
          {
            stepOrder: 2,
            name: "Head of Department",
            approverType: ApproverType.HEAD_OF_DEPARTMENT,
          },
          {
            stepOrder: 3,
            name: "HR Manager",
            approverType: ApproverType.SPECIFIC_ROLE,
            role: Role.HR_MANAGER,
          },
        ],
      });
      multiLevelWorkflowId = wf.id;
    });

    it("2.1 Submitting a request assigns matched workflow with totalSteps = 3 and currentStepOrder = 1", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      expect(req.workflowId).toBe(multiLevelWorkflowId);
      expect(req.totalSteps).toBe(3);
      expect(req.currentStepOrder).toBe(1);
      expect(req.status).toBe(RequestStatus.PENDING);
    });

    it("2.2 Step 1 Approval (Manager) advances request to step 2 while status remains PENDING", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      const res = await approvalsService.processApprovalStep(
        req.id,
        "user-manager",
        {
          action: WorkflowAction.APPROVE,
          comment: "Manager approved, proceed to HOD",
        },
      );

      expect(res.status).toBe(RequestStatus.PENDING);
      expect(res.currentStepOrder).toBe(2);
      expect(mockApprovalSteps.length).toBe(1);
      expect(mockApprovalSteps[0].stepOrder).toBe(1);
      expect(mockApprovalSteps[0].approverId).toBe("user-manager");
    });

    it("2.3 Step 2 Approval (HOD) advances request to step 3 while status remains PENDING", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      // Step 1
      await approvalsService.processApprovalStep(req.id, "user-manager", {
        action: WorkflowAction.APPROVE,
      });

      // Step 2
      const res = await approvalsService.processApprovalStep(
        req.id,
        "user-hod",
        {
          action: WorkflowAction.APPROVE,
          comment: "HOD approved, proceed to HR",
        },
      );

      expect(res.status).toBe(RequestStatus.PENDING);
      expect(res.currentStepOrder).toBe(3);
      expect(mockApprovalSteps.length).toBe(2);
    });

    it("2.4 Step 3 Final Approval (HR Manager) marks request as APPROVED and executes side-effects", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12", // 3 days
        reason: "Vacation",
      });

      // Step 1: Manager
      await approvalsService.processApprovalStep(req.id, "user-manager", {
        action: WorkflowAction.APPROVE,
      });
      // Step 2: HOD
      await approvalsService.processApprovalStep(req.id, "user-hod", {
        action: WorkflowAction.APPROVE,
      });
      // Step 3: HR Manager (Final)
      const finalRes = await approvalsService.processApprovalStep(
        req.id,
        "user-hr-manager",
        {
          action: WorkflowAction.APPROVE,
          comment: "HR final sign-off complete",
        },
      );

      expect(finalRes.status).toBe(RequestStatus.APPROVED);

      // Verify Side Effect: Leave Balance Deducted (21 - 3 = 18 remaining)
      const balance = mockLeaveBalances.find((b) => b.employeeId === "emp-100");
      expect(balance.remainingDays).toBe(18);
      expect(balance.usedDays).toBe(3);

      // Verify Side Effect: Attendance records created as ON_LEAVE
      expect(mockAttendanceRecords.length).toBe(3);
      expect(
        mockAttendanceRecords.every(
          (a) => a.status === AttendanceStatus.ON_LEAVE,
        ),
      ).toBe(true);

      // Verify Audit Log & Notifications
      expect(
        mockAuditLogs.some((l) => l.action === AuditAction.REQUEST_APPROVED),
      ).toBe(true);
      expect(notificationsService.sendNotification).toHaveBeenCalled();
    });
  });

  // =========================================================================
  // 3. REJECTIONS & TERMINATION
  // =========================================================================
  describe("3. Rejection & Workflow Termination", () => {
    it("3.1 Rejection at any step immediately terminates workflow with REJECTED status", async () => {
      await workflowService.create({
        name: "Engineering Multi-Level Pipeline",
        requestType: RequestType.ANNUAL_LEAVE,
        departmentId: "dept-eng",
        priority: 10,
        steps: [
          {
            stepOrder: 1,
            name: "Direct Manager",
            approverType: ApproverType.DIRECT_MANAGER,
          },
          {
            stepOrder: 2,
            name: "Head of Department",
            approverType: ApproverType.HEAD_OF_DEPARTMENT,
          },
        ],
      });

      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      const res = await approvalsService.processApprovalStep(
        req.id,
        "user-manager",
        {
          action: WorkflowAction.REJECT,
          rejectionReason: "Project deadline week — cannot take leave",
        },
      );

      expect(res.status).toBe(RequestStatus.REJECTED);
      expect(res.rejectionReason).toBe(
        "Project deadline week — cannot take leave",
      );

      // Verify leave balance was NOT deducted
      const balance = mockLeaveBalances.find((b) => b.employeeId === "emp-100");
      expect(balance.remainingDays).toBe(21);
      expect(balance.usedDays).toBe(0);

      // Attempting to approve after rejection must fail
      await expect(
        approvalsService.processApprovalStep(req.id, "user-hod", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("3.2 Rejection without non-empty reason is rejected with BadRequestException", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await expect(
        approvalsService.processApprovalStep(req.id, "user-manager", {
          action: WorkflowAction.REJECT,
          rejectionReason: "",
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // =========================================================================
  // 4. AUTHORITY DELEGATION
  // =========================================================================
  describe("4. Authority Delegation", () => {
    it("4.1 Manager delegates approval authority to substitute colleague", async () => {
      const delegation = await approvalsService.createDelegation(
        "user-manager",
        {
          delegateId: "user-delegate",
          startDate: "2026-09-01",
          endDate: "2026-09-30",
          reason: "Annual leave handover",
        },
      );

      expect(delegation).toBeDefined();
      expect(delegation.delegatorId).toBe("user-manager");
      expect(delegation.delegateId).toBe("user-delegate");
      expect(delegation.isActive).toBe(true);
    });

    it("4.2 Delegate approves request on behalf of manager during active window", async () => {
      await approvalsService.createDelegation("user-manager", {
        delegateId: "user-delegate",
        startDate: "2026-09-01",
        endDate: "2026-09-30",
        reason: "Annual leave handover",
      });

      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      const res = await approvalsService.processApprovalStep(
        req.id,
        "user-delegate",
        {
          action: WorkflowAction.APPROVE,
          comment: "Approved by delegated authority",
        },
      );

      expect(res.status).toBe(RequestStatus.APPROVED);
      expect(mockApprovalSteps.length).toBe(1);
      expect(mockApprovalSteps[0].approverId).toBe("user-delegate");
      expect(mockApprovalSteps[0].isDelegated).toBe(true);
      expect(mockApprovalSteps[0].delegatedById).toBe("user-manager");
    });

    it("4.3 Expired delegation is not accepted", async () => {
      await approvalsService.createDelegation("user-manager", {
        delegateId: "user-delegate",
        startDate: "2026-01-01",
        endDate: "2026-01-10", // expired
        reason: "Past delegation",
      });

      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await expect(
        approvalsService.processApprovalStep(req.id, "user-delegate", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("4.4 Revoked delegation prevents further approvals", async () => {
      const del = await approvalsService.createDelegation("user-manager", {
        delegateId: "user-delegate",
        startDate: "2026-09-01",
        endDate: "2026-09-30",
        reason: "Temporary delegation",
      });

      // Revoke
      await approvalsService.revokeDelegation(del.id, "user-manager");

      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await expect(
        approvalsService.processApprovalStep(req.id, "user-delegate", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // =========================================================================
  // 5. SECURITY, ZERO-TRUST & EDGE CASES
  // =========================================================================
  describe("5. Security, Zero-Trust & Edge Cases", () => {
    it("5.1 Unauthorized user (stranger) is rejected with ForbiddenException", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await expect(
        approvalsService.processApprovalStep(req.id, "user-stranger", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("5.2 Out-of-order approval attempt (e.g. HOD approving Step 1 before Manager) is rejected", async () => {
      await workflowService.create({
        name: "Multi-Tier",
        requestType: RequestType.ANNUAL_LEAVE,
        departmentId: "dept-eng",
        priority: 10,
        steps: [
          {
            stepOrder: 1,
            name: "Manager Step",
            approverType: ApproverType.DIRECT_MANAGER,
          },
          {
            stepOrder: 2,
            name: "HOD Step",
            approverType: ApproverType.HEAD_OF_DEPARTMENT,
          },
        ],
      });

      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      // HOD attempts to approve step 1 (which requires DIRECT_MANAGER)
      await expect(
        approvalsService.processApprovalStep(req.id, "user-hod", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("5.3 Inactive or suspended approver cannot process approvals", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await expect(
        approvalsService.processApprovalStep(req.id, "user-inactive", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("5.4 Super Admin can override and approve any step in the pipeline", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      const res = await approvalsService.processApprovalStep(
        req.id,
        "user-super-admin",
        {
          action: WorkflowAction.APPROVE,
          comment: "Executive bypass approval",
        },
      );

      expect(res.status).toBe(RequestStatus.APPROVED);
    });

    it("5.5 Double approval attempt on already approved request throws BadRequestException", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await approvalsService.processApprovalStep(req.id, "user-manager", {
        action: WorkflowAction.APPROVE,
      });

      await expect(
        approvalsService.processApprovalStep(req.id, "user-manager", {
          action: WorkflowAction.APPROVE,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // =========================================================================
  // 6. PENDING QUEUES & AUDIT HISTORY
  // =========================================================================
  describe("6. Pending Approvals Queue & History", () => {
    it("6.1 Direct Manager sees pending requests from direct reports", async () => {
      await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      const queue = await approvalsService.getPendingApprovals("user-manager", {
        page: 1,
        limit: 10,
      });
      expect(queue.data.length).toBe(1);
      expect(queue.meta.total).toBe(1);
    });

    it("6.2 Unrelated employee does not see another employee's request in pending queue", async () => {
      await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      const queue = await approvalsService.getPendingApprovals(
        "user-stranger",
        { page: 1, limit: 10 },
      );
      expect(queue.data.length).toBe(0);
    });

    it("6.3 Retrieves full approval history and chronological step audit trail", async () => {
      const req = await requestsService.create("user-emp", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-12",
        reason: "Vacation",
      });

      await approvalsService.processApprovalStep(req.id, "user-manager", {
        action: WorkflowAction.APPROVE,
        comment: "Looks good",
      });

      const history = await approvalsService.getApprovalHistory(req.id);
      expect(history.length).toBe(1);
      expect(history[0].approverId).toBe("user-manager");
    });
  });
});
