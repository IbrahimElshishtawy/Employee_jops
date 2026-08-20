import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { AttendanceStatus, AuditAction, Prisma } from '@prisma/client';

export const MAX_ALLOWED_GPS_ACCURACY_METERS = 50.0;

@Injectable()
export class AttendanceService {
  private readonly logger = new Logger(AttendanceService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Register employee check-in with geofencing, accuracy, and anti-fraud validation
   */
  async checkIn(userId: string, dto: CheckInDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        employeeProfile: {
          include: {
            workplace: true,
            schedule: true,
          },
        },
      },
    });

    if (!user || !user.employeeProfile) {
      throw new BadRequestException('Employee profile required to register attendance');
    }

    const employee = user.employeeProfile;

    if (!employee.isProfileComplete) {
      throw new BadRequestException('PROFILE_INCOMPLETE: Please complete your onboarding profile first');
    }

    if (!employee.workplace || !employee.workplace.isActive) {
      throw new BadRequestException('WORKPLACE_NOT_ASSIGNED: No active workplace assigned');
    }

    if (!employee.schedule) {
      throw new BadRequestException('SCHEDULE_NOT_ASSIGNED: No work schedule assigned');
    }

    // 1. GPS Accuracy Check
    if (dto.accuracy !== undefined && dto.accuracy > MAX_ALLOWED_GPS_ACCURACY_METERS) {
      await this.logRejection(userId, 'GPS_ACCURACY_TOO_LOW', { accuracy: dto.accuracy });
      throw new BadRequestException(
        `GPS_ACCURACY_TOO_LOW: Reading accuracy of ${dto.accuracy}m exceeds maximum allowed limit (${MAX_ALLOWED_GPS_ACCURACY_METERS}m)`,
      );
    }

    // 2. Geofence Boundary Check (Haversine Formula)
    const distanceMeters = this.calculateDistanceMeters(
      dto.latitude,
      dto.longitude,
      employee.workplace.latitude,
      employee.workplace.longitude,
    );

    const isWithinGeofence = distanceMeters <= employee.workplace.radiusMeters;
    if (!isWithinGeofence) {
      await this.logRejection(userId, 'OUTSIDE_WORKPLACE', {
        distanceMeters,
        allowedRadius: employee.workplace.radiusMeters,
      });
      throw new BadRequestException(
        `OUTSIDE_WORKPLACE: You are ${distanceMeters}m away from your assigned workplace (${employee.workplace.name}). Maximum allowed radius is ${employee.workplace.radiusMeters}m.`,
      );
    }

    // 3. Evaluate Anti-Fraud & Device Signals
    const isSuspicious = Boolean(
      dto.isMockLocation || dto.isJailbroken,
    );

    const deviceSignals = {
      isMockLocation: Boolean(dto.isMockLocation),
      isVpn: Boolean(dto.isVpn),
      isJailbroken: Boolean(dto.isJailbroken),
      biometricVerified: Boolean(dto.biometricVerified),
      distanceMeters,
      accuracy: dto.accuracy,
    };

    // 4. Server-Authoritative Time & Schedule Evaluation
    const now = new Date();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [schedHours, schedMins] = employee.schedule.startTime.split(':').map(Number);
    const scheduledCheckIn = new Date();
    scheduledCheckIn.setHours(schedHours, schedMins, 0, 0);

    const graceLimit = new Date(
      scheduledCheckIn.getTime() + employee.schedule.graceMinutesCheckIn * 60000,
    );

    let status: AttendanceStatus = AttendanceStatus.PRESENT;
    let lateMinutes = 0;

    if (now > graceLimit) {
      status = AttendanceStatus.LATE;
      lateMinutes = Math.round((now.getTime() - scheduledCheckIn.getTime()) / 60000);
    }

    // 5. Atomic Transaction: Check for idempotency & prevent duplicate check-in
    return this.prisma.$transaction(async (tx) => {
      // Check existing record for today
      const existing = await tx.attendanceRecord.findUnique({
        where: {
          employeeId_date: {
            employeeId: employee.id,
            date: today,
          },
        },
      });

      if (existing && existing.checkInTime) {
        throw new BadRequestException('ALREADY_CHECKED_IN: Attendance record for today has already been checked in');
      }

      // Check replay by requestId if provided
      if (dto.requestId) {
        const replay = await tx.attendanceRecord.findUnique({
          where: { requestId: dto.requestId },
        });
        if (replay) {
          return replay; // Idempotent return
        }
      }

      const record = await tx.attendanceRecord.upsert({
        where: {
          employeeId_date: {
            employeeId: employee.id,
            date: today,
          },
        },
        update: {
          requestId: dto.requestId,
          checkInTime: now,
          checkInLat: dto.latitude,
          checkInLng: dto.longitude,
          checkInMethod: dto.method,
          checkInAccuracy: dto.accuracy,
          isCheckInWithinGeofence: true,
          status,
          lateMinutes,
          isSuspicious,
          deviceSignals,
          notes: dto.notes,
        },
        create: {
          requestId: dto.requestId,
          employeeId: employee.id,
          workplaceId: employee.workplaceId,
          date: today,
          checkInTime: now,
          checkInLat: dto.latitude,
          checkInLng: dto.longitude,
          checkInMethod: dto.method,
          checkInAccuracy: dto.accuracy,
          isCheckInWithinGeofence: true,
          status,
          lateMinutes,
          isSuspicious,
          deviceSignals,
          notes: dto.notes,
        },
      });

      await tx.auditLog.create({
        data: {
          userId,
          action: AuditAction.ATTENDANCE_CHECK_IN,
          entity: 'AttendanceRecord',
          entityId: record.id,
          payload: {
            status,
            lateMinutes,
            distanceMeters,
            isSuspicious,
            deviceSignals,
          },
        },
      });

      return record;
    });
  }

  /**
   * Register employee check-out with duration and early departure calculations
   */
  async checkOut(userId: string, dto: CheckOutDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        employeeProfile: {
          include: {
            workplace: true,
            schedule: true,
          },
        },
      },
    });

    if (!user || !user.employeeProfile) {
      throw new BadRequestException('Employee profile required');
    }

    const employee = user.employeeProfile;
    const now = new Date();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. GPS Accuracy Check
    if (dto.accuracy !== undefined && dto.accuracy > MAX_ALLOWED_GPS_ACCURACY_METERS) {
      await this.logRejection(userId, 'GPS_ACCURACY_TOO_LOW', { accuracy: dto.accuracy });
      throw new BadRequestException(
        `GPS_ACCURACY_TOO_LOW: Reading accuracy of ${dto.accuracy}m exceeds maximum allowed limit (${MAX_ALLOWED_GPS_ACCURACY_METERS}m)`,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const record = await tx.attendanceRecord.findUnique({
        where: {
          employeeId_date: {
            employeeId: employee.id,
            date: today,
          },
        },
      });

      if (!record || !record.checkInTime) {
        throw new BadRequestException('NO_ACTIVE_CHECK_IN: You must check in first before checking out');
      }

      if (record.checkOutTime) {
        throw new BadRequestException('ALREADY_CHECKED_OUT: You have already checked out today');
      }

      let isWithinGeofence = true;
      let distanceMeters = 0;
      if (employee.workplace) {
        distanceMeters = this.calculateDistanceMeters(
          dto.latitude,
          dto.longitude,
          employee.workplace.latitude,
          employee.workplace.longitude,
        );
        isWithinGeofence = distanceMeters <= employee.workplace.radiusMeters;
      }

      const workDurationMinutes = Math.round(
        (now.getTime() - new Date(record.checkInTime).getTime()) / 60000,
      );

      let earlyLeaveMinutes = 0;
      if (employee.schedule) {
        const [endHours, endMins] = employee.schedule.endTime.split(':').map(Number);
        const scheduledCheckOut = new Date();
        scheduledCheckOut.setHours(endHours, endMins, 0, 0);

        if (now < scheduledCheckOut) {
          earlyLeaveMinutes = Math.round((scheduledCheckOut.getTime() - now.getTime()) / 60000);
        }
      }

      const updatedRecord = await tx.attendanceRecord.update({
        where: { id: record.id },
        data: {
          checkOutTime: now,
          checkOutLat: dto.latitude,
          checkOutLng: dto.longitude,
          checkOutMethod: dto.method,
          checkOutAccuracy: dto.accuracy,
          isCheckOutWithinGeofence: isWithinGeofence,
          workDurationMinutes,
          earlyLeaveMinutes,
        },
      });

      await tx.auditLog.create({
        data: {
          userId,
          action: AuditAction.ATTENDANCE_CHECK_OUT,
          entity: 'AttendanceRecord',
          entityId: record.id,
          payload: {
            workDurationMinutes,
            earlyLeaveMinutes,
            distanceMeters,
            isWithinGeofence,
          },
        },
      });

      return updatedRecord;
    });
  }

  async getTodayStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new NotFoundException('Employee profile not found');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const record = await this.prisma.attendanceRecord.findUnique({
      where: {
        employeeId_date: {
          employeeId: user.employeeProfile.id,
          date: today,
        },
      },
      include: { workplace: true },
    });

    return record;
  }

  async getEmployeeHistory(employeeProfileId: string, page = 1, limit = 30) {
    const skip = (page - 1) * limit;
    const [total, data] = await Promise.all([
      this.prisma.attendanceRecord.count({ where: { employeeId: employeeProfileId } }),
      this.prisma.attendanceRecord.findMany({
        where: { employeeId: employeeProfileId },
        skip,
        take: limit,
        orderBy: { date: 'desc' },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getAttendanceList(startDate?: string, endDate?: string, workplaceId?: string) {
    const where: Prisma.AttendanceRecordWhereInput = {};

    if (startDate && endDate) {
      where.date = {
        gte: new Date(startDate),
        lte: new Date(endDate),
      };
    }

    if (workplaceId) {
      where.workplaceId = workplaceId;
    }

    return this.prisma.attendanceRecord.findMany({
      where,
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
          },
        },
        workplace: { select: { id: true, name: true } },
      },
      orderBy: { date: 'desc' },
    });
  }

  /**
   * Great-circle distance between two GPS coordinates using Haversine formula
   */
  calculateDistanceMeters(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371e3; // Earth radius in meters
    const phi1 = (lat1 * Math.PI) / 180;
    const phi2 = (lat2 * Math.PI) / 180;
    const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
    const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
      Math.cos(phi1) *
        Math.cos(phi2) *
        Math.sin(deltaLambda / 2) *
        Math.sin(deltaLambda / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return Math.round(R * c);
  }

  private async logRejection(userId: string, reason: string, metadata: any) {
    try {
      await this.prisma.auditLog.create({
        data: {
          userId,
          action: AuditAction.ATTENDANCE_REJECTED,
          entity: 'AttendanceRecord',
          payload: { reason, ...metadata },
        },
      });
    } catch (e: any) {
      this.logger.warn(`Failed to log attendance rejection: ${e.message}`);
    }
  }
}
