import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/entities/employee_location.dart';
import '../../domain/entities/tracking_enums.dart';

abstract class LocationPlatformDataSource {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermissionState> checkPermission();
  Future<LocationPermissionState> requestPermission({bool requestBackground = true});
  Future<EmployeeLocation?> getCurrentPosition();
  Stream<EmployeeLocation> getPositionStream({
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  });
}

class GeolocatorLocationPlatformDataSource implements LocationPlatformDataSource {
  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      SecureLogger.error('LocationPlatformDataSource', 'isLocationServiceEnabled failed', e);
      return false;
    }
  }

  @override
  Future<LocationPermissionState> checkPermission() async {
    try {
      final enabled = await isLocationServiceEnabled();
      if (!enabled) {
        return LocationPermissionState.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      return _mapGeolocatorPermission(permission);
    } catch (e) {
      SecureLogger.error('LocationPlatformDataSource', 'checkPermission failed', e);
      return LocationPermissionState.notDetermined;
    }
  }

  @override
  Future<LocationPermissionState> requestPermission({bool requestBackground = true}) async {
    try {
      final enabled = await isLocationServiceEnabled();
      if (!enabled) {
        return LocationPermissionState.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return _mapGeolocatorPermission(permission);
    } catch (e) {
      SecureLogger.error('LocationPlatformDataSource', 'requestPermission failed', e);
      return LocationPermissionState.denied;
    }
  }

  @override
  Future<EmployeeLocation?> getCurrentPosition() async {
    try {
      final enabled = await isLocationServiceEnabled();
      if (!enabled) return null;

      final permissionState = await checkPermission();
      if (!permissionState.hasForegroundAccess) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return EmployeeLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        source: LocationSource.gps,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        isMock: position.isMocked,
      );
    } catch (e) {
      SecureLogger.error('LocationPlatformDataSource', 'getCurrentPosition failed', e);
      return null;
    }
  }

  @override
  Stream<EmployeeLocation> getPositionStream({
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  }) {
    LocationSettings settings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        intervalDuration: Duration(seconds: intervalSeconds),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'CyberWise — تتبع الموقع أثناء الدوام',
          notificationText: 'جاري تسجيل الموقع لحساب ساعات العمل بدقة',
          enableWakeLock: false,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      );
    }

    try {
      return Geolocator.getPositionStream(locationSettings: settings).map(
        (position) => EmployeeLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
          source: LocationSource.foreground,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          isMock: position.isMocked,
        ),
      ).handleError((e) {
        SecureLogger.info('LocationPlatformDataSource', 'getPositionStream error: $e');
      });
    } catch (e) {
      SecureLogger.info('LocationPlatformDataSource', 'getPositionStream headless fallback');
      return const Stream.empty();
    }
  }

  LocationPermissionState _mapGeolocatorPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return LocationPermissionState.backgroundGranted;
      case LocationPermission.whileInUse:
        return LocationPermissionState.foregroundGranted;
      case LocationPermission.denied:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.notDetermined;
    }
  }
}
