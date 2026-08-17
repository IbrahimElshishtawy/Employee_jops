import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/models/permission_request.dart';
import '../../domain/repositories/permissions_repository.dart';

class MockPermissionsRepository implements PermissionsRepository {
  final Ref? _ref;
  final _uuid = const Uuid();

  MockPermissionsRepository([Ref? ref]) : _ref = ref;

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;
  MockDatabase get _state =>
      _ref?.read(mockDatabaseProvider) ?? fallbackMockDatabaseNotifier.snapshot;

  @override
  Future<List<PermissionRequest>> getPermissions(String employeeId) async {
    return _state.permissions.where((p) => p.employeeId == employeeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<PermissionRequest?> getPermissionById(String id) async {
    try {
      return _state.permissions.firstWhere((p) => p.id == id);
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
    final perm = PermissionRequest(
      id: 'PERM-${_uuid.v4().substring(0, 6).toUpperCase()}',
      employeeId: employeeId,
      type: type,
      date: date,
      durationOrTime: durationOrTime,
      reason: reason,
      status: PermissionStatus.pending,
      createdAt: DateTime.now(),
    );
    _db.addPermission(perm);
    return perm;
  }

  @override
  Future<void> resetToDefaultMock() async {
    // Handled by MockDatabaseNotifier.resetDataKeepSession()
  }
}
