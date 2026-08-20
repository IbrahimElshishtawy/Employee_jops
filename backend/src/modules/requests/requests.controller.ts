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
  ApiQuery,
  ApiParam,
  ApiResponse,
} from "@nestjs/swagger";
import { RequestsService } from "./requests.service";
import {
  CreateRequestDto,
  QueryRequestsDto,
  ApproveRequestDto,
  RejectRequestDto,
  CancelRequestDto,
  CreateLeaveBalanceDto,
  AdjustLeaveBalanceDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";

@ApiTags("Requests")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("requests")
export class RequestsController {
  constructor(private readonly requestsService: RequestsService) {}

  // ============================================================
  // EMPLOYEE ENDPOINTS
  // ============================================================

  @Post()
  @ApiOperation({
    summary:
      "Submit a new request (Leave, Absence, Permission, Late Excuse, Early Leave, Half Day, etc.)",
  })
  @ApiResponse({
    status: 201,
    description: "Request created successfully and pending review",
  })
  @ApiResponse({
    status: 400,
    description: "Validation error or insufficient leave balance",
  })
  @ApiResponse({ status: 403, description: "Forbidden for inactive employees" })
  create(@CurrentUser("id") userId: string, @Body() dto: CreateRequestDto) {
    return this.requestsService.create(userId, dto);
  }

  @Get("me")
  @ApiOperation({
    summary: "Get paginated submitted requests for current employee",
  })
  getMyRequests(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryRequestsDto,
  ) {
    return this.requestsService.findMyRequests(employeeProfileId, query);
  }

  @Get("my-requests")
  @ApiOperation({
    summary: "Alias: Get submitted requests for current employee",
  })
  getMyRequestsAlias(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryRequestsDto,
  ) {
    return this.requestsService.findMyRequests(employeeProfileId, query);
  }

  @Get("leave-balances/me")
  @ApiOperation({
    summary:
      "Get current year leave balances and remaining days for current employee",
  })
  @ApiQuery({ name: "year", required: false, type: Number })
  getMyLeaveBalances(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query("year") year?: number,
  ) {
    return this.requestsService.getMyLeaveBalances(employeeProfileId, year);
  }

  @Get("leave-balances/employee/:employeeId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "HR: Get leave balances for a specific employee" })
  @ApiParam({ name: "employeeId", description: "Employee Profile UUID" })
  @ApiQuery({ name: "year", required: false, type: Number })
  getEmployeeLeaveBalances(
    @Param("employeeId") employeeId: string,
    @Query("year") year?: number,
  ) {
    return this.requestsService.getEmployeeLeaveBalances(employeeId, year);
  }

  @Post("leave-balances")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "HR: Allocate / Initialize new leave balance for an employee",
  })
  createLeaveBalance(
    @Body() dto: CreateLeaveBalanceDto,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.requestsService.createLeaveBalance(dto, currentUserId);
  }

  @Patch("leave-balances/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "HR: Adjust total or used days on an existing leave balance",
  })
  @ApiParam({ name: "id", description: "LeaveBalance UUID" })
  adjustLeaveBalance(
    @Param("id") id: string,
    @Body() dto: AdjustLeaveBalanceDto,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.requestsService.adjustLeaveBalance(id, dto, currentUserId);
  }

  // ============================================================
  // HR QUEUE & DETAILS
  // ============================================================

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "HR: Filtered and paginated queue of employee requests (status, department, workplace, dates)",
  })
  findAll(@Query() query: QueryRequestsDto) {
    return this.requestsService.findAll(query);
  }

  @Get(":id")
  @ApiOperation({
    summary:
      "Get request details with approval history (IDOR protected: Owner or HR)",
  })
  @ApiParam({ name: "id", description: "Request UUID" })
  findOne(
    @Param("id") id: string,
    @CurrentUser()
    currentUser: { id: string; role: Role; employeeProfileId?: string },
  ) {
    return this.requestsService.findOne(id, currentUser);
  }

  // ============================================================
  // ACTIONS: CANCEL, APPROVE, REJECT
  // ============================================================

  @Post(":id/cancel")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Employee: Cancel a pending request" })
  @ApiParam({ name: "id", description: "Request UUID" })
  cancelPost(
    @Param("id") id: string,
    @CurrentUser()
    currentUser: { id: string; role: Role; employeeProfileId?: string },
    @Body() dto?: CancelRequestDto,
  ) {
    return this.requestsService.cancel(id, currentUser, dto);
  }

  @Patch(":id/cancel")
  @ApiOperation({
    summary: "Employee: Cancel a pending request (PATCH method)",
  })
  @ApiParam({ name: "id", description: "Request UUID" })
  cancelPatch(
    @Param("id") id: string,
    @CurrentUser()
    currentUser: { id: string; role: Role; employeeProfileId?: string },
    @Body() dto?: CancelRequestDto,
  ) {
    return this.requestsService.cancel(id, currentUser, dto);
  }

  @Post(":id/approve")
  @HttpCode(HttpStatus.OK)
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "HR: Approve an employee request (updates leave balance, attendance records, audit & notification)",
  })
  @ApiParam({ name: "id", description: "Request UUID" })
  approvePost(
    @Param("id") id: string,
    @CurrentUser("id") approverId: string,
    @Body() dto?: ApproveRequestDto,
  ) {
    return this.requestsService.approve(id, approverId, dto);
  }

  @Patch(":id/approve")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "HR: Approve an employee request (PATCH method)" })
  @ApiParam({ name: "id", description: "Request UUID" })
  approvePatch(
    @Param("id") id: string,
    @CurrentUser("id") approverId: string,
    @Body() dto?: ApproveRequestDto,
  ) {
    return this.requestsService.approve(id, approverId, dto);
  }

  @Post(":id/reject")
  @HttpCode(HttpStatus.OK)
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "HR: Reject an employee request with mandatory reason",
  })
  @ApiParam({ name: "id", description: "Request UUID" })
  rejectPost(
    @Param("id") id: string,
    @CurrentUser("id") approverId: string,
    @Body() dto: RejectRequestDto,
  ) {
    return this.requestsService.reject(id, approverId, dto);
  }

  @Patch(":id/reject")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "HR: Reject an employee request with mandatory reason (PATCH method)",
  })
  @ApiParam({ name: "id", description: "Request UUID" })
  rejectPatch(
    @Param("id") id: string,
    @CurrentUser("id") approverId: string,
    @Body() dto: RejectRequestDto,
  ) {
    return this.requestsService.reject(id, approverId, dto);
  }
}
