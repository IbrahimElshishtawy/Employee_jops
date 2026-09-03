import { plainToInstance } from "class-transformer";
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  validateSync,
} from "class-validator";

export enum Environment {
  Development = "development",
  Production = "production",
  Test = "test",
}

export class EnvironmentVariables {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  @IsOptional()
  PORT: number = 3000;

  @IsString()
  @IsOptional()
  HOST: string = "0.0.0.0";

  @IsString()
  @IsOptional()
  APP_NAME: string = "CyberWise-IE-Backend";

  @IsString()
  @IsOptional()
  API_PREFIX: string = "api/v1";

  @IsString()
  DATABASE_URL: string;

  @IsString()
  @IsOptional()
  REDIS_HOST?: string;

  @IsNumber()
  @IsOptional()
  REDIS_PORT?: number;

  @IsString()
  @IsOptional()
  REDIS_PASSWORD?: string;

  @IsString()
  JWT_ACCESS_SECRET: string;

  @IsString()
  @IsOptional()
  JWT_ACCESS_EXPIRATION: string = "15m";

  @IsString()
  JWT_REFRESH_SECRET: string;

  @IsString()
  @IsOptional()
  JWT_REFRESH_EXPIRATION: string = "7d";

  @IsString()
  @IsOptional()
  CORS_ORIGINS: string = "*";

  @IsNumber()
  @IsOptional()
  THROTTLE_TTL: number = 60;

  @IsNumber()
  @IsOptional()
  THROTTLE_LIMIT: number = 100;

  @IsString()
  @IsOptional()
  FCM_PROJECT_ID?: string;

  @IsString()
  @IsOptional()
  FCM_CLIENT_EMAIL?: string;

  @IsString()
  @IsOptional()
  FCM_PRIVATE_KEY?: string;
}

export function validate(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`Config validation error: ${errors.toString()}`);
  }

  // Security hardening: reject fallback/weak secrets in production
  if (validatedConfig.NODE_ENV === Environment.Production) {
    const forbiddenPatterns = ["default_secret", "password", "secret", "test_secret", "123456"];
    const access = validatedConfig.JWT_ACCESS_SECRET?.toLowerCase() || "";
    const refresh = validatedConfig.JWT_REFRESH_SECRET?.toLowerCase() || "";

    for (const pattern of forbiddenPatterns) {
      if (access === pattern || refresh === pattern) {
        throw new Error(
          `Security Alert: Production deployment rejected. Insecure fallback pattern '${pattern}' detected in JWT secrets.`,
        );
      }
    }

    if (validatedConfig.JWT_ACCESS_SECRET.length < 32 || validatedConfig.JWT_REFRESH_SECRET.length < 32) {
      throw new Error(
        "Security Alert: Production deployment rejected. JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be at least 32 characters long.",
      );
    }
  }

  return validatedConfig;
}
