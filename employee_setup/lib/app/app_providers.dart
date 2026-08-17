import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/mock_connectivity_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/shared_prefs_storage.dart';

import '../features/advances/data/repositories/mock_advances_repository.dart';
import '../features/advances/domain/models/advance_request.dart';
import '../features/advances/domain/models/expense_report.dart';
import '../features/advances/domain/repositories/advances_repository.dart';

import '../features/attendance/data/repositories/mock_attendance_repository.dart';
import '../features/attendance/data/services/mock_biometric_service.dart';
import '../features/attendance/data/services/mock_location_service.dart';
import '../features/attendance/domain/models/attendance.dart';
import '../features/attendance/domain/models/location_result.dart';
import '../features/attendance/domain/repositories/attendance_repository.dart';
import '../features/attendance/domain/services/biometric_service.dart';
import '../features/attendance/domain/services/location_service.dart';

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

import '../features/requests/data/repositories/mock_requests_repository.dart';
import '../features/requests/domain/models/unified_request.dart';
import '../features/requests/domain/repositories/requests_repository.dart';

import '../features/settings/domain/models/app_settings.dart';
import '../features/settings/domain/models/demo_controls.dart';
import '../features/vacations/data/repositories/mock_vacations_repository.dart';
import '../features/vacations/domain/models/vacation_request.dart';
import '../features/vacations/domain/repositories/vacations_repository.dart';

// ==========================================
// 1. Core Service Providers
// ==========================================
final localStorageProvider = Provider<LocalStorage>((ref) {
  return SharedPrefsStorage();
});

final mockConnectivityServiceProvider = Provider<MockConnectivityService>((ref) {
  final service = MockConnectivityService(initialConnected: true);
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ref.watch(mockConnectivityServiceProvider);
});

// ==========================================
// 2. Demo Controls Provider
// ==========================================
class DemoControlsNotifier extends StateNotifier<DemoControlsState> {
  final Ref _ref;

  DemoControlsNotifier(this._ref) : super(const DemoControlsState());

  void setLocationMode(MockLocationMode mode, [double? distance]) {
    state = state.copyWith(
      locationMode: mode,
      simulatedDistance: distance ?? (mode == MockLocationMode.insideRange ? 2.3 : 48.5),
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
    await _ref.read(attendanceRepositoryProvider).resetToDefaultMock();
    await _ref.read(advancesRepositoryProvider).resetToDefaultMock();
    await _ref.read(permissionsRepositoryProvider).resetToDefaultMock();
    await _ref.read(vacationsRepositoryProvider).resetToDefaultMock();
    await _ref.read(notificationsRepositoryProvider).resetToDefaultMock();

    setLocationMode(MockLocationMode.insideRange, 2.3);
    setBiometricMode(MockBiometricMode.alwaysSuccess);
    setNetworkOnline(true);

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

// ==========================================
// 3. Location & Biometrics Services
// ==========================================
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

// ==========================================
// 4. Auth & Employee Providers
// ==========================================
final authDataSourceProvider = Provider<MockAuthDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return MockAuthDataSource(storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final ds = ref.watch(authDataSourceProvider);
  return MockAuthRepository(ds);
});

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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final currentEmployeeProvider = Provider<Employee?>((ref) {
  return ref.watch(authProvider).employee;
});

// ==========================================
// 5. Attendance Providers
// ==========================================
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return MockAttendanceRepository(storage);
});

final attendanceSummaryProvider =
    FutureProvider.autoDispose<TodayAttendanceSummary>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getTodayStatus(empId);
});

final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getHistory(empId);
});

// Attendance Action State & Controller
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

  const AttendanceFlowState({
    this.processState = AttendanceProcessState.idle,
    this.locationResult,
    this.message,
    this.isOffline = false,
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
  }) {
    return AttendanceFlowState(
      processState: processState ?? this.processState,
      locationResult: locationResult ?? this.locationResult,
      message: message,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class AttendanceFlowNotifier extends StateNotifier<AttendanceFlowState> {
  final Ref _ref;

  AttendanceFlowNotifier(this._ref) : super(const AttendanceFlowState());

  Future<bool> executeCheckIn() async {
    return _executeAttendanceAction(isCheckIn: true);
  }

  Future<bool> executeCheckOut() async {
    return _executeAttendanceAction(isCheckIn: false);
  }

  Future<bool> _executeAttendanceAction({required bool isCheckIn}) async {
    final locationService = _ref.read(locationServiceProvider);
    final biometricService = _ref.read(biometricServiceProvider);
    final attendanceRepo = _ref.read(attendanceRepositoryProvider);
    final connectivity = _ref.read(connectivityServiceProvider);
    final notifRepo = _ref.read(notificationsRepositoryProvider);
    final emp = _ref.read(currentEmployeeProvider);
    final empId = emp?.id ?? AppConstants.mockEmployeeId;

    final isOnline = await connectivity.isConnected;

    // 1. Check Location
    state = state.copyWith(
      processState: AttendanceProcessState.checkingLocation,
      message: 'جاري التحقق من الموقع الجغرافي...',
      isOffline: !isOnline,
    );

    final locResult = await locationService.getCurrentLocation();
    state = state.copyWith(locationResult: locResult);

    if (!locResult.isInsideRange) {
      String err = locResult.errorMessage ?? 'أنت خارج نطاق الشركة المسموح به (أقصى مسافة 4 أمتار)';
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: err,
      );
      return false;
    }

    // 2. Biometric Authentication
    state = state.copyWith(
      processState: AttendanceProcessState.authenticatingBiometric,
      message: 'يرجى تأكيد بصمة الإصبع أو الوجه...',
    );

    final bioResult = await biometricService.authenticate(
      reason: isCheckIn ? 'تأكيد الحضور ببصمة الموظف' : 'تأكيد الانصراف ببصمة الموظف',
    );

    if (bioResult != BiometricAuthResult.success) {
      String bioErr = bioResult == BiometricAuthResult.cancelled
          ? 'تم إلغاء المصادقة البيومترية'
          : 'فشلت المصادقة البيومترية، يرجى المحاولة مجددًا';
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        message: bioErr,
      );
      return false;
    }

    // 3. Submit Attendance
    state = state.copyWith(
      processState: AttendanceProcessState.submitting,
      message: isOnline ? 'جاري تسجيل العملية...' : 'جاري الحفظ المحلي (وضع بدون اتصال)...',
    );

    if (isCheckIn) {
      await attendanceRepo.checkIn(
        employeeId: empId,
        latitude: locResult.latitude,
        longitude: locResult.longitude,
        distance: locResult.distanceFromOfficeMeters,
        biometricVerified: true,
        isOffline: !isOnline,
      );
    } else {
      await attendanceRepo.checkOut(
        employeeId: empId,
        latitude: locResult.latitude,
        longitude: locResult.longitude,
        distance: locResult.distanceFromOfficeMeters,
        biometricVerified: true,
        isOffline: !isOnline,
      );
    }

    // Add immediate notification
    await notifRepo.addNotification(
      AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: isCheckIn ? 'تسجيل الحضور الذاتي' : 'تسجيل الانصراف الذاتي',
        message: isOnline
            ? 'تم ${isCheckIn ? 'تسجيل الحضور' : 'تسجيل الانصراف'} بنجاح داخل النطاق (${locResult.distanceFromOfficeMeters.toStringAsFixed(1)} م)'
            : 'تم حفظ عملية ${isCheckIn ? 'الحضور' : 'الانصراف'} محليًا لعدم وجود اتصال (في انتظار مراجعة HR).',
        category: NotificationCategory.attendance,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    // Invalidate queries to refresh UI
    _ref.invalidate(attendanceSummaryProvider);
    _ref.invalidate(attendanceHistoryProvider);
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(unreadNotificationsCountProvider);

    state = state.copyWith(
      processState: AttendanceProcessState.success,
      message: isOnline
          ? (isCheckIn ? 'تم تسجيل الحضور بنجاح!' : 'تم تسجيل الانصراف بنجاح!')
          : 'تم الحفظ محليًا - في انتظار مراجعة الـ HR',
    );

    return true;
  }

  void resetState() {
    state = const AttendanceFlowState();
  }
}

final attendanceFlowProvider =
    StateNotifierProvider<AttendanceFlowNotifier, AttendanceFlowState>((ref) {
  return AttendanceFlowNotifier(ref);
});

// ==========================================
// 6. Requests (Advances, Permissions, Vacations)
// ==========================================
final advancesRepositoryProvider = Provider<AdvancesRepository>((ref) {
  return MockAdvancesRepository();
});

final advancesListProvider =
    FutureProvider.autoDispose<List<AdvanceRequest>>((ref) async {
  final repo = ref.watch(advancesRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getAdvances(empId);
});

final permissionsRepositoryProvider = Provider<PermissionsRepository>((ref) {
  return MockPermissionsRepository();
});

final permissionsListProvider =
    FutureProvider.autoDispose<List<PermissionRequest>>((ref) async {
  final repo = ref.watch(permissionsRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getPermissions(empId);
});

final vacationsRepositoryProvider = Provider<VacationsRepository>((ref) {
  return MockVacationsRepository();
});

final vacationsListProvider =
    FutureProvider.autoDispose<List<VacationRequest>>((ref) async {
  final repo = ref.watch(vacationsRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getVacations(empId);
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

final allRequestsProvider =
    FutureProvider.autoDispose<List<UnifiedRequestItem>>((ref) async {
  final repo = ref.watch(requestsRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final settings = ref.watch(settingsProvider);
  final isArabic = settings.locale.languageCode == 'ar';
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getAllRequests(empId, isArabic);
});

// ==========================================
// 7. Notifications Providers
// ==========================================
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return MockNotificationsRepository(storage);
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getNotifications(empId);
});

final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final emp = ref.watch(currentEmployeeProvider);
  final empId = emp?.id ?? AppConstants.mockEmployeeId;
  return repo.getUnreadCount(empId);
});

// ==========================================
// 8. Settings Provider
// ==========================================
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

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SettingsNotifier(storage);
});
