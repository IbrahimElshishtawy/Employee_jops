import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateSupplierInvoiceDto {
  @ApiProperty({ example: "INV-SUP-8910" })
  @IsString()
  @IsNotEmpty()
  invoiceNumber: string;

  @ApiPropertyOptional({ example: "po-uuid-123" })
  @IsOptional()
  @IsString()
  purchaseOrderId?: string;

  @ApiProperty({ example: "supplier-uuid-456" })
  @IsString()
  @IsNotEmpty()
  supplierId: string;

  @ApiPropertyOptional({ example: "2026-09-03T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  invoiceDate?: string;

  @ApiProperty({ example: "2026-10-03T00:00:00.000Z" })
  @IsDateString()
  dueDate: string;

  @ApiProperty({ example: 1625.0 })
  @IsNumber()
  @Min(0)
  subtotal: number;

  @ApiPropertyOptional({ example: 243.75, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  taxAmount?: number;

  @ApiPropertyOptional({ example: "Matches delivered items for PO-901" })
  @IsOptional()
  @IsString()
  notes?: string;
}
