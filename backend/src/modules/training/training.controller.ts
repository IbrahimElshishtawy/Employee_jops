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
import { TrainingService } from "./training.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateTrainingCourseDto,
  CreateTrainingSessionDto,
  EnrollEmployeeDto,
  UpdateEnrollmentDto,
  IssueCertificateDto,
  QueryTrainingCoursesDto,
  QueryTrainingSessionsDto,
} from "./dto";

@ApiTags("Training & Development")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("training")
export class TrainingController {
  constructor(private readonly trainingService: TrainingService) {}

  // Courses
  @Post("courses")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a training course" })
  createCourse(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateTrainingCourseDto,
  ) {
    return this.trainingService.createCourse(userId, dto);
  }

  @Get("courses")
  @ApiOperation({ summary: "List training courses" })
  findCourses(@Query() query: QueryTrainingCoursesDto) {
    return this.trainingService.findCourses(query);
  }

  @Get("courses/:id")
  @ApiOperation({ summary: "Get course details and upcoming sessions" })
  findCourseById(@Param("id") id: string) {
    return this.trainingService.findCourseById(id);
  }

  // Sessions
  @Post("sessions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Schedule a training session" })
  createSession(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateTrainingSessionDto,
  ) {
    return this.trainingService.createSession(userId, dto);
  }

  @Get("sessions")
  @ApiOperation({ summary: "List training sessions with filters" })
  findSessions(@Query() query: QueryTrainingSessionsDto) {
    return this.trainingService.findSessions(query);
  }

  @Get("sessions/:id")
  @ApiOperation({ summary: "Get session details and enrolled participants" })
  findSessionById(@Param("id") id: string) {
    return this.trainingService.findSessionById(id);
  }

  // Enrollments
  @Post("sessions/:id/enroll")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Enroll an employee into a training session" })
  enrollEmployee(
    @Param("id") sessionId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: EnrollEmployeeDto,
  ) {
    return this.trainingService.enrollEmployee(sessionId, userId, dto);
  }

  @Patch("enrollments/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Update enrollment status and score (e.g. COMPLETED, FAILED)" })
  updateEnrollment(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateEnrollmentDto,
  ) {
    return this.trainingService.updateEnrollment(id, userId, dto);
  }

  // Certificates
  @Post("certificates")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Issue a training certificate to an employee" })
  issueCertificate(
    @CurrentUser("id") userId: string,
    @Body() dto: IssueCertificateDto,
  ) {
    return this.trainingService.issueCertificate(userId, dto);
  }

  @Get("certificates")
  @ApiOperation({ summary: "List employee certificates" })
  findCertificates(@Query("employeeId") employeeId?: string) {
    return this.trainingService.findCertificates(employeeId);
  }
}
