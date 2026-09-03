import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Res,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { FastifyReply } from "fastify";
import { DepartmentOperationsService } from "./department-operations.service";
import {
  QueryDepartmentOperationsDto,
  DepartmentTriageRequestDto,
  DepartmentReportQueryDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { DepartmentAccessGuard } from "./guards/department-access.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Department Operations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, DepartmentAccessGuard)
@Controller("department-operations")
export class DepartmentOperationsController {
  constructor(
    private readonly departmentOperationsService: DepartmentOperationsService,
  ) {}

  @Get("overview")
  @ApiOperation({
    summary:
      "Get real-time operational telemetry and dashboard for a department",
  })
  @ApiResponse({
    status: 200,
    description: "Department operational summary retrieved",
  })
  getOverview(
    @CurrentUser("id") userId: string,
    @Query() query: QueryDepartmentOperationsDto,
  ) {
    return this.departmentOperationsService.getOverview(userId, query);
  }

  @Post("triage")
  @ApiOperation({
    summary: "Triage and assign a service request with priority & deadline",
  })
  @ApiResponse({
    status: 200,
    description: "Service request triaged successfully",
  })
  triageRequest(
    @CurrentUser("id") userId: string,
    @Body() dto: DepartmentTriageRequestDto,
  ) {
    return this.departmentOperationsService.triageServiceRequest(userId, dto);
  }

  @Get("reports")
  @ApiOperation({
    summary:
      "Get operational KPI report (completion rates, resolution SLA, workload)",
  })
  async getReport(
    @CurrentUser("id") userId: string,
    @Query() dto: DepartmentReportQueryDto,
    @Res() reply: FastifyReply,
  ) {
    const result = await this.departmentOperationsService.getOperationalReport(
      userId,
      dto,
    );

    if (dto.exportCsv && typeof result === "string") {
      reply
        .header("Content-Type", "text/csv")
        .header(
          "Content-Disposition",
          `attachment; filename="dept-operations-report-${dto.departmentId}.csv"`,
        )
        .send(result);
      return;
    }

    reply.send(result);
  }
}
