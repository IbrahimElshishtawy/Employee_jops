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
import { HandoverService } from "./handover.service";
import {
  CreateHandoverDto,
  AcknowledgeHandoverDto,
  AddHandoverItemDto,
  QueryHandoversDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { HandoverAccessGuard } from "./guards/handover-access.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Shift Handover")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("handover")
export class HandoverController {
  constructor(private readonly handoverService: HandoverService) {}

  @Post()
  @ApiOperation({
    summary: "Create a new shift handover with notes & open tasks",
  })
  @ApiResponse({
    status: 201,
    description: "Shift handover created successfully",
  })
  create(@CurrentUser("id") userId: string, @Body() dto: CreateHandoverDto) {
    return this.handoverService.createHandover(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List shift handovers with filters and pagination" })
  findAll(
    @CurrentUser("id") userId: string,
    @Query() query: QueryHandoversDto,
  ) {
    return this.handoverService.listHandovers(userId, query);
  }

  @Get(":id")
  @UseGuards(HandoverAccessGuard)
  @ApiOperation({ summary: "Get shift handover details by ID" })
  findOne(@Param("id") id: string) {
    return this.handoverService.getHandoverById(id);
  }

  @Patch(":id/acknowledge")
  @UseGuards(HandoverAccessGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Acknowledge, flag or reject a shift handover" })
  acknowledge(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AcknowledgeHandoverDto,
  ) {
    return this.handoverService.acknowledgeHandover(id, userId, dto);
  }

  @Post(":id/items")
  @UseGuards(HandoverAccessGuard)
  @ApiOperation({
    summary: "Add an item, task, or incident to the shift handover",
  })
  addItem(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AddHandoverItemDto,
  ) {
    return this.handoverService.addItem(id, userId, dto);
  }
}
