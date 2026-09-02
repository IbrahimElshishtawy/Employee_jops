import { Test, TestingModule } from "@nestjs/testing";
import { TasksService } from "./tasks/tasks.service";
import { TasksRepository } from "./tasks/tasks.repository";
import { WorkManagementService } from "./work-management/work-management.service";
import { WorkManagementRepository } from "./work-management/work-management.repository";
import { ReportsService } from "./reports/reports.service";
import { PrismaService } from "../prisma/prisma.service";
import { NotificationsService } from "./notifications/notifications.service";
import { TaskAccessGuard } from "./tasks/guards/task-access.guard";
import {
  AuditAction,
  NotificationType,
  Role,
  TaskPriority,
  TaskReportStatus,
  TaskStatus,
  UserStatus,
} from "@prisma/client";
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import { TaskReviewAction } from "./work-management/dto";

describe("Phase 5 — Tasks, Work Management & Reports Complete Specification", () => {
  let tasksService: TasksService;
  let tasksRepo: TasksRepository;
  let workService: WorkManagementService;
  let workRepo: WorkManagementRepository;
  let reportsService: ReportsService;
  let prismaService: any;
  let notificationsService: any;
  let taskAccessGuard: TaskAccessGuard;

  // In-Memory Database Stores
  let mockTasks: any[] = [];
  let mockChecklistItems: any[] = [];
  let mockComments: any[] = [];
  let mockAttachments: any[] = [];
  let mockReports: any[] = [];
  let mockHistory: any[] = [];
  let mockAuditLogs: any[] = [];
  let mockNotifications: any[] = [];

  // Users & Profiles Fixtures
  const mockUsers: Record<string, any> = {
    "user-manager": {
      id: "user-manager",
      email: "manager@cyberwise.test",
      role: Role.SUPERVISOR,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-mgr",
        userId: "user-manager",
        employeeCode: "CW-050",
        firstName: "Zaid",
        lastName: "Manager",
        department: "Engineering",
        departmentId: "dept-eng",
      },
    },
    "user-emp-1": {
      id: "user-emp-1",
      email: "engineer1@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-101",
        userId: "user-emp-1",
        employeeCode: "CW-101",
        firstName: "Tariq",
        lastName: "Salem",
        department: "Engineering",
        departmentId: "dept-eng",
        managerId: "emp-mgr",
        manager: {
          id: "emp-mgr",
          userId: "user-manager",
          firstName: "Zaid",
          lastName: "Manager",
        },
        departmentRel: {
          id: "dept-eng",
          name: "Engineering",
          headOfDepartmentId: "emp-mgr",
          headOfDepartment: { userId: "user-manager" },
        },
      },
    },
    "user-emp-2": {
      id: "user-emp-2",
      email: "engineer2@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-102",
        userId: "user-emp-2",
        employeeCode: "CW-102",
        firstName: "Layla",
        lastName: "Mahmoud",
        department: "Engineering",
        departmentId: "dept-eng",
        managerId: "emp-mgr",
        manager: {
          id: "emp-mgr",
          userId: "user-manager",
          firstName: "Zaid",
          lastName: "Manager",
        },
      },
    },
    "user-stranger": {
      id: "user-stranger",
      email: "stranger@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-999",
        userId: "user-stranger",
        employeeCode: "CW-999",
        firstName: "Stranger",
        lastName: "User",
        department: "Marketing",
        departmentId: "dept-mkt",
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
        firstName: "Admin",
        lastName: "CEO",
      },
    },
    "user-inactive": {
      id: "user-inactive",
      email: "inactive@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.SUSPENDED,
      employeeProfile: {
        id: "emp-suspended",
        userId: "user-inactive",
        employeeCode: "CW-000",
        firstName: "Suspended",
        lastName: "User",
      },
    },
  };

  const mockDepartments: Record<string, any> = {
    "dept-eng": {
      id: "dept-eng",
      name: "Engineering",
      code: "ENG",
      isActive: true,
      headOfDepartmentId: "emp-mgr",
    },
    "dept-mkt": {
      id: "dept-mkt",
      name: "Marketing",
      code: "MKT",
      isActive: true,
      headOfDepartmentId: null,
    },
  };

  beforeEach(async () => {
    mockTasks = [];
    mockChecklistItems = [];
    mockComments = [];
    mockAttachments = [];
    mockReports = [];
    mockHistory = [];
    mockAuditLogs = [];
    mockNotifications = [];

    // Setup Mock Prisma Service
    prismaService = {
      user: {
        findUnique: jest.fn(({ where }) => {
          const u =
            mockUsers[where.id] ||
            Object.values(mockUsers).find((u) => u.email === where.email);
          return Promise.resolve(u || null);
        }),
        count: jest.fn(() => Promise.resolve(Object.keys(mockUsers).length)),
      },
      employeeProfile: {
        findUnique: jest.fn(({ where, include }) => {
          let user: any = null;
          if (where.id) {
            user = Object.values(mockUsers).find(
              (u) => u.employeeProfile?.id === where.id,
            );
          } else if (where.userId) {
            user = mockUsers[where.userId];
          }
          if (!user?.employeeProfile) return Promise.resolve(null);
          return Promise.resolve({
            ...user.employeeProfile,
            user: include?.user ? user : undefined,
          });
        }),
        findMany: jest.fn(({ where }) => {
          let list = Object.values(mockUsers)
            .map((u) => u.employeeProfile)
            .filter(Boolean);
          if (where?.departmentId) {
            list = list.filter((e) => e.departmentId === where.departmentId);
          }
          if (where?.id) {
            list = list.filter((e) => e.id === where.id);
          }
          return Promise.resolve(
            list.map((emp) => ({
              ...emp,
              assignedTasks: mockTasks.filter((t) => t.assigneeId === emp.id),
            })),
          );
        }),
        count: jest.fn(() => Promise.resolve(Object.keys(mockUsers).length)),
      },
      department: {
        findUnique: jest.fn(({ where }) => {
          return Promise.resolve(mockDepartments[where.id] || null);
        }),
        findMany: jest.fn(() => {
          return Promise.resolve(
            Object.values(mockDepartments).map((d) => ({
              ...d,
              tasks: mockTasks.filter((t) => t.departmentId === d.id),
            })),
          );
        }),
      },
      task: {
        create: jest.fn(({ data }) => {
          const { checklist, history, ...rest } = data;
          const newTask: any = {
            id: `task-${mockTasks.length + 1}`,
            progress: 0,
            status: TaskStatus.TODO,
            createdAt: new Date(),
            updatedAt: new Date(),
            ...rest,
            assignee: rest.assigneeId
              ? Object.values(mockUsers).find(
                  (u) => u.employeeProfile?.id === rest.assigneeId,
                )?.employeeProfile || null
              : null,
            creator: mockUsers[rest.creatorId] || null,
            department: rest.departmentId
              ? mockDepartments[rest.departmentId]
              : null,
          };

          if (checklist?.create) {
            checklist.create.forEach((c: any, idx: number) => {
              mockChecklistItems.push({
                id: `check-${mockChecklistItems.length + 1}`,
                taskId: newTask.id,
                title: c.title,
                isCompleted: false,
                orderIndex: c.orderIndex ?? idx,
                createdAt: new Date(),
                updatedAt: new Date(),
              });
            });
          }

          if (history?.create) {
            mockHistory.push({
              id: `hist-${mockHistory.length + 1}`,
              taskId: newTask.id,
              ...history.create,
              createdAt: new Date(),
            });
          }

          mockTasks.push(newTask);
          return Promise.resolve(newTask);
        }),
        findUnique: jest.fn(({ where }) => {
          const t = mockTasks.find((item) => item.id === where.id);
          if (!t) return Promise.resolve(null);
          const assignee = t.assigneeId
            ? Object.values(mockUsers).find(
                (u) => u.employeeProfile?.id === t.assigneeId,
              )?.employeeProfile || null
            : null;
          return Promise.resolve({
            ...t,
            assignee,
            checklist: mockChecklistItems
              .filter((c) => c.taskId === t.id)
              .sort((a, b) => a.orderIndex - b.orderIndex),
            comments: mockComments.filter((c) => c.taskId === t.id),
            attachments: mockAttachments.filter((a) => a.taskId === t.id),
            reports: mockReports.filter((r) => r.taskId === t.id),
            history: mockHistory.filter((h) => h.taskId === t.id),
          });
        }),
        findMany: jest.fn(({ where, skip = 0, take = 10 }) => {
          let list = [...mockTasks];
          if (where?.status) {
            if (typeof where.status === "object" && where.status.notIn) {
              list = list.filter((t) => !where.status.notIn.includes(t.status));
            } else {
              list = list.filter((t) => t.status === where.status);
            }
          }
          if (where?.priority) {
            list = list.filter((t) => t.priority === where.priority);
          }
          if (where?.assigneeId) {
            list = list.filter((t) => t.assigneeId === where.assigneeId);
          }
          if (where?.creatorId) {
            list = list.filter((t) => t.creatorId === where.creatorId);
          }
          if (where?.departmentId) {
            list = list.filter((t) => t.departmentId === where.departmentId);
          }
          if (where?.dueDate?.lt) {
            list = list.filter(
              (t) => t.dueDate && t.dueDate < where.dueDate.lt,
            );
          }
          return Promise.resolve(list.slice(skip, skip + take));
        }),
        count: jest.fn(({ where }) => {
          let list = [...mockTasks];
          if (where?.status) {
            if (typeof where.status === "object" && where.status.notIn) {
              list = list.filter((t) => !where.status.notIn.includes(t.status));
            } else {
              list = list.filter((t) => t.status === where.status);
            }
          }
          if (where?.dueDate?.lt) {
            list = list.filter(
              (t) => t.dueDate && t.dueDate < where.dueDate.lt,
            );
          }
          return Promise.resolve(list.length);
        }),
        groupBy: jest.fn(({ by, where }) => {
          const list = [...mockTasks];
          const key = by[0];
          const map: Record<string, number> = {};
          for (const item of list) {
            const val = item[key];
            if (val) {
              map[val] = (map[val] || 0) + 1;
            }
          }
          return Promise.resolve(
            Object.entries(map).map(([k, count]) => ({
              [key]: k,
              _count: { id: count },
            })),
          );
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockTasks.findIndex((t) => t.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          const t = mockTasks[idx];

          if (data.assignee?.connect?.id) {
            t.assigneeId = data.assignee.connect.id;
          }

          const { assignee: _ign, ...restData } = data;
          Object.assign(t, {
            ...restData,
            updatedAt: new Date(),
          });

          const currentAssignee = t.assigneeId
            ? Object.values(mockUsers).find(
                (u) => u.employeeProfile?.id === t.assigneeId,
              )?.employeeProfile || null
            : null;

          mockTasks[idx] = t;
          return Promise.resolve({ ...t, assignee: currentAssignee });
        }),
        updateMany: jest.fn(({ where, data }) => {
          let count = 0;
          for (const t of mockTasks) {
            let match = true;
            if (
              where?.dueDate?.lt &&
              (!t.dueDate || t.dueDate >= where.dueDate.lt)
            ) {
              match = false;
            }
            if (where?.status?.in && !where.status.in.includes(t.status)) {
              match = false;
            }
            if (match) {
              Object.assign(t, data);
              count++;
            }
          }
          return Promise.resolve({ count });
        }),
        delete: jest.fn(({ where }) => {
          const idx = mockTasks.findIndex((t) => t.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          const [removed] = mockTasks.splice(idx, 1);
          return Promise.resolve(removed);
        }),
      },
      taskChecklistItem: {
        create: jest.fn(({ data }) => {
          const item = {
            id: `check-${mockChecklistItems.length + 1}`,
            isCompleted: false,
            createdAt: new Date(),
            updatedAt: new Date(),
            ...data,
          };
          mockChecklistItems.push(item);
          return Promise.resolve(item);
        }),
        findUnique: jest.fn(({ where }) => {
          const item = mockChecklistItems.find((c) => c.id === where.id);
          return Promise.resolve(item || null);
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockChecklistItems.findIndex((c) => c.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          Object.assign(mockChecklistItems[idx], data);
          return Promise.resolve(mockChecklistItems[idx]);
        }),
        delete: jest.fn(({ where }) => {
          const idx = mockChecklistItems.findIndex((c) => c.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          const [removed] = mockChecklistItems.splice(idx, 1);
          return Promise.resolve(removed);
        }),
        count: jest.fn(({ where }) => {
          let list = mockChecklistItems.filter(
            (c) => c.taskId === where.taskId,
          );
          if (where?.isCompleted !== undefined) {
            list = list.filter((c) => c.isCompleted === where.isCompleted);
          }
          return Promise.resolve(list.length);
        }),
      },
      taskComment: {
        create: jest.fn(({ data }) => {
          const comment = {
            id: `comment-${mockComments.length + 1}`,
            createdAt: new Date(),
            updatedAt: new Date(),
            ...data,
            author: mockUsers[data.authorId] || null,
          };
          mockComments.push(comment);
          return Promise.resolve(comment);
        }),
        findMany: jest.fn(({ where }) => {
          return Promise.resolve(
            mockComments.filter((c) => c.taskId === where.taskId),
          );
        }),
      },
      taskAttachment: {
        create: jest.fn(({ data }) => {
          const attachment = {
            id: `att-${mockAttachments.length + 1}`,
            createdAt: new Date(),
            ...data,
            uploadedBy: mockUsers[data.uploadedById] || null,
          };
          mockAttachments.push(attachment);
          return Promise.resolve(attachment);
        }),
        findMany: jest.fn(({ where }) => {
          return Promise.resolve(
            mockAttachments.filter((a) => a.taskId === where.taskId),
          );
        }),
      },
      taskReport: {
        create: jest.fn(({ data }) => {
          const report = {
            id: `rep-${mockReports.length + 1}`,
            status: TaskReportStatus.SUBMITTED,
            createdAt: new Date(),
            updatedAt: new Date(),
            ...data,
          };
          mockReports.push(report);
          return Promise.resolve(report);
        }),
        findFirst: jest.fn(({ where }) => {
          const list = mockReports.filter((r) => r.taskId === where.taskId);
          return Promise.resolve(list[list.length - 1] || null);
        }),
        update: jest.fn(({ where, data }) => {
          const idx = mockReports.findIndex((r) => r.id === where.id);
          if (idx === -1) return Promise.resolve(null);
          Object.assign(mockReports[idx], data);
          return Promise.resolve(mockReports[idx]);
        }),
      },
      taskHistory: {
        create: jest.fn(({ data }) => {
          const h = {
            id: `hist-${mockHistory.length + 1}`,
            createdAt: new Date(),
            ...data,
          };
          mockHistory.push(h);
          return Promise.resolve(h);
        }),
        findMany: jest.fn(({ where }) => {
          return Promise.resolve(
            mockHistory.filter((h) => h.taskId === where.taskId),
          );
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
      $transaction: jest.fn(async (cb) => {
        return cb(prismaService);
      }),
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
          createdAt: new Date(),
        };
        mockNotifications.push(notif);
        return Promise.resolve(notif);
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TasksService,
        TasksRepository,
        WorkManagementService,
        WorkManagementRepository,
        ReportsService,
        TaskAccessGuard,
        { provide: PrismaService, useValue: prismaService },
        { provide: NotificationsService, useValue: notificationsService },
      ],
    }).compile();

    tasksService = module.get<TasksService>(TasksService);
    tasksRepo = module.get<TasksRepository>(TasksRepository);
    workService = module.get<WorkManagementService>(WorkManagementService);
    workRepo = module.get<WorkManagementRepository>(WorkManagementRepository);
    reportsService = module.get<ReportsService>(ReportsService);
    taskAccessGuard = module.get<TaskAccessGuard>(TaskAccessGuard);
  });

  // ============================================================
  // 1. CREATE TASK & ASSIGNMENT
  // ============================================================

  describe("1. Task Creation & Assignment", () => {
    it("1.1 Supervisor creates a task with checklist and assigns it to employee", async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Setup Enterprise Monitoring",
        description: "Deploy Prometheus and Grafana dashboards",
        priority: TaskPriority.HIGH,
        assigneeId: "emp-101",
        departmentId: "dept-eng",
        startDate: "2026-09-03T09:00:00Z",
        dueDate: "2026-09-10T18:00:00Z",
        checklist: [
          { title: "Configure Prometheus scraper" },
          { title: "Import Grafana Dashboards" },
        ],
      });

      expect(task).toBeDefined();
      expect(task.title).toBe("Setup Enterprise Monitoring");
      expect(task.status).toBe(TaskStatus.TODO);
      expect(task.priority).toBe(TaskPriority.HIGH);
      expect(task.progress).toBe(0);
      expect(mockChecklistItems).toHaveLength(2);

      // Verify Audit Log
      expect(mockAuditLogs).toContainEqual(
        expect.objectContaining({
          action: AuditAction.TASK_CREATED,
          userId: "user-manager",
        }),
      );

      // Verify Notification sent to assignee
      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        "user-emp-1",
        "New Task Assigned",
        expect.stringContaining("Setup Enterprise Monitoring"),
        NotificationType.TASK_ASSIGNED,
        expect.anything(),
      );
    });

    it("1.2 Rejects task creation when assignee employee does not exist or is inactive", async () => {
      await expect(
        tasksService.createTask("user-manager", {
          title: "Invalid Task",
          assigneeId: "emp-suspended",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("1.3 Rejects task creation when startDate is after dueDate", async () => {
      await expect(
        tasksService.createTask("user-manager", {
          title: "Time Traveler Task",
          startDate: "2026-09-20T09:00:00Z",
          dueDate: "2026-09-10T09:00:00Z",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("1.4 Re-assigns task to another employee and updates status and history", async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Database Migration",
        assigneeId: "emp-101",
      });

      const reassigned = await tasksService.assignTask(
        task.id,
        "user-manager",
        {
          assigneeId: "emp-102",
          notes: "Handed over due to capacity",
        },
      );

      expect(reassigned.assigneeId).toBe("emp-102");
      expect(mockHistory).toContainEqual(
        expect.objectContaining({
          action: "TASK_ASSIGNED",
          taskId: task.id,
        }),
      );
      expect(mockAuditLogs).toContainEqual(
        expect.objectContaining({
          action: AuditAction.TASK_ASSIGNED,
          userId: "user-manager",
        }),
      );
    });
  });

  // ============================================================
  // 2. EMPLOYEE ACCEPTANCE & LIFECYCLE
  // ============================================================

  describe("2. Employee Task Acceptance & Lifecycle Transitions", () => {
    let taskId: string;

    beforeEach(async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Security Hardening",
        assigneeId: "emp-101",
      });
      taskId = task.id;
    });

    it("2.1 Assigned employee accepts task (TODO -> ACCEPTED)", async () => {
      const accepted = await tasksService.acceptTask(taskId, "user-emp-1");
      expect(accepted.status).toBe(TaskStatus.ACCEPTED);

      expect(mockAuditLogs).toContainEqual(
        expect.objectContaining({
          action: AuditAction.TASK_ACCEPTED,
          userId: "user-emp-1",
        }),
      );

      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        "user-manager",
        "Task Accepted",
        expect.stringContaining("Security Hardening"),
        NotificationType.TASK_STATUS_UPDATE,
        expect.anything(),
      );
    });

    it("2.2 Stranger employee attempting to accept throws ForbiddenException", async () => {
      await expect(
        tasksService.acceptTask(taskId, "user-stranger"),
      ).rejects.toThrow(ForbiddenException);
    });

    it("2.3 Cannot accept a task that is already ACCEPTED or IN_PROGRESS", async () => {
      await tasksService.acceptTask(taskId, "user-emp-1");
      await expect(
        tasksService.acceptTask(taskId, "user-emp-1"),
      ).rejects.toThrow(BadRequestException);
    });

    it("2.4 Valid lifecycle flow: ACCEPTED -> IN_PROGRESS -> BLOCKED -> IN_PROGRESS", async () => {
      await tasksService.acceptTask(taskId, "user-emp-1");

      const inProgress = await tasksService.updateStatus(taskId, "user-emp-1", {
        status: TaskStatus.IN_PROGRESS,
      });
      expect(inProgress.status).toBe(TaskStatus.IN_PROGRESS);

      const blocked = await tasksService.updateStatus(taskId, "user-emp-1", {
        status: TaskStatus.BLOCKED,
        reason: "Waiting for third party SSL certificate",
      });
      expect(blocked.status).toBe(TaskStatus.BLOCKED);

      const unblocked = await tasksService.updateStatus(taskId, "user-emp-1", {
        status: TaskStatus.IN_PROGRESS,
        reason: "Certificate received",
      });
      expect(unblocked.status).toBe(TaskStatus.IN_PROGRESS);
    });

    it("2.5 Disallows invalid status jumps (e.g. TODO -> COMPLETED directly without review or progress)", async () => {
      await expect(
        tasksService.updateStatus(taskId, "user-emp-1", {
          status: TaskStatus.COMPLETED,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ============================================================
  // 3. CHECKLIST ITEMS & PROGRESS
  // ============================================================

  describe("3. Checklist Items & Auto-Progress Calculation", () => {
    it("3.1 Toggling checklist items automatically recalculates progress %", async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Deploy Cluster",
        assigneeId: "emp-101",
        checklist: [
          { title: "Node 1 provision" },
          { title: "Node 2 provision" },
        ],
      });

      expect(task.progress).toBe(0);
      const items = mockChecklistItems.filter((c) => c.taskId === task.id);

      // Toggle item 1 -> 50%
      await tasksService.updateChecklistItem(
        task.id,
        items[0].id,
        "user-emp-1",
        {
          isCompleted: true,
        },
      );
      let fetched = await tasksService.findOne(task.id);
      expect(fetched.progress).toBe(50);

      // Toggle item 2 -> 100%
      await tasksService.updateChecklistItem(
        task.id,
        items[1].id,
        "user-emp-1",
        {
          isCompleted: true,
        },
      );
      fetched = await tasksService.findOne(task.id);
      expect(fetched.progress).toBe(100);
    });

    it("3.2 Adding and removing comments and task attachments", async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Design Specs",
        assigneeId: "emp-101",
      });

      const comment = await tasksService.addComment(task.id, "user-emp-1", {
        content: "Drafting the initial data contract",
      });
      expect(comment.content).toBe("Drafting the initial data contract");

      const attachment = await tasksService.addAttachment(
        task.id,
        "user-emp-1",
        {
          fileName: "specs.pdf",
          fileUrl: "https://cyberwise.test/specs.pdf",
          fileSize: 1024,
          mimeType: "application/pdf",
        },
      );
      expect(attachment.fileName).toBe("specs.pdf");

      const comments = await tasksService.getComments(task.id);
      expect(comments).toHaveLength(1);
    });
  });

  // ============================================================
  // 4. OVERDUE DETECTION & SCANNER
  // ============================================================

  describe("4. Overdue Detection & Low-Resource Scanner", () => {
    it("4.1 Past due date dynamically flags isOverdue = true", async () => {
      const pastDate = new Date(Date.now() - 86400000).toISOString();
      const task = await tasksService.createTask("user-manager", {
        title: "Overdue Task Demo",
        assigneeId: "emp-101",
        dueDate: pastDate,
      });

      const fetched = await tasksService.findOne(task.id);
      expect(fetched.isOverdue).toBe(true);
    });

    it("4.2 Batch overdue scanner marks active tasks as OVERDUE", async () => {
      const pastDate = new Date(Date.now() - 86400000);
      mockTasks.push({
        id: "task-overdue-1",
        title: "Old task",
        status: TaskStatus.IN_PROGRESS,
        dueDate: pastDate,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await workService.checkOverdueTasks();
      expect(result.updatedCount).toBeGreaterThanOrEqual(1);

      const task = mockTasks.find((t) => t.id === "task-overdue-1");
      expect(task.status).toBe(TaskStatus.OVERDUE);
    });
  });

  // ============================================================
  // 5. EMPLOYEE TASK REPORT & MANAGER REVIEW (Full Workflow)
  // ============================================================

  describe("5. Employee Task Report & Manager Review Lifecycle", () => {
    let taskId: string;

    beforeEach(async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Implement SSO Auth",
        assigneeId: "emp-101",
      });
      taskId = task.id;
      await tasksService.acceptTask(taskId, "user-emp-1");
      await tasksService.updateStatus(taskId, "user-emp-1", {
        status: TaskStatus.IN_PROGRESS,
      });
    });

    it("5.1 Employee submits report -> Task transitions to PENDING_REVIEW", async () => {
      const { report, task } = await workService.submitTaskReport(
        taskId,
        "user-emp-1",
        {
          summary: "OAuth 2.0 and SAML implemented with 100% test coverage",
          challenges: "None",
          hoursSpent: 8.5,
          progress: 100,
        },
      );

      expect(report).toBeDefined();
      expect(report.status).toBe(TaskReportStatus.SUBMITTED);
      expect(task.status).toBe(TaskStatus.PENDING_REVIEW);

      expect(mockAuditLogs).toContainEqual(
        expect.objectContaining({
          action: AuditAction.TASK_REPORT_SUBMITTED,
          userId: "user-emp-1",
        }),
      );

      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        "user-manager",
        "Task Report Submitted",
        expect.stringContaining("Implement SSO Auth"),
        NotificationType.TASK_REPORT_SUBMITTED,
        expect.anything(),
      );
    });

    it("5.2 Stranger employee cannot submit report for this task", async () => {
      await expect(
        workService.submitTaskReport(taskId, "user-stranger", {
          summary: "Intrusion attempt",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("5.3 Self-review is strictly forbidden (Employee cannot approve their own report)", async () => {
      await workService.submitTaskReport(taskId, "user-emp-1", {
        summary: "Done",
      });

      await expect(
        workService.reviewTaskReport(taskId, "user-emp-1", {
          action: TaskReviewAction.APPROVE,
          reviewNotes: "I approve myself",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("5.4 Stranger supervisor cannot review employee report outside their jurisdiction", async () => {
      await workService.submitTaskReport(taskId, "user-emp-1", {
        summary: "Done",
      });

      await expect(
        workService.reviewTaskReport(taskId, "user-stranger", {
          action: TaskReviewAction.APPROVE,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("5.5 Manager APPROVES task report -> Task COMPLETED with 100% progress and completedAt", async () => {
      await workService.submitTaskReport(taskId, "user-emp-1", {
        summary: "Code clean and linted",
        hoursSpent: 6,
      });

      const { report, task } = await workService.reviewTaskReport(
        taskId,
        "user-manager",
        {
          action: TaskReviewAction.APPROVE,
          reviewNotes: "Exemplary implementation",
          rating: 5,
        },
      );

      expect(report.status).toBe(TaskReportStatus.APPROVED);
      expect(report.rating).toBe(5);
      expect(task.status).toBe(TaskStatus.COMPLETED);
      expect(task.progress).toBe(100);
      expect(task.completedAt).toBeDefined();

      expect(mockAuditLogs).toContainEqual(
        expect.objectContaining({
          action: AuditAction.TASK_REPORT_REVIEWED,
          userId: "user-manager",
        }),
      );

      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        "user-emp-1",
        "Task Report Approved",
        expect.stringContaining("approved"),
        NotificationType.TASK_REPORT_REVIEWED,
        expect.anything(),
      );
    });

    it("5.6 Manager REJECTS task report -> Task returns to IN_PROGRESS with feedback", async () => {
      await workService.submitTaskReport(taskId, "user-emp-1", {
        summary: "Done first pass",
      });

      const { report, task } = await workService.reviewTaskReport(
        taskId,
        "user-manager",
        {
          action: TaskReviewAction.REJECT,
          reviewNotes: "Missing documentation for corner cases",
        },
      );

      expect(report.status).toBe(TaskReportStatus.REJECTED);
      expect(task.status).toBe(TaskStatus.IN_PROGRESS);

      expect(notificationsService.sendNotification).toHaveBeenCalledWith(
        "user-emp-1",
        "Task Report Returned for Revision",
        expect.stringContaining("Missing documentation"),
        NotificationType.TASK_REPORT_REVIEWED,
        expect.anything(),
      );
    });

    it("5.7 Rejection requires feedback / reviewNotes", async () => {
      await workService.submitTaskReport(taskId, "user-emp-1", {
        summary: "Done",
      });

      await expect(
        workService.reviewTaskReport(taskId, "user-manager", {
          action: TaskReviewAction.REJECT,
          reviewNotes: "",
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ============================================================
  // 6. ZERO-TRUST GUARDS & PENDING REVIEWS
  // ============================================================

  describe("6. Security, Zero-Trust Access & Pending Reviews", () => {
    it("6.1 TaskAccessGuard allows creator, assignee, and manager, and rejects unauthorized", async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Confidential Project",
        assigneeId: "emp-101",
      });

      const mockExecutionContext = (user: any, taskIdParam: string) =>
        ({
          switchToHttp: () => ({
            getRequest: () => ({
              user,
              params: { id: taskIdParam },
            }),
          }),
        }) as any;

      // Assignee has access
      const canAssignee = await taskAccessGuard.canActivate(
        mockExecutionContext(mockUsers["user-emp-1"], task.id),
      );
      expect(canAssignee).toBe(true);

      // Creator has access
      const canCreator = await taskAccessGuard.canActivate(
        mockExecutionContext(mockUsers["user-manager"], task.id),
      );
      expect(canCreator).toBe(true);

      // Super Admin has access
      const canAdmin = await taskAccessGuard.canActivate(
        mockExecutionContext(mockUsers["user-super-admin"], task.id),
      );
      expect(canAdmin).toBe(true);

      // Stranger throws ForbiddenException
      await expect(
        taskAccessGuard.canActivate(
          mockExecutionContext(mockUsers["user-stranger"], task.id),
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it("6.2 Manager sees pending task reviews in queue", async () => {
      const task = await tasksService.createTask("user-manager", {
        title: "Pending Item",
        assigneeId: "emp-101",
      });
      await tasksService.acceptTask(task.id, "user-emp-1");
      await tasksService.updateStatus(task.id, "user-emp-1", {
        status: TaskStatus.IN_PROGRESS,
      });
      await workService.submitTaskReport(task.id, "user-emp-1", {
        summary: "Ready for check",
      });

      const queue = await workService.getPendingReviews("user-manager");
      expect(queue.data).toHaveLength(1);
      expect(queue.data[0].id).toBe(task.id);
    });
  });

  // ============================================================
  // 7. REPORTS & ANALYTICS
  // ============================================================

  describe("7. Task Reports & Statistics", () => {
    beforeEach(async () => {
      // Create a set of tasks in various states
      mockTasks.push(
        {
          id: "task-r1",
          title: "T1",
          status: TaskStatus.COMPLETED,
          priority: TaskPriority.HIGH,
          assigneeId: "emp-101",
          departmentId: "dept-eng",
          createdAt: new Date("2026-08-01"),
          completedAt: new Date("2026-08-03"),
        },
        {
          id: "task-r2",
          title: "T2",
          status: TaskStatus.IN_PROGRESS,
          priority: TaskPriority.MEDIUM,
          assigneeId: "emp-101",
          departmentId: "dept-eng",
          createdAt: new Date("2026-08-05"),
          dueDate: new Date("2026-08-08"),
        },
        {
          id: "task-r3",
          title: "T3",
          status: TaskStatus.COMPLETED,
          priority: TaskPriority.LOW,
          assigneeId: "emp-102",
          departmentId: "dept-eng",
          createdAt: new Date("2026-08-10"),
          completedAt: new Date("2026-08-12"),
        },
      );
    });

    it("7.1 getTaskAnalytics calculates completion rate, active tasks and status grouping", async () => {
      const analytics = await reportsService.getTaskAnalytics({
        startDate: "2026-08-01",
        endDate: "2026-08-31",
      });

      expect(analytics).toBeDefined();
      expect(analytics.summary.totalTasks).toBe(3);
      expect(analytics.summary.completedTasks).toBe(2);
      expect(analytics.summary.completionRate).toBe(66.7);
    });

    it("7.2 getEmployeeTaskProductivity aggregates performance per employee", async () => {
      const prod = await reportsService.getEmployeeTaskProductivity({
        startDate: "2026-08-01",
        endDate: "2026-08-31",
      });

      expect(prod.data).toBeDefined();
      expect(Array.isArray(prod.data)).toBe(true);
    });

    it("7.3 getDepartmentTaskStats calculates metrics per department", async () => {
      const deptStats = await reportsService.getDepartmentTaskStats({});
      expect(deptStats.data).toBeDefined();
      const eng = deptStats.data.find((d: any) => d.departmentCode === "ENG");
      expect(eng).toBeDefined();
    });

    it("7.4 exportTasksCsv generates sanitized CSV content", async () => {
      const csv = await reportsService.exportTasksCsv({
        startDate: "2026-08-01",
        endDate: "2026-08-31",
      });

      expect(typeof csv).toBe("string");
      expect(csv).toContain("Task ID");
      expect(csv).toContain("Title");
    });
  });
});
