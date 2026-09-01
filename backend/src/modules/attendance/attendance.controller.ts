import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Param,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";

import { AttendanceService } from "./attendance.service";
import { CheckInDto } from "./dto/check-in.dto";
import { CheckOutDto } from "./dto/check-out.dto";
import { ManualAttendanceDto } from "./dto/manual-attendance.dto";
import { QueryAttendanceDto } from "./dto/query-attendance.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";

@ApiTags("Attendance & Workforce Operations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("attendance")
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Post("check-in")
  @ApiOperation({
    summary: "Register employee check-in with GPS evidence & security signals",
  })
  checkIn(@CurrentUser("id") userId: string, @Body() dto: CheckInDto) {
    return this.attendanceService.checkIn(userId, dto);
  }

  @Post("check-out")
  @ApiOperation({
    summary:
      "Register employee check-out with GPS evidence & duration calculations",
  })
  checkOut(@CurrentUser("id") userId: string, @Body() dto: CheckOutDto) {
    return this.attendanceService.checkOut(userId, dto);
  }

  @Get("today")
  @ApiOperation({
    summary: "Get current authenticated employee attendance status for today",
  })
  getToday(@CurrentUser("id") userId: string) {
    return this.attendanceService.getTodayStatus(userId);
  }

  @Get("me")
  @ApiOperation({
    summary:
      "Get personal attendance history for current employee (supports month/date filters)",
  })
  getMyAttendance(
    @CurrentUser("id") userId: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getMyAttendance(userId, query);
  }

  @Get("history")
  @ApiOperation({ summary: "Backward-compatible personal attendance history" })
  getMyHistory(
    @CurrentUser("id") userId: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getMyAttendance(userId, query);
  }

  @Post("manual")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "HR Manual Attendance Adjustment / Creation with mandatory reason",
  })
  manualAdjustment(
    @CurrentUser("id") hrUserId: string,
    @Body() dto: ManualAttendanceDto,
  ) {
    return this.attendanceService.manualAttendanceEntry(hrUserId, dto);
  }

  @Get("employee/:employeeId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "HR Query: Get specific employee attendance records",
  })
  getEmployeeAttendance(
    @Param("employeeId") employeeId: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getEmployeeAttendance(employeeId, query);
  }

  @Get("workplace/:workplaceId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "HR Query: Get attendance records for a specific workplace/branch",
  })
  getWorkplaceAttendance(
    @Param("workplaceId") workplaceId: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getWorkplaceAttendance(workplaceId, query);
  }

  @Get("department/:department")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "HR Query: Get attendance records for a specific department",
  })
  getDepartmentAttendance(
    @Param("department") department: string,
    @Query() query: QueryAttendanceDto,
  ) {
    return this.attendanceService.getDepartmentAttendance(department, query);
  }

  @Get("records")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "HR General Query: List attendance records across company",
  })
  getAttendanceRecords(
    @Query("startDate") startDate?: string,
    @Query("endDate") endDate?: string,
    @Query("workplaceId") workplaceId?: string,
  ) {
    return this.attendanceService.getAttendanceList(
      startDate,
      endDate,
      workplaceId,
    );
  }
}
