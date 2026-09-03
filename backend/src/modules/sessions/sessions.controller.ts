import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { SessionsService } from "./sessions.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { RegisterDeviceSessionDto } from "./dto";

@ApiTags("Sessions & Active Devices")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("sessions")
export class SessionsController {
  constructor(private readonly sessionsService: SessionsService) {}

  @Post("register")
  @ApiOperation({
    summary: "Register or refresh device session (FCM token, hardware ID)",
  })
  @ApiResponse({ status: 200, description: "Device registered" })
  registerDeviceSession(
    @CurrentUser("id") userId: string,
    @Body() dto: RegisterDeviceSessionDto,
  ) {
    return this.sessionsService.registerDeviceSession(userId, dto);
  }

  @Get("my-devices")
  @ApiOperation({
    summary: "List currently active device sessions for current user",
  })
  getMyActiveSessions(@CurrentUser("id") userId: string) {
    return this.sessionsService.getMyActiveSessions(userId);
  }

  @Delete(":id")
  @ApiOperation({
    summary: "Remotely revoke and terminate a specific device session",
  })
  terminateSession(
    @Param("id") sessionId: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.sessionsService.terminateSession(userId, sessionId);
  }

  @Delete("other/:currentSessionId")
  @ApiOperation({
    summary:
      "Revoke and terminate all other devices except the current session",
  })
  terminateAllOtherSessions(
    @Param("currentSessionId") currentSessionId: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.sessionsService.terminateAllOtherSessions(
      userId,
      currentSessionId,
    );
  }
}
