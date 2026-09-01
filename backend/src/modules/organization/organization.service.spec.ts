import { Test, TestingModule } from "@nestjs/testing";
import { OrganizationService } from "./organization.service";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictException, NotFoundException } from "@nestjs/common";

describe("OrganizationService", () => {
  let service: OrganizationService;

  const mockPrismaService = {
    organization: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    branch: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    department: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    section: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    position: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    employeeProfile: {
      findUnique: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrganizationService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<OrganizationService>(OrganizationService);
    jest.clearAllMocks();
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("createOrganization", () => {
    it("should create organization and record audit log", async () => {
      mockPrismaService.organization.findUnique.mockResolvedValue(null);
      mockPrismaService.organization.create.mockResolvedValue({
        id: "org-1",
        name: "CyberWise Group",
        code: "CW-GRP",
      });
      mockPrismaService.auditLog.create.mockResolvedValue({});

      const res = await service.createOrganization(
        { name: "CyberWise Group", code: "CW-GRP" },
        "admin-id",
      );

      expect(res.code).toBe("CW-GRP");
      expect(mockPrismaService.organization.create).toHaveBeenCalled();
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should throw ConflictException if organization code exists", async () => {
      mockPrismaService.organization.findUnique.mockResolvedValue({
        id: "org-1",
        code: "CW-GRP",
      });

      await expect(
        service.createOrganization({ name: "CyberWise Group", code: "CW-GRP" }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe("createDepartment", () => {
    it("should create department successfully", async () => {
      mockPrismaService.department.findUnique.mockResolvedValue(null);
      mockPrismaService.department.create.mockResolvedValue({
        id: "dept-1",
        organizationId: "org-1",
        name: "Engineering",
        code: "ENG",
      });
      mockPrismaService.auditLog.create.mockResolvedValue({});

      const res = await service.createDepartment(
        { organizationId: "org-1", name: "Engineering", code: "ENG" },
        "admin-id",
      );

      expect(res.code).toBe("ENG");
    });
  });

  describe("getOrganizationHierarchy", () => {
    it("should return organization tree", async () => {
      mockPrismaService.organization.findFirst.mockResolvedValue({
        id: "org-1",
        name: "CyberWise Group",
        branches: [
          {
            id: "b-1",
            name: "Cairo Branch",
            departments: [
              {
                id: "d-1",
                name: "HR",
                subDepartments: [],
                sections: [],
                positions: [],
              },
            ],
          },
        ],
      });

      const res = await service.getOrganizationHierarchy("org-1");
      expect(res.branches).toHaveLength(1);
    });

    it("should throw NotFoundException if hierarchy not found", async () => {
      mockPrismaService.organization.findFirst.mockResolvedValue(null);
      await expect(
        service.getOrganizationHierarchy("non-existent"),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe("getEmployeeReportingHierarchy", () => {
    it("should return employee chain of command and direct reports", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        employeeCode: "CW-001",
        firstName: "Tariq",
        lastName: "Zaid",
        manager: {
          id: "mgr-1",
          firstName: "Sarah",
          lastName: "Mansoor",
          jobTitle: "HR Manager",
          manager: {
            id: "mgr-top",
            firstName: "System",
            lastName: "Administrator",
            jobTitle: "CEO",
          },
        },
        directReports: [
          {
            id: "sub-1",
            employeeCode: "CW-002",
            firstName: "Junior",
            lastName: "Dev",
          },
        ],
      });

      const res = await service.getEmployeeReportingHierarchy("emp-1");
      expect(res.managementChain).toHaveLength(2);
      expect(res.directReports).toHaveLength(1);
      expect(res.totalDirectReports).toBe(1);
    });
  });
});
