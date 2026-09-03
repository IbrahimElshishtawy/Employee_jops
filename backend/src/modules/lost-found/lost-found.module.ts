import { Module } from "@nestjs/common";
import { LostFoundController } from "./lost-found.controller";
import { LostFoundService } from "./lost-found.service";
import { LostFoundRepository } from "./lost-found.repository";

@Module({
  controllers: [LostFoundController],
  providers: [LostFoundService, LostFoundRepository],
  exports: [LostFoundService, LostFoundRepository],
})
export class LostFoundModule {}
