enum TaskStatus {
  todo,
  accepted,
  inProgress,
  blocked,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class TaskChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;

  const TaskChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  TaskChecklistItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TaskChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory TaskChecklistItem.fromJson(Map<String, dynamic> json) => TaskChecklistItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? json['text'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? json['completed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };
}

class TaskComment {
  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const TaskComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
        id: json['id'] as String? ?? '',
        authorName: json['authorName'] as String? ??
            json['author']?['name'] as String? ??
            'Colleague',
        content: json['content'] as String? ?? json['text'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

class TaskAttachment {
  final String id;
  final String filename;
  final String url;
  final int? sizeBytes;

  const TaskAttachment({
    required this.id,
    required this.filename,
    required this.url,
    this.sizeBytes,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
        id: json['id'] as String? ?? '',
        filename: json['filename'] as String? ?? json['name'] as String? ?? 'attachment',
        url: json['url'] as String? ?? json['path'] as String? ?? '',
        sizeBytes: json['sizeBytes'] as int? ?? json['size'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'url': url,
        'sizeBytes': sizeBytes,
      };
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime dueDate;
  final double progressPercent; // 0.0 to 100.0
  final List<TaskChecklistItem> checklist;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;
  final String? assignedTo;
  final String? department;

  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.progressPercent = 0.0,
    this.checklist = const [],
    this.comments = const [],
    this.attachments = const [],
    this.assignedTo,
    this.department,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    double? progressPercent,
    List<TaskChecklistItem>? checklist,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
    String? assignedTo,
    String? department,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      progressPercent: progressPercent ?? this.progressPercent,
      checklist: checklist ?? this.checklist,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      assignedTo: assignedTo ?? this.assignedTo,
      department: department ?? this.department,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    TaskStatus status = TaskStatus.todo;
    if (json['status'] is String) {
      final s = (json['status'] as String).toUpperCase();
      switch (s) {
        case 'ACCEPTED':
          status = TaskStatus.accepted;
          break;
        case 'IN_PROGRESS':
          status = TaskStatus.inProgress;
          break;
        case 'BLOCKED':
          status = TaskStatus.blocked;
          break;
        case 'COMPLETED':
          status = TaskStatus.completed;
          break;
        case 'CANCELLED':
          status = TaskStatus.cancelled;
          break;
        default:
          status = TaskStatus.todo;
      }
    }

    TaskPriority priority = TaskPriority.medium;
    if (json['priority'] is String) {
      final p = (json['priority'] as String).toUpperCase();
      switch (p) {
        case 'LOW':
          priority = TaskPriority.low;
          break;
        case 'HIGH':
          priority = TaskPriority.high;
          break;
        case 'URGENT':
          priority = TaskPriority.urgent;
          break;
        default:
          priority = TaskPriority.medium;
      }
    }

    final checklistItems = (json['checklist'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => TaskChecklistItem.fromJson(e))
            .toList() ??
        [];

    final commentsList = (json['comments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => TaskComment.fromJson(e))
            .toList() ??
        [];

    final attachmentsList = (json['attachments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => TaskAttachment.fromJson(e))
            .toList() ??
        [];

    double progress = (json['progress'] as num?)?.toDouble() ??
        (json['progressPercent'] as num?)?.toDouble() ??
        0.0;
    if (checklistItems.isNotEmpty && progress == 0.0) {
      final done = checklistItems.where((c) => c.isCompleted).length;
      progress = (done / checklistItems.length) * 100.0;
    }

    return TaskItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Task',
      description: json['description'] as String? ?? '',
      status: status,
      priority: priority,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      progressPercent: progress,
      checklist: checklistItems,
      comments: commentsList,
      attachments: attachmentsList,
      assignedTo: json['assignedTo'] as String?,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name.toUpperCase(),
        'priority': priority.name.toUpperCase(),
        'dueDate': dueDate.toIso8601String(),
        'progress': progressPercent,
        'checklist': checklist.map((e) => e.toJson()).toList(),
        'comments': comments.map((e) => e.toJson()).toList(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
      };
}
