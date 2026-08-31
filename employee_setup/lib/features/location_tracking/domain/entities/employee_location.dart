import 'package:flutter/foundation.dart';

/// Source of the location update
enum LocationSource {
  foreground,
  background,
  fused,
  gps,
  mock;

  String get sourceName => name.toUpperCase();
}

/// Domain entity representing an employee's location update during an active work session
@immutable
class EmployeeLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final LocationSource source;
  final String? workSessionId;
  final String? employeeId;
  final double? altitude;
  final double? speed;
  final double? heading;
  final bool isMock;

  const EmployeeLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.source = LocationSource.foreground,
    this.workSessionId,
    this.employeeId,
    this.altitude,
    this.speed,
    this.heading,
    this.isMock = false,
  });

  EmployeeLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    LocationSource? source,
    String? workSessionId,
    String? employeeId,
    double? altitude,
    double? speed,
    double? heading,
    bool? isMock,
  }) {
    return EmployeeLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      workSessionId: workSessionId ?? this.workSessionId,
      employeeId: employeeId ?? this.employeeId,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isMock: isMock ?? this.isMock,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy &&
          timestamp == other.timestamp &&
          source == other.source &&
          workSessionId == other.workSessionId;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      accuracy.hashCode ^
      timestamp.hashCode ^
      source.hashCode ^
      workSessionId.hashCode;

  @override
  String toString() =>
      'EmployeeLocation(lat: $latitude, lng: $longitude, acc: ${accuracy}m, time: $timestamp, src: ${source.name}, session: $workSessionId)';
}
