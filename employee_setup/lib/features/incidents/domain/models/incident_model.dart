class IncidentReport {
  final String id;
  final String title;
  final String description;
  final String severity; // LOW, MEDIUM, HIGH, CRITICAL
  final String location;
  final String status; // REPORTED, INVESTIGATING, RESOLVED
  final DateTime reportedAt;
  final String? photoUrl;

  const IncidentReport({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.status,
    required this.reportedAt,
    this.photoUrl,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) => IncidentReport(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Incident',
        description: json['description'] as String? ?? '',
        severity: json['severity'] as String? ?? 'MEDIUM',
        location: json['location'] as String? ?? 'Hotel Facility',
        status: json['status'] as String? ?? 'REPORTED',
        reportedAt: json['reportedAt'] != null
            ? DateTime.tryParse(json['reportedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        photoUrl: json['photoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity,
        'location': location,
        'status': status,
        'reportedAt': reportedAt.toIso8601String(),
        'photoUrl': photoUrl,
      };
}
