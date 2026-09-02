import { Controller, Get, Query, Res, UseGuards } from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { FastifyReply } from "fastify";
import { ReportsService } from "./reports.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  AdvanceReportQueryDto,
  AttendanceReportQueryDto,
  BaseReportQueryDto,
  DeductionReportQueryDto,
  ExportReportQueryDto,
  PayrollReportQueryDto,
  RequestReportQueryDto,
  TaskReportQueryDto,
} from "./dto";

@ApiTags("Reports & Analytics Engine")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("reports")
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  // ============================================================
  // 1. DASHBOARD & EMPLOYEE SELF-REPORT
  // ============================================================

  @Get("dashboard")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "HR Dashboard summary KPIs, today attendance, pending items",
  })
  @ApiResponse({ status: 200, description: "Real-time HR dashboard metrics" })
  getDashboard() {
    return this.reportsService.getDashboardSummary();
  }

  @Get("me")
  @ApiOperation({
    summary:
      "Employee self-report (own attendance rate, late minutes, absences, requests, advances, payroll)",
  })
  @ApiResponse({
    status: 200,
    description: "Personal performance and attendance summary",
  })
  getSelfReport(
    @CurrentUser("id") userId: string,
    @Query() query: BaseReportQueryDto,
  ) {
    return this.reportsService.getEmployeeSelfReport(userId, query);
  }

  // ============================================================
  // 2. ATTENDANCE, LATE & ABSENCE ANALYTICS
  // ============================================================

  @Get("attendance")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Comprehensive attendance analytics with rates & date ranges",
  })
  getAttendanceReport(
    @Query() query: AttendanceReportQueryDto,
    @CurrentUser() user: any,
  ) {
    return this.reportsService.getAttendanceReport(query, user);
  }

  @Get("attendance/late")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Late arrival analytics, top offenders, and distribution",
  })
  getLateAnalytics(@Query() query: AttendanceReportQueryDto) {
    return this.reportsService.getLateAnalytics(query);
  }

  @Get("attendance/absence")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Absence analytics (approved vs unapproved, rates, distribution)",
  })
  getAbsenceAnalytics(@Query() query: AttendanceReportQueryDto) {
    return this.reportsService.getAbsenceAnalytics(query);
  }

  @Get("attendance/security")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({
    summary:
      "Attendance security telemetry (geofence breaches, GPS accuracy, suspicious device signals)",
  })
  getSecurityAnalytics(
    @Query() query: BaseReportQueryDto,
    @CurrentUser() user: any,
  ) {
    return this.reportsService.getSecurityAnalytics(query, user);
  }

  @Get("attendance/export")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary:
      "Export filtered attendance reports with formula injection protection (CSV)",
  })
  async exportAttendance(
    @Query() query: ExportReportQueryDto,
    @CurrentUser() user: any,
    @Res() reply: FastifyReply,
  ) {
    const csvContent = await this.reportsService.exportAttendanceCsv(
      query,
      user,
    );
    const filename = `attendance-report-${new Date().toISOString().split("T")[0]}.csv`;

    reply
      .header("Content-Type", "text/csv; charset=utf-8")
      .header("Content-Disposition", `attachment; filename="${filename}"`)
      .send(csvContent);
  }

  // ============================================================
  // 3. REQUESTS & WORKFLOW ANALYTICS
  // ============================================================

  @Get("requests")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "Request analytics, approval/rejection rates & processing duration",
  })
  getRequestAnalytics(@Query() query: RequestReportQueryDto) {
    return this.reportsService.getRequestAnalytics(query);
  }

  // ============================================================
  // 4. FINANCIAL & PAYROLL ANALYTICS
  // ============================================================

  @Get("payroll")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Payroll analytics, gross/net trends, departmental payroll",
  })
  getPayrollAnalytics(
    @Query() query: PayrollReportQueryDto,
    @CurrentUser() user: any,
  ) {
    return this.reportsService.getPayrollAnalytics(query, user);
  }

  @Get("deductions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Deduction analytics grouped by type and department",
  })
  getDeductionAnalytics(@Query() query: DeductionReportQueryDto) {
    return this.reportsService.getDeductionAnalytics(query);
  }

  @Get("advances")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Salary advance analytics, active balances, repayment stats",
  })
  getAdvanceAnalytics(@Query() query: AdvanceReportQueryDto) {
    return this.reportsService.getAdvanceAnalytics(query);
  }

  // ============================================================
  // 5. ORGANIZATIONAL: EMPLOYEES, DEPARTMENTS & WORKPLACES
  // ============================================================

  @Get("employees")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Employee distribution by department, workplace, and job title",
  })
  getEmployeeAnalytics(@Query() query: BaseReportQueryDto) {
    return this.reportsService.getEmployeeAnalytics(query);
  }

  @Get("departments")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Department performance metrics and headcount stats",
  })
  getDepartmentStats() {
    return this.reportsService.getDepartmentStats();
  }

  @Get("workplaces")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Workplace operational metrics, geofence breaches, manual edits",
  })
  getWorkplaceAnalytics(@Query() query: BaseReportQueryDto) {
    return this.reportsService.getWorkplaceAnalytics(query);
  }

  // ============================================================
  // 6. TASKS & WORK MANAGEMENT ANALYTICS
  // ============================================================

  @Get("tasks")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "Comprehensive task KPIs, completion/overdue rates & status breakdown",
  })
  getTaskAnalytics(
    @Query() query: TaskReportQueryDto,
    @CurrentUser() user: any,
  ) {
    return this.reportsService.getTaskAnalytics(query, user);
  }

  @Get("tasks/employees")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "Employee task productivity, completion rates & performance ratings",
  })
  getEmployeeTaskProductivity(
    @Query() query: TaskReportQueryDto,
    @CurrentUser() user: any,
  ) {
    return this.reportsService.getEmployeeTaskProductivity(query, user);
  }

  @Get("tasks/departments")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Departmental task load, active bottlenecks & completion rates",
  })
  getDepartmentTaskStats(
    @Query() query: TaskReportQueryDto,
    @CurrentUser() user: any,
  ) {
    return this.reportsService.getDepartmentTaskStats(query, user);
  }

  @Get("tasks/export")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Export tasks report with CSV injection protection",
  })
  async exportTasks(
    @Query() query: TaskReportQueryDto,
    @CurrentUser() user: any,
    @Res() reply: FastifyReply,
  ) {
    const csvContent = await this.reportsService.exportTasksCsv(query, user);
    const filename = `tasks-report-${new Date().toISOString().split("T")[0]}.csv`;

    reply
      .header("Content-Type", "text/csv; charset=utf-8")
      .header("Content-Disposition", `attachment; filename="${filename}"`)
      .send(csvContent);
  }
}
