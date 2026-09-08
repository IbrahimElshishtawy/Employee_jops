class HandoverItem {
  final String id;
  final String description;
  final String status; // PENDING, RESOLVED
  final String priority; // NORMAL, URGENT

  const HandoverItem({
    required this.id,
    required this.description,
    this.status = 'PENDING',
    this.priority = 'NORMAL',
  });

  factory HandoverItem.fromJson(Map<String, dynamic> json) => HandoverItem(
        id: json['id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        priority: json['priority'] as String? ?? 'NORMAL',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status,
        'priority': priority,
      };
}

class HandoverReport {
  final String id;
  final String outgoingEmployeeName;
  final String incomingEmployeeName;
  final String department;
  final String shiftName;
  final DateTime handoverTime;
  final String notes;
  final bool isAcknowledged;
  final List<HandoverItem> pendingItems;

  const HandoverReport({
    required this.id,
    required this.outgoingEmployeeName,
    required this.incomingEmployeeName,
    required this.department,
    required this.shiftName,
    required this.handoverTime,
    required this.notes,
    this.isAcknowledged = false,
    this.pendingItems = const [],
  });

  factory HandoverReport.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => HandoverItem.fromJson(e))
            .toList() ??
        [];

    return HandoverReport(
      id: json['id'] as String? ?? '',
      outgoingEmployeeName: json['outgoingEmployeeName'] as String? ?? 'Outgoing Shift',
      incomingEmployeeName: json['incomingEmployeeName'] as String? ?? 'Incoming Shift',
      department: json['department'] as String? ?? 'Operations',
      shiftName: json['shiftName'] as String? ?? 'Morning Shift',
      handoverTime: json['handoverTime'] != null
          ? DateTime.tryParse(json['handoverTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      pendingItems: items,
    );
  }
}
