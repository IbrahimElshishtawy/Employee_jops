enum PermissionType {
  morningDelay,
  earlyLeave,
  fullDayAbsence,
  halfDay,
}

enum PermissionStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class PermissionRequest {
  final String id;
  final String employeeId;
  final PermissionType type;
  final DateTime date;
  final String durationOrTime;
  final String reason;
  final PermissionStatus status;
  final DateTime createdAt;
  final String? rejectionReason;
  final DateTime? approvedAt;

  const PermissionRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.date,
    required this.durationOrTime,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.approvedAt,
  });

  PermissionRequest copyWith({
    String? id,
    String? employeeId,
    PermissionType? type,
    DateTime? date,
    String? durationOrTime,
    String? reason,
    PermissionStatus? status,
    DateTime? createdAt,
    String? rejectionReason,
    DateTime? approvedAt,
  }) {
    return PermissionRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      date: date ?? this.date,
      durationOrTime: durationOrTime ?? this.durationOrTime,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'type': type.name,
        'date': date.toIso8601String(),
        'durationOrTime': durationOrTime,
        'reason': reason,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'rejectionReason': rejectionReason,
        'approvedAt': approvedAt?.toIso8601String(),
      };

  factory PermissionRequest.fromJson(Map<String, dynamic> json) => PermissionRequest(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        type: PermissionType.values.byName(json['type'] as String),
        date: DateTime.parse(json['date'] as String),
        durationOrTime: json['durationOrTime'] as String,
        reason: json['reason'] as String,
        status: PermissionStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        rejectionReason: json['rejectionReason'] as String?,
        approvedAt: json['approvedAt'] != null
            ? DateTime.parse(json['approvedAt'] as String)
            : null,
      );
}
