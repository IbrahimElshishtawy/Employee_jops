import '../../../../core/utils/secure_logger.dart';
import '../../domain/entities/employee_location.dart';
import '../models/employee_location_model.dart';

/// Interface for sending real-time / batch location data to the backend API.
/// Implementation can be swapped with Dio/Http client without touching Domain or UI layers.
abstract class LocationRemoteDataSource {
  /// Transmits a single location update to the backend
  Future<bool> syncLocation(EmployeeLocation location);

  /// Transmits a batch of offline recorded locations to the backend
  Future<bool> syncLocationBatch(List<EmployeeLocation> locations);
}

/// Standalone/Mockable implementation ready for backend integration
class BackendLocationRemoteDataSource implements LocationRemoteDataSource {
  final bool Function()? isConnectedChecker;

  BackendLocationRemoteDataSource({this.isConnectedChecker});

  @override
  Future<bool> syncLocation(EmployeeLocation location) async {
    try {
      if (isConnectedChecker != null && !isConnectedChecker!()) {
        return false;
      }
      final model = EmployeeLocationModel.fromEntity(location);
      SecureLogger.info(
        'LocationRemoteDataSource',
        'Syncing location for session ${model.workSessionId} at (${model.latitude.toStringAsFixed(4)}, ${model.longitude.toStringAsFixed(4)})',
      );
      return true;
    } catch (e) {
      SecureLogger.error('LocationRemoteDataSource', 'syncLocation failed', e);
      return false;
    }
  }

  @override
  Future<bool> syncLocationBatch(List<EmployeeLocation> locations) async {
    try {
      if (locations.isEmpty) return true;
      if (isConnectedChecker != null && !isConnectedChecker!()) {
        return false;
      }
      SecureLogger.info(
        'LocationRemoteDataSource',
        'Syncing batch of ${locations.length} offline locations to server',
      );
      return true;
    } catch (e) {
      SecureLogger.error('LocationRemoteDataSource', 'syncLocationBatch failed', e);
      return false;
    }
  }
}
