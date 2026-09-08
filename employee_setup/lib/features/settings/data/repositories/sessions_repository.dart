import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';

class DeviceSessionItem {
  final String id;
  final String deviceName;
  final String deviceType;
  final String? ipAddress;
  final DateTime lastActive;
  final bool isCurrent;

  const DeviceSessionItem({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    this.ipAddress,
    required this.lastActive,
    this.isCurrent = false,
  });

  factory DeviceSessionItem.fromJson(Map<String, dynamic> json) {
    return DeviceSessionItem(
      id: json['id'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? json['deviceModel'] as String? ?? 'Mobile Device',
      deviceType: json['deviceType'] as String? ?? 'MOBILE',
      ipAddress: json['ipAddress'] as String?,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

class SessionsRepository {
  final ApiClient apiClient;

  const SessionsRepository(this.apiClient);

  Future<List<DeviceSessionItem>> getMyDevices() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myDevices,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => DeviceSessionItem.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <DeviceSessionItem>[];
        },
      );
      return response.data ?? [];
    } on ApiException catch (e) {
      SecureLogger.error('SessionsRepository', 'Failed to fetch sessions', e);
      return [
        DeviceSessionItem(
          id: 'CURRENT-DEVICE-SESSION',
          deviceName: 'This Mobile Device',
          deviceType: 'MOBILE',
          ipAddress: '127.0.0.1',
          lastActive: DateTime.now(),
          isCurrent: true,
        ),
      ];
    }
  }

  Future<bool> revokeSession(String sessionId) async {
    try {
      final response = await apiClient.delete(ApiEndpoints.sessionById(sessionId));
      return response.success;
    } catch (e) {
      SecureLogger.error('SessionsRepository', 'Failed to revoke session $sessionId', e);
      return false;
    }
  }

  Future<bool> revokeOtherSessions(String currentSessionId) async {
    try {
      final response = await apiClient.delete(
        ApiEndpoints.terminateOtherSessions(currentSessionId),
      );
      return response.success;
    } catch (e) {
      SecureLogger.error('SessionsRepository', 'Failed to revoke other sessions', e);
      return false;
    }
  }
}
