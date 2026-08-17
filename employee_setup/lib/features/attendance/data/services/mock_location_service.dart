import '../../../../core/constants/app_constants.dart';
import '../../domain/models/location_result.dart';
import '../../domain/services/location_service.dart';

enum MockLocationMode {
  insideRange,
  outsideRange,
  permissionDenied,
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
    await Future.delayed(const Duration(milliseconds: 500));

    switch (mode) {
      case MockLocationMode.insideRange:
        return LocationResult(
          latitude: AppConstants.officeLatitude + 0.00001,
          longitude: AppConstants.officeLongitude + 0.00001,
          distanceFromOfficeMeters: customDistance <= 4.0 ? customDistance : 2.3,
          status: LocationStatus.insideRange,
        );
      case MockLocationMode.outsideRange:
        return const LocationResult(
          latitude: AppConstants.officeLatitude + 0.005,
          longitude: AppConstants.officeLongitude + 0.005,
          distanceFromOfficeMeters: 48.5,
          status: LocationStatus.outsideRange,
          errorMessage: 'أنت خارج نطاق تسجيل الحضور (48.5 متر)',
        );
      case MockLocationMode.permissionDenied:
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          status: LocationStatus.permissionDenied,
          errorMessage: 'تم رفض إذن الوصول إلى الموقع الجغرافي',
        );
      case MockLocationMode.gpsDisabled:
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          distanceFromOfficeMeters: 9999,
          status: LocationStatus.gpsDisabled,
          errorMessage: 'خدمة تحديد المواقع GPS معطلة',
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
}
