enum AdvanceStatus {
  pending,
  approved,
  rejected,
  paid,
  reportRequired,
  reportSubmitted,
}

class AdvanceRequest {
  final String id;
  final String employeeId;
  final double amount;
  final String reason;
  final String? details;
  final int installments;
  final DateTime createdAt;
  final AdvanceStatus status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? attachmentName;

  const AdvanceRequest({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.reason,
    this.details,
    this.installments = 1,
    required this.createdAt,
    required this.status,
    this.rejectionReason,
    this.approvedAt,
    this.attachmentName,
  });

  AdvanceRequest copyWith({
    String? id,
    String? employeeId,
    double? amount,
    String? reason,
    String? details,
    int? installments,
    DateTime? createdAt,
    AdvanceStatus? status,
    String? rejectionReason,
    DateTime? approvedAt,
    String? attachmentName,
  }) {
    return AdvanceRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      installments: installments ?? this.installments,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'amount': amount,
        'reason': reason,
        'details': details,
        'installments': installments,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'rejectionReason': rejectionReason,
        'approvedAt': approvedAt?.toIso8601String(),
        'attachmentName': attachmentName,
      };

  factory AdvanceRequest.fromJson(Map<String, dynamic> json) => AdvanceRequest(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'] as String,
        details: json['details'] as String?,
        installments: json['installments'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: AdvanceStatus.values.byName(json['status'] as String),
        rejectionReason: json['rejectionReason'] as String?,
        approvedAt: json['approvedAt'] != null
            ? DateTime.parse(json['approvedAt'] as String)
            : null,
        attachmentName: json['attachmentName'] as String?,
      );
}
