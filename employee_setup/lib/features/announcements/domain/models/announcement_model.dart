class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String category; // GENERAL, POLICY, URGENT, EVENT
  final DateTime publishedAt;
  final bool isRead;
  final bool requiresAcknowledgment;
  final bool isAcknowledged;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.publishedAt,
    this.isRead = false,
    this.requiresAcknowledgment = false,
    this.isAcknowledged = false,
  });

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    DateTime? publishedAt,
    bool? isRead,
    bool? requiresAcknowledgment,
    bool? isAcknowledged,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
      isRead: isRead ?? this.isRead,
      requiresAcknowledgment: requiresAcknowledgment ?? this.requiresAcknowledgment,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) => AnnouncementModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Announcement',
        content: json['content'] as String? ?? '',
        category: json['category'] as String? ?? 'GENERAL',
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        requiresAcknowledgment: json['requiresAcknowledgment'] as bool? ?? false,
        isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'publishedAt': publishedAt.toIso8601String(),
        'isRead': isRead,
        'requiresAcknowledgment': requiresAcknowledgment,
        'isAcknowledged': isAcknowledged,
      };
}
