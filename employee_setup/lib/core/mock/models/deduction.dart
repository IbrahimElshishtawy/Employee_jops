// ============================================================
// Deduction Model
// ============================================================

enum DeductionStatus {
  applied,
  pending,
  cancelled,
  appealed,
}

enum DeductionReason {
  lateArrival,
  absenceWithoutPermission,
  earlyDeparture,
  policyViolation,
  other,
}

class Deduction {
  final String id;
  final String employeeId;
  final double amount;
  final String reason;
  final DeductionReason reasonType;
  final DateTime date;
  final DeductionStatus status;
  final String? note;
  final String? appealReason;

  const Deduction({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.reason,
    required this.reasonType,
    required this.date,
    required this.status,
    this.note,
    this.appealReason,
  });

  Deduction copyWith({
    String? id,
    String? employeeId,
    double? amount,
    String? reason,
    DeductionReason? reasonType,
    DateTime? date,
    DeductionStatus? status,
    String? note,
    String? appealReason,
  }) {
    return Deduction(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      reasonType: reasonType ?? this.reasonType,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
      appealReason: appealReason ?? this.appealReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'amount': amount,
        'reason': reason,
        'reasonType': reasonType.name,
        'date': date.toIso8601String(),
        'status': status.name,
        'note': note,
        'appealReason': appealReason,
      };

  factory Deduction.fromJson(Map<String, dynamic> json) => Deduction(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'] as String,
        reasonType: DeductionReason.values.byName(json['reasonType'] as String),
        date: DateTime.parse(json['date'] as String),
        status: DeductionStatus.values.byName(json['status'] as String),
        note: json['note'] as String?,
        appealReason: json['appealReason'] as String?,
      );
}
