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
import { AssetsService } from "./assets.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateAssetDto,
  UpdateAssetDto,
  CreateAssetCategoryDto,
  QueryAssetsDto,
} from "./dto";

@ApiTags("Assets Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("assets")
export class AssetsController {
  constructor(private readonly assetsService: AssetsService) {}

  // Categories
  @Post("categories")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create an asset category" })
  @ApiResponse({ status: 201, description: "Category created" })
  createCategory(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateAssetCategoryDto,
  ) {
    return this.assetsService.createCategory(userId, dto);
  }

  @Get("categories")
  @ApiOperation({ summary: "List all asset categories" })
  getCategories() {
    return this.assetsService.getCategories();
  }

  // Assets
  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Register a new asset" })
  @ApiResponse({ status: 201, description: "Asset created" })
  createAsset(@CurrentUser("id") userId: string, @Body() dto: CreateAssetDto) {
    return this.assetsService.createAsset(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List assets with pagination and filters" })
  findAll(@Query() query: QueryAssetsDto) {
    return this.assetsService.findAll(query);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get asset details by ID" })
  findOne(@Param("id") id: string) {
    return this.assetsService.findOne(id);
  }

  @Patch(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Update asset metadata, status, location, or assignment",
  })
  updateAsset(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateAssetDto,
  ) {
    return this.assetsService.updateAsset(id, userId, dto);
  }

  @Post(":id/calculate-depreciation")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Calculate straight-line depreciation for an asset",
  })
  calculateDepreciation(@Param("id") id: string) {
    return this.assetsService.calculateDepreciation(id);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Delete an asset" })
  deleteAsset(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.assetsService.deleteAsset(id, userId);
  }
}
