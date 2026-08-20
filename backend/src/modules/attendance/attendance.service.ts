import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { ManualAttendanceDto } from './dto/manual-attendance.dto';
import { QueryAttendanceDto } from './dto/query-attendance.dto';
import {
  AttendanceStatus,
  AttendanceEventType,
  AuditAction,
  NotificationType,
  Prisma,
  UserStatus,
} from '@prisma/client';

export const MAX_ALLOWED_GPS_ACCURACY_METERS = 50.0;

@Injectable()
export class AttendanceService {
  private readonly logger = new Logger(AttendanceService.name);

  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

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

    if (user.status === UserStatus.SUSPENDED) {
      throw new ForbiddenException('EMPLOYEE_SUSPENDED: Your account is suspended');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException('EMPLOYEE_INACTIVE: Your account is inactive');
    }

    const employee = user.employeeProfile;

    if (!employee.isProfileComplete) {
      throw new BadRequestException('PROFILE_INCOMPLETE: Please complete your onboarding profile first');
    }

    if (!employee.workplace) {
      throw new BadRequestException('WORKPLACE_NOT_ASSIGNED: No workplace assigned to your profile');
    }

    if (!employee.workplace.isActive) {
      throw new BadRequestException('WORKPLACE_INACTIVE: Assigned workplace is currently inactive');
    }

    if (!employee.schedule) {
      throw new BadRequestException('SCHEDULE_NOT_ASSIGNED: No work schedule assigned to your profile');
    }

    // 1. Check Working Day via Server Clock
    const now = new Date();
    const currentDay = now.getDay(); // 0=Sunday, 1=Monday...
    if (!employee.schedule.workingDays.includes(currentDay)) {
      await this.logRejection(userId, 'NON_WORKING_DAY', { currentDay, workingDays: employee.schedule.workingDays });
      throw new BadRequestException('NON_WORKING_DAY: Today is not configured as a working day in your schedule');
    }

    // 2. GPS Accuracy Check
    if (dto.accuracy !== undefined && dto.accuracy > MAX_ALLOWED_GPS_ACCURACY_METERS) {
      await this.logRejection(userId, 'GPS_ACCURACY_TOO_LOW', { accuracy: dto.accuracy });
      throw new BadRequestException(
        `GPS_ACCURACY_TOO_LOW: Reading accuracy of ${dto.accuracy}m exceeds maximum allowed limit (${MAX_ALLOWED_GPS_ACCURACY_METERS}m)`,
      );
    }

    // 3. Geofence Boundary Check (Haversine Formula)
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

    // 4. Anti-Fraud & Security Signals
    const isSuspicious = Boolean(dto.isMockLocation || dto.isJailbroken);

    const deviceSignals = {
      isMockLocation: Boolean(dto.isMockLocation),
      isVpn: Boolean(dto.isVpn),
      isJailbroken: Boolean(dto.isJailbroken),
      biometricVerified: Boolean(dto.biometricVerified),
      distanceMeters,
      accuracy: dto.accuracy,
    };

    // 5. Server-Authoritative Shift Calculation
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

    // 6. Atomic Transaction: Check idempotency, check-in state, event log, and audit trail
    return this.prisma.$transaction(async (tx) => {
      // 1. Check replay by requestId first for idempotency
      if (dto.requestId) {
        const replay = await tx.attendanceRecord.findUnique({
          where: { requestId: dto.requestId },
        });
        if (replay) {
          return replay;
        }
      }

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

      // Record AttendanceEvent
      await tx.attendanceEvent.create({
        data: {
          attendanceRecordId: record.id,
          eventType: AttendanceEventType.CHECK_IN_ACCEPTED,
          latitude: dto.latitude,
          longitude: dto.longitude,
          accuracy: dto.accuracy,
          distanceMeters,
          isWithinGeofence: true,
          metadata: { status, lateMinutes, isSuspicious },
        },
      });

      // Audit Log
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

      // Dispatch Push / In-App Notification asynchronously
      this.notificationsService
        .sendNotification(
          userId,
          'Check-In Successful',
          `Checked in at ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} (${status})`,
          NotificationType.ATTENDANCE_REMINDER,
          { recordId: record.id, status },
        )
        .catch((e) => this.logger.warn(`Failed to dispatch checkin notification: ${e.message}`));

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

      // Record Event
      await tx.attendanceEvent.create({
        data: {
          attendanceRecordId: record.id,
          eventType: AttendanceEventType.CHECK_OUT_ACCEPTED,
          latitude: dto.latitude,
          longitude: dto.longitude,
          accuracy: dto.accuracy,
          distanceMeters,
          isWithinGeofence,
          metadata: { workDurationMinutes, earlyLeaveMinutes },
        },
      });

      // Audit Log
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

      this.notificationsService
        .sendNotification(
          userId,
          'Check-Out Successful',
          `Checked out at ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} (${workDurationMinutes} mins worked)`,
          NotificationType.ATTENDANCE_REMINDER,
          { recordId: record.id, workDurationMinutes },
        )
        .catch((e) => this.logger.warn(`Failed to dispatch checkout notification: ${e.message}`));

      return updatedRecord;
    });
  }

  /**
   * HR Manual Attendance Creation or Correction
   */
  async manualAttendanceEntry(hrUserId: string, dto: ManualAttendanceDto) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { workplace: true, user: true },
    });

    if (!employee) {
      throw new NotFoundException('Target employee profile not found');
    }

    const targetDate = new Date(dto.date);
    targetDate.setHours(0, 0, 0, 0);

    const checkInDate = dto.checkInTime ? new Date(dto.checkInTime) : null;
    const checkOutDate = dto.checkOutTime ? new Date(dto.checkOutTime) : null;

    let workDurationMinutes = 0;
    if (checkInDate && checkOutDate) {
      workDurationMinutes = Math.round(
        (checkOutDate.getTime() - checkInDate.getTime()) / 60000,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.attendanceRecord.findUnique({
        where: {
          employeeId_date: {
            employeeId: employee.id,
            date: targetDate,
          },
        },
      });

      const isUpdate = Boolean(existing);

      const record = await tx.attendanceRecord.upsert({
        where: {
          employeeId_date: {
            employeeId: employee.id,
            date: targetDate,
          },
        },
        update: {
          status: dto.status,
          checkInTime: checkInDate ?? undefined,
          checkOutTime: checkOutDate ?? undefined,
          workDurationMinutes: workDurationMinutes || existing?.workDurationMinutes,
          isManualEntry: true,
          manualCorrectionReason: dto.reason,
          manualCorrectedByUserId: hrUserId,
        },
        create: {
          employeeId: employee.id,
          workplaceId: employee.workplaceId,
          date: targetDate,
          status: dto.status,
          checkInTime: checkInDate,
          checkOutTime: checkOutDate,
          workDurationMinutes,
          isManualEntry: true,
          manualCorrectionReason: dto.reason,
          manualCorrectedByUserId: hrUserId,
        },
      });

      // Log Event
      await tx.attendanceEvent.create({
        data: {
          attendanceRecordId: record.id,
          eventType: AttendanceEventType.MANUAL_CORRECTION,
          metadata: {
            reason: dto.reason,
            hrUserId,
            status: dto.status,
            isUpdate,
          },
        },
      });

      // Audit Log
      await tx.auditLog.create({
        data: {
          userId: hrUserId,
          action: isUpdate
            ? AuditAction.MANUAL_ATTENDANCE_UPDATED
            : AuditAction.MANUAL_ATTENDANCE_CREATED,
          entity: 'AttendanceRecord',
          entityId: record.id,
          payload: {
            targetEmployeeId: employee.id,
            date: dto.date,
            status: dto.status,
            reason: dto.reason,
          },
        },
      });

      // Notify Employee of HR Adjustment
      this.notificationsService
        .sendNotification(
          employee.user.id,
          'Attendance Record Adjusted by HR',
          `Your attendance for ${dto.date} was updated to ${dto.status}. Reason: ${dto.reason}`,
          NotificationType.SYSTEM_ALERT,
          { recordId: record.id, date: dto.date },
        )
        .catch((e) => this.logger.warn(`Failed to dispatch adjustment notification: ${e.message}`));

      return record;
    });
  }

  /**
   * Get personal attendance history for current authenticated employee
   */
  async getMyAttendance(userId: string, query: QueryAttendanceDto = {}) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new NotFoundException('Employee profile not found');
    }

    return this.queryAttendanceRecords({
      ...query,
      employeeId: user.employeeProfile.id,
    });
  }

  /**
   * HR Query: Get attendance for specific employee with IDOR prevention
   */
  async getEmployeeAttendance(employeeId: string, query: QueryAttendanceDto = {}) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: employeeId },
    });

    if (!employee) {
      throw new NotFoundException('Employee profile not found');
    }

    return this.queryAttendanceRecords({
      ...query,
      employeeId,
    });
  }

  /**
   * HR Query: Get attendance by workplace
   */
  async getWorkplaceAttendance(workplaceId: string, query: QueryAttendanceDto = {}) {
    return this.queryAttendanceRecords({
      ...query,
      workplaceId,
    });
  }

  /**
   * HR Query: Get attendance by department
   */
  async getDepartmentAttendance(department: string, query: QueryAttendanceDto = {}) {
    return this.queryAttendanceRecords({
      ...query,
      department,
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
      include: { workplace: true, events: true },
    });

    return record;
  }

  async getEmployeeHistory(employeeProfileId: string, page = 1, limit = 30) {
    return this.queryAttendanceRecords({
      page,
      limit,
      employeeId: employeeProfileId,
    });
  }

  async getAttendanceList(startDate?: string, endDate?: string, workplaceId?: string) {
    return this.queryAttendanceRecords({
      startDate,
      endDate,
      workplaceId,
      limit: 100,
    });
  }

  private async queryAttendanceRecords(filters: {
    employeeId?: string;
    workplaceId?: string;
    department?: string;
    startDate?: string;
    endDate?: string;
    month?: string;
    status?: AttendanceStatus;
    page?: number;
    limit?: number;
  }) {
    const where: Prisma.AttendanceRecordWhereInput = {};

    if (filters.employeeId) {
      where.employeeId = filters.employeeId;
    }

    if (filters.workplaceId) {
      where.workplaceId = filters.workplaceId;
    }

    if (filters.status) {
      where.status = filters.status;
    }

    if (filters.department) {
      where.employee = { department: filters.department };
    }

    if (filters.month) {
      const [year, month] = filters.month.split('-').map(Number);
      const startOfMonth = new Date(year, month - 1, 1);
      const endOfMonth = new Date(year, month, 0, 23, 59, 59);
      where.date = {
        gte: startOfMonth,
        lte: endOfMonth,
      };
    } else if (filters.startDate && filters.endDate) {
      where.date = {
        gte: new Date(filters.startDate),
        lte: new Date(filters.endDate),
      };
    }

    const page = filters.page || 1;
    const limit = filters.limit || 30;
    const skip = (page - 1) * limit;

    const [total, data] = await Promise.all([
      this.prisma.attendanceRecord.count({ where }),
      this.prisma.attendanceRecord.findMany({
        where,
        skip,
        take: limit,
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
          workplace: { select: { id: true, name: true, code: true } },
          events: { orderBy: { timestamp: 'desc' } },
        },
        orderBy: { date: 'desc' },
      }),
    ]);

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
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
