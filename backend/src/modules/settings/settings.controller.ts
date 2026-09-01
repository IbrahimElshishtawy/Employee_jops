import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from "@nestjs/swagger";
import { SettingsService } from "./settings.service";
import {
  SetSystemSettingDto,
  QuerySettingsDto,
  CreateFeatureFlagDto,
  UpdateFeatureFlagDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Public } from "../../common/decorators/public.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("Settings & Feature Flags")
@Controller("settings")
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  // ==========================================
  // 1. PUBLIC SETTINGS
  // ==========================================

  @Get("public")
  @Public()
  @ApiOperation({ summary: "Get public system settings (Unauthenticated bootstrap endpoint)" })
  getPublicSettings() {
    return this.settingsService.getPublicSettings();
  }

  // ==========================================
  // 2. SYSTEM SETTINGS
  // ==========================================

  @Get()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Get all system settings with category filtering" })
  getAllSettings(@Query() query: QuerySettingsDto) {
    return this.settingsService.getAllSettings(query);
  }

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Set or update a system setting (Super Admin only)" })
  @ApiResponse({ status: 201, description: "Setting saved successfully" })
  setSetting(
    @Body() dto: SetSystemSettingDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.settingsService.setSetting(dto, userId);
  }

  @Delete(":key")
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Delete a system setting (Super Admin only)" })
  deleteSetting(
    @Param("key") key: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.settingsService.deleteSetting(key, userId);
  }

  // ==========================================
  // 3. FEATURE FLAGS
  // ==========================================

  @Get("flags")
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "List all system feature flags" })
  @ApiQuery({ name: "organizationId", required: false })
  getFeatureFlags(@Query("organizationId") organizationId?: string) {
    return this.settingsService.getFeatureFlags(organizationId);
  }

  @Post("flags")
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Create a feature flag" })
  createFeatureFlag(
    @Body() dto: CreateFeatureFlagDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.settingsService.createFeatureFlag(dto, userId);
  }

  @Put("flags/:key")
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Update feature flag status and rules" })
  updateFeatureFlag(
    @Param("key") key: string,
    @Body() dto: UpdateFeatureFlagDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.settingsService.updateFeatureFlag(key, dto, userId);
  }
}
