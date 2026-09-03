import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Param,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { OfflineSyncService } from "./offline-sync.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { PushSyncBatchDto, QuerySyncQueueDto, ResolveConflictDto } from "./dto";
import { SyncStatus } from "@prisma/client";

@ApiTags("Offline Sync Engine")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("sync")
export class OfflineSyncController {
  constructor(private readonly offlineSyncService: OfflineSyncService) {}

  @Post()
  @ApiOperation({
    summary: "Standard mobile client sync endpoint (POST /api/v1/sync)",
  })
  @ApiResponse({ status: 200, description: "Batch processed" })
  sync(
    @CurrentUser("id") userId: string,
    @Body() dto: PushSyncBatchDto,
  ) {
    return this.offlineSyncService.processSyncBatch(userId, dto);
  }

  @Post("batch")
  @ApiOperation({
    summary: "Push batch of offline actions recorded on mobile client",
  })
  @ApiResponse({ status: 200, description: "Batch processed" })
  processSyncBatch(
    @CurrentUser("id") userId: string,
    @Body() dto: PushSyncBatchDto,
  ) {
    return this.offlineSyncService.processSyncBatch(userId, dto);
  }

  @Get("changes")
  @ApiOperation({
    summary: "Retrieve server delta changes since client cursor (FR-SYNC-001)",
  })
  getServerChanges(
    @CurrentUser("id") userId: string,
    @Query("cursor") cursor?: string,
  ) {
    return this.offlineSyncService.getServerChanges(userId, cursor);
  }

  @Get("queue")
  @ApiOperation({ summary: "Check status of previously submitted sync items" })
  getMySyncQueue(
    @CurrentUser("id") userId: string,
    @Query() query: QuerySyncQueueDto,
  ) {
    return this.offlineSyncService.getMySyncQueue(userId, query);
  }

  @Post("retry/:id")
  @ApiOperation({
    summary: "Retry a failed or pending sync item (FR-SYNC-006)",
  })
  retryItem(@CurrentUser("id") userId: string, @Param("id") itemId: string) {
    return this.offlineSyncService.retryItem(userId, itemId);
  }

  @Post("resolve-conflict/:id")
  @ApiOperation({
    summary:
      "Resolve a synchronization conflict item using specified strategy (FR-SYNC-007)",
  })
  resolveConflict(
    @CurrentUser("id") userId: string,
    @Param("id") itemId: string,
    @Body() dto: ResolveConflictDto,
  ) {
    return this.offlineSyncService.resolveConflict(userId, itemId, dto);
  }

  @Get("logs")
  @ApiOperation({
    summary: "Query operational synchronization audit logs (FR-SYNC-008)",
  })
  getSyncLogs(
    @Query("entityType") entityType?: string,
    @Query("status") status?: SyncStatus,
    @Query("page") page?: number,
    @Query("limit") limit?: number,
  ) {
    return this.offlineSyncService.getSyncLogs({
      entityType,
      status,
      page,
      limit,
    });
  }
}
