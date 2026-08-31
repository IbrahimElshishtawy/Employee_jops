import '../../domain/entities/employee_location.dart';

/// Data model for EmployeeLocation with JSON serialization
class EmployeeLocationModel extends EmployeeLocation {
  const EmployeeLocationModel({
    required super.latitude,
    required super.longitude,
    required super.accuracy,
    required super.timestamp,
    super.source = LocationSource.foreground,
    super.workSessionId,
    super.employeeId,
    super.altitude,
    super.speed,
    super.heading,
    super.isMock = false,
  });

  factory EmployeeLocationModel.fromEntity(EmployeeLocation entity) {
    return EmployeeLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      timestamp: entity.timestamp,
      source: entity.source,
      workSessionId: entity.workSessionId,
      employeeId: entity.employeeId,
      altitude: entity.altitude,
      speed: entity.speed,
      heading: entity.heading,
      isMock: entity.isMock,
    );
  }

  factory EmployeeLocationModel.fromJson(Map<String, dynamic> json) {
    return EmployeeLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      source: LocationSource.values.firstWhere(
        (s) => s.name.toUpperCase() == (json['source'] as String? ?? '').toUpperCase(),
        orElse: () => LocationSource.foreground,
      ),
      workSessionId: json['workSessionId'] as String?,
      employeeId: json['employeeId'] as String?,
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      isMock: json['isMock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'source': source.sourceName,
        'workSessionId': workSessionId,
        'employeeId': employeeId,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'isMock': isMock,
      };
}
