import { Test, TestingModule } from "@nestjs/testing";
import { ServiceRequestsService } from "./service-requests.service";
import { ServiceRequestsRepository } from "./service-requests.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { WorkflowService } from "../workflow/workflow.service";
import { ServiceRequestAccessGuard } from "./guards/service-request-access.guard";
import {
  AuditAction,
  NotificationType,
  Role,
  ServiceRequestCategory,
  ServiceRequestPriority,
  ServiceRequestStatus,
  UserStatus,
} from "@prisma/client";
import { BadRequestException, ForbiddenException } from "@nestjs/common";

describe("ServiceRequestsService (Phase 7 Service Requests)", () => {
  let service: ServiceRequestsService;
  let guard: ServiceRequestAccessGuard;

  // In-Memory Fixtures
  const mockRequesterUser = {
    id: "user-req-1",
    role: Role.EMPLOYEE,
    status: UserStatus.ACTIVE,
  };

  const mockRequesterProfile = {
    id: "emp-req-1",
    userId: "user-req-1",
    employeeCode: "CW-101",
    firstName: "Ahmed",
    lastName: "Hassan",
    departmentId: "dept-finance",
    user: mockRequesterUser,
  };

  const mockAssigneeProfile = {
    id: "emp-tech-1",
    userId: "user-tech-1",
    employeeCode: "CW-201",
    firstName: "Tariq",
    lastName: "Nabil",
    jobTitle: "IT Technician",
    departmentId: "dept-it",
    user: { id: "user-tech-1", role: Role.EMPLOYEE, status: UserStatus.ACTIVE },
  };

  const mockDepartment = {
    id: "dept-it",
    name: "Information Technology",
    code: "IT",
    isActive: true,
    headOfDepartmentId: "emp-head-it",
    headOfDepartment: {
      id: "emp-head-it",
      userId: "user-head-it",
      firstName: "Hossam",
      lastName: "Director",
    },
  };

  let mockServiceRequests: any[] = [];
  let mockHistory: any[] = [];
  let mockComments: any[] = [];
  let mockAuditLogs: any[] = [];
  let mockNotifications: any[] = [];

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === "user-req-1")
          return Promise.resolve(mockRequesterUser);
        if (where.id === "user-tech-1")
          return Promise.resolve(mockAssigneeProfile.user);
        if (where.id === "user-admin")
          return Promise.resolve({
            id: "user-admin",
            role: Role.SUPER_ADMIN,
            status: UserStatus.ACTIVE,
          });
        if (where.id === "user-stranger")
          return Promise.resolve({
            id: "user-stranger",
            role: Role.EMPLOYEE,
            status: UserStatus.ACTIVE,
          });
        return Promise.resolve(null);
      }),
    },
    employeeProfile: {
      findUnique: jest.fn(({ where }) => {
        if (where.userId === "user-req-1" || where.id === "emp-req-1")
          return Promise.resolve(mockRequesterProfile);
        if (where.userId === "user-tech-1" || where.id === "emp-tech-1")
          return Promise.resolve(mockAssigneeProfile);
        if (where.userId === "user-stranger" || where.id === "emp-stranger")
          return Promise.resolve({
            id: "emp-stranger",
            userId: "user-stranger",
            departmentId: "dept-sales",
            user: { status: UserStatus.ACTIVE, role: Role.EMPLOYEE },
          });
        return Promise.resolve(null);
      }),
    },
    department: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === "dept-it") return Promise.resolve(mockDepartment);
        return Promise.resolve(null);
      }),
    },
    serviceRequest: {
      count: jest.fn(() => Promise.resolve(mockServiceRequests.length)),
      create: jest.fn(({ data }) => {
        const sr = {
          id: `sr-${mockServiceRequests.length + 1}`,
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
          requester: mockRequesterProfile,
          department: mockDepartment,
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
          requester: mockRequesterProfile,
          department: mockDepartment,
          assignedTo: found.assignedToId ? mockAssigneeProfile : null,
          history: mockHistory.filter((h) => h.serviceRequestId === found.id),
          comments: mockComments.filter((c) => c.serviceRequestId === found.id),
        });
      }),
      update: jest.fn(({ where, data }) => {
        const found = mockServiceRequests.find((s) => s.id === where.id);
        if (!found) throw new Error("Not found");
        if (data.assignedTo?.connect?.id) {
          found.assignedToId = data.assignedTo.connect.id;
          found.assignedTo = mockAssigneeProfile;
        }
        Object.assign(found, data);
        return Promise.resolve(found);
      }),
    },
    serviceRequestHistory: {
      create: jest.fn(({ data }) => {
        const h = {
          id: `hist-${mockHistory.length + 1}`,
          ...data,
          createdAt: new Date(),
        };
        mockHistory.push(h);
        return Promise.resolve(h);
      }),
    },
    serviceRequestComment: {
      create: jest.fn(({ data }) => {
        const c = {
          id: `comment-${mockComments.length + 1}`,
          ...data,
          createdAt: new Date(),
          author: {
            id: data.authorId,
            email: "author@cyberwise.test",
            role: Role.EMPLOYEE,
          },
        };
        mockComments.push(c);
        return Promise.resolve(c);
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
      workflowId: "wf-general-service",
      workflowName: "General Service Flow",
      totalSteps: 1,
    }),
  };

  beforeEach(async () => {
    mockServiceRequests = [];
    mockHistory = [];
    mockComments = [];
    mockAuditLogs = [];
    mockNotifications = [];

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ServiceRequestsService,
        ServiceRequestsRepository,
        ServiceRequestAccessGuard,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: WorkflowService, useValue: mockWorkflowService },
      ],
    }).compile();

    service = module.get<ServiceRequestsService>(ServiceRequestsService);
    guard = module.get<ServiceRequestAccessGuard>(ServiceRequestAccessGuard);
    expect(guard).toBeDefined();

    jest.clearAllMocks();
  });

  describe("1. Service Request Creation", () => {
    it("should successfully create a service request and notify department head", async () => {
      const created = await service.createServiceRequest("user-req-1", {
        title: "Network connectivity issue in Office 301",
        description: "Ethernet port is loose and keeps disconnecting.",
        category: ServiceRequestCategory.IT_SUPPORT,
        priority: ServiceRequestPriority.HIGH,
        departmentId: "dept-it",
        location: "Floor 3, Office 301",
      });

      expect(created.id).toBeDefined();
      expect(created.status).toBe(ServiceRequestStatus.SUBMITTED);
      expect(created.requestNumber).toMatch(/^SR-\d{8}-\d{4}$/);
      expect(created.priority).toBe(ServiceRequestPriority.HIGH);

      // Verify Audit Log
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.SERVICE_REQUEST_CREATED &&
          a.entityId === created.id,
      );
      expect(audit).toBeDefined();

      // Verify Notification sent to department head
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-head-it" &&
          n.type === NotificationType.SERVICE_REQUEST_CREATED,
      );
      expect(notif).toBeDefined();
    });

    it("should throw BadRequestException if target department is invalid", async () => {
      await expect(
        service.createServiceRequest("user-req-1", {
          title: "Invalid department request",
          description: "Testing invalid dept",
          departmentId: "dept-non-existent",
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe("2. Assignment & Work Execution Lifecycle", () => {
    let srId: string;

    beforeEach(async () => {
      const sr = await service.createServiceRequest("user-req-1", {
        title: "PC won't boot",
        description: "Blue screen of death on startup",
        category: ServiceRequestCategory.IT_SUPPORT,
        priority: ServiceRequestPriority.MEDIUM,
        departmentId: "dept-it",
      });
      srId = sr.id;
    });

    it("should assign service request to technician and transition to ASSIGNED", async () => {
      const assigned = await service.assignServiceRequest(
        srId,
        "user-head-it",
        {
          assignedToId: "emp-tech-1",
          notes: "Please inspect RAM and SSD",
        },
      );

      expect(assigned.assignedToId).toBe("emp-tech-1");
      expect(assigned.status).toBe(ServiceRequestStatus.ASSIGNED);

      // Notification sent to technician
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-tech-1" &&
          n.type === NotificationType.SERVICE_REQUEST_ASSIGNED,
      );
      expect(notif).toBeDefined();
    });

    it("should start work and transition status to IN_PROGRESS", async () => {
      await service.assignServiceRequest(srId, "user-head-it", {
        assignedToId: "emp-tech-1",
      });

      const inProgress = await service.startWork(srId, "user-tech-1");
      expect(inProgress.status).toBe(ServiceRequestStatus.IN_PROGRESS);

      // Requester notified of progress
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-req-1" &&
          n.type === NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
      );
      expect(notif).toBeDefined();
    });

    it("should complete service request with mandatory resolution notes", async () => {
      await service.assignServiceRequest(srId, "user-head-it", {
        assignedToId: "emp-tech-1",
      });
      await service.startWork(srId, "user-tech-1");

      // Attempt complete without resolution notes throws
      await expect(
        service.completeServiceRequest(srId, "user-tech-1", {
          status: ServiceRequestStatus.COMPLETED,
          resolutionNotes: "",
        }),
      ).rejects.toThrow(BadRequestException);

      const completed = await service.completeServiceRequest(
        srId,
        "user-tech-1",
        {
          status: ServiceRequestStatus.COMPLETED,
          resolutionNotes:
            "Replaced faulty RAM stick. Boot sequence tested successfully.",
        },
      );

      expect(completed.status).toBe(ServiceRequestStatus.COMPLETED);
      expect(completed.completedAt).toBeDefined();
      expect(completed.resolutionNotes).toContain("Replaced faulty RAM stick");
    });
  });

  describe("3. Review, Sign-off & Closure", () => {
    let srId: string;

    beforeEach(async () => {
      const sr = await service.createServiceRequest("user-req-1", {
        title: "AC maintenance",
        description: "Filter replacement",
        departmentId: "dept-it",
      });
      srId = sr.id;
      await service.assignServiceRequest(srId, "user-head-it", {
        assignedToId: "emp-tech-1",
      });
      await service.startWork(srId, "user-tech-1");
      await service.completeServiceRequest(srId, "user-tech-1", {
        status: ServiceRequestStatus.COMPLETED,
        resolutionNotes: "Air filters replaced and cleaned.",
      });
    });

    it("should prevent non-requester from reviewing (IDOR protection)", async () => {
      await expect(
        service.reviewServiceRequest(srId, "user-stranger", {
          rating: 5,
          feedback: "Sneaky review",
          decision: "ACCEPT",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should allow requester to accept and close the service request with 5-star rating", async () => {
      const closed = await service.reviewServiceRequest(srId, "user-req-1", {
        rating: 5,
        feedback: "Excellent and speedy repair!",
        decision: "ACCEPT",
      });

      expect(closed.status).toBe(ServiceRequestStatus.CLOSED);
      expect(closed.reviewRating).toBe(5);
      expect(closed.reviewFeedback).toBe("Excellent and speedy repair!");
      expect(closed.closedAt).toBeDefined();

      // Audit Log for closed request
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.SERVICE_REQUEST_CLOSED &&
          a.entityId === srId,
      );
      expect(audit).toBeDefined();
    });

    it("should return request to IN_PROGRESS when customer requests REVISION", async () => {
      const revised = await service.reviewServiceRequest(srId, "user-req-1", {
        rating: 2,
        feedback: "AC is still making whistling noises",
        decision: "REVISION",
      });

      expect(revised.status).toBe(ServiceRequestStatus.IN_PROGRESS);
      expect(revised.reviewFeedback).toContain("whistling noises");
    });
  });

  describe("4. Cancellation and Rejection", () => {
    it("should allow requester to cancel a submitted request", async () => {
      const sr = await service.createServiceRequest("user-req-1", {
        title: "Cancelled request test",
        description: "Testing cancellation",
        departmentId: "dept-it",
      });

      const cancelled = await service.cancelServiceRequest(
        sr.id,
        "user-req-1",
        "Issue resolved itself",
      );

      expect(cancelled.status).toBe(ServiceRequestStatus.CANCELLED);
      expect(cancelled.cancellationReason).toBe("Issue resolved itself");
    });

    it("should reject assignment on a cancelled request", async () => {
      const sr = await service.createServiceRequest("user-req-1", {
        title: "Cancelled request",
        description: "Testing",
        departmentId: "dept-it",
      });
      await service.cancelServiceRequest(
        sr.id,
        "user-req-1",
        "No longer needed",
      );

      await expect(
        service.assignServiceRequest(sr.id, "user-head-it", {
          assignedToId: "emp-tech-1",
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe("5. Comments and Access Guard", () => {
    let srId: string;

    beforeEach(async () => {
      const sr = await service.createServiceRequest("user-req-1", {
        title: "Comments test request",
        description: "Testing internal and external comments",
        departmentId: "dept-it",
      });
      srId = sr.id;
      await service.assignServiceRequest(srId, "user-head-it", {
        assignedToId: "emp-tech-1",
      });
    });

    it("should block non-internal staff from posting internal notes", async () => {
      await expect(
        service.addComment(srId, "user-req-1", {
          content: "Requester trying to post internal note",
          isInternal: true,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should allow servicing staff to post internal notes", async () => {
      const comment = await service.addComment(srId, "user-tech-1", {
        content: "Internal note: waiting on supplier parts",
        isInternal: true,
      });

      expect(comment.id).toBeDefined();
      expect(comment.isInternal).toBe(true);
    });

    it("should filter internal comments when requester fetches the service request", async () => {
      await service.addComment(srId, "user-tech-1", {
        content: "Internal secret note",
        isInternal: true,
      });
      await service.addComment(srId, "user-tech-1", {
        content: "Public update for customer",
        isInternal: false,
      });

      const reqView = await service.getServiceRequestById(srId, "user-req-1");
      expect(reqView.comments).toHaveLength(1);
      expect(reqView.comments[0].content).toBe("Public update for customer");

      const techView = await service.getServiceRequestById(srId, "user-tech-1");
      expect(techView.comments).toHaveLength(2);
    });
  });
});
