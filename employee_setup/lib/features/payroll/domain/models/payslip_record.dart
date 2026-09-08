class PayslipItem {
  final String label;
  final double amount;
  final bool isDeduction;

  const PayslipItem({
    required this.label,
    required this.amount,
    this.isDeduction = false,
  });

  factory PayslipItem.fromJson(Map<String, dynamic> json) => PayslipItem(
        label: json['label'] as String? ?? json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        isDeduction: json['isDeduction'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'isDeduction': isDeduction,
      };
}

class PayslipRecord {
  final String id;
  final String month; // YYYY-MM
  final double basicSalary;
  final double totalAllowances;
  final double totalDeductions;
  final double netSalary;
  final String paymentStatus; // PAID, PROCESSING, PENDING
  final DateTime? paymentDate;
  final List<PayslipItem> earnings;
  final List<PayslipItem> deductions;
  final String currency;

  const PayslipRecord({
    required this.id,
    required this.month,
    required this.basicSalary,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.netSalary,
    required this.paymentStatus,
    this.paymentDate,
    this.earnings = const [],
    this.deductions = const [],
    this.currency = 'EGP',
  });

  factory PayslipRecord.fromJson(Map<String, dynamic> json) {
    final earningsList = (json['earnings'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => PayslipItem.fromJson(e))
            .toList() ??
        [];

    final deductionsList = (json['deductions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => PayslipItem.fromJson(e))
            .toList() ??
        [];

    return PayslipRecord(
      id: json['id'] as String? ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      month: json['month'] as String? ?? '2026-08',
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 8500.0,
      totalAllowances: (json['totalAllowances'] as num?)?.toDouble() ?? 3500.0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 500.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 11500.0,
      paymentStatus: json['paymentStatus'] as String? ?? json['status'] as String? ?? 'PAID',
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'] as String)
          : null,
      earnings: earningsList,
      deductions: deductionsList,
      currency: json['currency'] as String? ?? 'EGP',
    );
  }
}
