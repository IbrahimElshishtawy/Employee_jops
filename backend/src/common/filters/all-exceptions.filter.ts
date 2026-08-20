import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import { FastifyReply, FastifyRequest } from "fastify";
import { Prisma } from "@prisma/client";

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<FastifyReply>();
    const request = ctx.getRequest<FastifyRequest>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = "Internal server error";
    let error = "Internal Server Error";

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === "object" && exceptionResponse !== null) {
        const resObj = exceptionResponse as Record<string, any>;
        message = resObj.message || exception.message;
        error = resObj.error || exception.name;
      } else {
        message = exception.message;
        error = exception.name;
      }
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      switch (exception.code) {
        case "P2002": {
          status = HttpStatus.CONFLICT;
          const fields =
            (exception.meta?.target as string[])?.join(", ") || "field";
          message = `Unique constraint violation on ${fields}`;
          error = "Conflict";
          break;
        }
        case "P2025": {
          status = HttpStatus.NOT_FOUND;
          message = "The requested resource was not found";
          error = "Not Found";
          break;
        }
        case "P2003": {
          status = HttpStatus.BAD_REQUEST;
          message = "Foreign key constraint violation";
          error = "Bad Request";
          break;
        }
        default: {
          status = HttpStatus.BAD_REQUEST;
          message = `Database query error (${exception.code})`;
          error = "Bad Request";
          break;
        }
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      this.logger.error(
        `[Unhandled Error] ${request.method} ${request.url} - ${exception.message}`,
        exception.stack,
      );
    }

    const responseBody = {
      success: false,
      statusCode: status,
      error,
      message,
      path: request.url,
      method: request.method,
      timestamp: new Date().toISOString(),
    };

    response.status(status).send(responseBody);
  }
}
