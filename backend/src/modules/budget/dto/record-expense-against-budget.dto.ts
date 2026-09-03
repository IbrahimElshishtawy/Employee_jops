import { IsString, IsNotEmpty, IsNumber, Min } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class RecordBudgetSpendingDto {
  @ApiProperty({ example: "budget-line-uuid" })
  @IsString()
  @IsNotEmpty()
  budgetLineId: string;

  @ApiProperty({ example: 4500.0 })
  @IsNumber()
  @Min(0.01)
  amount: number;
}
