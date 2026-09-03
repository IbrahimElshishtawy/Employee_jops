import { Test, TestingModule } from "@nestjs/testing";
import { DocumentsService } from "./documents.service";
import { DocumentsRepository } from "./documents.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ForbiddenException } from "@nestjs/common";
import { Role } from "@prisma/client";

describe("DocumentsService", () => {
  let service: DocumentsService;
  let repo: jest.Mocked<DocumentsRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      generateDocumentNumber: jest.fn().mockResolvedValue("DOC-20260903-0001"),
      createDocument: jest.fn(),
      findDocuments: jest.fn(),
      findDocumentById: jest.fn(),
      addVersion: jest.fn(),
      archiveDocument: jest.fn(),
    };

    const mockPrisma = {
      department: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DocumentsService,
        { provide: DocumentsRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<DocumentsService>(DocumentsService);
    repo = module.get(DocumentsRepository);
    prisma = module.get(PrismaService);
  });

  describe("createDocument", () => {
    it("should create document and log audit", async () => {
      repo.createDocument.mockResolvedValue({
        id: "doc-1",
        documentNumber: "DOC-20260903-0001",
        title: "Front Desk SOP",
        category: "SOP",
      } as any);

      const result = await service.createDocument("user-1", {
        title: "Front Desk SOP",
        fileUrl: "https://storage.com/sop.pdf",
      });

      expect(result.id).toBe("doc-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("findDocumentById", () => {
    it("should throw ForbiddenException if user role is not permitted", async () => {
      repo.findDocumentById.mockResolvedValue({
        id: "doc-1",
        title: "Financial Audit",
        accessRoles: [Role.SUPER_ADMIN, Role.HR_ADMIN],
      } as any);

      await expect(
        service.findDocumentById("doc-1", Role.EMPLOYEE),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should allow access if role is included", async () => {
      repo.findDocumentById.mockResolvedValue({
        id: "doc-1",
        title: "Financial Audit",
        accessRoles: [Role.SUPER_ADMIN, Role.HR_ADMIN],
      } as any);

      const result = await service.findDocumentById("doc-1", Role.HR_ADMIN);
      expect(result.id).toBe("doc-1");
    });
  });
});
