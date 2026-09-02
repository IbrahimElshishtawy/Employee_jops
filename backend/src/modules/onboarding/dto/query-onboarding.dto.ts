import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsUUID } from "class-validator";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";
import { OnboardingStatus } from "@prisma/client";

export class QueryOnboardingWorkflowsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: OnboardingStatus })
  @IsEnum(OnboardingStatus)
  @IsOptional()
  status?: OnboardingStatus;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  employeeId?: string;
}
