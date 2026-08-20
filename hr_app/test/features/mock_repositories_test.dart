import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:hr_app/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_app/features/employees/data/repositories/mock_employee_repository.dart';
import 'package:hr_app/features/employees/domain/entities/employee_entity.dart';
import 'package:hr_app/features/requests/data/repositories/mock_requests_repository.dart';
import 'package:hr_app/features/requests/domain/entities/hr_request_entity.dart';

void main() {
  group('Mock Repositories Tests', () {
    test('MockEmployeeRepository returns strictly fake test employees and paginates', () async {
      final repo = MockEmployeeRepository();
      final result = await repo.getEmployees(const EmployeeFilter(page: 1, pageSize: 5));

      expect(result.items, isNotEmpty);
      for (final emp in result.items) {
        expect(emp.id.startsWith('TEST-EMP-'), isTrue, reason: 'Must use TEST-EMP prefix');
        expect(emp.email.endsWith('.test'), isTrue, reason: 'Must use safe .test domain');
      }
    });

    test('MockAttendanceRepository filters records correctly', () async {
      final repo = MockAttendanceRepository();
      final all = await repo.getAttendanceRecords(const AttendanceFilter());
      expect(all.items, isNotEmpty);

      final lateRecords = await repo.getAttendanceRecords(
        const AttendanceFilter(status: AttendanceStatus.late),
      );
      expect(lateRecords.items.every((r) => r.status == AttendanceStatus.late), isTrue);
    });

    test('MockRequestsRepository allows approving and rejecting requests', () async {
      final repo = MockRequestsRepository();
      final initial = await repo.getRequestById('TEST-REQ-001');
      expect(initial.status, equals(RequestStatus.pending));

      await repo.reviewRequest('TEST-REQ-001', approve: true, comment: 'Approved in test');
      final updated = await repo.getRequestById('TEST-REQ-001');
      expect(updated.status, equals(RequestStatus.approved));
      expect(updated.reviewComment, equals('Approved in test'));
    });
  });
}
