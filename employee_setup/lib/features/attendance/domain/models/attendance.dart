enum AttendanceType { checkIn, checkOut }

enum AttendanceStatus {
  success,
  offlinePending,
  rejectedLocation,
  rejectedBiometric,
  error,
}

enum AttendanceMethod {
  biometric,
  offlineBiometric,
}

enum AttendanceSyncStatus {
  synced,
  pending,
  failed,
}

class Attendance {
  final String id;
  final String employeeId;
  final String workLocationId;
  final DateTime date;
  final AttendanceType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distanceFromOffice;
  final bool biometricVerified;
  final bool isOffline;
  final AttendanceStatus status;
  final AttendanceMethod method;
  final AttendanceSyncStatus syncStatus;
  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkOutAccuracy;
  final double? checkOutDistance;
  final AttendanceMethod? checkOutMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  const Attendance({
    required this.id,
    required this.employeeId,
    this.workLocationId = 'LOC-CAIRO-HQ',
    DateTime? date,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy = 3.0,
    required this.distanceFromOffice,
    required this.biometricVerified,
    required this.isOffline,
    required this.status,
    this.method = AttendanceMethod.biometric,
    AttendanceSyncStatus? syncStatus,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAccuracy,
    this.checkOutDistance,
    this.checkOutMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.note,
  }) : date = date ?? timestamp,
       syncStatus = syncStatus ?? (isOffline ? AttendanceSyncStatus.pending : AttendanceSyncStatus.synced),
       createdAt = createdAt ?? timestamp,
       updatedAt = updatedAt ?? timestamp;

  DateTime get checkInAt => timestamp;
  double get checkInLatitude => latitude;
  double get checkInLongitude => longitude;
  double get checkInAccuracy => accuracy;
  double get checkInDistance => distanceFromOffice;
  AttendanceMethod get checkInMethod => method;

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? workLocationId,
    DateTime? date,
    AttendanceType? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? distanceFromOffice,
    bool? biometricVerified,
    bool? isOffline,
    AttendanceStatus? status,
    AttendanceMethod? method,
    AttendanceSyncStatus? syncStatus,
    DateTime? checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
    double? checkOutAccuracy,
    double? checkOutDistance,
    AttendanceMethod? checkOutMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      workLocationId: workLocationId ?? this.workLocationId,
      date: date ?? this.date,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      distanceFromOffice: distanceFromOffice ?? this.distanceFromOffice,
      biometricVerified: biometricVerified ?? this.biometricVerified,
      isOffline: isOffline ?? this.isOffline,
      status: status ?? this.status,
      method: method ?? this.method,
      syncStatus: syncStatus ?? this.syncStatus,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkOutAccuracy: checkOutAccuracy ?? this.checkOutAccuracy,
      checkOutDistance: checkOutDistance ?? this.checkOutDistance,
      checkOutMethod: checkOutMethod ?? this.checkOutMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'workLocationId': workLocationId,
    'date': date.toIso8601String(),
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'distanceFromOffice': distanceFromOffice,
    'biometricVerified': biometricVerified,
    'isOffline': isOffline,
    'status': status.name,
    'method': method.name,
    'syncStatus': syncStatus.name,
    'checkOutAt': checkOutAt?.toIso8601String(),
    'checkOutLatitude': checkOutLatitude,
    'checkOutLongitude': checkOutLongitude,
    'checkOutAccuracy': checkOutAccuracy,
    'checkOutDistance': checkOutDistance,
    'checkOutMethod': checkOutMethod?.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'note': note,
  };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    workLocationId: json['workLocationId'] as String? ?? 'LOC-CAIRO-HQ',
    date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
    type: AttendanceType.values.byName(json['type'] as String),
    timestamp: DateTime.parse(json['timestamp'] as String),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : 3.0,
    distanceFromOffice: (json['distanceFromOffice'] as num).toDouble(),
    biometricVerified: json['biometricVerified'] as bool,
    isOffline: json['isOffline'] as bool,
    status: AttendanceStatus.values.byName(json['status'] as String),
    method: json['method'] != null
        ? AttendanceMethod.values.byName(json['method'] as String)
        : (json['isOffline'] == true ? AttendanceMethod.offlineBiometric : AttendanceMethod.biometric),
    syncStatus: json['syncStatus'] != null
        ? AttendanceSyncStatus.values.byName(json['syncStatus'] as String)
        : null,
    checkOutAt: json['checkOutAt'] != null ? DateTime.parse(json['checkOutAt'] as String) : null,
    checkOutLatitude: json['checkOutLatitude'] != null ? (json['checkOutLatitude'] as num).toDouble() : null,
    checkOutLongitude: json['checkOutLongitude'] != null ? (json['checkOutLongitude'] as num).toDouble() : null,
    checkOutAccuracy: json['checkOutAccuracy'] != null ? (json['checkOutAccuracy'] as num).toDouble() : null,
    checkOutDistance: json['checkOutDistance'] != null ? (json['checkOutDistance'] as num).toDouble() : null,
    checkOutMethod: json['checkOutMethod'] != null ? AttendanceMethod.values.byName(json['checkOutMethod'] as String) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    note: json['note'] as String?,
  );
}

class TodayAttendanceSummary {
  final Attendance? checkIn;
  final Attendance? checkOut;

  const TodayAttendanceSummary({this.checkIn, this.checkOut});

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
