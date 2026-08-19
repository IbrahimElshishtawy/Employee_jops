import '../../../../core/services/time_service.dart';
import '../models/work_schedule.dart';

class WorkScheduleService {
  final TimeService _timeService;

  WorkScheduleService([TimeService? timeService])
      : _timeService = timeService ?? DeviceTimeService();

  /// Evaluates the current status of the employee's work schedule.
  WorkScheduleShiftStatus evaluateScheduleStatus(WorkSchedule schedule) {
    final now = _timeService.now();
    final today = _timeService.today();

    final shiftStart = DateTime(
      today.year,
      today.month,
      today.day,
      schedule.startTime.hour,
      schedule.startTime.minute,
    );

    final shiftEnd = DateTime(
      today.year,
      today.month,
      today.day,
      schedule.endTime.hour,
      schedule.endTime.minute,
    );

    if (!schedule.isWorkDay(today)) {
      return WorkScheduleShiftStatus(
        type: ShiftStatusType.offDay,
        messageKey: 'attendance.schedule_off_day',
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      );
    }

    if (now.isBefore(shiftStart)) {
      final diff = shiftStart.difference(now);
      return WorkScheduleShiftStatus(
        type: ShiftStatusType.beforeShift,
        messageKey: 'attendance.schedule_before_shift',
        timeDifference: diff,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      );
    }

    if (now.isAfter(shiftEnd)) {
      final diff = now.difference(shiftEnd);
      return WorkScheduleShiftStatus(
        type: ShiftStatusType.afterShift,
        messageKey: 'attendance.schedule_after_shift',
        timeDifference: diff,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      );
    }

    // Inside shift window
    return WorkScheduleShiftStatus(
      type: ShiftStatusType.withinShift,
      messageKey: 'attendance.schedule_within_shift',
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
    );
  }

  /// Calculates human-readable status text (e.g. "Your shift starts in 15 minutes", etc.)
  String getScheduleSummaryMessage(WorkSchedule schedule, {required bool isArabic}) {
    final status = evaluateScheduleStatus(schedule);
    switch (status.type) {
      case ShiftStatusType.offDay:
        return isArabic ? 'اليوم عطلة أسبوعية' : 'Today is your scheduled off day.';
      case ShiftStatusType.beforeShift:
        final minutes = status.timeDifference?.inMinutes ?? 0;
        if (minutes <= 60) {
          return isArabic
              ? 'يبدأ دوامك خلال $minutes دقيقة'
              : 'Your shift starts in $minutes minutes.';
        } else {
          final hours = status.timeDifference?.inHours ?? 0;
          return isArabic
              ? 'يبدأ دوامك خلال $hours ساعة'
              : 'Your shift starts in $hours hours.';
        }
      case ShiftStatusType.withinShift:
        return isArabic
            ? 'أنت في فترة الدوام الرسمي الآن'
            : 'You are currently in working hours.';
      case ShiftStatusType.afterShift:
        return isArabic
            ? 'انتهى وقت دوام اليوم'
            : 'Your workday has ended.';
    }
  }

  /// Returns true if attempting to checkout before the scheduled shift ends.
  bool isEarlyCheckout(WorkSchedule schedule, {DateTime? checkTime}) {
    final now = checkTime ?? _timeService.now();
    final today = _timeService.today();
    final shiftEnd = DateTime(
      today.year,
      today.month,
      today.day,
      schedule.endTime.hour,
      schedule.endTime.minute,
    );
    return now.isBefore(shiftEnd.subtract(const Duration(minutes: 5)));
  }
}
