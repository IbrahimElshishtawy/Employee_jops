import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from "@nestjs/swagger";
import { BackupService } from "./backup.service";
import { CreateBackupDto, RestoreBackupDto } from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Backup & Disaster Recovery")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("backup")
export class BackupController {
  constructor(private readonly backupService: BackupService) {}

  @Post("create")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Create immediate database & system state backup (OPS-006)" })
  createBackup(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateBackupDto,
  ) {
    return this.backupService.createBackup(userId, dto);
  }

  @Get("list")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "List all existing system backups with checksums" })
  listBackups() {
    return this.backupService.listBackups();
  }

  @Get("health")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Backup readiness, storage, and retention health check" })
  getHealth() {
    return this.backupService.getBackupHealth();
  }

  @Get(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Get single backup details by ID or Number" })
  getBackup(@Param("id") id: string) {
    return this.backupService.getBackup(id);
  }

  @Post(":id/restore")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Test restore simulation or execute restore (OPS-007)" })
  restoreBackup(
    @CurrentUser("id") userId: string,
    @Param("id") id: string,
    @Body() dto: RestoreBackupDto,
  ) {
    return this.backupService.restoreBackup(userId, id, dto);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Delete backup according to retention policy (OPS-008)" })
  deleteBackup(
    @CurrentUser("id") userId: string,
    @Param("id") id: string,
  ) {
    return this.backupService.deleteBackup(userId, id);
  }
}
