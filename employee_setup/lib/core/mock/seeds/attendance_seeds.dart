import '../../../features/attendance/domain/models/attendance.dart';
import '../seeds/employee_seed.dart';
import '../seeds/company_seed.dart';

/// Seed attendance records — historical data for the mock employee.
class AttendanceSeeds {
  static const String _empId = EmployeeSeed.id;
  static final double _lat = CompanySeed.location.latitude + 0.000001;
  static final double _lng = CompanySeed.location.longitude + 0.000001;
  static const double _dist = 2.3;

  static List<Attendance> get records => [
        // ── 17 Aug 2026 ─── Check In ──────────────────────
        Attendance(
          id: 'ATT-001-IN',
          employeeId: _empId,
          type: AttendanceType.checkIn,
          timestamp: DateTime(2026, 8, 17, 8, 57),
          latitude: _lat,
          longitude: _lng,
          distanceFromOffice: _dist,
          biometricVerified: true,
          isOffline: false,
          status: AttendanceStatus.success,
        ),
        // ── 17 Aug 2026 ─── Check Out ─────────────────────
        Attendance(
          id: 'ATT-001-OUT',
          employeeId: _empId,
          type: AttendanceType.checkOut,
          timestamp: DateTime(2026, 8, 17, 17, 4),
          latitude: _lat,
          longitude: _lng,
          distanceFromOffice: _dist,
          biometricVerified: true,
          isOffline: false,
          status: AttendanceStatus.success,
        ),
        // ── 16 Aug 2026 ─── Check In ──────────────────────
        Attendance(
          id: 'ATT-002-IN',
          employeeId: _empId,
          type: AttendanceType.checkIn,
          timestamp: DateTime(2026, 8, 16, 9, 2),
          latitude: _lat,
          longitude: _lng,
          distanceFromOffice: _dist,
          biometricVerified: true,
          isOffline: false,
          status: AttendanceStatus.success,
        ),
        // ── 16 Aug 2026 ─── Check Out ─────────────────────
        Attendance(
          id: 'ATT-002-OUT',
          employeeId: _empId,
          type: AttendanceType.checkOut,
          timestamp: DateTime(2026, 8, 16, 17, 11),
          latitude: _lat,
          longitude: _lng,
          distanceFromOffice: _dist,
          biometricVerified: true,
          isOffline: false,
          status: AttendanceStatus.success,
        ),
        // ── 15 Aug 2026 ─── Late Check In ─────────────────
        Attendance(
          id: 'ATT-003-IN',
          employeeId: _empId,
          type: AttendanceType.checkIn,
          timestamp: DateTime(2026, 8, 15, 9, 21),
          latitude: _lat,
          longitude: _lng,
          distanceFromOffice: _dist,
          biometricVerified: true,
          isOffline: false,
          status: AttendanceStatus.success,
          note: 'تأخير 21 دقيقة',
        ),
        // ── 15 Aug 2026 ─── Check Out ─────────────────────
        Attendance(
          id: 'ATT-003-OUT',
          employeeId: _empId,
          type: AttendanceType.checkOut,
          timestamp: DateTime(2026, 8, 15, 17, 0),
          latitude: _lat,
          longitude: _lng,
          distanceFromOffice: _dist,
          biometricVerified: true,
          isOffline: false,
          status: AttendanceStatus.success,
        ),
      ];
}
