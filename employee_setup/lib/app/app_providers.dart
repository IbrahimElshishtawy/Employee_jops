import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/mock/mock_database.dart';
import '../core/mock/models/app_session.dart';
import '../core/mock/models/deduction.dart';
import '../core/mock/models/hr_message.dart';
import '../core/mock/repositories/deduction_repository.dart';
import '../core/mock/repositories/hr_message_repository.dart';
import '../core/mock/repositories/mock_deduction_repository.dart';
import '../core/mock/repositories/mock_hr_message_repository.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/mock_connectivity_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/shared_prefs_storage.dart';

import '../core/services/time_service.dart';
import '../features/advances/data/repositories/mock_advances_repository.dart';
import '../features/advances/domain/models/advance_request.dart';
import '../features/advances/domain/repositories/advances_repository.dart';

import '../features/attendance/data/repositories/mock_attendance_repository.dart';
import '../features/attendance/data/services/mock_biometric_service.dart';
import '../features/attendance/data/services/mock_location_service.dart';
import '../features/attendance/domain/models/attendance.dart';
import '../features/attendance/domain/models/attendance_state_type.dart';
import '../features/attendance/domain/models/location_result.dart';
import '../features/attendance/domain/models/work_schedule.dart';
import '../features/attendance/domain/repositories/attendance_repository.dart';
import '../features/attendance/domain/services/biometric_service.dart';
import '../features/attendance/domain/services/location_service.dart';
import '../features/attendance/domain/services/work_schedule_service.dart';

import '../features/auth/data/datasources/mock_auth_datasource.dart';
import '../features/auth/data/repositories/mock_auth_repository.dart';
import '../features/auth/domain/models/employee.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

import '../features/notifications/data/repositories/mock_notifications_repository.dart';
import '../features/notifications/domain/models/app_notification.dart';
import '../features/notifications/domain/repositories/notifications_repository.dart';

import '../features/permissions/data/repositories/mock_permissions_repository.dart';
import '../features/permissions/domain/models/permission_request.dart';
import '../features/permissions/domain/repositories/permissions_repository.dart';

import '../features/requests/domain/models/unified_request.dart';
import '../features/requests/domain/repositories/requests_repository.dart';

import '../features/settings/domain/models/app_settings.dart';
import '../features/settings/domain/models/demo_controls.dart';
import '../features/vacations/data/repositories/mock_vacations_repository.dart';
import '../features/vacations/domain/models/vacation_request.dart';
import '../features/vacations/domain/repositories/vacations_repository.dart';

// ══════════════════════════════════════════════════════════════════
// 0. MockDatabase Provider  (Single Source of Truth)
// ══════════════════════════════════════════════════════════════════
// Re-exported so screens can import from one place
export '../core/mock/mock_database.dart' show mockDatabaseProvider;

// ══════════════════════════════════════════════════════════════════
// 1. Core Infrastructure Providers
// ══════════════════════════════════════════════════════════════════

final localStorageProvider = Provider<LocalStorage>((ref) {
  return SharedPrefsStorage();
});

final timeServiceProvider = Provider<TimeService>((ref) {
  return DeviceTimeService();
});

final workScheduleServiceProvider = Provider<WorkScheduleService>((ref) {
  final timeService = ref.watch(timeServiceProvider);
  return WorkScheduleService(timeService);
});

final mockConnectivityServiceProvider = Provider<MockConnectivityService>((
  ref,
) {
  final service = MockConnectivityService(initialConnected: true);
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ref.watch(mockConnectivityServiceProvider);
});

// ══════════════════════════════════════════════════════════════════
// 2. Demo Controls
// ══════════════════════════════════════════════════════════════════

class DemoControlsNotifier extends StateNotifier<DemoControlsState> {
  final Ref _ref;

  DemoControlsNotifier(this._ref) : super(const DemoControlsState());

  void setLocationMode(MockLocationMode mode, [double? distance]) {
    state = state.copyWith(
      locationMode: mode,
      simulatedDistance:
          distance ?? (mode == MockLocationMode.insideRange ? 2.3 : 48.5),
    );
    final locService = _ref.read(mockLocationServiceProvider);
    locService.mode = mode;
    locService.customDistance = state.simulatedDistance;
  }

  void setBiometricMode(MockBiometricMode mode) {
    state = state.copyWith(biometricMode: mode);
    final bioService = _ref.read(mockBiometricServiceProvider);
    bioService.mode = mode;
  }

  void setNetworkOnline(bool online) {
    state = state.copyWith(isOnline: online);
    final connService = _ref.read(mockConnectivityServiceProvider);
    connService.setConnected(online);
  }

  Future<void> resetAllData() async {
    // Reset all data but keep the current session
    _ref.read(mockDatabaseProvider.notifier).resetDataKeepSession();

    setLocationMode(MockLocationMode.insideRange, 2.3);
    setBiometricMode(MockBiometricMode.alwaysSuccess);
    setNetworkOnline(true);

    // Invalidate all derived providers
    _ref.invalidate(attendanceSummaryProvider);
    _ref.invalidate(attendanceHistoryProvider);
    _ref.invalidate(advancesListProvider);
    _ref.invalidate(permissionsListProvider);
    _ref.invalidate(vacationsListProvider);
    _ref.invalidate(allRequestsProvider);
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(unreadNotificationsCountProvider);
  }
}

final demoControlsProvider =
    StateNotifierProvider<DemoControlsNotifier, DemoControlsState>((ref) {
      return DemoControlsNotifier(ref);
    });

// ══════════════════════════════════════════════════════════════════
// 3. Location & Biometric Services
// ══════════════════════════════════════════════════════════════════

final mockLocationServiceProvider = Provider<MockLocationService>((ref) {
  return MockLocationService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return ref.watch(mockLocationServiceProvider);
});

final mockBiometricServiceProvider = Provider<MockBiometricService>((ref) {
  return MockBiometricService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return ref.watch(mockBiometricServiceProvider);
});

// ══════════════════════════════════════════════════════════════════
// 4. Auth & Employee Providers
// ══════════════════════════════════════════════════════════════════

final authDataSourceProvider = Provider<MockAuthDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return MockAuthDataSource(storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final ds = ref.watch(authDataSourceProvider);
  return MockAuthRepository(ds, ref);
});

/// The current authenticated Employee — derived from MockDatabase.
/// This is the primary source for all screens that need employee info.
final employeeProvider = Provider<Employee>((ref) {
  return ref.watch(mockDatabaseProvider).employee;
});

/// The current AppSession — null if logged out.
final sessionProvider = Provider<AppSession?>((ref) {
  return ref.watch(mockDatabaseProvider).session;
});

// AuthState — tracks authentication flow (loading, error, user)
class AuthState {
  final Employee? employee;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.employee,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => employee != null;

  AuthState copyWith({
    Employee? employee,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      employee: clearUser ? null : (employee ?? this.employee),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await _repo.getCurrentUser();
    state = state.copyWith(employee: user, isInitialized: true);
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.signInWithGoogle();
      state = state.copyWith(employee: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = state.copyWith(clearUser: true);
  }

  /// Update employee profile (for onboarding completion)
  void updateEmployee(Employee updatedEmployee) {
    state = state.copyWith(employee: updatedEmployee);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

/// Convenience alias — nullable employee from auth state.
final currentEmployeeProvider = Provider<Employee?>((ref) {
  return ref.watch(authProvider).employee;
});

// ══════════════════════════════════════════════════════════════════
// 5. Attendance Providers — all derived from MockDatabase
// ══════════════════════════════════════════════════════════════════

/// The current employee's assigned work schedule
final workScheduleProvider = Provider<WorkSchedule>((ref) {
  return ref.watch(mockDatabaseProvider).workSchedule;
});

/// Current live evaluation of the employee's work schedule
final workScheduleShiftStatusProvider = Provider<WorkScheduleShiftStatus>((ref) {
  final scheduleService = ref.watch(workScheduleServiceProvider);
  final schedule = ref.watch(workScheduleProvider);
  return scheduleService.evaluateScheduleStatus(schedule);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return MockAttendanceRepository(ref);
});

/// Today's check-in / check-out summary — auto-updates when MockDatabase changes.
final attendanceSummaryProvider = Provider<TodayAttendanceSummary>((ref) {
  return ref.watch(mockDatabaseProvider).todaySummary;
});

/// Full attendance history — sorted descending by timestamp.
final attendanceHistoryProvider = Provider<List<Attendance>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.attendance.where((a) => a.employeeId == empId).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

// ─── Attendance Action State ──────────────────────────────────────

enum AttendanceProcessState {
  idle,
  checkingLocation,
  authenticatingBiometric,
  submitting,
  success,
  error,
}

class AttendanceFlowState {
  final AttendanceProcessState processState;
  final LocationResult? locationResult;
  final String? message;
  final bool isOffline;
  final bool isLocationUpdating;
  final bool isSyncing;
  final DateTime? lastLocationUpdateTime;

  const AttendanceFlowState({
    this.processState = AttendanceProcessState.idle,
    this.locationResult,
    this.message,
    this.isOffline = false,
    this.isLocationUpdating = false,
    this.isSyncing = false,
    this.lastLocationUpdateTime,
  });

  bool get isLoading =>
      processState == AttendanceProcessState.checkingLocation ||
      processState == AttendanceProcessState.authenticatingBiometric ||
      processState == AttendanceProcessState.submitting;

  AttendanceFlowState copyWith({
    AttendanceProcessState? processState,
    LocationResult? locationResult,
    String? message,
    bool? isOffline,
    bool? isLocationUpdating,
    bool? isSyncing,
    DateTime? lastLocationUpdateTime,
  }) {
    return AttendanceFlowState(
      processState: processState ?? this.processState,
      locationResult: locationResult ?? this.locationResult,
      message: message,
      isOffline: isOffline ?? this.isOffline,
      isLocationUpdating: isLocationUpdating ?? this.isLocationUpdating,
      isSyncing: isSyncing ?? this.isSyncing,
      lastLocationUpdateTime:
          lastLocationUpdateTime ?? this.lastLocationUpdateTime,
    );
  }
}

class AttendanceFlowNotifier extends StateNotifier<AttendanceFlowState> {
  final Ref _ref;

  AttendanceFlowNotifier(this._ref) : super(const AttendanceFlowState()) {
    // Initial silent location query
    refreshLocation();
  }

  /// Refreshes current GPS position and distance without triggering attendance submission.
  Future<LocationResult> refreshLocation() async {
    if (state.isLocationUpdating) {
      return state.locationResult ??
          LocationResult(
            latitude: 0,
            longitude: 0,
            distanceFromOfficeMeters: 9999,
            timestamp: DateTime(2000),
            status: LocationStatus.error,
          );
    }

    state = state.copyWith(isLocationUpdating: true);
    try {
      final locationService = _ref.read(locationServiceProvider);
      final result = await locationService.getCurrentLocation();
      state = state.copyWith(
        locationResult: result,
        isLocationUpdating: false,
        lastLocationUpdateTime: DateTime.now(),
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isLocationUpdating: false,
        message: 'تعذر تحديد الموقع الجغرافي حاليًا',
      );
      return LocationResult(
        latitude: 0,
        longitude: 0,
        distanceFromOfficeMeters: 9999,
        timestamp: DateTime.now(),
        status: LocationStatus.error,
      );
    }
  }

  /// Requests location permission from the device
  Future<bool> requestLocationPermission() async {
    final locationService = _ref.read(locationServiceProvider);
    final granted = await locationService.requestPermission();
    if (granted) {
      await refreshLocation();
    }
    return granted;
  }

  Future<bool> executeCheckIn() async {
    return _executeAttendanceAction(isCheckIn: true);
  }

  Future<bool> executeCheckOut() async {
    return _executeAttendanceAction(isCheckIn: false);
  }

  Future<bool> _executeAttendanceAction({required bool isCheckIn}) async {
    // Race Condition Prevention: ignore multiple rapid taps
    if (state.isLoading) return false;

    final locationService = _ref.read(locationServiceProvider);
    final biometricService = _ref.read(biometricServiceProvider);
    final attendanceRepo = _ref.read(attendanceRepositoryProvider);
    final connectivity = _ref.read(connectivityServiceProvider);
    final notifRepo = _ref.read(notificationsRepositoryProvider);
    final db = _ref.read(mockDatabaseProvider);
    final empId = db.session?.employeeId ?? db.employee.id;
    final summary = db.todaySummary;

    // 0. Validation: Session & Duplicate State
    if (isCheckIn && summary.hasCheckedIn) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: 'تم تسجيل الحضور لهذا اليوم مسبقًا.',
      );
      return false;
    }

    if (!isCheckIn && !summary.hasCheckedIn) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: 'لم يتم تسجيل الحضور بعد، لا يمكن تسجيل الانصراف.',
      );
      return false;
    }

    if (!isCheckIn && summary.hasCheckedOut) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: 'تم إكمال يوم العمل وتسجيل الانصراف مسبقًا.',
      );
      return false;
    }

    final isOnline = await connectivity.isConnected;

    // 1. Check Location & Accuracy & Staleness
    state = state.copyWith(
      processState: AttendanceProcessState.checkingLocation,
      message: 'جاري التحقق من الموقع الجغرافي والدقة والمسافة...',
      isOffline: !isOnline,
    );

    var locResult = await locationService.getCurrentLocation();
    // Stale location check: if older than 60s, refresh again
    if (locResult.isStale) {
      locResult = await locationService.getCurrentLocation();
    }

    state = state.copyWith(
      locationResult: locResult,
      lastLocationUpdateTime: DateTime.now(),
    );

    // Check Mock Location
    if (locResult.isMockLocation || locResult.status == LocationStatus.mockLocationDetected) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: 'تم رصد استخدام موقع وهمي (Mock Location). تم رفض العملية.',
      );
      return false;
    }

    // Check GPS Accuracy
    if (!locResult.isAccuracyValid || locResult.status == LocationStatus.lowAccuracy) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: 'دقة الموقع غير كافية (${locResult.accuracyMeters.toInt()} م). يرجى الانتقال لمكان مكشوف.',
      );
      return false;
    }

    // Check 4-meter Geofence
    if (!locResult.isInsideRange) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message:
            locResult.errorMessage ??
            'أنت خارج نطاق الشركة المسموح به (أقصى مسافة ${db.companyLocation.radiusMeters.toInt()} أمتار)',
      );
      return false;
    }

    // 2. Biometric Authentication
    state = state.copyWith(
      processState: AttendanceProcessState.authenticatingBiometric,
      message: 'يرجى تأكيد بصمة الإصبع أو Face ID...',
    );

    final bioResult = await biometricService.authenticate(
      reason: isCheckIn
          ? 'تأكيد الحضور ببصمة الموظف'
          : 'تأكيد الانصراف ببصمة الموظف',
    );

    if (bioResult != BiometricAuthResult.success) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: bioResult == BiometricAuthResult.cancelled
            ? 'تم إلغاء المصادقة البيومترية'
            : bioResult == BiometricAuthResult.notAvailable
                ? 'المصادقة البيومترية غير مفعلة على الجهاز'
                : 'فشلت المصادقة بالبصمة، يرجى المحاولة مجددًا',
      );
      return false;
    }

    // 3. Submit Attendance
    state = state.copyWith(
      processState: AttendanceProcessState.submitting,
      message: isOnline
          ? 'جاري تسجيل العملية...'
          : 'جاري الحفظ المحلي (وضع بدون اتصال)...',
    );

    if (isCheckIn) {
      await attendanceRepo.checkIn(
        employeeId: empId,
        workLocationId: db.companyLocation.id,
        latitude: locResult.latitude,
        longitude: locResult.longitude,
        accuracy: locResult.accuracyMeters,
        distance: locResult.distanceFromOfficeMeters,
        biometricVerified: true,
        isOffline: !isOnline,
      );
    } else {
      await attendanceRepo.checkOut(
        employeeId: empId,
        workLocationId: db.companyLocation.id,
        latitude: locResult.latitude,
        longitude: locResult.longitude,
        accuracy: locResult.accuracyMeters,
        distance: locResult.distanceFromOfficeMeters,
        biometricVerified: true,
        isOffline: !isOnline,
      );
    }

    // 4. Push In-App Notification
    await notifRepo.addNotification(
      AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: isCheckIn ? 'تسجيل الحضور' : 'تسجيل الانصراف',
        message: isOnline
            ? 'تم ${isCheckIn ? 'تسجيل الحضور' : 'تسجيل الانصراف'} بنجاح (${locResult.distanceFromOfficeMeters.toStringAsFixed(1)} م)'
            : 'تم الحفظ محليًا — سيتم المزامنة تلقائيًا',
        category: NotificationCategory.attendance,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    state = state.copyWith(
      processState: AttendanceProcessState.success,
      message: isOnline
          ? (isCheckIn ? 'تم تسجيل الحضور بنجاح!' : 'تم تسجيل الانصراف بنجاح!')
          : 'تم تسجيل الحضور بدون اتصال وسيتم المزامنة لاحقًا.',
    );

    return true;
  }

  /// Syncs offline pending records when connectivity is restored
  Future<int> syncPendingAttendance() async {
    state = state.copyWith(isSyncing: true);
    try {
      final attendanceRepo = _ref.read(attendanceRepositoryProvider);
      final count = await attendanceRepo.syncPendingAttendance();
      state = state.copyWith(
        isSyncing: false,
        message: count > 0
            ? 'تمت مزامنة $count سجلات بنجاح'
            : 'لا توجد سجلات معلقة للمزامنة',
      );
      return count;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        message: 'فشلت المزامنة، يرجى إعادة المحاولة',
      );
      return 0;
    }
  }

  void resetState() {
    state = const AttendanceFlowState();
  }
}

final attendanceFlowProvider =
    StateNotifierProvider<AttendanceFlowNotifier, AttendanceFlowState>((ref) {
      return AttendanceFlowNotifier(ref);
    });

/// Master 22-state machine determining the exact current UI & business state.
final attendanceStateProvider = Provider<AttendanceStateType>((ref) {
  final summary = ref.watch(attendanceSummaryProvider);
  final flowState = ref.watch(attendanceFlowProvider);
  final shiftStatus = ref.watch(workScheduleShiftStatusProvider);
  final demo = ref.watch(demoControlsProvider);

  // 1. Process / Action states
  if (flowState.processState == AttendanceProcessState.checkingLocation) {
    return AttendanceStateType.checkingLocation;
  }
  if (flowState.processState == AttendanceProcessState.authenticatingBiometric) {
    return AttendanceStateType.verifyingBiometric;
  }
  if (flowState.processState == AttendanceProcessState.submitting) {
    return summary.hasCheckedIn
        ? AttendanceStateType.checkingOut
        : AttendanceStateType.checkingIn;
  }
  if (flowState.processState == AttendanceProcessState.error) {
    return AttendanceStateType.error;
  }

  // 2. Completed State
  if (summary.hasCheckedOut) {
    return AttendanceStateType.workdayCompleted;
  }

  // 3. Checked In State
  if (summary.hasCheckedIn) {
    if (summary.checkIn?.isOffline == true) {
      return AttendanceStateType.offlinePendingSync;
    }
    return AttendanceStateType.checkedIn;
  }

  // 4. Location & Permissions Check
  final loc = flowState.locationResult;
  if (loc != null) {
    if (loc.isPermissionDenied || demo.locationMode == MockLocationMode.permissionDenied) {
      return AttendanceStateType.locationPermissionRequired;
    }
    if (loc.isGpsDisabled || demo.locationMode == MockLocationMode.gpsDisabled) {
      return AttendanceStateType.locationServiceDisabled;
    }
    if (loc.status == LocationStatus.locationUnavailable || loc.status == LocationStatus.error) {
      return AttendanceStateType.locationUnavailable;
    }
    if (!loc.isInsideRange) {
      return AttendanceStateType.outsideWorkplace;
    }
  }

  // 5. Shift Schedule Check
  if (shiftStatus.isBeforeShift) {
    return AttendanceStateType.beforeShift;
  }

  return AttendanceStateType.readyForCheckIn;
});

// ══════════════════════════════════════════════════════════════════
// 6. Requests (Advances / Permissions / Vacations)
// ══════════════════════════════════════════════════════════════════

final advancesRepositoryProvider = Provider<AdvancesRepository>((ref) {
  return MockAdvancesRepository(ref);
});

/// Advances — reactive: rebuilds when MockDatabase.advances changes.
final advancesListProvider = Provider<List<AdvanceRequest>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.advances.where((a) => a.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final permissionsRepositoryProvider = Provider<PermissionsRepository>((ref) {
  return MockPermissionsRepository(ref);
});

/// Permissions list — reactive.
final permissionsListProvider = Provider<List<PermissionRequest>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.permissions.where((p) => p.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final vacationsRepositoryProvider = Provider<VacationsRepository>((ref) {
  return MockVacationsRepository(ref);
});

/// Vacations list — reactive.
final vacationsListProvider = Provider<List<VacationRequest>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.vacations.where((v) => v.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  final adv = ref.watch(advancesRepositoryProvider);
  final perm = ref.watch(permissionsRepositoryProvider);
  final vac = ref.watch(vacationsRepositoryProvider);
  return MockRequestsRepository(
    advancesRepo: adv,
    permissionsRepo: perm,
    vacationsRepo: vac,
  );
});

/// Unified requests list — reactive, sorted by date descending.
final allRequestsProvider = Provider<List<UnifiedRequestItem>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  final isArabic = ref.watch(settingsProvider).locale.languageCode == 'ar';

  final list = <UnifiedRequestItem>[
    ...db.advances
        .where((a) => a.employeeId == empId)
        .map((a) => UnifiedRequestItem.fromAdvance(a, isArabic)),
    ...db.permissions
        .where((p) => p.employeeId == empId)
        .map((p) => UnifiedRequestItem.fromPermission(p, isArabic)),
    ...db.vacations
        .where((v) => v.employeeId == empId)
        .map((v) => UnifiedRequestItem.fromVacation(v, isArabic)),
  ];
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});

// ══════════════════════════════════════════════════════════════════
// 7. Notifications — reactive, direct from MockDatabase
// ══════════════════════════════════════════════════════════════════

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return MockNotificationsRepository(ref);
});

/// All notifications sorted newest first.
final notificationsListProvider = Provider<List<AppNotification>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  return db.notifications.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Unread count — drives the badge on the bottom nav.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(mockDatabaseProvider).unreadNotificationsCount;
});

// ══════════════════════════════════════════════════════════════════
// 8. Deductions & HR Messages
// ══════════════════════════════════════════════════════════════════

final deductionRepositoryProvider = Provider<DeductionRepository>((ref) {
  return MockDeductionRepository(ref);
});

final deductionsListProvider = Provider<List<Deduction>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.deductions.where((d) => d.employeeId == empId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final hrMessageRepositoryProvider = Provider<HRMessageRepository>((ref) {
  return MockHRMessageRepository(ref);
});

final hrMessagesListProvider = Provider<List<HRMessage>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.hrMessages.where((m) => m.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

// ══════════════════════════════════════════════════════════════════
// 9. Settings Provider
// ══════════════════════════════════════════════════════════════════

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorage _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final themeStr = _storage.getString(AppConstants.keyThemeMode);
    final localeStr = _storage.getString(AppConstants.keyLocale);

    ThemeMode mode = ThemeMode.system;
    if (themeStr == 'light') mode = ThemeMode.light;
    if (themeStr == 'dark') mode = ThemeMode.dark;

    Locale loc = const Locale('ar');
    if (localeStr == 'en') loc = const Locale('en');

    state = state.copyWith(themeMode: mode, locale: loc);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _storage.setString(AppConstants.keyThemeMode, val);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _storage.setString(AppConstants.keyLocale, locale.languageCode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final storage = ref.watch(localStorageProvider);
  return SettingsNotifier(storage);
});
