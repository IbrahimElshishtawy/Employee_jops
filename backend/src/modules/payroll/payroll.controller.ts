import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PayrollService } from './payroll.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role, AdvanceStatus, DeductionType } from '@prisma/client';

@ApiTags('Payroll & Advances')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('payroll')
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  @Post('advances')
  @ApiOperation({ summary: 'Request salary advance (Employee App)' })
  requestAdvance(@CurrentUser('id') userId: string, @Body() body: any) {
    return this.payrollService.requestAdvance(userId, body);
  }

  @Get('advances/my')
  @ApiOperation({ summary: 'Get current employee advances' })
  getMyAdvances(@CurrentUser('employeeProfileId') employeeProfileId: string) {
    return this.payrollService.getMyAdvances(employeeProfileId);
  }

  @Get('advances')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: 'HR Dashboard: List all salary advance requests' })
  @ApiQuery({ name: 'status', enum: AdvanceStatus, required: false })
  getAllAdvances(@Query('status') status?: AdvanceStatus) {
    return this.payrollService.getAllAdvances(status);
  }

  @Patch('advances/:id/status')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: 'Approve, reject, or mark paid for salary advance' })
  updateAdvanceStatus(
    @Param('id') id: string,
    @Body('status') status: AdvanceStatus,
    @Body('approvedAmount') approvedAmount: number,
    @Body('remarks') remarks: string,
    @CurrentUser('id') approverId: string,
  ) {
    return this.payrollService.updateAdvanceStatus(id, status, approvedAmount, remarks, approverId);
  }

  @Post('deductions')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: 'Create financial deduction or penalty' })
  createDeduction(@Body() body: any, @CurrentUser('id') createdById: string) {
    return this.payrollService.createDeduction(body, createdById);
  }

  @Get('deductions/my')
  @ApiOperation({ summary: 'Get current employee deduction list' })
  getMyDeductions(@CurrentUser('employeeProfileId') employeeProfileId: string) {
    return this.payrollService.getMyDeductions(employeeProfileId);
  }

  @Get('deductions')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: 'HR Dashboard: List all deductions' })
  getAllDeductions(@Query('employeeId') employeeId?: string) {
    return this.payrollService.getAllDeductions(employeeId);
  }
}
