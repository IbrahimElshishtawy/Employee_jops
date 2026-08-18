import 'package:flutter/material.dart';

enum ShiftStatusType {
  offDay,
  beforeShift,
  withinShift,
  afterShift,
}

class WorkScheduleShiftStatus {
  final ShiftStatusType type;
  final String messageKey;
  final Duration? timeDifference;
  final DateTime shiftStart;
  final DateTime shiftEnd;

  const WorkScheduleShiftStatus({
    required this.type,
    required this.messageKey,
    this.timeDifference,
    required this.shiftStart,
    required this.shiftEnd,
  });

  bool get isBeforeShift => type == ShiftStatusType.beforeShift;
  bool get isWithinShift => type == ShiftStatusType.withinShift;
  bool get isAfterShift => type == ShiftStatusType.afterShift;
  bool get isOffDay => type == ShiftStatusType.offDay;
}

class WorkSchedule {
  final String id;
  final String employeeId;
  /// Working days represented as integers (1 = Monday, 7 = Sunday)
  final List<int> workingDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int gracePeriodMinutes;

  const WorkSchedule({
    required this.id,
    required this.employeeId,
    required this.workingDays,
    required this.startTime,
    required this.endTime,
    this.gracePeriodMinutes = 15,
  });

  String get formattedStartTime {
    final h = startTime.hourOfPeriod == 0 ? 12 : startTime.hourOfPeriod;
    final m = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get formattedEndTime {
    final h = endTime.hourOfPeriod == 0 ? 12 : endTime.hourOfPeriod;
    final m = endTime.minute.toString().padLeft(2, '0');
    final period = endTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  bool isWorkDay(DateTime date) {
    return workingDays.contains(date.weekday);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'workingDays': workingDays,
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime.hour,
    'endMinute': endTime.minute,
    'gracePeriodMinutes': gracePeriodMinutes,
  };

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    workingDays: (json['workingDays'] as List<dynamic>).map((e) => e as int).toList(),
    startTime: TimeOfDay(
      hour: json['startHour'] as int,
      minute: json['startMinute'] as int,
    ),
    endTime: TimeOfDay(
      hour: json['endHour'] as int,
      minute: json['endMinute'] as int,
    ),
    gracePeriodMinutes: json['gracePeriodMinutes'] as int? ?? 15,
  );

  static WorkSchedule defaultSchedule({String employeeId = 'EMP-1024'}) => WorkSchedule(
    id: 'SCH-DEFAULT',
    employeeId: employeeId,
    workingDays: const [
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
    ],
    startTime: const TimeOfDay(hour: 9, minute: 0),
    endTime: const TimeOfDay(hour: 17, minute: 0),
    gracePeriodMinutes: 15,
  );
}
