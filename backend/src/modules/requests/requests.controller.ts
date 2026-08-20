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
import { RequestsService } from './requests.service';
import { CreateRequestDto } from './dto/create-request.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role, RequestStatus } from '@prisma/client';

@ApiTags('Requests')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('requests')
export class RequestsController {
  constructor(private readonly requestsService: RequestsService) {}

  @Post()
  @ApiOperation({ summary: 'Submit leave / excuse / remote work request (Employee App)' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreateRequestDto) {
    return this.requestsService.create(userId, dto);
  }

  @Get('my-requests')
  @ApiOperation({ summary: 'Get current employee submitted requests' })
  getMyRequests(@CurrentUser('employeeProfileId') employeeProfileId: string) {
    return this.requestsService.findMyRequests(employeeProfileId);
  }

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: 'HR Dashboard: List all requests with optional status filter' })
  @ApiQuery({ name: 'status', enum: RequestStatus, required: false })
  findAll(@Query('status') status?: RequestStatus) {
    return this.requestsService.findAll(status);
  }

  @Patch(':id/approve')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: 'Approve an employee request' })
  approve(
    @Param('id') id: string,
    @CurrentUser('id') approverId: string,
    @Body('comment') comment?: string,
  ) {
    return this.requestsService.processRequest(id, 'APPROVE', approverId, comment);
  }

  @Patch(':id/reject')
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: 'Reject an employee request' })
  reject(
    @Param('id') id: string,
    @CurrentUser('id') approverId: string,
    @Body('comment') comment?: string,
  ) {
    return this.requestsService.processRequest(id, 'REJECT', approverId, comment);
  }
}
