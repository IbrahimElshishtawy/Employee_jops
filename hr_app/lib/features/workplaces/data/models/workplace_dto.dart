import '../../domain/entities/workplace_entity.dart';

/// DTO for Backend Workplace API responses and requests
class WorkplaceDto {
  final String id;
  final String name;
  final String address;
  final String geofenceType;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<Map<String, dynamic>> polygonCoordinates;
  final bool isActive;
  final int assignedEmployeesCount;
  final List<String> assignedEmployeeIds;
  final String createdAt;
  final String? updatedAt;

  const WorkplaceDto({
    required this.id,
    required this.name,
    required this.address,
    required this.geofenceType,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.polygonCoordinates,
    required this.isActive,
    required this.assignedEmployeesCount,
    required this.assignedEmployeeIds,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkplaceDto.fromJson(Map<String, dynamic> json) {
    final rawCoords = (json['polygonCoordinates'] as List<dynamic>?) ??
        (json['polygonPoints'] as List<dynamic>?) ??
        [];

    final rawEmpIds = (json['assignedEmployeeIds'] as List<dynamic>?) ?? [];

    return WorkplaceDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      geofenceType: json['geofenceType'] as String? ?? 'CIRCLE',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ??
          (json['allowedRadiusMeters'] as num?)?.toDouble() ??
          100.0,
      polygonCoordinates: rawCoords.map((c) {
        if (c is Map<String, dynamic>) {
          return c;
        } else if (c is Map) {
          return Map<String, dynamic>.from(c);
        }
        return <String, dynamic>{};
      }).toList(),
      isActive: json['isActive'] as bool? ?? true,
      assignedEmployeesCount: json['assignedEmployeesCount'] as int? ?? rawEmpIds.length,
      assignedEmployeeIds: rawEmpIds.map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'geofenceType': geofenceType,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'polygonCoordinates': polygonCoordinates,
        'isActive': isActive,
        'assignedEmployeesCount': assignedEmployeesCount,
        'assignedEmployeeIds': assignedEmployeeIds,
        'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  WorkplaceEntity toDomain() {
    final points = polygonCoordinates.map((c) {
      return GeoCoordinate(
        latitude: (c['latitude'] as num?)?.toDouble() ?? (c['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (c['longitude'] as num?)?.toDouble() ?? (c['lng'] as num?)?.toDouble() ?? 0.0,
        label: c['label'] as String?,
      );
    }).toList();

    return WorkplaceEntity(
      id: id,
      name: name,
      address: address,
      geofenceType: GeofenceType.fromKey(geofenceType),
      latitude: latitude,
      longitude: longitude,
      allowedRadiusMeters: radiusMeters,
      polygonPoints: points,
      isActive: isActive,
      assignedEmployeesCount: assignedEmployeesCount,
      assignedEmployeeIds: assignedEmployeeIds,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
    );
  }

  factory WorkplaceDto.fromDomain(WorkplaceEntity entity) {
    return WorkplaceDto(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      geofenceType: entity.geofenceType.key,
      latitude: entity.latitude,
      longitude: entity.longitude,
      radiusMeters: entity.allowedRadiusMeters,
      polygonCoordinates: entity.polygonPoints.map((p) => p.toJson()).toList(),
      isActive: entity.isActive,
      assignedEmployeesCount: entity.assignedEmployeesCount,
      assignedEmployeeIds: entity.assignedEmployeeIds,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt?.toIso8601String(),
    );
  }
}
