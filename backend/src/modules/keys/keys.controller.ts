import {
  Controller,
  Get,
  Post,
  Patch,
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
import { KeysService } from "./keys.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateKeyDto,
  QueryKeysDto,
  AssignKeyDto,
  ReturnKeyDto,
  LogKeyAccessDto,
} from "./dto";

@ApiTags("Key & Physical Access Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("keys")
export class KeysController {
  constructor(private readonly keysService: KeysService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Register a new physical key" })
  @ApiResponse({ status: 201, description: "Key registered" })
  createKey(@CurrentUser("id") userId: string, @Body() dto: CreateKeyDto) {
    return this.keysService.createKey(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List physical keys with pagination and filters" })
  findKeys(@Query() query: QueryKeysDto) {
    return this.keysService.findKeys(query);
  }

  @Get(":id")
  @ApiOperation({
    summary: "Get key details including active assignment and access history",
  })
  findKeyById(@Param("id") id: string) {
    return this.keysService.findKeyById(id);
  }

  @Post(":id/assign")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Assign a key to an employee" })
  assignKey(
    @Param("id") keyId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AssignKeyDto,
  ) {
    return this.keysService.assignKey(keyId, userId, dto);
  }

  @Post("assignments/:assignmentId/return")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Return an assigned key and increment available copies",
  })
  returnKey(
    @Param("assignmentId") assignmentId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: ReturnKeyDto,
  ) {
    return this.keysService.returnKey(assignmentId, userId, dto);
  }

  @Post(":id/access-log")
  @ApiOperation({ summary: "Log a physical access event for this key" })
  logAccess(
    @Param("id") keyId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: LogKeyAccessDto,
  ) {
    return this.keysService.logAccess(keyId, userId, dto);
  }
}
