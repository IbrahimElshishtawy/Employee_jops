/// Leave balances entity matching GET /api/v1/requests/leave-balances/me.
class LeaveBalances {
  final int annual;
  final int sick;
  final int emergency;
  final int unpaid;
  final int usedAnnual;
  final int remainingAnnual;

  const LeaveBalances({
    this.annual = 21,
    this.sick = 14,
    this.emergency = 6,
    this.unpaid = 0,
    this.usedAnnual = 0,
    this.remainingAnnual = 21,
  });

  factory LeaveBalances.fromJson(Map<String, dynamic> json) {
    return LeaveBalances(
      annual: json['annual'] as int? ?? json['totalAnnual'] as int? ?? 21,
      sick: json['sick'] as int? ?? 14,
      emergency: json['emergency'] as int? ?? json['casual'] as int? ?? 6,
      unpaid: json['unpaid'] as int? ?? 0,
      usedAnnual: json['usedAnnual'] as int? ?? 0,
      remainingAnnual:
          json['remainingAnnual'] as int? ?? json['remaining'] as int? ?? 21,
    );
  }

  Map<String, dynamic> toJson() => {
        'annual': annual,
        'sick': sick,
        'emergency': emergency,
        'unpaid': unpaid,
        'usedAnnual': usedAnnual,
        'remainingAnnual': remainingAnnual,
      };
}
