export default () => ({
  env: process.env.NODE_ENV || "development",
  port: parseInt(process.env.PORT || "3000", 10),
  host: process.env.HOST || "0.0.0.0",
  appName: process.env.APP_NAME || "CyberWise-IE-Backend",
  apiPrefix: process.env.API_PREFIX || "api/v1",
  database: {
    url: process.env.DATABASE_URL,
  },
  redis: {
    host: process.env.REDIS_HOST || "localhost",
    port: parseInt(process.env.REDIS_PORT || "6379", 10),
    password: process.env.REDIS_PASSWORD || undefined,
  },
  jwt: {
    accessSecret: (() => {
      const secret = process.env.JWT_ACCESS_SECRET;
      if (process.env.NODE_ENV === "production") {
        if (
          !secret ||
          secret === "default_secret" ||
          secret.includes("test") ||
          secret.length < 32
        ) {
          throw new Error(
            "FATAL: JWT_ACCESS_SECRET is missing, insecure, or uses default fallback in production",
          );
        }
      }
      return secret || "development_insecure_access_secret_key_32bytes_minimum";
    })(),
    accessExpiration: process.env.JWT_ACCESS_EXPIRATION || "15m",
    refreshSecret: (() => {
      const secret = process.env.JWT_REFRESH_SECRET;
      if (process.env.NODE_ENV === "production") {
        if (
          !secret ||
          secret === "default_refresh_secret" ||
          secret.includes("test") ||
          secret.length < 32
        ) {
          throw new Error(
            "FATAL: JWT_REFRESH_SECRET is missing, insecure, or uses default fallback in production",
          );
        }
      }
      return (
        secret || "development_insecure_refresh_secret_key_32bytes_minimum"
      );
    })(),
    refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || "7d",
  },
  cors: {
    origins: process.env.CORS_ORIGINS
      ? process.env.CORS_ORIGINS.split(",")
      : "*",
  },
  throttler: {
    ttl: parseInt(process.env.THROTTLE_TTL || "60", 10),
    limit: parseInt(process.env.THROTTLE_LIMIT || "100", 10),
  },
});
