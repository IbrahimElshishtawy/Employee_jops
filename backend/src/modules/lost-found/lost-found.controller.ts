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
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { LostFoundService } from "./lost-found.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role, LostFoundStatus } from "@prisma/client";
import {
  CreateLostFoundItemDto,
  ClaimLostFoundItemDto,
  QueryLostFoundDto,
} from "./dto";

@ApiTags("Lost & Found")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("lost-found")
export class LostFoundController {
  constructor(private readonly lostFoundService: LostFoundService) {}

  @Post()
  @ApiOperation({ summary: "Register a found item" })
  @ApiResponse({ status: 201, description: "Item registered" })
  createItem(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateLostFoundItemDto,
  ) {
    return this.lostFoundService.createItem(userId, dto);
  }

  @Get()
  @ApiOperation({
    summary: "List lost and found items with filters and search",
  })
  findItems(@Query() query: QueryLostFoundDto) {
    return this.lostFoundService.findItems(query);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get details of a lost & found item" })
  findItemById(@Param("id") id: string) {
    return this.lostFoundService.findItemById(id);
  }

  @Post(":id/claim")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Process owner claim and return of item" })
  claimItem(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: ClaimLostFoundItemDto,
  ) {
    return this.lostFoundService.claimItem(id, userId, dto);
  }

  @Patch(":id/status")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({
    summary: "Update item status (DISPOSED, AUCTIONED, EXPIRED)",
  })
  updateItemStatus(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("status") status: LostFoundStatus,
  ) {
    return this.lostFoundService.updateItemStatus(id, userId, status);
  }
}
