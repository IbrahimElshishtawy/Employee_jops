import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { StorageService } from "./storage.service";
import { UploadFileDto, UploadResultDto } from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("File Storage")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("storage")
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  @Post("upload")
  @ApiOperation({ summary: "Upload file (Image, PDF, Document, Attachment)" })
  @ApiResponse({ status: 201, type: UploadResultDto })
  uploadFile(
    @CurrentUser("id") userId: string,
    @Body() dto: UploadFileDto,
  ) {
    return this.storageService.uploadFile(userId, dto);
  }

  @Get("metadata/:folder/:filename")
  @ApiOperation({ summary: "Get metadata for a stored file" })
  getFileMetadata(
    @Param("folder") folder: string,
    @Param("filename") filename: string,
  ) {
    return this.storageService.getFileMetadata(folder, filename);
  }

  @Delete(":folder/:filename")
  @ApiOperation({ summary: "Delete a stored file" })
  deleteFile(
    @CurrentUser("id") userId: string,
    @Param("folder") folder: string,
    @Param("filename") filename: string,
  ) {
    return this.storageService.deleteFile(userId, folder, filename);
  }
}
