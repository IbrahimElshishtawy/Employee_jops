import { ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
} from "class-validator";
import { Transform } from "class-transformer";
import { NotificationPriority, NotificationType } from "@prisma/client";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class QueryNotificationsDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    enum: NotificationType,
    description: "Filter notifications by category/type",
  })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @ApiPropertyOptional({
    enum: NotificationPriority,
    description: "Filter notifications by priority",
  })
  @IsOptional()
  @IsEnum(NotificationPriority)
  priority?: NotificationPriority;

  @ApiPropertyOptional({
    description: "Filter read (true) or unread (false) notifications",
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === "true" || value === true) return true;
    if (value === "false" || value === false) return false;
    return value;
  })
  @IsBoolean()
  isRead?: boolean;

  @ApiPropertyOptional({
    example: "2026-08-01",
    description: "Filter notifications created on or after this date",
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    example: "2026-08-31",
    description: "Filter notifications created on or before this date",
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class UpdateNotificationPreferencesDto {
  @ApiPropertyOptional({
    default: true,
    description: "Receive attendance alerts",
  })
  @IsOptional()
  @IsBoolean()
  attendanceNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Receive request status alerts",
  })
  @IsOptional()
  @IsBoolean()
  requestNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Receive payroll and payslip alerts",
  })
  @IsOptional()
  @IsBoolean()
  payrollNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Receive salary advance status alerts",
  })
  @IsOptional()
  @IsBoolean()
  advanceNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Receive company & HR announcements",
  })
  @IsOptional()
  @IsBoolean()
  announcementNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Receive internal chat message alerts",
  })
  @IsOptional()
  @IsBoolean()
  messageNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Enable email notifications channel",
  })
  @IsOptional()
  @IsBoolean()
  emailNotifications?: boolean;

  @ApiPropertyOptional({
    default: true,
    description: "Enable mobile push notifications channel",
  })
  @IsOptional()
  @IsBoolean()
  pushNotifications?: boolean;
}
