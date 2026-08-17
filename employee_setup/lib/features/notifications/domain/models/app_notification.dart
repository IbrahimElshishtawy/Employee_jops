enum NotificationCategory {
  hrMessage,
  requestUpdate,
  deduction,
  attendance,
  advance,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedEntityId;
  final String? actionRoute;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.relatedEntityId,
    this.actionRoute,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    String? relatedEntityId,
    String? actionRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'relatedEntityId': relatedEntityId,
        'actionRoute': actionRoute,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        category: NotificationCategory.values.byName(json['category'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        relatedEntityId: json['relatedEntityId'] as String?,
        actionRoute: json['actionRoute'] as String?,
      );
}
