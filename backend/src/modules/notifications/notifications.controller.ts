import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { NotificationsService } from "./notifications.service";
import { RegisterDeviceTokenDto } from "./dto/register-device.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Notifications")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("notifications")
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post("device-token")
  @ApiOperation({
    summary: "Register FCM device token for mobile push notifications",
  })
  registerDevice(
    @CurrentUser("id") userId: string,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.notificationsService.registerDeviceToken(userId, dto);
  }

  @Get("my")
  @ApiOperation({ summary: "Get current user in-app notifications" })
  getMyNotifications(@CurrentUser("id") userId: string) {
    return this.notificationsService.getMyNotifications(userId);
  }

  @Patch(":id/read")
  @ApiOperation({ summary: "Mark single notification as read" })
  markAsRead(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.notificationsService.markAsRead(id, userId);
  }

  @Patch("read-all")
  @ApiOperation({ summary: "Mark all notifications as read" })
  markAllAsRead(@CurrentUser("id") userId: string) {
    return this.notificationsService.markAllAsRead(userId);
  }
}
