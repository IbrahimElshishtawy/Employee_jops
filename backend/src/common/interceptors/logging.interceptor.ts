import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from "@nestjs/common";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";
import { FastifyRequest, FastifyReply } from "fastify";

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger("HTTP");

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest<FastifyRequest>();
    const res = context.switchToHttp().getResponse<FastifyReply>();
    const { method, url, ip } = req;
    const requestId =
      (req as any).requestId ||
      (req.headers["x-request-id"] as string) ||
      "no-req-id";
    const userId = (req as any).user?.id ? ` User:${(req as any).user.id}` : "";
    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const delay = Date.now() - now;
          const statusCode = res.statusCode;
          this.logger.log(
            `[${requestId}] [${method}] ${url} - ${statusCode} - ${delay}ms - IP: ${ip}${userId}`,
          );
        },
        error: (err) => {
          const delay = Date.now() - now;
          const status = err.status || res.statusCode || 500;
          this.logger.warn(
            `[${requestId}] [${method}] ${url} - ${status} - ${delay}ms - Error: ${err.message}`,
          );
        },
      }),
    );
  }
}
