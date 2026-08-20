import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Param,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AttendanceService } from './attendance.service';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@ApiTags('Attendance')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('attendance')
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Post('check-in')
  @ApiOperation({ summary: 'Register employee check-in with GPS coordinates' })
  checkIn(@CurrentUser('id') userId: string, @Body() dto: CheckInDto) {
    return this.attendanceService.checkIn(userId, dto);
  }

  @Post('check-out')
  @ApiOperation({ summary: 'Register employee check-out with GPS coordinates' })
  checkOut(@CurrentUser('id') userId: string, @Body() dto: CheckOutDto) {
    return this.attendanceService.checkOut(userId, dto);
  }

  @Get('today')
  @ApiOperation({ summary: 'Get current user attendance status for today' })
  getToday(@CurrentUser('id') userId: string) {
    return this.attendanceService.getTodayStatus(userId);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get current employee personal attendance history' })
  getMyHistory(
    @CurrentUser('employeeProfileId') employeeProfileId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 30,
  ) {
    return this.attendanceService.getEmployeeHistory(employeeProfileId, +page, +limit);
  }

  @Get('records')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: 'HR Dashboard: Query attendance records across company' })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  @ApiQuery({ name: 'workplaceId', required: false })
  getAttendanceRecords(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('workplaceId') workplaceId?: string,
  ) {
    return this.attendanceService.getAttendanceList(startDate, endDate, workplaceId);
  }
}
