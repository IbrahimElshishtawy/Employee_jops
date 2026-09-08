class PerformanceGoal {
  final String id;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime dueDate;
  final String status;

  const PerformanceGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.dueDate,
    required this.status,
  });

  double get progressRatio =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  factory PerformanceGoal.fromJson(Map<String, dynamic> json) {
    return PerformanceGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 100.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '%',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}

class PerformanceReview {
  final String id;
  final String period;
  final double rating;
  final String reviewerName;
  final String feedback;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final DateTime createdAt;

  const PerformanceReview({
    required this.id,
    required this.period,
    required this.rating,
    required this.reviewerName,
    required this.feedback,
    required this.isAcknowledged,
    this.acknowledgedAt,
    required this.createdAt,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    return PerformanceReview(
      id: json['id'] as String? ?? '',
      period: json['period'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewerName: json['reviewerName'] as String? ?? 'HR Supervisor',
      feedback: json['feedback'] as String? ?? '',
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.tryParse(json['acknowledgedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
