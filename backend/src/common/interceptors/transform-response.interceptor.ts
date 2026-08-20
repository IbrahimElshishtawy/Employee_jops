import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { FastifyReply } from 'fastify';

export interface StandardResponse<T> {
  success: boolean;
  statusCode: number;
  data: T;
  meta?: any;
  timestamp: string;
}

@Injectable()
export class TransformResponseInterceptor<T>
  implements NestInterceptor<T, StandardResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<StandardResponse<T>> {
    const response = context.switchToHttp().getResponse<FastifyReply>();
    const statusCode = response.statusCode || 200;

    return next.handle().pipe(
      map((res) => {
        // If data is already an object containing meta/data separation
        if (
          res &&
          typeof res === 'object' &&
          'data' in res &&
          ('meta' in res || 'message' in res)
        ) {
          return {
            success: true,
            statusCode,
            message: res.message,
            data: res.data,
            meta: res.meta,
            timestamp: new Date().toISOString(),
          };
        }

        return {
          success: true,
          statusCode,
          data: res ?? null,
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }
}
