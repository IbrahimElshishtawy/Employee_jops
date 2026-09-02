import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { RecruitmentService } from "./recruitment.service";
import { CreateJobOpeningDto } from "./dto/create-job-opening.dto";
import { UpdateJobOpeningDto } from "./dto/update-job-opening.dto";
import { CreateCandidateDto } from "./dto/create-candidate.dto";
import { UpdateCandidateDto } from "./dto/update-candidate.dto";
import { CreateApplicationDto } from "./dto/create-application.dto";
import { UpdateApplicationDto } from "./dto/update-application.dto";
import { CreateInterviewDto } from "./dto/create-interview.dto";
import { UpdateInterviewDto } from "./dto/update-interview.dto";
import { CreateEvaluationDto } from "./dto/create-evaluation.dto";
import { CreateJobOfferDto } from "./dto/create-job-offer.dto";
import { UpdateJobOfferDto } from "./dto/update-job-offer.dto";
import { HireCandidateDto } from "./dto/hire-candidate.dto";
import {
  QueryJobOpeningsDto,
  QueryCandidatesDto,
  QueryApplicationsDto,
  QueryInterviewsDto,
  QueryJobOffersDto,
} from "./dto/query-recruitment.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { PermissionsGuard } from "../../common/guards/permissions.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RequirePermissions } from "../../common/decorators/permissions.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("Recruitment & ATS")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller("recruitment")
export class RecruitmentController {
  constructor(private readonly recruitmentService: RecruitmentService) {}

  // ============================================================
  // JOB OPENINGS
  // ============================================================

  @Post("job-openings")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("job_openings:create")
  @ApiOperation({ summary: "Create a new job opening requisition" })
  createJobOpening(
    @Body() dto: CreateJobOpeningDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.createJobOpening(dto, userId);
  }

  @Get("job-openings")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE)
  @ApiOperation({ summary: "List paginated job openings with filter support" })
  getJobOpenings(@Query() query: QueryJobOpeningsDto) {
    return this.recruitmentService.getJobOpenings(query);
  }

  @Get("job-openings/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE)
  @ApiOperation({ summary: "Get job opening details with applications timeline" })
  getJobOpeningById(@Param("id") id: string) {
    return this.recruitmentService.getJobOpeningById(id);
  }

  @Patch("job-openings/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("job_openings:update")
  @ApiOperation({ summary: "Update job opening parameters or status" })
  updateJobOpening(
    @Param("id") id: string,
    @Body() dto: UpdateJobOpeningDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.updateJobOpening(id, dto, userId);
  }

  @Delete("job-openings/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @RequirePermissions("job_openings:delete")
  @ApiOperation({ summary: "Delete job opening" })
  deleteJobOpening(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.deleteJobOpening(id, userId);
  }

  // ============================================================
  // CANDIDATES
  // ============================================================

  @Post("candidates")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("candidates:create")
  @ApiOperation({ summary: "Create candidate talent profile" })
  createCandidate(
    @Body() dto: CreateCandidateDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.createCandidate(dto, userId);
  }

  @Get("candidates")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("candidates:read")
  @ApiOperation({ summary: "Search and list candidate talent database" })
  getCandidates(@Query() query: QueryCandidatesDto) {
    return this.recruitmentService.getCandidates(query);
  }

  @Get("candidates/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("candidates:read")
  @ApiOperation({ summary: "Get candidate profile with full application & interview history" })
  getCandidateById(@Param("id") id: string) {
    return this.recruitmentService.getCandidateById(id);
  }

  @Patch("candidates/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("candidates:update")
  @ApiOperation({ summary: "Update candidate contact details and skills" })
  updateCandidate(
    @Param("id") id: string,
    @Body() dto: UpdateCandidateDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.updateCandidate(id, dto, userId);
  }

  @Delete("candidates/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @RequirePermissions("candidates:delete")
  @ApiOperation({ summary: "Delete candidate record" })
  deleteCandidate(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.deleteCandidate(id, userId);
  }

  // ============================================================
  // JOB APPLICATIONS
  // ============================================================

  @Post("applications")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("applications:create")
  @ApiOperation({ summary: "Submit/link candidate application for a job opening" })
  createApplication(
    @Body() dto: CreateApplicationDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.createApplication(dto, userId);
  }

  @Get("applications")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("applications:read")
  @ApiOperation({ summary: "List and filter job applications by opening or status" })
  getApplications(@Query() query: QueryApplicationsDto) {
    return this.recruitmentService.getApplications(query);
  }

  @Get("applications/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("applications:read")
  @ApiOperation({ summary: "Get application details with interview notes and evaluations" })
  getApplicationById(@Param("id") id: string) {
    return this.recruitmentService.getApplicationById(id);
  }

  @Patch("applications/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("applications:update")
  @ApiOperation({ summary: "Update application stage, rating, or rejection reason" })
  updateApplication(
    @Param("id") id: string,
    @Body() dto: UpdateApplicationDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.updateApplication(id, dto, userId);
  }

  // ============================================================
  // INTERVIEWS & EVALUATIONS
  // ============================================================

  @Post("interviews")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("interviews:create")
  @ApiOperation({ summary: "Schedule candidate interview round" })
  scheduleInterview(
    @Body() dto: CreateInterviewDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.scheduleInterview(dto, userId);
  }

  @Get("interviews")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("interviews:read")
  @ApiOperation({ summary: "List scheduled interviews" })
  getInterviews(@Query() query: QueryInterviewsDto) {
    return this.recruitmentService.getInterviews(query);
  }

  @Get("interviews/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("interviews:read")
  @ApiOperation({ summary: "Get interview details and scorecard" })
  getInterviewById(@Param("id") id: string) {
    return this.recruitmentService.getInterviewById(id);
  }

  @Patch("interviews/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("interviews:update")
  @ApiOperation({ summary: "Update interview time, meeting link, or status" })
  updateInterview(
    @Param("id") id: string,
    @Body() dto: UpdateInterviewDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.updateInterview(id, dto, userId);
  }

  @Post("interviews/:id/evaluations")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("interviews:update")
  @ApiOperation({ summary: "Submit structured interviewer scorecard and rating" })
  submitEvaluation(
    @Param("id") interviewId: string,
    @Body() dto: CreateEvaluationDto,
    @CurrentUser("id") evaluatorId: string,
  ) {
    return this.recruitmentService.submitEvaluation(interviewId, dto, evaluatorId);
  }

  // ============================================================
  // JOB OFFERS
  // ============================================================

  @Post("offers")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("job_offers:create")
  @ApiOperation({ summary: "Generate job offer for candidate" })
  createJobOffer(
    @Body() dto: CreateJobOfferDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.createJobOffer(dto, userId);
  }

  @Get("offers")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("job_offers:read")
  @ApiOperation({ summary: "List all generated job offers" })
  getJobOffers(@Query() query: QueryJobOffersDto) {
    return this.recruitmentService.getJobOffers(query);
  }

  @Get("offers/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("job_offers:read")
  @ApiOperation({ summary: "Get job offer terms and acceptance status" })
  getJobOfferById(@Param("id") id: string) {
    return this.recruitmentService.getJobOfferById(id);
  }

  @Patch("offers/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("job_offers:update")
  @ApiOperation({ summary: "Update job offer details, status (SENT, ACCEPTED, REJECTED)" })
  updateJobOffer(
    @Param("id") id: string,
    @Body() dto: UpdateJobOfferDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.recruitmentService.updateJobOffer(id, dto, userId);
  }

  // ============================================================
  // ATOMIC HIRING WORKFLOW
  // ============================================================

  @Post("hire")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("candidates:manage")
  @ApiOperation({
    summary:
      "Execute atomic hiring: Creates corporate user account, employee profile, links hierarchy & starts onboarding",
  })
  hireCandidate(
    @Body() dto: HireCandidateDto,
    @CurrentUser("id") creatorId: string,
  ) {
    return this.recruitmentService.hireCandidate(dto, creatorId);
  }
}
