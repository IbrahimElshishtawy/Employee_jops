import { Module } from "@nestjs/common";
import { StorageService } from "./storage.service";
import { StorageController } from "./storage.controller";
import { LocalStorageProvider } from "./providers/local-storage.provider";
import { S3CompatibleStorageProvider } from "./providers/s3-storage.provider";

@Module({
  controllers: [StorageController],
  providers: [
    StorageService,
    LocalStorageProvider,
    S3CompatibleStorageProvider,
    {
      provide: "STORAGE_PROVIDER",
      useFactory: (local: LocalStorageProvider, s3: S3CompatibleStorageProvider) => {
        return process.env.STORAGE_DRIVER === "s3" ? s3 : local;
      },
      inject: [LocalStorageProvider, S3CompatibleStorageProvider],
    },
  ],
  exports: [StorageService, LocalStorageProvider, S3CompatibleStorageProvider],
})
export class StorageModule {}
