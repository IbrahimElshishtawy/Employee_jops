import { Module, Global } from "@nestjs/common";
import { JwtModule } from "@nestjs/jwt";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { PresenceService } from "./presence.service";
import { RealTimeService } from "./realtime.service";
import { RealTimeGateway } from "./realtime.gateway";
import { WsJwtGuard } from "./guards/ws-jwt.guard";
import { PrismaModule } from "../../prisma/prisma.module";

@Global()
@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret:
          configService.get<string>("jwt.accessSecret") ||
          process.env.JWT_ACCESS_SECRET ||
          "development_insecure_access_secret_key_32bytes_minimum",
        signOptions: {
          expiresIn: configService.get<string>("jwt.accessExpiration") || "15m",
        },
      }),
    }),
  ],
  providers: [PresenceService, RealTimeService, WsJwtGuard, RealTimeGateway],
  exports: [PresenceService, RealTimeService, WsJwtGuard],
})
export class RealTimeModule {}
