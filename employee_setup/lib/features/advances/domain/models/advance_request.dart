enum AdvanceStatus {
  pending,
  approved,
  rejected,
  paid,
  reportRequired,
  reportSubmitted,
}

class AdvanceInstallmentItem {
  final String? month;
  final double amount;
  final String status;

  const AdvanceInstallmentItem({
    this.month,
    required this.amount,
    this.status = 'PENDING',
  });

  factory AdvanceInstallmentItem.fromJson(Map<String, dynamic> json) =>
      AdvanceInstallmentItem(
        month: json['month'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'PENDING',
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'amount': amount,
        'status': status,
      };
}

class AdvanceRequest {
  final String id;
  final String employeeId;
  final double amount;
  final String reason;
  final String? details;
  final int installments;
  final List<AdvanceInstallmentItem> installmentItems;
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
    this.installmentItems = const [],
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
    List<AdvanceInstallmentItem>? installmentItems,
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
      installmentItems: installmentItems ?? this.installmentItems,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  /// Exact contract payload for NestJS Fastify RequestAdvanceDto
  Map<String, dynamic> toBackendDto() => {
        'amount': amount,
        'requestedInstallments': installments,
        'reason': reason,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'amount': amount,
        'reason': reason,
        'details': details,
        'installments': installments,
        'requestedInstallments': installments,
        'installmentItems': installmentItems.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'rejectionReason': rejectionReason,
        'approvedAt': approvedAt?.toIso8601String(),
        'attachmentName': attachmentName,
      };

  factory AdvanceRequest.fromJson(Map<String, dynamic> json) {
    int count = 1;
    List<AdvanceInstallmentItem> items = [];

    if (json['installments'] is int) {
      count = json['installments'] as int;
    } else if (json['requestedInstallments'] is int) {
      count = json['requestedInstallments'] as int;
    } else if (json['installmentsCount'] is int) {
      count = json['installmentsCount'] as int;
    }

    if (json['installments'] is List) {
      final list = json['installments'] as List;
      items = list
          .whereType<Map<String, dynamic>>()
          .map((e) => AdvanceInstallmentItem.fromJson(e))
          .toList();
      if (items.isNotEmpty && count == 1) {
        count = items.length;
      }
    } else if (json['installmentItems'] is List) {
      final list = json['installmentItems'] as List;
      items = list
          .whereType<Map<String, dynamic>>()
          .map((e) => AdvanceInstallmentItem.fromJson(e))
          .toList();
    }

    AdvanceStatus statusValue = AdvanceStatus.pending;
    if (json['status'] is String) {
      final s = (json['status'] as String).toLowerCase();
      for (final val in AdvanceStatus.values) {
        if (val.name.toLowerCase() == s) {
          statusValue = val;
          break;
        }
      }
    }

    return AdvanceRequest(
      id: json['id'] as String? ?? 'ADV-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: json['employeeId'] as String? ?? 'EMP-001',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String?,
      installments: count,
      installmentItems: items,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: statusValue,
      rejectionReason: json['rejectionReason'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : null,
      attachmentName: json['attachmentName'] as String?,
    );
  }
}
