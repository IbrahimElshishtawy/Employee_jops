enum AttendanceType {
  checkIn,
  checkOut,
}

enum AttendanceStatus {
  success,
  offlinePending,
  rejectedLocation,
  rejectedBiometric,
  error,
}

class Attendance {
  final String id;
  final String employeeId;
  final AttendanceType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double distanceFromOffice;
  final bool biometricVerified;
  final bool isOffline;
  final AttendanceStatus status;
  final String? note;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.distanceFromOffice,
    required this.biometricVerified,
    required this.isOffline,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'distanceFromOffice': distanceFromOffice,
        'biometricVerified': biometricVerified,
        'isOffline': isOffline,
        'status': status.name,
        'note': note,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        type: AttendanceType.values.byName(json['type'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanceFromOffice: (json['distanceFromOffice'] as num).toDouble(),
        biometricVerified: json['biometricVerified'] as bool,
        isOffline: json['isOffline'] as bool,
        status: AttendanceStatus.values.byName(json['status'] as String),
        note: json['note'] as String?,
      );
}

class TodayAttendanceSummary {
  final Attendance? checkIn;
  final Attendance? checkOut;

  const TodayAttendanceSummary({
    this.checkIn,
    this.checkOut,
  });

  bool get hasCheckedIn => checkIn != null;
  bool get hasCheckedOut => checkOut != null;

  TodayAttendanceSummary copyWith({
    Attendance? checkIn,
    Attendance? checkOut,
    bool clearCheckOut = false,
  }) {
    return TodayAttendanceSummary(
      checkIn: checkIn ?? this.checkIn,
      checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
    );
  }
}
