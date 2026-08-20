import { NestFactory } from "@nestjs/core";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { ValidationPipe, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import helmet from "@fastify/helmet";
import compression from "@fastify/compress";
import * as crypto from "crypto";
import { AppModule } from "./app.module";

async function bootstrap() {
  const logger = new Logger("Bootstrap");

  const fastifyAdapter = new FastifyAdapter({
    logger: false,
    trustProxy: true,
    bodyLimit: 10485760, // 10MB payload ceiling
  });

  // Attach request correlation ID hook on Fastify
  const fastifyInstance = fastifyAdapter.getInstance();
  fastifyInstance.addHook("onRequest", (request, reply, done) => {
    const incomingId = request.headers["x-request-id"];
    const requestId =
      typeof incomingId === "string" && incomingId.trim().length > 0
        ? incomingId.trim()
        : crypto.randomUUID();

    (request as any).requestId = requestId;
    reply.header("X-Request-Id", requestId);
    done();
  });

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    fastifyAdapter,
  );

  // Enable NestJS lifecycle shutdown hooks
  app.enableShutdownHooks();

  const configService = app.get(ConfigService);
  const port = configService.get<number>("port") || 3000;
  const host = configService.get<string>("host") || "0.0.0.0";
  const apiPrefix = configService.get<string>("apiPrefix") || "api/v1";

  // Global Prefix
  app.setGlobalPrefix(apiPrefix);

  // Security: Helmet
  await app.register(helmet as any, {
    contentSecurityPolicy: false, // Preserves Swagger UI compatibility
    frameguard: { action: "deny" },
    noSniff: true,
  });

  // Performance: Fastify Compression
  await app.register(compression as any);

  // CORS Configuration
  const isProduction = process.env.NODE_ENV === "production";
  const corsOrigin =
    configService.get<string>("corsOrigin") || process.env.CORS_ORIGIN;

  app.enableCors({
    origin:
      isProduction && corsOrigin
        ? corsOrigin.split(",").map((o) => o.trim())
        : "*",
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept", "X-Request-Id"],
  });

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger OpenAPI Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle("CyberWise IE — API")
    .setDescription(
      "Unified Backend REST API for CyberWise IE Employee Mobile App & HR Management Web Dashboard",
    )
    .setVersion("1.0.0")
    .addBearerAuth()
    .addTag("Authentication", "Login, token refresh, password management")
    .addTag("Employees", "Employee profiles, lifecycle, and directory")
    .addTag("Workplaces", "Branches, locations, and GPS geofences")
    .addTag("Attendance", "GPS check-in/out, live status, history, logs")
    .addTag("Schedules", "Shift schedules and working hours")
    .addTag("Requests", "Leave, excuse, overtime, remote work workflows")
    .addTag("Payroll & Advances", "Salary advances, loans, and deductions")
    .addTag("Notifications", "In-app alerts and FCM device tokens")
    .addTag("Messages", "Internal chat and announcements")
    .addTag(
      "Reports & Analytics",
      "Executive dashboard KPIs and department stats",
    )
    .addTag("Audit Logs", "Compliance and audit trail")
    .addTag("Health", "Database and system health indicators")
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup("api/docs", app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      docExpansion: "none",
    },
  });

  // Graceful signal termination handling
  const shutdown = async (signal: string) => {
    logger.log(`Received ${signal}. Initiating graceful shutdown...`);
    try {
      await app.close();
      logger.log("Application gracefully closed. Exiting.");
      process.exit(0);
    } catch (err) {
      logger.error("Error during graceful shutdown:", err);
      process.exit(1);
    }
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));

  await app.listen(port, host);
  logger.log(
    `🚀 CyberWise IE Backend is running on: http://${host}:${port}/${apiPrefix}`,
  );
  logger.log(
    `📚 Swagger API Documentation available at: http://${host}:${port}/api/docs`,
  );
}

bootstrap().catch((err) => {
  console.error("Fatal Error during startup:", err);
  process.exit(1);
});
