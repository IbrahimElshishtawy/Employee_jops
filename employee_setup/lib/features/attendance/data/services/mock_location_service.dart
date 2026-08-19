import '../../../../core/constants/app_constants.dart';
import '../../domain/models/location_result.dart';
import '../../domain/services/attendance_location_policy.dart';
import '../../domain/services/location_service.dart';

enum MockLocationMode {
  insideRange,
  outsideRange,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  lowAccuracy,
  staleLocation,
  mockLocationDetected,
  error,
}

class MockLocationService implements LocationService {
  MockLocationMode mode;
  double customDistance;
  double customAccuracy;
  DateTime? simulatedTimestamp;
  double workplaceLatitude;
  double workplaceLongitude;

  MockLocationService({
    this.mode = MockLocationMode.insideRange,
    this.customDistance = 2.3, // default: 2.3m from workplace
    this.customAccuracy = 3.5, // default: 3.5m high accuracy
    this.simulatedTimestamp,
    this.workplaceLatitude = AppConstants.officeLatitude,
    this.workplaceLongitude = AppConstants.officeLongitude,
  });

  void updateWorkplaceCoordinates({
    required double latitude,
    required double longitude,
  }) {
    workplaceLatitude = latitude;
    workplaceLongitude = longitude;
  }

  @override
  Future<LocationResult> getCurrentLocation() async {
    // Artificial small delay for realistic UI loading states
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    final baseLat = workplaceLatitude;
    final baseLon = workplaceLongitude;

    switch (mode) {
      case MockLocationMode.insideRange:
        final distance = customDistance <= 4.0 ? customDistance : 2.3;
        return LocationResult(
          latitude: baseLat + 0.00001,
          longitude: baseLon + 0.00001,
          distanceFromOfficeMeters: distance,
          accuracyMeters: customAccuracy <= 20.0 ? customAccuracy : 3.5,
          timestamp: simulatedTimestamp ?? now,
          status: LocationStatus.insideRange,
        );
      case MockLocationMode.outsideRange:
        final distance = customDistance > 4.0 ? customDistance : 48.5;
        return LocationResult(
          latitude: baseLat + 0.005,
          longitude: baseLon + 0.005,
          distanceFromOfficeMeters: distance,
          accuracyMeters: customAccuracy,
          timestamp: simulatedTimestamp ?? now,
          status: LocationStatus.outsideRange,
          errorMessage: 'أنت خارج نطاق تسجيل الحضور (${distance.toStringAsFixed(1)} متر)',
        );
      case MockLocationMode.lowAccuracy:
        return LocationResult(
          latitude: baseLat,
          longitude: baseLon,
          distanceFromOfficeMeters: 2.0,
          accuracyMeters: 45.0, // poor accuracy > 20m
          timestamp: simulatedTimestamp ?? now,
          status: LocationStatus.lowAccuracy,
          errorMessage: 'دقة الموقع غير كافية (${45} م). يرجى الانتقال لمكان مكشوف وإعادة المحاولة.',
        );
      case MockLocationMode.staleLocation:
        return LocationResult(
          latitude: baseLat,
          longitude: baseLon,
          distanceFromOfficeMeters: 2.0,
          accuracyMeters: 3.0,
          timestamp: now.subtract(const Duration(minutes: 5)), // 5 mins old
          status: LocationStatus.staleLocation,
          errorMessage: 'بيانات الموقع الجغرافي قديمة، جاري إعادة التحديث.',
        );
      case MockLocationMode.mockLocationDetected:
        return LocationResult(
          latitude: baseLat,
          longitude: baseLon,
          distanceFromOfficeMeters: 2.0,
          accuracyMeters: 3.0,
          timestamp: simulatedTimestamp ?? now,
          isMockLocation: true,
          status: LocationStatus.mockLocationDetected,
          errorMessage: 'تم رصد استخدام موقع وهمي (Mock Location). تم رفض العملية لأسباب أمنية.',
        );
      case MockLocationMode.permissionDenied:
        return LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          accuracyMeters: 999,
          timestamp: now,
          status: LocationStatus.permissionDenied,
          errorMessage: 'تم رفض إذن الوصول إلى الموقع الجغرافي',
        );
      case MockLocationMode.permissionDeniedForever:
        return LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          accuracyMeters: 999,
          timestamp: now,
          status: LocationStatus.permissionDeniedForever,
          errorMessage: 'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات الجهاز.',
        );
      case MockLocationMode.gpsDisabled:
        return LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          accuracyMeters: 999,
          timestamp: now,
          status: LocationStatus.gpsDisabled,
          errorMessage: 'خدمة تحديد المواقع GPS معطلة على هذا الجهاز',
        );
      case MockLocationMode.error:
        return LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          accuracyMeters: 999,
          timestamp: now,
          status: LocationStatus.error,
          errorMessage: 'تعذر الاتصال بخدمة الخرائط وتحديد المواقع',
        );
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return mode != MockLocationMode.gpsDisabled;
  }

  @override
  Future<bool> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mode == MockLocationMode.permissionDenied ||
        mode == MockLocationMode.permissionDeniedForever) {
      mode = MockLocationMode.insideRange;
      return true;
    }
    return true;
  }

  @override
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return AttendanceLocationPolicy.calculateDistanceInMeters(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );
  }

  @override
  bool isWithinAllowedRadius(double distanceMeters, [double allowedRadiusMeters = 4.0]) {
    return AttendanceLocationPolicy.isWithinAllowedRadius(distanceMeters, allowedRadiusMeters);
  }
}
