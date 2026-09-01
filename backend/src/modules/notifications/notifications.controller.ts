import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";

import { NotificationsService } from "./notifications.service";
import {
  RegisterDeviceTokenDto,
  QueryNotificationsDto,
  UpdateNotificationPreferencesDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Notifications & In-App Alerts")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("notifications")
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post("device-token")
  @ApiOperation({
    summary: "Register/Refresh FCM device token for push notifications",
  })
  registerDevice(
    @CurrentUser("id") userId: string,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.notificationsService.registerDeviceToken(userId, dto);
  }

  @Delete("device-token/:fcmToken")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Unregister/Deactivate device token on logout" })
  removeDevice(
    @CurrentUser("id") userId: string,
    @Param("fcmToken") fcmToken: string,
  ) {
    return this.notificationsService.removeDeviceToken(userId, fcmToken);
  }

  @Get()
  @ApiOperation({
    summary: "Get current user notifications with pagination & filters",
  })
  getMyNotifications(
    @CurrentUser("id") userId: string,
    @Query() query: QueryNotificationsDto,
  ) {
    return this.notificationsService.getMyNotifications(userId, query);
  }

  @Get("my")
  @ApiOperation({ summary: "Get current user notifications (alias)" })
  getMyNotificationsAlias(
    @CurrentUser("id") userId: string,
    @Query() query: QueryNotificationsDto,
  ) {
    return this.notificationsService.getMyNotifications(userId, query);
  }

  @Get("unread-count")
  @ApiOperation({ summary: "Get count of unread in-app notifications" })
  getUnreadCount(@CurrentUser("id") userId: string) {
    return this.notificationsService.getUnreadCount(userId);
  }

  @Post(":id/read")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Mark single notification as read" })
  markAsRead(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.notificationsService.markAsRead(id, userId);
  }

  @Patch(":id/read")
  @ApiOperation({ summary: "Mark single notification as read (PATCH alias)" })
  markAsReadPatch(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.notificationsService.markAsRead(id, userId);
  }

  @Post("read-all")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Mark all notifications as read in bulk" })
  markAllAsRead(@CurrentUser("id") userId: string) {
    return this.notificationsService.markAllAsRead(userId);
  }

  @Patch("read-all")
  @ApiOperation({
    summary: "Mark all notifications as read in bulk (PATCH alias)",
  })
  markAllAsReadPatch(@CurrentUser("id") userId: string) {
    return this.notificationsService.markAllAsRead(userId);
  }

  @Get("preferences")
  @ApiOperation({ summary: "Get user notification channel preferences" })
  getPreferences(@CurrentUser("id") userId: string) {
    return this.notificationsService.getPreferences(userId);
  }

  @Patch("preferences")
  @ApiOperation({ summary: "Update user notification channel preferences" })
  updatePreferences(
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateNotificationPreferencesDto,
  ) {
    return this.notificationsService.updatePreferences(userId, dto);
  }
}
