import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { IntegrationsService } from "./integrations.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import { CreateApiKeyDto, CreateWebhookDto, QueryLogsDto } from "./dto";

@ApiTags("Integrations & Webhooks")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
@Controller("integrations")
export class IntegrationsController {
  constructor(private readonly integrationsService: IntegrationsService) {}

  // API Keys
  @Post("api-keys")
  @ApiOperation({ summary: "Generate a new scoped API key (SHA-256 hashed)" })
  createApiKey(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateApiKeyDto,
  ) {
    return this.integrationsService.createApiKey(userId, dto);
  }

  @Get("api-keys")
  @ApiOperation({ summary: "List active API keys with prefixes and scopes" })
  findApiKeys() {
    return this.integrationsService.findApiKeys();
  }

  @Delete("api-keys/:id")
  @ApiOperation({ summary: "Revoke an API key" })
  revokeApiKey(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.integrationsService.revokeApiKey(id, userId);
  }

  // Webhooks
  @Post("webhooks")
  @ApiOperation({ summary: "Register an outgoing webhook subscription" })
  createWebhook(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateWebhookDto,
  ) {
    return this.integrationsService.createWebhook(userId, dto);
  }

  @Get("webhooks")
  @ApiOperation({ summary: "List configured webhooks" })
  findWebhooks() {
    return this.integrationsService.findWebhooks();
  }

  @Patch("webhooks/:id/status")
  @ApiOperation({ summary: "Enable or disable a webhook configuration" })
  updateWebhookStatus(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("isActive") isActive: boolean,
  ) {
    return this.integrationsService.updateWebhookStatus(id, userId, isActive);
  }

  // Logs
  @Get("logs")
  @ApiOperation({ summary: "Audit integration request logs" })
  findLogs(@Query() query: QueryLogsDto) {
    return this.integrationsService.findLogs(query);
  }
}
