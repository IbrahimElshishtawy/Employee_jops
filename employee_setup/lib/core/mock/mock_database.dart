import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/advances/domain/models/advance_request.dart';
import '../../features/advances/domain/models/expense_report.dart';
import '../../features/attendance/domain/models/attendance.dart';
import '../../features/attendance/domain/models/work_schedule.dart';
import '../../features/auth/domain/models/employee.dart';
import '../../features/notifications/domain/models/app_notification.dart';
import '../../features/permissions/domain/models/permission_request.dart';
import '../../features/vacations/domain/models/vacation_request.dart';

import 'models/app_session.dart';
import 'models/company.dart';
import 'models/deduction.dart';
import 'models/hr_message.dart';

import 'seeds/advance_seeds.dart';
import 'seeds/attendance_seeds.dart';
import 'seeds/company_seed.dart';
import 'seeds/deduction_seeds.dart';
import 'seeds/employee_seed.dart';
import 'seeds/hr_message_seeds.dart';
import 'seeds/notification_seeds.dart';
import 'seeds/permission_seeds.dart';
import 'seeds/vacation_seeds.dart';

// ─────────────────────────────────────────────────────────────
// MockDatabase — immutable snapshot of the entire app state
// ─────────────────────────────────────────────────────────────

class MockDatabase {
  final Employee employee;
  final Company company;
  final CompanyLocation companyLocation;
  final AppSession? session;

  final List<Attendance> attendance;
  final List<AdvanceRequest> advances;
  final List<ExpenseReport> expenseReports;
  final List<PermissionRequest> permissions;
  final List<VacationRequest> vacations;
  final List<AppNotification> notifications;
  final List<Deduction> deductions;
  final List<HRMessage> hrMessages;

  final WorkSchedule workSchedule;

  const MockDatabase({
    required this.employee,
    required this.company,
    required this.companyLocation,
    this.session,
    required this.workSchedule,
    required this.attendance,
    required this.advances,
    required this.expenseReports,
    required this.permissions,
    required this.vacations,
    required this.notifications,
    required this.deductions,
    required this.hrMessages,
  });

  // ── Derived Getters ──────────────────────────────────────

  /// Today's check-in record, if any.
  Attendance? get todayCheckIn {
    final today = DateTime.now();
    try {
      return attendance.firstWhere(
        (a) =>
            a.type == AttendanceType.checkIn &&
            a.timestamp.year == today.year &&
            a.timestamp.month == today.month &&
            a.timestamp.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Today's check-out record, if any.
  Attendance? get todayCheckOut {
    final today = DateTime.now();
    try {
      return attendance.firstWhere(
        (a) =>
            a.type == AttendanceType.checkOut &&
            a.timestamp.year == today.year &&
            a.timestamp.month == today.month &&
            a.timestamp.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  TodayAttendanceSummary get todaySummary =>
      TodayAttendanceSummary(checkIn: todayCheckIn, checkOut: todayCheckOut);

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  // ── CopyWith ─────────────────────────────────────────────

  MockDatabase copyWith({
    Employee? employee,
    Company? company,
    CompanyLocation? companyLocation,
    AppSession? Function()? session,
    WorkSchedule? workSchedule,
    List<Attendance>? attendance,
    List<AdvanceRequest>? advances,
    List<ExpenseReport>? expenseReports,
    List<PermissionRequest>? permissions,
    List<VacationRequest>? vacations,
    List<AppNotification>? notifications,
    List<Deduction>? deductions,
    List<HRMessage>? hrMessages,
  }) {
    return MockDatabase(
      employee: employee ?? this.employee,
      company: company ?? this.company,
      companyLocation: companyLocation ?? this.companyLocation,
      session: session != null ? session() : this.session,
      workSchedule: workSchedule ?? this.workSchedule,
      attendance: attendance ?? this.attendance,
      advances: advances ?? this.advances,
      expenseReports: expenseReports ?? this.expenseReports,
      permissions: permissions ?? this.permissions,
      vacations: vacations ?? this.vacations,
      notifications: notifications ?? this.notifications,
      deductions: deductions ?? this.deductions,
      hrMessages: hrMessages ?? this.hrMessages,
    );
  }

  /// Returns the canonical seed state — used for Reset.
  static MockDatabase seed() => MockDatabase(
    employee: EmployeeSeed.employee,
    company: CompanySeed.company,
    companyLocation: CompanySeed.location,
    session: null,
    workSchedule: WorkSchedule.defaultSchedule(),
    attendance: List.from(AttendanceSeeds.records),
    advances: List.from(AdvanceSeeds.advances),
    expenseReports: List.from(AdvanceSeeds.expenseReports),
    permissions: List.from(PermissionSeeds.permissions),
    vacations: List.from(VacationSeeds.vacations),
    notifications: List.from(NotificationSeeds.notifications),
    deductions: List.from(DeductionSeeds.deductions),
    hrMessages: List.from(HRMessageSeeds.messages),
  );
}

// ─────────────────────────────────────────────────────────────
// MockDatabaseNotifier
// ─────────────────────────────────────────────────────────────

final fallbackMockDatabaseNotifier = MockDatabaseNotifier();

class MockDatabaseNotifier extends StateNotifier<MockDatabase> {
  MockDatabaseNotifier() : super(MockDatabase.seed());

  MockDatabase get snapshot => state;

  // ── Session ───────────────────────────────────────────────

  void setSession(AppSession session) {
    state = state.copyWith(session: () => session);
  }

  void clearSession() {
    state = state.copyWith(session: () => null);
  }

  // ── Attendance ────────────────────────────────────────────

  void replaceState(MockDatabase nextState) {
    state = nextState;
  }

  void replaceAttendance(List<Attendance> attendance) {
    state = state.copyWith(attendance: attendance);
  }

  void addAttendance(Attendance record) {
    state = state.copyWith(attendance: [...state.attendance, record]);
  }

  void resetAttendance() {
    state = state.copyWith(attendance: List.from(AttendanceSeeds.records));
  }

  // ── Advances ──────────────────────────────────────────────

  void addAdvance(AdvanceRequest advance) {
    state = state.copyWith(advances: [...state.advances, advance]);
  }

  void updateAdvanceStatus(String id, AdvanceStatus status) {
    state = state.copyWith(
      advances: state.advances
          .map((a) => a.id == id ? a.copyWith(status: status) : a)
          .toList(),
    );
  }

  void addExpenseReport(ExpenseReport report) {
    state = state.copyWith(expenseReports: [...state.expenseReports, report]);
  }

  // ── Permissions ───────────────────────────────────────────

  void addPermission(PermissionRequest perm) {
    state = state.copyWith(permissions: [...state.permissions, perm]);
  }

  void updatePermissionStatus(String id, PermissionStatus status) {
    state = state.copyWith(
      permissions: state.permissions
          .map((p) => p.id == id ? p.copyWith(status: status) : p)
          .toList(),
    );
  }

  // ── Vacations ─────────────────────────────────────────────

  void addVacation(VacationRequest vac) {
    state = state.copyWith(vacations: [...state.vacations, vac]);
  }

  void updateVacationStatus(String id, VacationStatus status) {
    state = state.copyWith(
      vacations: state.vacations
          .map((v) => v.id == id ? v.copyWith(status: status) : v)
          .toList(),
    );
  }

  // ── Notifications ─────────────────────────────────────────

  void addNotification(AppNotification notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
    );
  }

  // ── HR Messages ───────────────────────────────────────────

  void markHRMessageRead(String id) {
    state = state.copyWith(
      hrMessages: state.hrMessages
          .map((m) => m.id == id ? m.copyWith(status: HRMessageStatus.read) : m)
          .toList(),
    );
  }

  // ── Full Reset ────────────────────────────────────────────

  /// Resets ALL data back to seed values. Session is cleared (user stays logged out).
  void resetAll() {
    state = MockDatabase.seed();
  }

  /// Resets data but preserves the current session (user stays logged in).
  void resetDataKeepSession() {
    final currentSession = state.session;
    state = MockDatabase.seed().copyWith(session: () => currentSession);
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final mockDatabaseProvider =
    StateNotifierProvider<MockDatabaseNotifier, MockDatabase>((ref) {
      return MockDatabaseNotifier();
    });
