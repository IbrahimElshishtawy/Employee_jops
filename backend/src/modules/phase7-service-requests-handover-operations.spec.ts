import { Test, TestingModule } from "@nestjs/testing";
import { ServiceRequestsService } from "./service-requests/service-requests.service";
import { ServiceRequestsRepository } from "./service-requests/service-requests.repository";
import { HandoverService } from "./handover/handover.service";
import { HandoverRepository } from "./handover/handover.repository";
import { DepartmentOperationsService } from "./department-operations/department-operations.service";
import { DepartmentOperationsRepository } from "./department-operations/department-operations.repository";
import { ServiceRequestAccessGuard } from "./service-requests/guards/service-request-access.guard";
import { HandoverAccessGuard } from "./handover/guards/handover-access.guard";
import { DepartmentAccessGuard } from "./department-operations/guards/department-access.guard";
import { PrismaService } from "../prisma/prisma.service";
import { NotificationsService } from "./notifications/notifications.service";
import { WorkflowService } from "./workflow/workflow.service";
import {
  AuditAction,
  HandoverItemCategory,
  HandoverItemPriority,
  HandoverStatus,
  NotificationType,
  Role,
  ServiceRequestCategory,
  ServiceRequestPriority,
  ServiceRequestStatus,
  TaskPriority,
  TaskStatus,
  UserStatus,
} from "@prisma/client";
import { BadRequestException, ForbiddenException } from "@nestjs/common";

describe("Phase 7 — Service Requests, Shift Handover & Department Operations Specification", () => {
  let srService: ServiceRequestsService;
  let hoService: HandoverService;
  let deptOpsService: DepartmentOperationsService;
  let srGuard: ServiceRequestAccessGuard;
  let hoGuard: HandoverAccessGuard;
  let deptGuard: DepartmentAccessGuard;

  // In-Memory Storage
  let mockServiceRequests: any[] = [];
  let mockServiceRequestHistory: any[] = [];
  let mockServiceRequestComments: any[] = [];
  let mockShiftHandovers: any[] = [];
  let mockShiftHandoverItems: any[] = [];
  let mockTasks: any[] = [];
  let mockAuditLogs: any[] = [];
  let mockNotifications: any[] = [];

  // Organization Fixtures
  const mockDeptFacility = {
    id: "dept-facility",
    name: "Facility & Maintenance",
    code: "FAC",
    isActive: true,
    headOfDepartmentId: "emp-head-fac",
    headOfDepartment: {
      id: "emp-head-fac",
      userId: "user-head-fac",
      firstName: "Mahmoud",
      lastName: "Director",
      jobTitle: "Facility Operations Director",
    },
  };

  const mockUsers: Record<string, any> = {
    "user-head-fac": {
      id: "user-head-fac",
      role: Role.SUPERVISOR,
      status: UserStatus.ACTIVE,
      employeeProfile: mockDeptFacility.headOfDepartment,
    },
    "user-emp-requester": {
      id: "user-emp-requester",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-requester",
        userId: "user-emp-requester",
        employeeCode: "CW-105",
        firstName: "Layla",
        lastName: "Salem",
        departmentId: "dept-accounting",
        jobTitle: "Senior Accountant",
      },
    },
    "user-tech-current": {
      id: "user-tech-current",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-tech-current",
        userId: "user-tech-current",
        employeeCode: "CW-201",
        firstName: "Kareem",
        lastName: "Said",
        departmentId: "dept-facility",
        jobTitle: "Facility Morning Technician",
      },
    },
    "user-tech-next": {
      id: "user-tech-next",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-tech-next",
        userId: "user-tech-next",
        employeeCode: "CW-202",
        firstName: "Omar",
        lastName: "Farouk",
        departmentId: "dept-facility",
        jobTitle: "Facility Evening Technician",
      },
    },
    "user-stranger": {
      id: "user-stranger",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-stranger",
        userId: "user-stranger",
        employeeCode: "CW-999",
        firstName: "Stranger",
        lastName: "User",
        departmentId: "dept-sales",
        jobTitle: "Sales Representative",
      },
    },
    "user-admin": {
      id: "user-admin",
      role: Role.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
    },
  };

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(({ where }) => {
        const u = mockUsers[where.id];
        return Promise.resolve(u || null);
      }),
    },
    employeeProfile: {
      findUnique: jest.fn(({ where }) => {
        for (const key of Object.keys(mockUsers)) {
          const profile = mockUsers[key].employeeProfile;
          if (
            profile &&
            (profile.id === where.id || profile.userId === where.userId)
          ) {
            return Promise.resolve({ ...profile, user: mockUsers[key] });
          }
        }
        return Promise.resolve(null);
      }),
      count: jest.fn().mockImplementation(({ where }) => {
        if (where.departmentId === "dept-facility") return Promise.resolve(8);
        return Promise.resolve(10);
      }),
      findMany: jest.fn().mockImplementation(({ where }) => {
        if (where.departmentId === "dept-facility") {
          return Promise.resolve([
            {
              id: "emp-tech-current",
              firstName: "Kareem",
              lastName: "Said",
              jobTitle: "Facility Morning Technician",
              assignedTasks: [{ id: "t1" }, { id: "t2" }],
              serviceRequestsAssigned: [{ id: "sr1" }],
            },
            {
              id: "emp-tech-next",
              firstName: "Omar",
              lastName: "Farouk",
              jobTitle: "Facility Evening Technician",
              assignedTasks: [{ id: "t3" }],
              serviceRequestsAssigned: [],
            },
          ]);
        }
        return Promise.resolve([]);
      }),
    },
    department: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === "dept-facility")
          return Promise.resolve(mockDeptFacility);
        return Promise.resolve(null);
      }),
    },
    attendanceRecord: {
      count: jest.fn().mockResolvedValue(6), // 6 present today on shift
    },
    task: {
      findMany: jest.fn(({ where }) => {
        if (where.departmentId === "dept-facility") {
          return Promise.resolve(
            mockTasks.filter((t) => t.departmentId === "dept-facility"),
          );
        }
        return Promise.resolve([]);
      }),
      count: jest.fn(({ where }) => {
        if (where.status === TaskStatus.COMPLETED) return Promise.resolve(6);
        return Promise.resolve(8);
      }),
      groupBy: jest.fn().mockResolvedValue([
        { status: TaskStatus.TODO, _count: { id: 2 } },
        { status: TaskStatus.IN_PROGRESS, _count: { id: 3 } },
        { status: TaskStatus.BLOCKED, _count: { id: 1 } },
        { status: TaskStatus.COMPLETED, _count: { id: 6 } },
      ]),
    },
    serviceRequest: {
      count: jest.fn(({ where }) => {
        if (!where) return Promise.resolve(mockServiceRequests.length);
        if (where.status?.in) {
          return Promise.resolve(
            mockServiceRequests.filter((s) =>
              where.status.in.includes(s.status),
            ).length,
          );
        }
        if (where.status) {
          return Promise.resolve(
            mockServiceRequests.filter((s) => s.status === where.status).length,
          );
        }
        if (where.priority) {
          return Promise.resolve(
            mockServiceRequests.filter((s) => s.priority === where.priority)
              .length,
          );
        }
        return Promise.resolve(mockServiceRequests.length);
      }),
      create: jest.fn(({ data }) => {
        const sr = {
          id: `sr-${mockServiceRequests.length + 1}`,
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
          requester: mockUsers["user-emp-requester"].employeeProfile,
          department: mockDeptFacility,
          assignedTo: null,
          history: [],
          comments: [],
        };
        mockServiceRequests.push(sr);
        return Promise.resolve(sr);
      }),
      findUnique: jest.fn(({ where }) => {
        const found = mockServiceRequests.find((s) => s.id === where.id);
        if (!found) return Promise.resolve(null);
        return Promise.resolve({
          ...found,
          requester: mockUsers["user-emp-requester"].employeeProfile,
          department: mockDeptFacility,
          assignedTo: found.assignedToId
            ? mockUsers["user-tech-current"].employeeProfile
            : null,
          history: mockServiceRequestHistory.filter(
            (h) => h.serviceRequestId === found.id,
          ),
          comments: mockServiceRequestComments.filter(
            (c) => c.serviceRequestId === found.id,
          ),
        });
      }),
      findMany: jest.fn(() =>
        Promise.resolve([
          {
            createdAt: new Date("2026-09-01T08:00:00Z"),
            completedAt: new Date("2026-09-01T11:00:00Z"), // 3 hrs
          },
          {
            createdAt: new Date("2026-09-02T13:00:00Z"),
            completedAt: new Date("2026-09-02T15:00:00Z"), // 2 hrs
          },
        ]),
      ),
      groupBy: jest.fn().mockResolvedValue([
        { status: ServiceRequestStatus.SUBMITTED, _count: { id: 1 } },
        { status: ServiceRequestStatus.ASSIGNED, _count: { id: 1 } },
        { status: ServiceRequestStatus.IN_PROGRESS, _count: { id: 2 } },
        { status: ServiceRequestStatus.COMPLETED, _count: { id: 4 } },
        { status: ServiceRequestStatus.CLOSED, _count: { id: 4 } },
      ]),
      update: jest.fn(({ where, data }) => {
        const found = mockServiceRequests.find((s) => s.id === where.id);
        if (!found) throw new Error("Not found");
        if (data.assignedTo?.connect?.id) {
          found.assignedToId = data.assignedTo.connect.id;
        }
        Object.assign(found, data);
        return Promise.resolve(found);
      }),
    },
    serviceRequestHistory: {
      create: jest.fn(({ data }) => {
        const h = {
          id: `srh-${mockServiceRequestHistory.length + 1}`,
          ...data,
          createdAt: new Date(),
        };
        mockServiceRequestHistory.push(h);
        return Promise.resolve(h);
      }),
    },
    serviceRequestComment: {
      create: jest.fn(({ data }) => {
        const c = {
          id: `src-${mockServiceRequestComments.length + 1}`,
          ...data,
          createdAt: new Date(),
        };
        mockServiceRequestComments.push(c);
        return Promise.resolve(c);
      }),
    },
    shiftHandover: {
      count: jest.fn(({ where }) => {
        if (!where) return Promise.resolve(mockShiftHandovers.length);
        if (where.status) {
          return Promise.resolve(
            mockShiftHandovers.filter((h) => h.status === where.status).length,
          );
        }
        return Promise.resolve(mockShiftHandovers.length);
      }),
      create: jest.fn(({ data }) => {
        const items = data.items?.create || [];
        const ho = {
          id: `ho-${mockShiftHandovers.length + 1}`,
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
          handedOverBy: mockUsers["user-tech-current"].employeeProfile,
          receivedBy: data.receivedById
            ? mockUsers["user-tech-next"].employeeProfile
            : null,
          department: mockDeptFacility,
          items: items.map((it: any, idx: number) => ({
            id: `hoi-${idx + 1}`,
            ...it,
          })),
        };
        mockShiftHandovers.push(ho);
        return Promise.resolve(ho);
      }),
      findUnique: jest.fn(({ where }) => {
        const found = mockShiftHandovers.find((h) => h.id === where.id);
        if (!found) return Promise.resolve(null);
        return Promise.resolve({
          ...found,
          handedOverBy: mockUsers["user-tech-current"].employeeProfile,
          receivedBy: found.receivedById
            ? mockUsers["user-tech-next"].employeeProfile
            : null,
          department: mockDeptFacility,
          items: found.items || [],
        });
      }),
      findFirst: jest.fn(() => {
        if (mockShiftHandovers.length === 0) return Promise.resolve(null);
        return Promise.resolve(
          mockShiftHandovers[mockShiftHandovers.length - 1],
        );
      }),
      update: jest.fn(({ where, data }) => {
        const found = mockShiftHandovers.find((h) => h.id === where.id);
        if (!found) throw new Error("Not found");
        Object.assign(found, data);
        return Promise.resolve(found);
      }),
    },
    shiftHandoverItem: {
      create: jest.fn(({ data }) => {
        const it = {
          id: `hoi-${mockShiftHandoverItems.length + 1}`,
          ...data,
          createdAt: new Date(),
        };
        mockShiftHandoverItems.push(it);
        return Promise.resolve(it);
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        mockAuditLogs.push(data);
        return Promise.resolve(data);
      }),
    },
  };

  const mockNotificationsService = {
    sendNotification: jest.fn((userId, title, body, type, data) => {
      mockNotifications.push({ userId, title, body, type, data });
      return Promise.resolve(true);
    }),
  };

  const mockWorkflowService = {
    matchWorkflow: jest.fn().mockResolvedValue({
      workflowId: "wf-fac-request",
      workflowName: "Facility Maintenance Workflow",
      totalSteps: 1,
    }),
  };

  beforeEach(async () => {
    mockServiceRequests = [];
    mockServiceRequestHistory = [];
    mockServiceRequestComments = [];
    mockShiftHandovers = [];
    mockShiftHandoverItems = [];
    mockAuditLogs = [];
    mockNotifications = [];

    // Seed mock active tasks for department
    mockTasks = [
      {
        id: "task-generator",
        title: "Emergency Generator Fuel Test",
        description: "Verify standby generator fuel level and transfer switch",
        priority: TaskPriority.CRITICAL,
        status: TaskStatus.IN_PROGRESS,
        departmentId: "dept-facility",
        dueDate: new Date(),
        assignee: mockUsers["user-tech-current"].employeeProfile,
      },
      {
        id: "task-cooling-tower",
        title: "Cooling Tower Water Chemical Treatment",
        description: "Add anti-scaling agent to cooling tower reservoir",
        priority: TaskPriority.HIGH,
        status: TaskStatus.TODO,
        departmentId: "dept-facility",
        dueDate: new Date(),
        assignee: mockUsers["user-tech-current"].employeeProfile,
      },
    ];

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ServiceRequestsService,
        ServiceRequestsRepository,
        ServiceRequestAccessGuard,
        HandoverService,
        HandoverRepository,
        HandoverAccessGuard,
        DepartmentOperationsService,
        DepartmentOperationsRepository,
        DepartmentAccessGuard,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: WorkflowService, useValue: mockWorkflowService },
      ],
    }).compile();

    srService = module.get<ServiceRequestsService>(ServiceRequestsService);
    hoService = module.get<HandoverService>(HandoverService);
    deptOpsService = module.get<DepartmentOperationsService>(
      DepartmentOperationsService,
    );
    srGuard = module.get<ServiceRequestAccessGuard>(ServiceRequestAccessGuard);
    hoGuard = module.get<HandoverAccessGuard>(HandoverAccessGuard);
    deptGuard = module.get<DepartmentAccessGuard>(DepartmentAccessGuard);
    expect(srGuard).toBeDefined();
    expect(hoGuard).toBeDefined();
    expect(deptGuard).toBeDefined();

    jest.clearAllMocks();
  });

  // ============================================================
  // TEST GROUP 1: SERVICE REQUEST FULL LIFECYCLE
  // ============================================================

  describe("1. Service Request Lifecycle (Creation → Triage → Progress → Completion → Review → Closed)", () => {
    it("should execute full service request lifecycle from creation to closure", async () => {
      // Step 1: Employee creates service request (status: SUBMITTED)
      const created = await srService.createServiceRequest(
        "user-emp-requester",
        {
          title: "Central AC blowing warm air in Accounting Office",
          description:
            "Temperature in office 204 reached 28C, thermostat unresponsive.",
          category: ServiceRequestCategory.FACILITY,
          priority: ServiceRequestPriority.HIGH,
          departmentId: "dept-facility",
          location: "Floor 2, Room 204",
        },
      );

      expect(created.id).toBeDefined();
      expect(created.requestNumber).toMatch(/^SR-\d{8}-\d{4}$/);
      expect(created.status).toBe(ServiceRequestStatus.SUBMITTED);
      expect(created.priority).toBe(ServiceRequestPriority.HIGH);
      const serviceRequestId = created.id;

      // Audit Log recorded
      const auditCreate = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.SERVICE_REQUEST_CREATED &&
          a.entityId === created.id,
      );
      expect(auditCreate).toBeDefined();

      // Department head notified
      const notifHead = mockNotifications.find(
        (n) =>
          n.userId === "user-head-fac" &&
          n.type === NotificationType.SERVICE_REQUEST_CREATED,
      );
      expect(notifHead).toBeDefined();

      // Step 2: Department Head triages and assigns to technician (status: ASSIGNED)
      const assigned = await deptOpsService.triageServiceRequest(
        "user-head-fac",
        {
          serviceRequestId,
          assignedToId: "emp-tech-current",
          priority: ServiceRequestPriority.URGENT,
          notes:
            "Prioritize immediately due to heat and computer equipment in room 204",
        },
      );

      expect(assigned?.assignedTo?.id).toBe("emp-tech-current");

      const sr = mockServiceRequests.find((s) => s.id === serviceRequestId);
      expect(sr.status).toBe(ServiceRequestStatus.ASSIGNED);
      expect(sr.priority).toBe(ServiceRequestPriority.URGENT);

      // Technician notified
      const notifTech = mockNotifications.find(
        (n) =>
          n.userId === "user-tech-current" &&
          n.type === NotificationType.SERVICE_REQUEST_ASSIGNED,
      );
      expect(notifTech).toBeDefined();

      // Step 3: Technician starts work (status: IN_PROGRESS)
      const inProgress = await srService.startWork(
        serviceRequestId,
        "user-tech-current",
      );
      expect(inProgress.status).toBe(ServiceRequestStatus.IN_PROGRESS);

      // Requester notified of progress
      const notifProgress = mockNotifications.find(
        (n) =>
          n.userId === "user-emp-requester" &&
          n.type === NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
      );
      expect(notifProgress).toBeDefined();

      // Step 4: Technician completes work with resolution notes (status: COMPLETED)
      const completed = await srService.completeServiceRequest(
        serviceRequestId,
        "user-tech-current",
        {
          status: ServiceRequestStatus.COMPLETED,
          resolutionNotes:
            "Replaced blown 24V transformer and reset chilled water valve actuator. Office cooled to 21C.",
        },
      );

      expect(completed.status).toBe(ServiceRequestStatus.COMPLETED);
      expect(completed.completedAt).toBeDefined();
      expect(completed.resolutionNotes).toContain(
        "Replaced blown 24V transformer",
      );

      // Requester notified to review
      const notifReview = mockNotifications.find(
        (n) =>
          n.userId === "user-emp-requester" &&
          n.body.includes("Please review and provide feedback"),
      );
      expect(notifReview).toBeDefined();

      // Step 5: Requester reviews and signs off with 5-star rating (status: CLOSED)
      const closed = await srService.reviewServiceRequest(
        serviceRequestId,
        "user-emp-requester",
        {
          rating: 5,
          feedback:
            "Extremely fast response and AC is blowing ice cold. Thank you Kareem!",
          decision: "ACCEPT",
        },
      );

      expect(closed.status).toBe(ServiceRequestStatus.CLOSED);
      expect(closed.reviewRating).toBe(5);
      expect(closed.reviewFeedback).toContain("Extremely fast response");
      expect(closed.closedAt).toBeDefined();

      // Final Audit Log
      const auditClose = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.SERVICE_REQUEST_CLOSED &&
          a.entityId === serviceRequestId,
      );
      expect(auditClose).toBeDefined();
    });
  });

  // ============================================================
  // TEST GROUP 2: REVISION & REJECTION FLOWS
  // ============================================================

  describe("2. Revisions, Rejections & Cancellations", () => {
    it("should return request to IN_PROGRESS when requester requests REVISION", async () => {
      const sr = await srService.createServiceRequest("user-emp-requester", {
        title: "Leaking faucet in restroom",
        description: "Sink #2 leaking continuously",
        departmentId: "dept-facility",
      });
      await srService.assignServiceRequest(sr.id, "user-head-fac", {
        assignedToId: "emp-tech-current",
      });
      await srService.startWork(sr.id, "user-tech-current");
      await srService.completeServiceRequest(sr.id, "user-tech-current", {
        status: ServiceRequestStatus.COMPLETED,
        resolutionNotes: "Tightened valve packing.",
      });

      const revised = await srService.reviewServiceRequest(
        sr.id,
        "user-emp-requester",
        {
          rating: 2,
          feedback: "Still dripping slowly under the sink cabinet",
          decision: "REVISION",
        },
      );

      expect(revised.status).toBe(ServiceRequestStatus.IN_PROGRESS);
      expect(revised.reviewFeedback).toContain("Still dripping slowly");

      // Technician notified of revision
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-tech-current" && n.title === "Revision Requested",
      );
      expect(notif).toBeDefined();
    });

    it("should allow department supervisor to reject inappropriate service requests", async () => {
      const sr = await srService.createServiceRequest("user-emp-requester", {
        title: "Request for personal sofa in accounting",
        description: "Need luxury recliner sofa for lunch breaks",
        departmentId: "dept-facility",
      });

      const rejected = await srService.rejectServiceRequest(
        sr.id,
        "user-head-fac",
        "Personal furniture requests are not permitted under company policy.",
      );

      expect(rejected.status).toBe(ServiceRequestStatus.REJECTED);
      expect(rejected.rejectionReason).toContain(
        "Personal furniture requests are not permitted",
      );

      // Requester notified of rejection
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-emp-requester" &&
          n.type === NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
      );
      expect(notif).toBeDefined();
    });
  });

  // ============================================================
  // TEST GROUP 3: SHIFT HANDOVER LIFECYCLE & TASK TRANSFER
  // ============================================================

  describe("3. Shift Handover Lifecycle (Creation → Open Tasks → Review → Acknowledgement)", () => {
    it("should execute full shift handover lifecycle with open tasks transfer and acknowledgement", async () => {
      // Step 1: Outgoing shift technician creates handover with auto-captured open tasks
      const created = await hoService.createHandover("user-tech-current", {
        shiftDate: "2026-09-03",
        shiftName: "Day Shift (08:00 - 16:00)",
        departmentId: "dept-facility",
        receivedById: "emp-tech-next",
        summary:
          "Day shift completed. AC repair in office 204 closed. 2 pending plant maintenance tasks transferred.",
        notes:
          "Generator fuel level tested at 85%. Cooling tower chemicals batch scheduled for 18:00.",
        includeOpenTasks: true,
        items: [
          {
            title: "Facility master key set handed over in security pouch #7",
            category: HandoverItemCategory.ASSET,
            priority: HandoverItemPriority.HIGH,
            requiresAction: false,
          },
        ],
      });

      expect(created.id).toBeDefined();
      expect(created.handoverNumber).toMatch(/^HO-\d{8}-\d{4}$/);
      expect(created.status).toBe(HandoverStatus.PENDING_ACKNOWLEDGEMENT);
      const handoverId = created.id;

      // 1 manual item + 2 open tasks captured
      expect(created.items.length).toBe(3);
      expect(
        created.items.some((i: any) =>
          i.title.includes("Emergency Generator Fuel Test"),
        ),
      ).toBe(true);
      expect(
        created.items.some((i: any) =>
          i.title.includes("Cooling Tower Water Chemical Treatment"),
        ),
      ).toBe(true);

      // Audit Log recorded
      const auditCreate = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.HANDOVER_CREATED &&
          a.entityId === created.id,
      );
      expect(auditCreate).toBeDefined();

      // Incoming shift technician notified
      const notifCreate = mockNotifications.find(
        (n) =>
          n.userId === "user-tech-next" &&
          n.type === NotificationType.HANDOVER_SUBMITTED,
      );
      expect(notifCreate).toBeDefined();

      // Step 2: Incoming shift technician reviews and acknowledges handover (status: ACKNOWLEDGED)
      const ack = await hoService.acknowledgeHandover(
        handoverId,
        "user-tech-next",
        {
          action: "ACKNOWLEDGE",
          acknowledgementNotes:
            "Shift handover received. Pouch #7 keys verified, taking custody of generator and cooling tower tasks.",
        },
      );

      expect(ack.status).toBe(HandoverStatus.ACKNOWLEDGED);
      expect(ack.acknowledgedAt).toBeDefined();
      expect(ack.acknowledgementNotes).toContain("Shift handover received");

      // Audit Log for acknowledgement
      const auditAck = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.HANDOVER_ACKNOWLEDGED &&
          a.entityId === handoverId,
      );
      expect(auditAck).toBeDefined();

      // Outgoing technician notified of receipt
      const notifAck = mockNotifications.find(
        (n) =>
          n.userId === "user-tech-current" &&
          n.type === NotificationType.HANDOVER_ACKNOWLEDGED,
      );
      expect(notifAck).toBeDefined();

      // Step 3: Prevent duplicate acknowledgement or modifications on acknowledged handover
      await expect(
        hoService.acknowledgeHandover(handoverId, "user-tech-next", {
          action: "ACKNOWLEDGE",
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        hoService.addItem(handoverId, "user-tech-current", {
          title: "Late note",
          category: HandoverItemCategory.NOTE,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ============================================================
  // TEST GROUP 4: SHIFT HANDOVER DISCREPANCIES & FLAGGING
  // ============================================================

  describe("4. Shift Handover Discrepancies & Flagging", () => {
    it("should flag handover when incoming shift notes missing equipment or discrepancies", async () => {
      const ho = await hoService.createHandover("user-tech-current", {
        shiftDate: "2026-09-03",
        shiftName: "Evening Shift",
        departmentId: "dept-facility",
        receivedById: "emp-tech-next",
        summary: "Handover with potential discrepancy",
      });

      const flagged = await hoService.acknowledgeHandover(
        ho.id,
        "user-tech-next",
        {
          action: "FLAG",
          discrepancyNotes:
            "Multimeter Fluke 87V is missing from workbench #2.",
        },
      );

      expect(flagged.status).toBe(HandoverStatus.FLAGGED);
      expect(flagged.discrepancyNotes).toContain(
        "Multimeter Fluke 87V is missing",
      );

      // Audit Log for dispute
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.HANDOVER_DISPUTED && a.entityId === ho.id,
      );
      expect(audit).toBeDefined();
    });
  });

  // ============================================================
  // TEST GROUP 5: DEPARTMENT OPERATIONS TELEMETRY & KPIS
  // ============================================================

  describe("5. Department Operations Dashboard, Telemetry & Reports", () => {
    it("should calculate live department staffing, active task breakdown, and service request metrics", async () => {
      const overview = await deptOpsService.getOverview("user-head-fac", {
        departmentId: "dept-facility",
      });

      expect(overview.department?.name).toBe("Facility & Maintenance");
      expect(overview.staffing.totalEmployees).toBe(8);
      expect(overview.staffing.onDutyPresent).toBe(6); // 6 present today
      expect(overview.tasks.activeCount).toBe(6); // 2 todo + 3 in progress + 1 blocked
      expect(overview.serviceRequests.activeCount).toBe(4); // 1 submitted + 1 assigned + 2 in progress

      // Audit Log recorded
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.DEPARTMENT_OPERATION_LOGGED &&
          a.payload.action === "OVERVIEW_ACCESSED",
      );
      expect(audit).toBeDefined();
    });

    it("should produce operational KPI report with workload balance and CSV export", async () => {
      const report: any = await deptOpsService.getOperationalReport(
        "user-head-fac",
        {
          departmentId: "dept-facility",
          startDate: "2026-09-01",
          endDate: "2026-09-30",
          exportCsv: false,
        },
      );

      expect(report.department.code).toBe("FAC");
      expect(report.tasks.completionRate).toBe(75); // 6/8 = 75%
      expect(report.serviceRequests.averageResolutionHours).toBe(2.5); // (3 + 2) / 2 = 2.5 hrs

      // Workload distribution
      expect(report.workloadDistribution).toHaveLength(2);
      expect(report.workloadDistribution[0].name).toBe("Kareem Said");
      expect(report.workloadDistribution[0].totalActiveItems).toBe(3); // 2 tasks + 1 request

      // CSV export with anti-formula injection sanitization
      const csv = await deptOpsService.getOperationalReport("user-head-fac", {
        departmentId: "dept-facility",
        startDate: "2026-09-01",
        endDate: "2026-09-30",
        exportCsv: true,
      });

      expect(typeof csv).toBe("string");
      expect(csv).toContain('"Kareem Said"');
      expect(csv).toContain('"Facility Morning Technician"');
    });
  });

  // ============================================================
  // TEST GROUP 6: SECURITY & AUTHORIZATION BARRIERS
  // ============================================================

  describe("6. Security, Authorization & Concurrency Barriers", () => {
    it("should prevent unauthorized stranger from reviewing another user's request (IDOR barrier)", async () => {
      const sr = await srService.createServiceRequest("user-emp-requester", {
        title: "Private office repair",
        description: "Door handle repair",
        departmentId: "dept-facility",
      });
      await srService.assignServiceRequest(sr.id, "user-head-fac", {
        assignedToId: "emp-tech-current",
      });
      await srService.startWork(sr.id, "user-tech-current");
      await srService.completeServiceRequest(sr.id, "user-tech-current", {
        status: ServiceRequestStatus.COMPLETED,
        resolutionNotes: "Fixed door handle.",
      });

      await expect(
        srService.reviewServiceRequest(sr.id, "user-stranger", {
          rating: 1,
          feedback: "Malicious 1-star review by competitor",
          decision: "ACCEPT",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should prevent outgoing giver from acknowledging their own handover", async () => {
      const ho = await hoService.createHandover("user-tech-current", {
        shiftDate: "2026-09-03",
        shiftName: "Self review test",
        departmentId: "dept-facility",
        summary: "Testing self ack",
      });

      await expect(
        hoService.acknowledgeHandover(ho.id, "user-tech-current", {
          action: "ACKNOWLEDGE",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should reject cancelling an already completed service request", async () => {
      const sr = await srService.createServiceRequest("user-emp-requester", {
        title: "Plumbing repair",
        description: "Water pipe",
        departmentId: "dept-facility",
      });
      await srService.assignServiceRequest(sr.id, "user-head-fac", {
        assignedToId: "emp-tech-current",
      });
      await srService.startWork(sr.id, "user-tech-current");
      await srService.completeServiceRequest(sr.id, "user-tech-current", {
        status: ServiceRequestStatus.COMPLETED,
        resolutionNotes: "Fixed pipe",
      });

      await expect(
        srService.cancelServiceRequest(
          sr.id,
          "user-emp-requester",
          "Cancel completed",
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
