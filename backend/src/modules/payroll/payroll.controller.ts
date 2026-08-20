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
import { PayrollService } from "./payroll.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";
import {
  CreateSalaryProfileDto,
  RequestAdvanceDto,
  ApproveAdvanceDto,
  RejectAdvanceDto,
  PayInstallmentDto,
  QueryAdvancesDto,
  CreateDeductionDto,
  QueryDeductionsDto,
  CreatePayrollPeriodDto,
  CalculatePayrollDto,
  FinalizePayrollDto,
  CreateAdjustmentDto,
  QueryPayrollDto,
} from "./dto";

@ApiTags("Payroll, Salary Advances & Deductions")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("payroll")
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  // ============================================================
  // 1. SALARY PROFILE ENDPOINTS
  // ============================================================

  @Get("salary/me")
  @ApiOperation({ summary: "Employee: View my current salary profile" })
  getMySalaryProfile(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @CurrentUser() currentUser: any,
  ) {
    return this.payrollService.getSalaryProfile(employeeProfileId, currentUser);
  }

  @Get("salary/employee/:employeeId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: View salary profile for specific employee" })
  getEmployeeSalaryProfile(
    @Param("employeeId") employeeId: string,
    @CurrentUser() currentUser: any,
  ) {
    return this.payrollService.getSalaryProfile(employeeId, currentUser);
  }

  @Post("salary")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({
    summary:
      "HR: Set or update employee salary profile (with history versioning)",
  })
  setSalaryProfile(
    @Body() dto: CreateSalaryProfileDto,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.payrollService.setSalaryProfile(dto, currentUserId);
  }

  @Get("salary/history/:employeeId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "HR: View salary modification history for employee",
  })
  getSalaryHistory(@Param("employeeId") employeeId: string) {
    return this.payrollService.getSalaryHistory(employeeId);
  }

  // ============================================================
  // 2. SALARY ADVANCE ENDPOINTS
  // ============================================================

  @Post("advances")
  @ApiOperation({ summary: "Employee: Request a salary advance" })
  @ApiResponse({
    status: 201,
    description: "Advance request created successfully",
  })
  requestAdvance(
    @CurrentUser("id") userId: string,
    @Body() dto: RequestAdvanceDto,
  ) {
    return this.payrollService.requestAdvance(userId, dto);
  }

  @Get("advances/me")
  @ApiOperation({
    summary: "Employee: View my salary advance requests & installment schedule",
  })
  getMyAdvances(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryAdvancesDto,
  ) {
    return this.payrollService.getMyAdvances(employeeProfileId, query);
  }

  @Get("advances/my")
  @ApiOperation({ summary: "Employee: View my salary advances (alias)" })
  getMyAdvancesAlias(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryAdvancesDto,
  ) {
    return this.payrollService.getMyAdvances(employeeProfileId, query);
  }

  @Get("advances")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: List and filter all salary advance requests" })
  getAllAdvances(@Query() query: QueryAdvancesDto) {
    return this.payrollService.getAllAdvances(query);
  }

  @Get("advances/:id")
  @ApiOperation({
    summary: "View detailed salary advance with installment schedule",
  })
  getAdvanceDetails(@Param("id") id: string, @CurrentUser() currentUser: any) {
    return this.payrollService.getAdvanceDetails(id, currentUser);
  }

  @Post("advances/:id/approve")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "HR: Approve salary advance and generate installment schedule",
  })
  approveAdvance(
    @Param("id") id: string,
    @CurrentUser("id") approverId: string,
    @Body() dto: ApproveAdvanceDto,
  ) {
    return this.payrollService.approveAdvance(id, approverId, dto);
  }

  @Post("advances/:id/reject")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "HR: Reject salary advance with mandatory reason" })
  rejectAdvance(
    @Param("id") id: string,
    @CurrentUser("id") approverId: string,
    @Body() dto: RejectAdvanceDto,
  ) {
    return this.payrollService.rejectAdvance(id, approverId, dto);
  }

  @Post("advances/installments/:installmentId/pay")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "HR / Finance: Record payment towards an advance installment",
  })
  payInstallment(
    @Param("installmentId") installmentId: string,
    @CurrentUser("id") currentUserId: string,
    @Body() dto: PayInstallmentDto,
  ) {
    return this.payrollService.recordInstallmentPayment(
      installmentId,
      currentUserId,
      dto,
    );
  }

  // ============================================================
  // 3. FINANCIAL DEDUCTION ENDPOINTS
  // ============================================================

  @Post("deductions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: Create manual financial deduction or penalty" })
  createDeduction(
    @Body() dto: CreateDeductionDto,
    @CurrentUser("id") createdById: string,
  ) {
    return this.payrollService.createDeduction(dto, createdById);
  }

  @Get("deductions/me")
  @ApiOperation({ summary: "Employee: View my deductions" })
  getMyDeductions(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryDeductionsDto,
  ) {
    return this.payrollService.getMyDeductions(employeeProfileId, query);
  }

  @Get("deductions/my")
  @ApiOperation({ summary: "Employee: View my deductions (alias)" })
  getMyDeductionsAlias(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryDeductionsDto,
  ) {
    return this.payrollService.getMyDeductions(employeeProfileId, query);
  }

  @Get("deductions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: List and filter all financial deductions" })
  getAllDeductions(@Query() query: QueryDeductionsDto) {
    return this.payrollService.getAllDeductions(query);
  }

  // ============================================================
  // 4. PAYROLL PERIODS & CALCULATION ENGINE
  // ============================================================

  @Post("periods")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "HR: Create a new monthly payroll period" })
  createPeriod(
    @Body() dto: CreatePayrollPeriodDto,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.payrollService.createPayrollPeriod(dto, currentUserId);
  }

  @Get("periods")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: List all payroll periods" })
  getPeriods(@Query("page") page?: number, @Query("limit") limit?: number) {
    return this.payrollService.getPayrollPeriods(
      Number(page) || 1,
      Number(limit) || 12,
    );
  }

  @Post("periods/:id/calculate")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "HR: Run calculation engine for payroll period" })
  calculatePeriod(
    @Param("id") periodId: string,
    @Body() dto: CalculatePayrollDto,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.payrollService.calculatePeriodPayroll(
      periodId,
      dto,
      currentUserId,
    );
  }

  @Post("periods/:id/finalize")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "HR / Finance: Finalize and lock payroll period" })
  finalizePeriod(
    @Param("id") periodId: string,
    @CurrentUser("id") currentUserId: string,
    @Body() dto: FinalizePayrollDto,
  ) {
    return this.payrollService.finalizePayrollPeriod(
      periodId,
      currentUserId,
      dto,
    );
  }

  // ============================================================
  // 5. PAYROLL RECORDS & PAYSLIPS
  // ============================================================

  @Get("me")
  @ApiOperation({ summary: "Employee: View my monthly payroll payslips" })
  getMyPayroll(
    @CurrentUser("employeeProfileId") employeeProfileId: string,
    @Query() query: QueryPayrollDto,
  ) {
    return this.payrollService.getMyPayroll(employeeProfileId, query);
  }

  @Get("records/:id")
  @ApiOperation({ summary: "View detailed payslip with itemized line items" })
  getPayrollRecordDetails(
    @Param("id") id: string,
    @CurrentUser() currentUser: any,
  ) {
    return this.payrollService.getPayrollRecordDetails(id, currentUser);
  }

  @Post("records/:id/adjust")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({
    summary: "HR: Create post-finalization adjustment for payroll record",
  })
  adjustPayrollRecord(
    @Param("id") recordId: string,
    @CurrentUser("id") currentUserId: string,
    @Body() dto: CreateAdjustmentDto,
  ) {
    return this.payrollService.createPayrollAdjustment(
      recordId,
      currentUserId,
      dto,
    );
  }

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "HR: List and filter all employee payroll records" })
  getHrPayroll(@Query() query: QueryPayrollDto) {
    return this.payrollService.getHrPayroll(query);
  }
}
