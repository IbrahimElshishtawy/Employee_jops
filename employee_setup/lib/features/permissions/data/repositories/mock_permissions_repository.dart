import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/permission_request.dart';
import '../../domain/repositories/permissions_repository.dart';

class MockPermissionsRepository implements PermissionsRepository {
  final Uuid _uuid = const Uuid();
  final List<PermissionRequest> _permissions = [];

  MockPermissionsRepository() {
    _initMockData();
  }

  void _initMockData() {
    _permissions.clear();
    final now = DateTime.now();

    _permissions.addAll([
      PermissionRequest(
        id: 'perm-001',
        employeeId: AppConstants.mockEmployeeId,
        type: PermissionType.earlyLeave,
        date: now.subtract(const Duration(days: 3)),
        durationOrTime: 'ساعتان (من 3:00 م حتى 5:00 م)',
        reason: 'مراجعة موعد طبي في العيادة الخارجية',
        status: PermissionStatus.approved,
        createdAt: now.subtract(const Duration(days: 4)),
        approvedAt: now.subtract(const Duration(days: 3)),
      ),
      PermissionRequest(
        id: 'perm-002',
        employeeId: AppConstants.mockEmployeeId,
        type: PermissionType.morningDelay,
        date: now.subtract(const Duration(days: 7)),
        durationOrTime: 'ساعة ونصف (وصول 10:30 ص)',
        reason: 'تجديد رخصة القيادة في المرور',
        status: PermissionStatus.approved,
        createdAt: now.subtract(const Duration(days: 8)),
        approvedAt: now.subtract(const Duration(days: 7)),
      ),
      PermissionRequest(
        id: 'perm-003',
        employeeId: AppConstants.mockEmployeeId,
        type: PermissionType.halfDay,
        date: now.add(const Duration(days: 2)),
        durationOrTime: 'نصف يوم مسائي (من 1:00 م)',
        reason: 'حضور مناسبة عائلية خاصة',
        status: PermissionStatus.pending,
        createdAt: now,
      ),
    ]);
  }

  @override
  Future<List<PermissionRequest>> getPermissions(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_permissions);
  }

  @override
  Future<PermissionRequest?> getPermissionById(String id) async {
    try {
      return _permissions.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PermissionRequest> createPermission({
    required String employeeId,
    required PermissionType type,
    required DateTime date,
    required String durationOrTime,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final newPerm = PermissionRequest(
      id: 'perm-${_uuid.v4().substring(0, 6)}',
      employeeId: employeeId,
      type: type,
      date: date,
      durationOrTime: durationOrTime,
      reason: reason,
      status: PermissionStatus.pending,
      createdAt: DateTime.now(),
    );

    _permissions.insert(0, newPerm);
    return newPerm;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _initMockData();
  }
}
