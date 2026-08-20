import { BadRequestException } from "@nestjs/common";

export interface ParsedDateRange {
  startDate: Date;
  endDate: Date;
}

export class DateRangeUtil {
  /**
   * Resolves start and end Date objects from DTO parameters with validation.
   * Enforces max span (default: 366 days).
   */
  static parseAndValidateDateRange(
    startDateStr?: string,
    endDateStr?: string,
    year?: number,
    month?: number,
    maxDaysSpan: number = 366,
  ): ParsedDateRange {
    let start: Date;
    let end: Date;

    if (year && month) {
      start = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0, 0));
      // End is the last day of the month at 23:59:59.999
      end = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));
    } else if (year) {
      start = new Date(Date.UTC(year, 0, 1, 0, 0, 0, 0));
      end = new Date(Date.UTC(year, 11, 31, 23, 59, 59, 999));
    } else if (startDateStr && endDateStr) {
      start = new Date(startDateStr);
      end = new Date(endDateStr);

      if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        throw new BadRequestException(
          "Invalid date format provided for startDate or endDate",
        );
      }

      start.setUTCHours(0, 0, 0, 0);
      end.setUTCHours(23, 59, 59, 999);
    } else if (startDateStr) {
      start = new Date(startDateStr);
      if (isNaN(start.getTime())) {
        throw new BadRequestException("Invalid startDate format");
      }
      start.setUTCHours(0, 0, 0, 0);
      // Default end to 30 days later or today
      end = new Date(start.getTime() + 30 * 24 * 60 * 60 * 1000);
      end.setUTCHours(23, 59, 59, 999);
    } else {
      // Default to current month
      const now = new Date();
      start = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1, 0, 0, 0, 0),
      );
      end = new Date(
        Date.UTC(
          now.getUTCFullYear(),
          now.getUTCMonth() + 1,
          0,
          23,
          59,
          59,
          999,
        ),
      );
    }

    if (start.getTime() > end.getTime()) {
      throw new BadRequestException(
        "startDate must be before or equal to endDate",
      );
    }

    const diffDays = Math.ceil(
      (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24),
    );
    if (diffDays > maxDaysSpan) {
      throw new BadRequestException(
        `Date range exceeds maximum allowed window of ${maxDaysSpan} days`,
      );
    }

    return { startDate: start, endDate: end };
  }

  /**
   * Calculates expected working days between two dates given working day indices (0=Sun..6=Sat).
   * Default working days: Sun, Mon, Tue, Wed, Thu (indices 0, 1, 2, 3, 4) if not provided.
   */
  static calculateExpectedWorkingDays(
    startDate: Date,
    endDate: Date,
    workingDays: number[] = [0, 1, 2, 3, 4],
  ): number {
    let count = 0;
    const current = new Date(startDate);
    current.setUTCHours(0, 0, 0, 0);
    const end = new Date(endDate);
    end.setUTCHours(0, 0, 0, 0);

    const workingDaysSet = new Set(workingDays);

    while (current.getTime() <= end.getTime()) {
      const dayOfWeek = current.getUTCDay();
      if (workingDaysSet.has(dayOfWeek)) {
        count++;
      }
      current.setUTCDate(current.getUTCDate() + 1);
    }

    return count;
  }
}
