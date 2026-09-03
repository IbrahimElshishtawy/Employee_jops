import { Test, TestingModule } from "@nestjs/testing";
import { DepartmentOperationsService } from "./department-operations.service";
import { DepartmentOperationsRepository } from "./department-operations.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ServiceRequestsService } from "../service-requests/service-requests.service";
import { DepartmentAccessGuard } from "./guards/department-access.guard";
import {
  AttendanceStatus,
  AuditAction,
  HandoverStatus,
  Role,
  ServiceRequestPriority,
  ServiceRequestStatus,
  TaskStatus,
  UserStatus,
} from "@prisma/client";
import { NotFoundException } from "@nestjs/common";

describe("DepartmentOperationsService (Phase 7 Department Operations)", () => {
  let service: DepartmentOperationsService;
  let guard: DepartmentAccessGuard;

  const mockDepartmentId = "dept-engineering";
  const mockDeptHeadUserId = "user-head-eng";

  const mockDepartment = {
    id: mockDepartmentId,
    name: "Software Engineering",
    code: "ENG",
    isActive: true,
    headOfDepartmentId: "emp-head-eng",
    headOfDepartment: {
      id: "emp-head-eng",
      firstName: "Hassan",
      lastName: "Director",
      jobTitle: "VP of Engineering",
    },
  };

  let mockAuditLogs: any[] = [];

  const mockPrismaService: any = {
    department: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === mockDepartmentId)
          return Promise.resolve(mockDepartment);
        return Promise.resolve(null);
      }),
    },
    employeeProfile: {
      count: jest.fn().mockResolvedValue(15),
      findMany: jest.fn().mockResolvedValue([
        {
          id: "emp-eng-1",
          firstName: "Tariq",
          lastName: "Salem",
          jobTitle: "Senior Backend Engineer",
          assignedTasks: [{ id: "t1" }, { id: "t2" }],
          serviceRequestsAssigned: [{ id: "sr1" }],
        },
        {
          id: "emp-eng-2",
          firstName: "Layla",
          lastName: "Mahmoud",
          jobTitle: "Frontend Engineer",
          assignedTasks: [{ id: "t3" }],
          serviceRequestsAssigned: [],
        },
      ]),
      findUnique: jest.fn(({ where }) => {
        if (where.userId === mockDeptHeadUserId) {
          return Promise.resolve({
            id: "emp-head-eng",
            departmentId: mockDepartmentId,
          });
        }
        if (where.userId === "user-eng-staff") {
          return Promise.resolve({
            id: "emp-eng-1",
            departmentId: mockDepartmentId,
          });
        }
        if (where.userId === "user-stranger") {
          return Promise.resolve({
            id: "emp-stranger",
            departmentId: "dept-marketing",
          });
        }
        return Promise.resolve(null);
      }),
    },
    attendanceRecord: {
      count: jest.fn().mockResolvedValue(12), // 12 on duty today
    },
    task: {
      groupBy: jest.fn().mockResolvedValue([
        { status: TaskStatus.TODO, _count: { id: 4 } },
        { status: TaskStatus.IN_PROGRESS, _count: { id: 5 } },
        { status: TaskStatus.COMPLETED, _count: { id: 10 } },
        { status: TaskStatus.OVERDUE, _count: { id: 1 } },
      ]),
      count: jest.fn().mockImplementation(({ where }) => {
        if (where.status === TaskStatus.COMPLETED) return Promise.resolve(8);
        return Promise.resolve(10); // 10 total
      }),
    },
    serviceRequest: {
      groupBy: jest.fn().mockResolvedValue([
        { status: ServiceRequestStatus.SUBMITTED, _count: { id: 2 } },
        { status: ServiceRequestStatus.IN_PROGRESS, _count: { id: 3 } },
        { status: ServiceRequestStatus.COMPLETED, _count: { id: 7 } },
      ]),
      count: jest.fn().mockImplementation(({ where }) => {
        if (where.priority) return Promise.resolve(1); // urgent count
        if (where.status) return Promise.resolve(7); // completed count
        return Promise.resolve(8); // total count
      }),
      findMany: jest.fn().mockResolvedValue([
        {
          createdAt: new Date("2026-09-01T09:00:00Z"),
          completedAt: new Date("2026-09-01T13:00:00Z"), // 4 hours
        },
        {
          createdAt: new Date("2026-09-02T10:00:00Z"),
          completedAt: new Date("2026-09-02T16:00:00Z"), // 6 hours
        },
      ]),
      update: jest.fn().mockResolvedValue({
        id: "sr-1",
        priority: ServiceRequestPriority.URGENT,
      }),
      findUnique: jest.fn().mockResolvedValue({
        id: "sr-1",
        title: "Database index issue",
        priority: ServiceRequestPriority.URGENT,
        assignedTo: { id: "emp-eng-1", firstName: "Tariq", lastName: "Salem" },
      }),
    },
    shiftHandover: {
      findFirst: jest.fn().mockResolvedValue({
        id: "ho-1",
        handoverNumber: "HO-20260903-0001",
        shiftName: "Day Shift",
        status: HandoverStatus.ACKNOWLEDGED,
        acknowledgedAt: new Date(),
        handedOverBy: { firstName: "Ali", lastName: "Lead" },
        receivedBy: { firstName: "Khaled", lastName: "Lead" },
      }),
      count: jest.fn().mockImplementation(({ where }) => {
        if (where.status === HandoverStatus.ACKNOWLEDGED)
          return Promise.resolve(4);
        return Promise.resolve(5); // 5 total handovers
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        mockAuditLogs.push(data);
        return Promise.resolve(data);
      }),
    },
  };

  const mockServiceRequestsService = {
    assignServiceRequest: jest.fn().mockResolvedValue({
      id: "sr-1",
      departmentId: mockDepartmentId,
      assignedToId: "emp-eng-1",
      priority: ServiceRequestPriority.MEDIUM,
    }),
  };

  beforeEach(async () => {
    mockAuditLogs = [];

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DepartmentOperationsService,
        DepartmentOperationsRepository,
        DepartmentAccessGuard,
        { provide: PrismaService, useValue: mockPrismaService },
        {
          provide: ServiceRequestsService,
          useValue: mockServiceRequestsService,
        },
      ],
    }).compile();

    service = module.get<DepartmentOperationsService>(
      DepartmentOperationsService,
    );
    guard = module.get<DepartmentAccessGuard>(DepartmentAccessGuard);

    jest.clearAllMocks();
  });

  describe("1. Department Operational Overview Telemetry", () => {
    it("should retrieve department operational summary with real-time staffing, tasks, and service requests", async () => {
      const overview = await service.getOverview(mockDeptHeadUserId, {
        departmentId: mockDepartmentId,
      });

      expect(overview.department?.name).toBe("Software Engineering");
      expect(overview.staffing.totalEmployees).toBe(15);
      expect(overview.staffing.onDutyPresent).toBe(12);

      // Tasks
      expect(overview.tasks.activeCount).toBe(10); // 4 todo + 5 in progress + 1 overdue
      expect(overview.tasks.breakdown.TODO).toBe(4);

      // Service Requests
      expect(overview.serviceRequests.activeCount).toBe(5); // 2 submitted + 3 in progress
      expect(overview.serviceRequests.urgentCount).toBe(1);

      // Handover
      expect(overview.handover).toBeDefined();
      expect(overview.handover?.handoverNumber).toBe("HO-20260903-0001");

      // Audit Log recorded
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.DEPARTMENT_OPERATION_LOGGED &&
          a.entityId === mockDepartmentId,
      );
      expect(audit).toBeDefined();
    });

    it("should throw NotFoundException for non-existent department", async () => {
      await expect(
        service.getOverview(mockDeptHeadUserId, {
          departmentId: "dept-unknown",
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe("2. Service Request Triage", () => {
    it("should triage and assign a service request with priority escalation", async () => {
      const result = await service.triageServiceRequest(mockDeptHeadUserId, {
        serviceRequestId: "sr-1",
        assignedToId: "emp-eng-1",
        priority: ServiceRequestPriority.URGENT,
        notes: "Escalated for immediate production hotfix",
      });

      expect(result?.assignedTo?.id).toBe("emp-eng-1");
      expect(
        mockServiceRequestsService.assignServiceRequest,
      ).toHaveBeenCalledWith(
        "sr-1",
        mockDeptHeadUserId,
        expect.objectContaining({ assignedToId: "emp-eng-1" }),
      );

      // Audit log
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.DEPARTMENT_OPERATION_LOGGED &&
          a.payload.action === "TRIAGE_SERVICE_REQUEST",
      );
      expect(audit).toBeDefined();
    });
  });

  describe("3. Department Operational KPIs & Reporting", () => {
    it("should calculate resolution SLA, completion rates, and workload distribution", async () => {
      const report: any = await service.getOperationalReport(
        mockDeptHeadUserId,
        {
          departmentId: mockDepartmentId,
          startDate: "2026-09-01",
          endDate: "2026-09-30",
          exportCsv: false,
        },
      );

      expect(report.department.code).toBe("ENG");
      expect(report.tasks.completionRate).toBe(80); // 8/10 * 100
      expect(report.serviceRequests.resolutionRate).toBe(87.5); // 7/8 * 100
      expect(report.serviceRequests.averageResolutionHours).toBe(5); // (4 + 6) / 2 = 5 hrs
      expect(report.handovers.complianceRate).toBe(80); // 4/5 * 100

      // Workload distribution
      expect(report.workloadDistribution).toHaveLength(2);
      expect(report.workloadDistribution[0].totalActiveItems).toBe(3); // 2 tasks + 1 request
      expect(report.workloadDistribution[1].totalActiveItems).toBe(1); // 1 task + 0 request
    });

    it("should export operational KPI report as sanitized CSV", async () => {
      const csv = await service.getOperationalReport(mockDeptHeadUserId, {
        departmentId: mockDepartmentId,
        startDate: "2026-09-01",
        endDate: "2026-09-30",
        exportCsv: true,
      });

      expect(typeof csv).toBe("string");
      expect(csv).toContain('"Employee ID","Employee Name","Job Title"');
      expect(csv).toContain('"Tariq Salem"');
      expect(csv).toContain('"Layla Mahmoud"');
    });
  });
});
