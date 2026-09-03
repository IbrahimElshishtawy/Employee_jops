import { Module } from "@nestjs/common";
import { KeysController } from "./keys.controller";
import { KeysService } from "./keys.service";
import { KeysRepository } from "./keys.repository";

@Module({
  controllers: [KeysController],
  providers: [KeysService, KeysRepository],
  exports: [KeysService, KeysRepository],
})
export class KeysModule {}
