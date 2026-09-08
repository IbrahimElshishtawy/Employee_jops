class AllowanceItem {
  final String name;
  final double amount;

  const AllowanceItem({required this.name, required this.amount});

  factory AllowanceItem.fromJson(Map<String, dynamic> json) => AllowanceItem(
        name: json['name'] as String? ?? json['title'] as String? ?? 'Allowance',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class SalaryStructure {
  final double basicSalary;
  final double housingAllowance;
  final double transportationAllowance;
  final double otherAllowances;
  final List<AllowanceItem> customAllowances;
  final double totalGrossSalary;
  final String currency;

  const SalaryStructure({
    required this.basicSalary,
    this.housingAllowance = 0.0,
    this.transportationAllowance = 0.0,
    this.otherAllowances = 0.0,
    this.customAllowances = const [],
    required this.totalGrossSalary,
    this.currency = 'EGP',
  });

  factory SalaryStructure.fromJson(Map<String, dynamic> json) {
    final basic = (json['basicSalary'] as num?)?.toDouble() ??
        (json['baseSalary'] as num?)?.toDouble() ??
        8500.0;
    final housing = (json['housingAllowance'] as num?)?.toDouble() ?? 2000.0;
    final trans = (json['transportationAllowance'] as num?)?.toDouble() ?? 1000.0;
    final other = (json['otherAllowances'] as num?)?.toDouble() ?? 500.0;

    List<AllowanceItem> custom = [];
    if (json['allowances'] is List) {
      custom = (json['allowances'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => AllowanceItem.fromJson(e))
          .toList();
    }

    final gross = (json['totalGrossSalary'] as num?)?.toDouble() ??
        (json['grossSalary'] as num?)?.toDouble() ??
        (basic + housing + trans + other);

    return SalaryStructure(
      basicSalary: basic,
      housingAllowance: housing,
      transportationAllowance: trans,
      otherAllowances: other,
      customAllowances: custom,
      totalGrossSalary: gross,
      currency: json['currency'] as String? ?? 'EGP',
    );
  }
}
