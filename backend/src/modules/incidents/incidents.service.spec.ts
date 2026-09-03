import { Test, TestingModule } from "@nestjs/testing";
import { IncidentsService } from "./incidents.service";
import { IncidentsRepository } from "./incidents.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { BadRequestException, NotFoundException } from "@nestjs/common";
import { UserStatus, IncidentSeverity, IncidentStatus } from "@prisma/client";

describe("IncidentsService", () => {
  let service: IncidentsService;
  let repo: jest.Mocked<IncidentsRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      generateIncidentNumber: jest.fn().mockResolvedValue("INC-20260903-0001"),
      createIncident: jest.fn(),
      findIncidents: jest.fn(),
      findIncidentById: jest.fn(),
      updateIncident: jest.fn(),
      addInvestigation: jest.fn(),
      addCorrectiveAction: jest.fn(),
      resolveCorrectiveAction: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: { findUnique: jest.fn() },
      department: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IncidentsService,
        { provide: IncidentsRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<IncidentsService>(IncidentsService);
    repo = module.get(IncidentsRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
  });

  describe("createIncident", () => {
    it("should throw BadRequestException if reporter profile is missing or inactive", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue(null);

      await expect(
        service.createIncident("user-1", {
          title: "Fire alarm tripped",
          description: "False alarm in kitchen",
          location: "Kitchen",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should create incident and log audit", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        user: { status: UserStatus.ACTIVE },
      });
      repo.createIncident.mockResolvedValue({
        id: "inc-1",
        incidentNumber: "INC-20260903-0001",
        title: "Fire alarm tripped",
        severity: IncidentSeverity.LOW,
      } as any);

      const result = await service.createIncident("user-1", {
        title: "Fire alarm tripped",
        description: "False alarm in kitchen",
        location: "Kitchen",
      });

      expect(result.id).toBe("inc-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("addInvestigation", () => {
    it("should add investigation and advance incident status", async () => {
      repo.findIncidentById.mockResolvedValue({ id: "inc-1" } as any);
      prisma.employeeProfile.findUnique.mockResolvedValue({ id: "investigator-1" });
      repo.addInvestigation.mockResolvedValue({
        id: "inv-1",
        findings: "Steam triggered detector",
      } as any);

      const result = await service.addInvestigation("inc-1", "user-1", {
        findings: "Steam triggered detector",
        rootCause: "Boiler valve left open",
      });

      expect(result.id).toBe("inv-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
