import '../../../features/permissions/domain/models/permission_request.dart';
import '../seeds/employee_seed.dart';

class PermissionSeeds {
  static const String _empId = EmployeeSeed.id;

  static List<PermissionRequest> get permissions => [
        PermissionRequest(
          id: 'PERM-001',
          employeeId: _empId,
          type: PermissionType.earlyLeave,
          date: DateTime(2026, 8, 17),
          durationOrTime: 'الساعة 15:00',
          reason: 'ظرف شخصي طارئ',
          status: PermissionStatus.pending,
          createdAt: DateTime(2026, 8, 17, 9, 0),
        ),
        PermissionRequest(
          id: 'PERM-002',
          employeeId: _empId,
          type: PermissionType.morningDelay,
          date: DateTime(2026, 8, 14),
          durationOrTime: '30 دقيقة',
          reason: 'موعد طبي',
          status: PermissionStatus.approved,
          createdAt: DateTime(2026, 8, 13, 17, 0),
          approvedAt: DateTime(2026, 8, 13, 18, 0),
        ),
        PermissionRequest(
          id: 'PERM-003',
          employeeId: _empId,
          type: PermissionType.halfDay,
          date: DateTime(2026, 8, 10),
          durationOrTime: 'الفترة الصباحية',
          reason: 'إجراءات حكومية',
          status: PermissionStatus.approved,
          createdAt: DateTime(2026, 8, 9),
          approvedAt: DateTime(2026, 8, 9, 20, 0),
        ),
      ];
}
