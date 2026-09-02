import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
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
  ApiParam,
  ApiResponse,
} from "@nestjs/swagger";
import { ApprovalsService } from "./approvals.service";
import {
  ProcessApprovalDto,
  CreateDelegationDto,
  QueryPendingApprovalsDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";

@ApiTags("Approvals")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("approvals")
export class ApprovalsController {
  constructor(private readonly approvalsService: ApprovalsService) {}

  @Get("pending")
  @ApiOperation({
    summary:
      "Get pending requests awaiting review by current user (as Direct Manager, Dept Head, Role, or Delegate)",
  })
  getPendingApprovals(
    @CurrentUser("id") userId: string,
    @Query() query: QueryPendingApprovalsDto,
  ) {
    return this.approvalsService.getPendingApprovals(userId, query);
  }

  @Post(":requestId/action")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      "Process approval, rejection, or delegation for current active workflow step",
  })
  @ApiParam({ name: "requestId", description: "Request UUID" })
  @ApiResponse({ status: 200, description: "Step processed successfully" })
  @ApiResponse({ status: 400, description: "Validation error or duplicate approval" })
  @ApiResponse({ status: 403, description: "Forbidden: Not authorized for this step" })
  processStep(
    @Param("requestId") requestId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: ProcessApprovalDto,
  ) {
    return this.approvalsService.processApprovalStep(requestId, userId, dto);
  }

  @Get("history/:requestId")
  @ApiOperation({
    summary: "Get full approval history and step progression audit trail for a request",
  })
  @ApiParam({ name: "requestId", description: "Request UUID" })
  getHistory(@Param("requestId") requestId: string) {
    return this.approvalsService.getApprovalHistory(requestId);
  }

  // ============================================================
  // DELEGATION MANAGEMENT
  // ============================================================

  @Post("delegations")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE)
  @ApiOperation({
    summary: "Delegate approval authority to another user for a temporary period",
  })
  createDelegation(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateDelegationDto,
  ) {
    return this.approvalsService.createDelegation(userId, dto);
  }

  @Get("delegations")
  @ApiOperation({ summary: "List active and historical delegations for current user" })
  getMyDelegations(@CurrentUser("id") userId: string) {
    return this.approvalsService.getMyDelegations(userId);
  }

  @Patch("delegations/:id/revoke")
  @ApiOperation({ summary: "Revoke an active delegation before its expiration" })
  @ApiParam({ name: "id", description: "Delegation UUID" })
  revokeDelegation(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.approvalsService.revokeDelegation(id, userId);
  }
}
