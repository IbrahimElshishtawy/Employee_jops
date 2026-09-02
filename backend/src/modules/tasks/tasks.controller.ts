import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
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
import { TasksService } from "./tasks.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { TaskAccessGuard } from "./guards/task-access.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateTaskDto,
  UpdateTaskDto,
  QueryTasksDto,
  AssignTaskDto,
  UpdateTaskStatusDto,
  AddChecklistItemDto,
  UpdateChecklistItemDto,
  CreateTaskCommentDto,
  CreateTaskAttachmentDto,
} from "./dto";

@ApiTags("Tasks & Work Execution")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("tasks")
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Create a new task and optionally assign to an employee",
  })
  @ApiResponse({ status: 201, description: "Task created successfully" })
  createTask(@CurrentUser("id") userId: string, @Body() dto: CreateTaskDto) {
    return this.tasksService.createTask(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List tasks with pagination, filters and search" })
  findAll(@Query() query: QueryTasksDto) {
    return this.tasksService.findAll(query);
  }

  @Get("my")
  @ApiOperation({ summary: "Get current employee assigned and created tasks" })
  getMyTasks(@CurrentUser("id") userId: string, @Query() query: QueryTasksDto) {
    return this.tasksService.getMyTasks(userId, query);
  }

  @Get(":id")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({
    summary: "Get task details including checklist, comments, and attachments",
  })
  findOne(@Param("id") id: string) {
    return this.tasksService.findOne(id);
  }

  @Patch(":id")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({
    summary: "Update task metadata, priority, due date, or progress",
  })
  updateTask(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateTaskDto,
  ) {
    return this.tasksService.updateTask(id, userId, dto);
  }

  @Post(":id/assign")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Assign or reassign task to an employee" })
  assignTask(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AssignTaskDto,
  ) {
    return this.tasksService.assignTask(id, userId, dto);
  }

  @Post(":id/accept")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({
    summary: "Assigned employee accepts task (TODO -> ACCEPTED)",
  })
  acceptTask(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.tasksService.acceptTask(id, userId);
  }

  @Post(":id/status")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({
    summary: "Update task lifecycle status (IN_PROGRESS, BLOCKED, etc.)",
  })
  updateStatus(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateTaskStatusDto,
  ) {
    return this.tasksService.updateStatus(id, userId, dto);
  }

  // Checklist
  @Post(":id/checklist")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Add checklist item to task" })
  addChecklistItem(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AddChecklistItemDto,
  ) {
    return this.tasksService.addChecklistItem(id, userId, dto);
  }

  @Patch(":id/checklist/:itemId")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({
    summary: "Toggle or update checklist item (auto-updates progress %)",
  })
  updateChecklistItem(
    @Param("id") id: string,
    @Param("itemId") itemId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateChecklistItemDto,
  ) {
    return this.tasksService.updateChecklistItem(id, itemId, userId, dto);
  }

  @Delete(":id/checklist/:itemId")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Delete checklist item from task" })
  deleteChecklistItem(
    @Param("id") id: string,
    @Param("itemId") itemId: string,
  ) {
    return this.tasksService.deleteChecklistItem(id, itemId);
  }

  // Comments
  @Post(":id/comments")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Add comment to task" })
  addComment(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: CreateTaskCommentDto,
  ) {
    return this.tasksService.addComment(id, userId, dto);
  }

  @Get(":id/comments")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Get all comments for a task" })
  getComments(@Param("id") id: string) {
    return this.tasksService.getComments(id);
  }

  // Attachments
  @Post(":id/attachments")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Attach file metadata to task" })
  addAttachment(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: CreateTaskAttachmentDto,
  ) {
    return this.tasksService.addAttachment(id, userId, dto);
  }

  @Get(":id/attachments")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "List task attachments" })
  getAttachments(@Param("id") id: string) {
    return this.tasksService.getAttachments(id);
  }

  // History
  @Get(":id/history")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Get chronological audit history for a task" })
  getHistory(@Param("id") id: string) {
    return this.tasksService.getTaskHistory(id);
  }

  // Delete
  @Delete(":id")
  @UseGuards(TaskAccessGuard)
  @ApiOperation({ summary: "Delete or cancel task" })
  deleteTask(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.tasksService.deleteTask(id, userId);
  }
}
