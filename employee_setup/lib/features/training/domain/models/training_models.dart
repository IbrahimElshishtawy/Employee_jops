class TrainingCourse {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final int durationHours;
  final String category;
  final String status;

  const TrainingCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.durationHours,
    required this.category,
    this.status = 'AVAILABLE',
  });

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    return TrainingCourse(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructor: json['instructor'] as String? ?? '',
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'GENERAL',
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }
}

class TrainingCertificate {
  final String id;
  final String courseTitle;
  final String issueDate;
  final String expiryDate;
  final String certificateNumber;
  final String? downloadUrl;

  const TrainingCertificate({
    required this.id,
    required this.courseTitle,
    required this.issueDate,
    required this.expiryDate,
    required this.certificateNumber,
    this.downloadUrl,
  });

  factory TrainingCertificate.fromJson(Map<String, dynamic> json) {
    return TrainingCertificate(
      id: json['id'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      issueDate: json['issueDate'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      certificateNumber: json['certificateNumber'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String?,
    );
  }
}
