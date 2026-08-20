import { Module } from "@nestjs/common";
import { MessagesService } from "./messages.service";
import { MessagesController } from "./messages.controller";
import { RealTimeService } from "./realtime.service";

@Module({
  controllers: [MessagesController],
  providers: [MessagesService, RealTimeService],
  exports: [MessagesService, RealTimeService],
})
export class MessagesModule {}
