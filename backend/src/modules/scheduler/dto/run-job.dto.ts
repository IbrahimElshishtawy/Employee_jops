import { ApiProperty } from "@nestjs/swagger";

export class JobStatusDto {
  @ApiProperty()
  name: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  intervalSeconds: number;

  @ApiProperty()
  lastRunAt: string | null;

  @ApiProperty()
  lastStatus: "IDLE" | "SUCCESS" | "FAILED";

  @ApiProperty()
  lastError: string | null;

  @ApiProperty()
  totalExecutions: number;
}
