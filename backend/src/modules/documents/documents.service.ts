import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { DocumentsRepository } from "./documents.repository";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateDocumentDto,
  UploadDocumentVersionDto,
  QueryDocumentsDto,
} from "./dto";
import { AuditAction, DocumentStatus, Role } from "@prisma/client";

@Injectable()
export class DocumentsService {
  private readonly logger = new Logger(DocumentsService.name);

  constructor(
    private readonly repo: DocumentsRepository,
    private readonly prisma: PrismaService,
  ) {}

  async createDocument(userId: string, dto: CreateDocumentDto) {
    if (dto.departmentId) {
      const dept = await this.prisma.department.findUnique({
        where: { id: dto.departmentId },
      });
      if (!dept)
        throw new NotFoundException(
          `Department '${dto.departmentId}' not found`,
        );
    }

    const documentNumber = await this.repo.generateDocumentNumber();
    const doc = await this.repo.createDocument(userId, dto, documentNumber);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "DocumentRecord",
        entityId: doc.id,
        payload: { documentNumber, title: doc.title, category: doc.category },
      },
    });

    return doc;
  }

  async findDocuments(query: QueryDocumentsDto, userRole?: Role) {
    return this.repo.findDocuments(query, userRole);
  }

  async findDocumentById(id: string, userRole?: Role) {
    const doc = await this.repo.findDocumentById(id);
    if (!doc) throw new NotFoundException(`Document '${id}' not found`);

    if (
      userRole &&
      userRole !== Role.SUPER_ADMIN &&
      !doc.accessRoles.includes(userRole)
    ) {
      throw new ForbiddenException(
        "You do not have permission to access this document",
      );
    }

    return doc;
  }

  async addVersion(
    documentId: string,
    userId: string,
    dto: UploadDocumentVersionDto,
  ) {
    await this.findDocumentById(documentId);

    const result = await this.repo.addVersion(documentId, userId, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "DocumentVersion",
        entityId: result.version.id,
        payload: {
          documentId,
          versionNumber: dto.versionNumber,
          changeSummary: dto.changeSummary,
        },
      },
    });

    return result;
  }

  async archiveDocument(id: string, userId: string) {
    await this.findDocumentById(id);
    const updated = await this.repo.archiveDocument(id);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "DocumentRecord",
        entityId: id,
        payload: { status: DocumentStatus.ARCHIVED },
      },
    });

    return updated;
  }
}
