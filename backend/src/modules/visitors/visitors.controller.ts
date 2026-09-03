import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { VisitorsService } from "./visitors.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { CheckInVisitorDto, CheckOutVisitorDto, QueryVisitorsDto } from "./dto";

@ApiTags("Visitor Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("visitors")
export class VisitorsController {
  constructor(private readonly visitorsService: VisitorsService) {}

  @Post("check-in")
  @ApiOperation({ summary: "Check in a visitor and notify host employee" })
  @ApiResponse({ status: 201, description: "Visitor checked in" })
  checkInVisitor(
    @CurrentUser("id") userId: string,
    @Body() dto: CheckInVisitorDto,
  ) {
    return this.visitorsService.checkInVisitor(userId, dto);
  }

  @Post(":id/check-out")
  @ApiOperation({ summary: "Check out a visitor" })
  checkOutVisitor(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: CheckOutVisitorDto,
  ) {
    return this.visitorsService.checkOutVisitor(id, userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List visitors with filters and search" })
  findVisitors(@Query() query: QueryVisitorsDto) {
    return this.visitorsService.findVisitors(query);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get visitor details by ID" })
  findVisitorById(@Param("id") id: string) {
    return this.visitorsService.findVisitorById(id);
  }
}
