import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CheckInDto } from './dto/check-in.dto';
import { CheckOutDto } from './dto/check-out.dto';
import { AttendanceStatus, AuditAction, Prisma } from '@prisma/client';

@Injectable()
export class AttendanceService {
  constructor(private prisma: PrismaService) {}

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
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if already checked in today
    const existingRecord = await this.prisma.attendanceRecord.findUnique({
      where: {
        employeeId_date: {
          employeeId: employee.id,
          date: today,
        },
      },
    });

    if (existingRecord && existingRecord.checkInTime) {
      throw new BadRequestException('You have already checked in today');
    }

    // Geofence verification
    let isWithinGeofence = true;
    if (employee.workplace) {
      const distance = this.calculateDistanceMeters(
        dto.latitude,
        dto.longitude,
        employee.workplace.latitude,
        employee.workplace.longitude,
      );
      isWithinGeofence = distance <= employee.workplace.radiusMeters;
    }

    // Calculate lateness
    const now = new Date();
    let status: AttendanceStatus = AttendanceStatus.PRESENT;
    let lateMinutes = 0;

    if (employee.schedule) {
      const [schedHours, schedMins] = employee.schedule.startTime.split(':').map(Number);
      const scheduledCheckIn = new Date();
      scheduledCheckIn.setHours(schedHours, schedMins, 0, 0);

      const graceLimit = new Date(
        scheduledCheckIn.getTime() + employee.schedule.graceMinutesCheckIn * 60000,
      );

      if (now > graceLimit) {
        status = AttendanceStatus.LATE;
        lateMinutes = Math.round((now.getTime() - scheduledCheckIn.getTime()) / 60000);
      }
    }

    const record = await this.prisma.attendanceRecord.upsert({
      where: {
        employeeId_date: {
          employeeId: employee.id,
          date: today,
        },
      },
      update: {
        checkInTime: now,
        checkInLat: dto.latitude,
        checkInLng: dto.longitude,
        checkInMethod: dto.method,
        isCheckInWithinGeofence: isWithinGeofence,
        status,
        lateMinutes,
        notes: dto.notes,
      },
      create: {
        employeeId: employee.id,
        workplaceId: employee.workplaceId,
        date: today,
        checkInTime: now,
        checkInLat: dto.latitude,
        checkInLng: dto.longitude,
        checkInMethod: dto.method,
        isCheckInWithinGeofence: isWithinGeofence,
        status,
        lateMinutes,
        notes: dto.notes,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CHECK_IN,
        entity: 'AttendanceRecord',
        entityId: record.id,
        payload: { isWithinGeofence, status, lateMinutes },
      },
    });

    return record;
  }

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
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const record = await this.prisma.attendanceRecord.findUnique({
      where: {
        employeeId_date: {
          employeeId: employee.id,
          date: today,
        },
      },
    });

    if (!record || !record.checkInTime) {
      throw new BadRequestException('Cannot check out without checking in first');
    }

    if (record.checkOutTime) {
      throw new BadRequestException('You have already checked out today');
    }

    let isWithinGeofence = true;
    if (employee.workplace) {
      const distance = this.calculateDistanceMeters(
        dto.latitude,
        dto.longitude,
        employee.workplace.latitude,
        employee.workplace.longitude,
      );
      isWithinGeofence = distance <= employee.workplace.radiusMeters;
    }

    const now = new Date();
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

    const updatedRecord = await this.prisma.attendanceRecord.update({
      where: { id: record.id },
      data: {
        checkOutTime: now,
        checkOutLat: dto.latitude,
        checkOutLng: dto.longitude,
        checkOutMethod: dto.method,
        isCheckOutWithinGeofence: isWithinGeofence,
        workDurationMinutes,
        earlyLeaveMinutes,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CHECK_OUT,
        entity: 'AttendanceRecord',
        entityId: record.id,
        payload: { isWithinGeofence, workDurationMinutes, earlyLeaveMinutes },
      },
    });

    return updatedRecord;
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
   * Haversine formula to calculate great-circle distance between two GPS coordinates in meters
   */
  private calculateDistanceMeters(
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
}
