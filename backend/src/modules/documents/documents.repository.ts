import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateDocumentDto, UploadDocumentVersionDto, QueryDocumentsDto } from "./dto";
import { Prisma, DocumentStatus, Role } from "@prisma/client";

@Injectable()
export class DocumentsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateDocumentNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.documentRecord.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `DOC-${today}-${seq}`;
  }

  async createDocument(userId: string, dto: CreateDocumentDto, documentNumber: string) {
    return this.prisma.$transaction(async (tx) => {
      const doc = await tx.documentRecord.create({
        data: {
          documentNumber,
          title: dto.title,
          description: dto.description,
          category: dto.category,
          status: DocumentStatus.ACTIVE,
          fileUrl: dto.fileUrl,
          fileType: dto.fileType || "pdf",
          fileSize: dto.fileSize || 0,
          currentVersion: dto.currentVersion || "1.0",
          expirationDate: dto.expirationDate ? new Date(dto.expirationDate) : null,
          departmentId: dto.departmentId,
          accessRoles: dto.accessRoles || [Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER],
          createdById: userId,
        },
        include: {
          createdBy: { select: { email: true } },
        },
      });

      // Also create initial DocumentVersion record
      await tx.documentVersion.create({
        data: {
          documentId: doc.id,
          versionNumber: dto.currentVersion || "1.0",
          fileUrl: dto.fileUrl,
          changeSummary: "Initial version",
          uploadedById: userId,
        },
      });

      return doc;
    });
  }

  async findDocuments(query: QueryDocumentsDto, userRole?: Role) {
    const { page = 1, limit = 20, search, category, status, departmentId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.DocumentRecordWhereInput = {};
    if (category) where.category = category;
    if (status) where.status = status;
    if (departmentId) where.departmentId = departmentId;
    if (userRole && userRole !== Role.SUPER_ADMIN) {
      where.accessRoles = { has: userRole };
    }
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { documentNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.documentRecord.count({ where }),
      this.prisma.documentRecord.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          createdBy: { select: { email: true } },
          _count: { select: { versions: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findDocumentById(id: string) {
    return this.prisma.documentRecord.findUnique({
      where: { id },
      include: {
        createdBy: { select: { email: true } },
        versions: {
          orderBy: { createdAt: "desc" },
          include: {
            uploadedBy: { select: { email: true } },
          },
        },
      },
    });
  }

  async addVersion(documentId: string, userId: string, dto: UploadDocumentVersionDto) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Create version
      const version = await tx.documentVersion.create({
        data: {
          documentId,
          versionNumber: dto.versionNumber,
          fileUrl: dto.fileUrl,
          changeSummary: dto.changeSummary,
          uploadedById: userId,
        },
        include: { uploadedBy: { select: { email: true } } },
      });

      // 2. Update current version and fileUrl on DocumentRecord
      const doc = await tx.documentRecord.update({
        where: { id: documentId },
        data: {
          currentVersion: dto.versionNumber,
          fileUrl: dto.fileUrl,
        },
        include: { versions: true },
      });

      return { version, doc };
    });
  }

  async archiveDocument(id: string) {
    return this.prisma.documentRecord.update({
      where: { id },
      data: { status: DocumentStatus.ARCHIVED },
    });
  }
}
