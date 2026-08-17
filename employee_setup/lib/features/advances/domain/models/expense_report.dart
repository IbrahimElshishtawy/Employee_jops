class ExpenseItem {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String? invoiceNumber;

  const ExpenseItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.invoiceNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'invoiceNumber': invoiceNumber,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        invoiceNumber: json['invoiceNumber'] as String?,
      );
}

class ExpenseReport {
  final String id;
  final String advanceId;
  final String employeeId;
  final double totalAmount;
  final List<ExpenseItem> items;
  final String? notes;
  final DateTime submittedAt;

  const ExpenseReport({
    required this.id,
    required this.advanceId,
    required this.employeeId,
    required this.totalAmount,
    required this.items,
    this.notes,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'advanceId': advanceId,
        'employeeId': employeeId,
        'totalAmount': totalAmount,
        'items': items.map((e) => e.toJson()).toList(),
        'notes': notes,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory ExpenseReport.fromJson(Map<String, dynamic> json) => ExpenseReport(
        id: json['id'] as String,
        advanceId: json['advanceId'] as String,
        employeeId: json['employeeId'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        items: (json['items'] as List<dynamic>)
            .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );
}
