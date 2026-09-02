import { Test, TestingModule } from "@nestjs/testing";
import { HrService } from "./hr.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotFoundException, BadRequestException } from "@nestjs/common";
import { EmployeeDocumentType } from "@prisma/client";

describe("HrService", () => {
  let service: HrService;
  let prisma: any;

  const mockPrismaService = {
    employeeProfile: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    employeeDocument: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    position: {
      findUnique: jest.fn(),
    },
    department: {
      findUnique: jest.fn(),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({ id: "audit-1" }),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HrService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<HrService>(HrService);
    prisma = module.get<PrismaService>(PrismaService);
    jest.clearAllMocks();
  });

  describe("getEmployees", () => {
    it("should return paginated employees and mask nationalId", async () => {
      mockPrismaService.employeeProfile.count.mockResolvedValue(1);
      mockPrismaService.employeeProfile.findMany.mockResolvedValue([
        {
          id: "emp-1",
          firstName: "Omar",
          lastName: "Ali",
          nationalId: "29801011234567",
          employeeCode: "CW-1001",
          jobTitle: "Developer",
        },
      ]);

      const result = await service.getEmployees({
        page: 1,
        limit: 10,
        skip: 0,
      } as any);

      expect(result.data.length).toBe(1);
      expect(result.data[0].nationalId).toBe("**********4567");
      expect(result.meta.total).toBe(1);
    });
  });

  describe("getEmployeeById", () => {
    it("should return full employee profile if found", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        firstName: "Omar",
        lastName: "Ali",
        nationalId: "29801011234567",
        documents: [],
      });

      const result = await service.getEmployeeById("emp-1");
      expect(result.id).toBe("emp-1");
      expect(result.nationalId).toBe("**********4567");
    });

    it("should throw NotFoundException if employee not found", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue(null);
      await expect(service.getEmployeeById("non-existent")).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe("updateEmployeeAssignment", () => {
    it("should prevent employee from being their own manager", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
      });

      await expect(
        service.updateEmployeeAssignment(
          "emp-1",
          { managerId: "emp-1" },
          "admin-1",
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it("should update assignment and sync titles if positionId is supplied", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
      });
      mockPrismaService.position.findUnique.mockResolvedValue({
        id: "pos-1",
        title: "Lead Architect",
      });
      mockPrismaService.employeeProfile.update.mockResolvedValue({
        id: "emp-1",
        jobTitle: "Lead Architect",
        positionId: "pos-1",
        nationalId: null,
      });

      const result = await service.updateEmployeeAssignment(
        "emp-1",
        { positionId: "pos-1" },
        "admin-1",
      );

      expect(result.jobTitle).toBe("Lead Architect");
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("addEmployeeDocument & verifyEmployeeDocument", () => {
    it("should create document metadata and audit log", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
      });
      mockPrismaService.employeeDocument.create.mockResolvedValue({
        id: "doc-1",
        employeeId: "emp-1",
        title: "National ID",
        documentType: EmployeeDocumentType.NATIONAL_ID,
      });

      const doc = await service.addEmployeeDocument(
        "emp-1",
        {
          title: "National ID",
          documentType: EmployeeDocumentType.NATIONAL_ID,
        },
        "admin-1",
      );

      expect(doc.id).toBe("doc-1");
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should verify document metadata", async () => {
      mockPrismaService.employeeDocument.findUnique.mockResolvedValue({
        id: "doc-1",
      });
      mockPrismaService.employeeDocument.update.mockResolvedValue({
        id: "doc-1",
        isVerified: true,
        verifiedById: "admin-1",
      });

      const result = await service.verifyEmployeeDocument(
        "doc-1",
        { isVerified: true, notes: "Verified" },
        "admin-1",
      );

      expect(result.isVerified).toBe(true);
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });
  });
});
