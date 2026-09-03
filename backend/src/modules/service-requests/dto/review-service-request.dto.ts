import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  Max,
  IsIn,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class ReviewServiceRequestDto {
  @ApiProperty({
    description: "Customer satisfaction rating from 1 (poor) to 5 (excellent)",
    example: 5,
    minimum: 1,
    maximum: 5,
  })
  @IsInt()
  @Min(1)
  @Max(5)
  @IsNotEmpty()
  rating: number;

  @ApiPropertyOptional({
    description: "Feedback comments regarding service fulfillment",
    example: "The technician arrived fast and fixed the problem thoroughly.",
  })
  @IsOptional()
  @IsString()
  feedback?: string;

  @ApiProperty({
    description:
      "Review decision: ACCEPT (closes request) or REVISION (requests additional work)",
    enum: ["ACCEPT", "REVISION"],
    example: "ACCEPT",
  })
  @IsIn(["ACCEPT", "REVISION"])
  @IsNotEmpty()
  decision: "ACCEPT" | "REVISION";
}
