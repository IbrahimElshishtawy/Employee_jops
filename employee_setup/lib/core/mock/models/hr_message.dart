// ============================================================
// HRMessage Model
// ============================================================

enum HRMessageStatus {
  unread,
  read,
  archived,
}

enum HRMessagePriority {
  low,
  normal,
  high,
  urgent,
}

class HRMessage {
  final String id;
  final String employeeId;
  final String title;
  final String message;
  final String senderName;
  final DateTime createdAt;
  final HRMessageStatus status;
  final HRMessagePriority priority;
  final String? actionRoute;

  const HRMessage({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.message,
    required this.senderName,
    required this.createdAt,
    required this.status,
    this.priority = HRMessagePriority.normal,
    this.actionRoute,
  });

  bool get isRead => status != HRMessageStatus.unread;

  HRMessage copyWith({
    String? id,
    String? employeeId,
    String? title,
    String? message,
    String? senderName,
    DateTime? createdAt,
    HRMessageStatus? status,
    HRMessagePriority? priority,
    String? actionRoute,
  }) {
    return HRMessage(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      title: title ?? this.title,
      message: message ?? this.message,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'title': title,
        'message': message,
        'senderName': senderName,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'priority': priority.name,
        'actionRoute': actionRoute,
      };

  factory HRMessage.fromJson(Map<String, dynamic> json) => HRMessage(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        senderName: json['senderName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: HRMessageStatus.values.byName(json['status'] as String),
        priority: HRMessagePriority.values.byName(
            json['priority'] as String? ?? HRMessagePriority.normal.name),
        actionRoute: json['actionRoute'] as String?,
      );
}
