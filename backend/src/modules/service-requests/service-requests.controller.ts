import {
  Controller,
  Get,
  Post,
  Patch,
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
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { ServiceRequestsService } from "./service-requests.service";
import {
  CreateServiceRequestDto,
  AssignServiceRequestDto,
  UpdateServiceRequestStatusDto,
  ReviewServiceRequestDto,
  CreateServiceRequestCommentDto,
  QueryServiceRequestsDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { ServiceRequestAccessGuard } from "./guards/service-request-access.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Service Requests")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("service-requests")
export class ServiceRequestsController {
  constructor(
    private readonly serviceRequestsService: ServiceRequestsService,
  ) {}

  @Post()
  @ApiOperation({ summary: "Create a new service request" })
  @ApiResponse({
    status: 201,
    description: "Service request created successfully",
  })
  create(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateServiceRequestDto,
  ) {
    return this.serviceRequestsService.createServiceRequest(userId, dto);
  }

  @Get()
  @ApiOperation({
    summary: "List service requests with filters and pagination",
  })
  findAll(
    @CurrentUser("id") userId: string,
    @Query() query: QueryServiceRequestsDto,
  ) {
    return this.serviceRequestsService.listServiceRequests(userId, query);
  }

  @Get(":id")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({ summary: "Get service request details by ID" })
  findOne(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.serviceRequestsService.getServiceRequestById(id, userId);
  }

  @Patch(":id/assign")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({
    summary: "Assign service request to an employee / technician",
  })
  assign(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AssignServiceRequestDto,
  ) {
    return this.serviceRequestsService.assignServiceRequest(id, userId, dto);
  }

  @Patch(":id/start")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({
    summary: "Start working on a service request (status -> IN_PROGRESS)",
  })
  startWork(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.serviceRequestsService.startWork(id, userId);
  }

  @Patch(":id/complete")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({
    summary: "Mark service request as COMPLETED with resolution notes",
  })
  complete(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateServiceRequestStatusDto,
  ) {
    return this.serviceRequestsService.completeServiceRequest(id, userId, dto);
  }

  @Post(":id/review")
  @UseGuards(ServiceRequestAccessGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Customer/Requester review and sign-off (ACCEPT or REVISION)",
  })
  review(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: ReviewServiceRequestDto,
  ) {
    return this.serviceRequestsService.reviewServiceRequest(id, userId, dto);
  }

  @Patch(":id/close")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({ summary: "Directly close a service request" })
  close(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("notes") notes?: string,
  ) {
    return this.serviceRequestsService.closeServiceRequest(id, userId, notes);
  }

  @Patch(":id/cancel")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({ summary: "Cancel a service request (by requester or admin)" })
  cancel(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("reason") reason: string,
  ) {
    return this.serviceRequestsService.cancelServiceRequest(id, userId, reason);
  }

  @Patch(":id/reject")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({
    summary: "Reject a service request (by department supervisor or admin)",
  })
  reject(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("reason") reason: string,
  ) {
    return this.serviceRequestsService.rejectServiceRequest(id, userId, reason);
  }

  @Post(":id/comments")
  @UseGuards(ServiceRequestAccessGuard)
  @ApiOperation({
    summary: "Add a comment or internal note to the service request",
  })
  addComment(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: CreateServiceRequestCommentDto,
  ) {
    return this.serviceRequestsService.addComment(id, userId, dto);
  }
}
