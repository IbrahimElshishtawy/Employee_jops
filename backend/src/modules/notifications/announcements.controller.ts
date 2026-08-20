import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { AnnouncementsService } from "./announcements.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";
import { CreateAnnouncementDto, QueryAnnouncementsDto } from "./dto";

@ApiTags("HR Announcements & Broadcasts")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("announcements")
export class AnnouncementsController {
  constructor(private readonly announcementsService: AnnouncementsService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: Create a company or department announcement" })
  @ApiResponse({ status: 201, description: "Announcement created" })
  createAnnouncement(
    @Body() dto: CreateAnnouncementDto,
    @CurrentUser("id") createdById: string,
  ) {
    return this.announcementsService.createAnnouncement(dto, createdById);
  }

  @Get()
  @ApiOperation({
    summary: "Get announcements visible to current user (or all if HR)",
  })
  getAnnouncements(
    @CurrentUser() currentUser: any,
    @Query() query: QueryAnnouncementsDto,
  ) {
    return this.announcementsService.getAnnouncements(currentUser, query);
  }

  @Get(":id")
  @ApiOperation({ summary: "View announcement details (auto-marks as read)" })
  getAnnouncementDetails(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.announcementsService.getAnnouncementDetails(id, userId);
  }

  @Post(":id/publish")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "HR: Publish announcement and broadcast notifications",
  })
  publishAnnouncement(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.announcementsService.publishAnnouncement(id, userId);
  }

  @Post(":id/cancel")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "HR: Cancel an announcement" })
  cancelAnnouncement(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.announcementsService.cancelAnnouncement(id, userId);
  }

  @Post(":id/read")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Mark announcement as read by employee" })
  markAsRead(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.announcementsService.markAsRead(id, userId);
  }
}
