import '../../../employees/domain/entities/employee_entity.dart';

/// Supported Geofence boundary types in CyberWise IE
enum GeofenceType {
  circle('CIRCLE', 'Circle Radius'),
  polygon('POLYGON', 'Custom Polygon');

  final String key;
  final String label;

  const GeofenceType(this.key, this.label);

  static GeofenceType fromKey(String? key) {
    if (key == null) return GeofenceType.circle;
    return GeofenceType.values.firstWhere(
      (t) => t.key.toUpperCase() == key.toUpperCase(),
      orElse: () => GeofenceType.circle,
    );
  }
}

/// Geographic coordinate pair (Latitude, Longitude) with optional label
class GeoCoordinate {
  final double latitude;
  final double longitude;
  final String? label;

  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (label != null) 'label': label,
      };

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) {
    return GeoCoordinate(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinate &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 1e-7 &&
          (longitude - other.longitude).abs() < 1e-7;

  @override
  int get hashCode => Object.hash(
        (latitude * 1000000).round(),
        (longitude * 1000000).round(),
      );

  @override
  String toString() => '(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
}

/// Workplace domain entity with authoritative Circle and Polygon geofencing
class WorkplaceEntity {
  final String id;
  final String name;
  final String address;
  final GeofenceType geofenceType;
  final double latitude;
  final double longitude;
  final double allowedRadiusMeters;
  final List<GeoCoordinate> polygonPoints;
  final bool isActive;
  final int assignedEmployeesCount;
  final List<String> assignedEmployeeIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkplaceEntity({
    required this.id,
    required this.name,
    required this.address,
    this.geofenceType = GeofenceType.circle,
    required this.latitude,
    required this.longitude,
    this.allowedRadiusMeters = 100.0,
    this.polygonPoints = const [],
    required this.isActive,
    required this.assignedEmployeesCount,
    this.assignedEmployeeIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  WorkplaceEntity copyWith({
    String? id,
    String? name,
    String? address,
    GeofenceType? geofenceType,
    double? latitude,
    double? longitude,
    double? allowedRadiusMeters,
    List<GeoCoordinate>? polygonPoints,
    bool? isActive,
    int? assignedEmployeesCount,
    List<String>? assignedEmployeeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkplaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      geofenceType: geofenceType ?? this.geofenceType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      allowedRadiusMeters: allowedRadiusMeters ?? this.allowedRadiusMeters,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      isActive: isActive ?? this.isActive,
      assignedEmployeesCount: assignedEmployeesCount ?? this.assignedEmployeesCount,
      assignedEmployeeIds: assignedEmployeeIds ?? this.assignedEmployeeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Workplace query filter
class WorkplaceFilter {
  final String? searchQuery;
  final GeofenceType? geofenceType;
  final bool? isActive;
  final int page;
  final int pageSize;

  const WorkplaceFilter({
    this.searchQuery,
    this.geofenceType,
    this.isActive,
    this.page = 1,
    this.pageSize = 10,
  });
}

/// Abstract contract for Workplace Repository
abstract class WorkplacesRepository {
  Future<PaginatedList<WorkplaceEntity>> getWorkplaces(WorkplaceFilter filter);
  Future<WorkplaceEntity> getWorkplaceById(String id);
  Future<WorkplaceEntity> createWorkplace(WorkplaceEntity workplace);
  Future<WorkplaceEntity> updateWorkplace(WorkplaceEntity workplace);
  Future<void> toggleStatus(String id, bool isActive);
  Future<void> deleteWorkplace(String id);
  Future<List<EmployeeEntity>> getAssignedEmployees(String workplaceId);
  Future<void> assignEmployees(String workplaceId, List<String> employeeIds);
}
