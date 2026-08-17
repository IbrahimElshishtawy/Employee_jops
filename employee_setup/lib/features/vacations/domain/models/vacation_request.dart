enum VacationType {
  annual,
  sick,
  casual,
  unpaid,
}

enum VacationStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class VacationRequest {
  final String id;
  final String employeeId;
  final VacationType type;
  final DateTime fromDate;
  final DateTime toDate;
  final int daysCount;
  final String reason;
  final VacationStatus status;
  final DateTime createdAt;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? attachmentName;

  const VacationRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.daysCount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.approvedAt,
    this.attachmentName,
  });

  VacationRequest copyWith({
    String? id,
    String? employeeId,
    VacationType? type,
    DateTime? fromDate,
    DateTime? toDate,
    int? daysCount,
    String? reason,
    VacationStatus? status,
    DateTime? createdAt,
    String? rejectionReason,
    DateTime? approvedAt,
    String? attachmentName,
  }) {
    return VacationRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      daysCount: daysCount ?? this.daysCount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'type': type.name,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'daysCount': daysCount,
        'reason': reason,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'rejectionReason': rejectionReason,
        'approvedAt': approvedAt?.toIso8601String(),
        'attachmentName': attachmentName,
      };

  factory VacationRequest.fromJson(Map<String, dynamic> json) => VacationRequest(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        type: VacationType.values.byName(json['type'] as String),
        fromDate: DateTime.parse(json['fromDate'] as String),
        toDate: DateTime.parse(json['toDate'] as String),
        daysCount: json['daysCount'] as int,
        reason: json['reason'] as String,
        status: VacationStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        rejectionReason: json['rejectionReason'] as String?,
        approvedAt: json['approvedAt'] != null
            ? DateTime.parse(json['approvedAt'] as String)
            : null,
        attachmentName: json['attachmentName'] as String?,
      );
}
