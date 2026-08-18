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
  error,
}

class MockLocationService implements LocationService {
  MockLocationMode mode;
  double customDistance;

  MockLocationService({
    this.mode = MockLocationMode.insideRange,
    this.customDistance = 2.3, // default: 2.3m from workplace
  });

  @override
  Future<LocationResult> getCurrentLocation() async {
    // Artificial small delay for realistic UI loading states
    await Future.delayed(const Duration(milliseconds: 350));

    switch (mode) {
      case MockLocationMode.insideRange:
        final distance = customDistance <= 4.0 ? customDistance : 2.3;
        return LocationResult(
          latitude: AppConstants.officeLatitude + 0.00001,
          longitude: AppConstants.officeLongitude + 0.00001,
          distanceFromOfficeMeters: distance,
          status: LocationStatus.insideRange,
        );
      case MockLocationMode.outsideRange:
        final distance = customDistance > 4.0 ? customDistance : 48.5;
        return LocationResult(
          latitude: AppConstants.officeLatitude + 0.005,
          longitude: AppConstants.officeLongitude + 0.005,
          distanceFromOfficeMeters: distance,
          status: LocationStatus.outsideRange,
          errorMessage: 'أنت خارج نطاق تسجيل الحضور (${distance.toStringAsFixed(1)} متر)',
        );
      case MockLocationMode.permissionDenied:
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          status: LocationStatus.permissionDenied,
          errorMessage: 'تم رفض إذن الوصول إلى الموقع الجغرافي',
        );
      case MockLocationMode.permissionDeniedForever:
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          status: LocationStatus.permissionDeniedForever,
          errorMessage: 'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات الجهاز.',
        );
      case MockLocationMode.gpsDisabled:
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          status: LocationStatus.gpsDisabled,
          errorMessage: 'خدمة تحديد المواقع GPS معطلة على هذا الجهاز',
        );
      case MockLocationMode.error:
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
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
