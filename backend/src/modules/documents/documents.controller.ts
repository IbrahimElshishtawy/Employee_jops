import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { DocumentsService } from "./documents.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateDocumentDto,
  UploadDocumentVersionDto,
  QueryDocumentsDto,
} from "./dto";

@ApiTags("Documents Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("documents")
export class DocumentsController {
  constructor(private readonly documentsService: DocumentsService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Upload and register a document in central archive",
  })
  createDocument(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateDocumentDto,
  ) {
    return this.documentsService.createDocument(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List accessible documents based on user role" })
  findDocuments(
    @Query() query: QueryDocumentsDto,
    @CurrentUser("role") role: Role,
  ) {
    return this.documentsService.findDocuments(query, role);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get document details and version history" })
  findDocumentById(@Param("id") id: string, @CurrentUser("role") role: Role) {
    return this.documentsService.findDocumentById(id, role);
  }

  @Post(":id/versions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Upload a new version of an existing document" })
  addVersion(
    @Param("id") documentId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UploadDocumentVersionDto,
  ) {
    return this.documentsService.addVersion(documentId, userId, dto);
  }

  @Patch(":id/archive")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Archive an obsolete document" })
  archiveDocument(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.documentsService.archiveDocument(id, userId);
  }
}
