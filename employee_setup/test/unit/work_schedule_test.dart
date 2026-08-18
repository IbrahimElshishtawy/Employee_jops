import 'package:employee_setup/core/services/time_service.dart';
import 'package:employee_setup/features/attendance/domain/models/work_schedule.dart';
import 'package:employee_setup/features/attendance/domain/services/work_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkSchedule & WorkScheduleService Tests', () {
    test('WorkSchedule default schedule is configured for Sunday-Thursday 9AM-5PM', () {
      final schedule = WorkSchedule.defaultSchedule();
      expect(schedule.workingDays.contains(DateTime.monday), isTrue);
      expect(schedule.workingDays.contains(DateTime.friday), isFalse);
      expect(schedule.startTime, equals(const TimeOfDay(hour: 9, minute: 0)));
      expect(schedule.endTime, equals(const TimeOfDay(hour: 17, minute: 0)));
      expect(schedule.gracePeriodMinutes, equals(15));
      expect(schedule.formattedStartTime, equals('9:00 AM'));
      expect(schedule.formattedEndTime, equals('5:00 PM'));
    });

    test('WorkScheduleService detects beforeShift correctly', () {
      // Set time to 8:30 AM on Monday
      final monday = DateTime(2026, 8, 17, 8, 30); // Monday
      final timeService = DeviceTimeService(() => monday);
      final scheduleService = WorkScheduleService(timeService);
      final schedule = WorkSchedule.defaultSchedule();

      final status = scheduleService.evaluateScheduleStatus(schedule);
      expect(status.type, equals(ShiftStatusType.beforeShift));
      expect(status.isBeforeShift, isTrue);
      expect(status.timeDifference?.inMinutes, equals(30));

      final messageAr = scheduleService.getScheduleSummaryMessage(schedule, isArabic: true);
      expect(messageAr, contains('30 دقيقة'));
    });

    test('WorkScheduleService detects withinShift correctly', () {
      // Set time to 11:00 AM on Monday
      final monday = DateTime(2026, 8, 17, 11, 0); // Monday
      final timeService = DeviceTimeService(() => monday);
      final scheduleService = WorkScheduleService(timeService);
      final schedule = WorkSchedule.defaultSchedule();

      final status = scheduleService.evaluateScheduleStatus(schedule);
      expect(status.type, equals(ShiftStatusType.withinShift));
      expect(status.isWithinShift, isTrue);

      final messageAr = scheduleService.getScheduleSummaryMessage(schedule, isArabic: true);
      expect(messageAr, contains('فترة الدوام'));
    });

    test('WorkScheduleService detects afterShift correctly', () {
      // Set time to 18:00 (6 PM) on Monday
      final monday = DateTime(2026, 8, 17, 18, 0); // Monday
      final timeService = DeviceTimeService(() => monday);
      final scheduleService = WorkScheduleService(timeService);
      final schedule = WorkSchedule.defaultSchedule();

      final status = scheduleService.evaluateScheduleStatus(schedule);
      expect(status.type, equals(ShiftStatusType.afterShift));
      expect(status.isAfterShift, isTrue);

      final messageAr = scheduleService.getScheduleSummaryMessage(schedule, isArabic: true);
      expect(messageAr, contains('انتهى'));
    });

    test('WorkScheduleService detects offDay on Friday correctly', () {
      // Set time to Friday
      final friday = DateTime(2026, 8, 21, 10, 0); // Friday
      final timeService = DeviceTimeService(() => friday);
      final scheduleService = WorkScheduleService(timeService);
      final schedule = WorkSchedule.defaultSchedule();

      final status = scheduleService.evaluateScheduleStatus(schedule);
      expect(status.type, equals(ShiftStatusType.offDay));
      expect(status.isOffDay, isTrue);

      final messageAr = scheduleService.getScheduleSummaryMessage(schedule, isArabic: true);
      expect(messageAr, contains('عطلة'));
    });
  });
}
