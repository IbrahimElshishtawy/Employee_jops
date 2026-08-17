import '../models/permission_request.dart';

abstract class PermissionsRepository {
  Future<List<PermissionRequest>> getPermissions(String employeeId);
  Future<PermissionRequest?> getPermissionById(String id);
  Future<PermissionRequest> createPermission({
    required String employeeId,
    required PermissionType type,
    required DateTime date,
    required String durationOrTime,
    required String reason,
  });
  Future<void> resetToDefaultMock();
}
