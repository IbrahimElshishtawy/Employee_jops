import {
  Controller,
  Post,
  Body,
  Get,
  Req,
  HttpCode,
  HttpStatus,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { LoginDto } from "./dto/login.dto";
import { GoogleLoginDto } from "./dto/google-login.dto";
import { RefreshTokenDto } from "./dto/refresh-token.dto";
import { ChangePasswordDto } from "./dto/change-password.dto";
import { AuthResponseDto } from "./dto/auth-response.dto";
import { Public } from "../../common/decorators/public.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { FastifyRequest } from "fastify";

@ApiTags("Authentication")
@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post("google")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Employee Google Sign-In with authoritative onboarding state",
  })
  @ApiResponse({ status: 200, type: AuthResponseDto })
  async googleLogin(@Body() dto: GoogleLoginDto, @Req() req: FastifyRequest) {
    const meta = {
      ipAddress: req.ip,
      userAgent: req.headers["user-agent"],
    };
    return this.authService.googleLogin(dto, meta);
  }

  @Public()
  @Post("login")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Login user with Email/Password (HR Dashboard / Admin)",
  })
  @ApiResponse({ status: 200, type: AuthResponseDto })
  async login(@Body() dto: LoginDto, @Req() req: FastifyRequest) {
    const meta = {
      ipAddress: req.ip,
      userAgent: req.headers["user-agent"],
    };
    return this.authService.login(dto, meta);
  }

  @Public()
  @Post("refresh")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Rotate and refresh JWT access token" })
  async refresh(@Body() dto: RefreshTokenDto, @Req() req: FastifyRequest) {
    const meta = {
      ipAddress: req.ip,
      userAgent: req.headers["user-agent"],
    };
    return this.authService.refreshToken(dto.refreshToken, meta);
  }

  @UseGuards(JwtAuthGuard)
  @Post("logout")
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Logout and revoke refresh token" })
  async logout(
    @CurrentUser("id") userId: string,
    @Body() dto: RefreshTokenDto,
  ) {
    await this.authService.logout(dto.refreshToken, userId);
    return { message: "Logged out successfully" };
  }

  @UseGuards(JwtAuthGuard)
  @Post("change-password")
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Change password for authenticated user" })
  async changePassword(
    @CurrentUser("id") userId: string,
    @Body() dto: ChangePasswordDto,
  ) {
    await this.authService.changePassword(userId, dto);
    return { message: "Password changed successfully" };
  }

  @UseGuards(JwtAuthGuard)
  @Get("me")
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get current authenticated user & profile status" })
  async getMe(@CurrentUser("id") userId: string) {
    return this.authService.getMe(userId);
  }
}
