import { PartialType } from "@nestjs/swagger";
import { CreateJobOpeningDto } from "./create-job-opening.dto";

export class UpdateJobOpeningDto extends PartialType(CreateJobOpeningDto) {}
