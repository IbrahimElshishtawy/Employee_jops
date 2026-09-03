import {
  Controller,
  Get,
  Post,
  Body,
  Query,
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
import { PushSyncBatchDto, QuerySyncQueueDto } from "./dto";

@ApiTags("Offline Sync Engine")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("sync")
export class OfflineSyncController {
  constructor(private readonly offlineSyncService: OfflineSyncService) {}

  @Post("batch")
  @ApiOperation({ summary: "Push batch of offline actions recorded on mobile client" })
  @ApiResponse({ status: 200, description: "Batch processed" })
  processSyncBatch(
    @CurrentUser("id") userId: string,
    @Body() dto: PushSyncBatchDto,
  ) {
    return this.offlineSyncService.processSyncBatch(userId, dto);
  }

  @Get("queue")
  @ApiOperation({ summary: "Check status of previously submitted sync items" })
  getMySyncQueue(
    @CurrentUser("id") userId: string,
    @Query() query: QuerySyncQueueDto,
  ) {
    return this.offlineSyncService.getMySyncQueue(userId, query);
  }
}
