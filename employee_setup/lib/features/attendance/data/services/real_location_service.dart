import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/location_result.dart';
import '../../domain/services/attendance_location_policy.dart';
import '../../domain/services/geofence_service.dart';
import '../../domain/services/location_service.dart';

/// RealLocationService obtains GPS coordinates, validates permissions, checks mock location
/// flags where supported, and computes geodesic distance to the workplace geofence.
class RealLocationService implements LocationService {
  final GeofenceService _geofenceService;
  double workplaceLatitude;
  double workplaceLongitude;
  final double allowedRadiusMeters;

  RealLocationService({
    GeofenceService? geofenceService,
    this.workplaceLatitude = AppConstants.officeLatitude,
    this.workplaceLongitude = AppConstants.officeLongitude,
    this.allowedRadiusMeters = 4.0,
  }) : _geofenceService = geofenceService ?? const GeofenceService();

  void updateWorkplaceCoordinates({
    required double latitude,
    required double longitude,
  }) {
    workplaceLatitude = latitude;
    workplaceLongitude = longitude;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      SecureLogger.error('RealLocationService', 'isLocationServiceEnabled error', e);
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      SecureLogger.error('RealLocationService', 'requestPermission error', e);
      return false;
    }
  }

  @override
  Future<LocationResult> getCurrentLocation() async {
    final now = DateTime.now();

    try {
      // 1. Check if location services (GPS) are enabled
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          accuracyMeters: 999,
          timestamp: now,
          status: LocationStatus.gpsDisabled,
          errorMessage: 'خدمة تحديد المواقع (GPS) معطلة. يرجى تفعيلها للمتابعة.',
        );
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            latitude: 0,
            longitude: 0,
            distanceFromOfficeMeters: 9999,
            accuracyMeters: 999,
            timestamp: now,
            status: LocationStatus.permissionDenied,
            errorMessage: 'تم رفض إذن الوصول إلى الموقع الجغرافي.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          accuracyMeters: 999,
          timestamp: now,
          status: LocationStatus.permissionDeniedForever,
          errorMessage:
              'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات الجهاز.',
        );
      }

      // 3. Acquire GPS Position
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      // 4. Check Mock Location (Android platform signal)
      final bool isMocked = position.isMocked;
      if (isMocked) {
        SecureLogger.warn('RealLocationService', 'Mock location detected from platform telemetry');
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          distanceFromOfficeMeters: 0,
          accuracyMeters: position.accuracy,
          timestamp: position.timestamp,
          isMockLocation: true,
          status: LocationStatus.mockLocationDetected,
          errorMessage:
              'تم رصد استخدام موقع جغرافي وهمي (Mock Location). تم رفض العملية لأسباب أمنية.',
        );
      }

      // 5. Calculate geodesic distance to workplace geofence
      final double distance = _geofenceService.calculateDistanceInMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: workplaceLatitude,
        endLongitude: workplaceLongitude,
      );

      // 6. Check GPS Accuracy
      final bool isAccurate =
          AttendanceLocationPolicy.isAccuracyAcceptable(position.accuracy);
      if (!isAccurate) {
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          distanceFromOfficeMeters: distance,
          accuracyMeters: position.accuracy,
          timestamp: position.timestamp,
          status: LocationStatus.lowAccuracy,
          errorMessage:
              'دقة الموقع الجغرافي غير كافية (${position.accuracy.toStringAsFixed(1)} م). يرجى الانتقال إلى مكان مكشوف.',
        );
      }

      // 7. Check Geofence Radius
      final bool isInside = distance <= allowedRadiusMeters;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        distanceFromOfficeMeters: distance,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
        isMockLocation: false,
        status: isInside
            ? LocationStatus.insideRange
            : LocationStatus.outsideRange,
        errorMessage: isInside
            ? null
            : 'أنت خارج نطاق مقر العمل المعتمد (${distance.toStringAsFixed(1)} م). الحد الأقصى المصرح به هو $allowedRadiusMeters أمتار.',
      );
    } on TimeoutException {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        distanceFromOfficeMeters: 9999,
        accuracyMeters: 999,
        timestamp: now,
        status: LocationStatus.locationUnavailable,
        errorMessage:
            'استغرق الحصول على الموقع الجغرافي وقتًا طويلاً. يرجى التأكد من اتصال GPS وإعادة المحاولة.',
      );
    } catch (e) {
      SecureLogger.error('RealLocationService', 'getCurrentLocation error', e);
      return LocationResult(
        latitude: 0,
        longitude: 0,
        distanceFromOfficeMeters: 9999,
        accuracyMeters: 999,
        timestamp: now,
        status: LocationStatus.error,
        errorMessage: 'تعذر تحديد الموقع الجغرافي: $e',
      );
    }
  }

  @override
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return _geofenceService.calculateDistanceInMeters(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );
  }

  @override
  bool isWithinAllowedRadius(double distanceMeters,
      [double allowedRadiusMeters = 4.0]) {
    return _geofenceService.isWithinRadius(
      distanceInMeters: distanceMeters,
      allowedRadiusMeters: allowedRadiusMeters,
    );
  }
}
