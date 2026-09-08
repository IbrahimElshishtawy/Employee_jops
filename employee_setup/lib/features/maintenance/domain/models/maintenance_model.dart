class MaintenanceOrder {
  final String id;
  final String title;
  final String description;
  final String roomOrFacility;
  final String category; // PLUMBING, ELECTRICAL, HVAC, CARPENTRY
  final String status; // SUBMITTED, ASSIGNED, IN_PROGRESS, COMPLETED
  final DateTime createdAt;

  const MaintenanceOrder({
    required this.id,
    required this.title,
    required this.description,
    required this.roomOrFacility,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  factory MaintenanceOrder.fromJson(Map<String, dynamic> json) => MaintenanceOrder(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Maintenance Order',
        description: json['description'] as String? ?? '',
        roomOrFacility: json['roomOrFacility'] as String? ?? json['room'] as String? ?? 'General Facility',
        category: json['category'] as String? ?? 'GENERAL',
        status: json['status'] as String? ?? 'SUBMITTED',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'roomOrFacility': roomOrFacility,
        'category': category,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
