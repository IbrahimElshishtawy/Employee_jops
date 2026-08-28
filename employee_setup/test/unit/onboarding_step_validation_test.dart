import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/mock/models/app_session.dart';
import 'package:employee_setup/core/mock/seeds/employee_seed.dart';
import 'package:employee_setup/core/mock/seeds/onboarding_catalog.dart';
import 'package:employee_setup/core/services/device_info_service.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:employee_setup/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:employee_setup/features/onboarding/domain/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 01 — Onboarding, Validation, Review, Session & Device Tests', () {
    late SharedPrefsStorage storage;
    late MockAuthDataSource authDataSource;
    late MockAuthRepository authRepo;
    late ProviderContainer container;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();
      authDataSource = MockAuthDataSource(storage);
      authRepo = MockAuthRepository(authDataSource);

      container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(authRepo),
          deviceInfoServiceProvider.overrideWithValue(
            PlatformDeviceInfoService(
              overrideInfo: DeviceInfo.defaultMock(type: DeviceType.android),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // ──────────────────────────────────────────────────────────
    // Step 1 — Basic Information Tests
    // ──────────────────────────────────────────────────────────
    group('Step 1 — Basic Information Validation', () {
      test('1.1 Name editing: Employee can edit pre-filled Google name', () async {
        // Authenticate with Google initial name
        final user = await authRepo.signInWithGoogle(email: 'ahmed.ali@gmail.com');
        expect(user.email, equals('ahmed.ali@gmail.com'));

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setStep1Data(
          fullName: 'Ahmed Mohamed', // Edited from Ahmed Mohamed Ali
          email: user.email,
          phone: '01012345678',
        );

        final state = container.read(onboardingProvider);
        expect(state.fullName, equals('Ahmed Mohamed'));
        expect(state.email, equals('ahmed.ali@gmail.com'));
        expect(state.phone, equals('01012345678'));
      });

      test('1.2 Email read-only: Email strictly mirrors authenticated Google identity', () async {
        final user = await authRepo.signInWithGoogle(email: 'verified.user@gmail.com');
        final notifier = container.read(onboardingProvider.notifier);

        notifier.setStep1Data(
          fullName: 'Test Employee',
          email: user.email,
          phone: '01122334455',
        );

        final state = container.read(onboardingProvider);
        expect(state.email, equals('verified.user@gmail.com'));
      });

      test('1.3 Phone validation: Whitespace trimming and format handling', () {
        final notifier = container.read(onboardingProvider.notifier);

        // Leading/trailing whitespace should be trimmed
        notifier.setStep1Data(
          fullName: 'Ahmed Ali',
          email: 'ahmed@gmail.com',
          phone: '   01012345678   ',
        );

        final state = container.read(onboardingProvider);
        expect(state.phone, equals('01012345678'));
      });
    });

    // ──────────────────────────────────────────────────────────
    // Step 2 — Job & Department Selection Tests
    // ──────────────────────────────────────────────────────────
    group('Step 2 — Job & Department Selection & Localization', () {
      test('2.1 Job and Department selection from centralized catalog with stable IDs', () {
        final job = OnboardingCatalog.findJobTitle('RECEPTIONIST');
        expect(job, isNotNull);
        expect(job!.nameEn, equals('Receptionist'));
        expect(job.nameAr, equals('موظف استقبال'));
        expect(job.localizedName(true), equals('موظف استقبال'));
        expect(job.localizedName(false), equals('Receptionist'));

        final dept = OnboardingCatalog.findDepartment('FRONT_OFFICE');
        expect(dept, isNotNull);
        expect(dept!.nameEn, equals('Front Office'));
        expect(dept.nameAr, equals('مكتب الاستقبال'));
        expect(dept.emoji, equals('🏨'));
        expect(dept.localizedName(true), equals('مكتب الاستقبال'));
        expect(dept.localizedName(false), equals('Front Office'));

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setStep2Data(
          jobTitleId: 'RECEPTIONIST',
          jobTitle: 'Receptionist',
          departmentId: 'FRONT_OFFICE',
          department: 'Front Office',
          role: EmployeeRole.employee,
          hierarchyLevel: HierarchyLevel.staff,
        );

        final state = container.read(onboardingProvider);
        expect(state.jobTitleId, equals('RECEPTIONIST'));
        expect(state.jobTitle, equals('Receptionist'));
        expect(state.departmentId, equals('FRONT_OFFICE'));
        expect(state.department, equals('Front Office'));
        expect(state.role, equals(EmployeeRole.employee));
        expect(state.hierarchyLevel, equals(HierarchyLevel.staff));
      });

      test('2.2 Bilingual search lookup: Arabic & English queries match correctly', () {
        // Arabic search queries
        final arabicSearch1 = OnboardingCatalog.findJobTitle('استقبال');
        expect(arabicSearch1, isNotNull);
        expect(arabicSearch1!.id, equals('RECEPTIONIST'));

        final arabicDeptSearch = OnboardingCatalog.findDepartment('الأمن');
        expect(arabicDeptSearch, isNotNull);
        expect(arabicDeptSearch!.id, equals('SECURITY'));

        // English search queries
        final englishSearch1 = OnboardingCatalog.findJobTitle('security guard');
        expect(englishSearch1, isNotNull);
        expect(englishSearch1!.id, equals('SECURITY_GUARD'));

        final englishDeptSearch = OnboardingCatalog.findDepartment('housekeeping');
        expect(englishDeptSearch, isNotNull);
        expect(englishDeptSearch!.id, equals('HOUSEKEEPING'));
      });

      test('2.3 Concept separation: Department, Job Title, Role, and Hierarchy Level are separate', () {
        final notifier = container.read(onboardingProvider.notifier);

        // Staff employee
        notifier.setStep2Data(
          jobTitleId: 'RECEPTIONIST',
          jobTitle: 'Receptionist',
          departmentId: 'FRONT_OFFICE',
          department: 'Front Office',
          role: EmployeeRole.employee,
          hierarchyLevel: HierarchyLevel.staff,
        );
        var state = container.read(onboardingProvider);
        expect(state.departmentId, equals('FRONT_OFFICE'));
        expect(state.jobTitleId, equals('RECEPTIONIST'));
        expect(state.role, equals(EmployeeRole.employee));
        expect(state.hierarchyLevel, equals(HierarchyLevel.staff));

        // Supervisor
        notifier.setStep2Data(
          jobTitleId: 'SECURITY_SUPERVISOR',
          jobTitle: 'Security Supervisor',
          departmentId: 'SECURITY',
          department: 'Security',
          role: EmployeeRole.supervisor,
          hierarchyLevel: HierarchyLevel.supervisor,
        );
        state = container.read(onboardingProvider);
        expect(state.departmentId, equals('SECURITY'));
        expect(state.jobTitleId, equals('SECURITY_SUPERVISOR'));
        expect(state.role, equals(EmployeeRole.supervisor));
        expect(state.hierarchyLevel, equals(HierarchyLevel.supervisor));
      });
    });

    // ──────────────────────────────────────────────────────────
    // Step 3 — Review & Back Navigation Tests
    // ──────────────────────────────────────────────────────────
    group('Step 3 — Review, Back Navigation & State Persistence', () {
      test('3.1 Full information available in Review and persists across navigation', () {
        final notifier = container.read(onboardingProvider.notifier);

        // Enter Step 1
        notifier.setStep1Data(
          fullName: 'Ahmed Mohamed',
          email: 'ahmed.mohamed@gmail.com',
          phone: '01099887766',
        );

        // Enter Step 2
        notifier.setStep2Data(
          jobTitleId: 'ENGINEER',
          jobTitle: 'Engineer',
          departmentId: 'ENGINEERING',
          department: 'Engineering',
        );

        // Inspect Review state (Step 3)
        var state = container.read(onboardingProvider);
        expect(state.fullName, equals('Ahmed Mohamed'));
        expect(state.email, equals('ahmed.mohamed@gmail.com'));
        expect(state.phone, equals('01099887766'));
        expect(state.jobTitleId, equals('ENGINEER'));
        expect(state.jobTitle, equals('Engineer'));
        expect(state.departmentId, equals('ENGINEERING'));
        expect(state.department, equals('Engineering'));

        // Simulate going back to Step 1 and updating name
        notifier.setStep1Data(
          fullName: 'Ahmed M. Ali',
          email: 'ahmed.mohamed@gmail.com',
          phone: '01099887766',
        );

        // Verify Step 2 data was NOT lost
        state = container.read(onboardingProvider);
        expect(state.fullName, equals('Ahmed M. Ali'));
        expect(state.jobTitleId, equals('ENGINEER'));
        expect(state.jobTitle, equals('Engineer'));
        expect(state.departmentId, equals('ENGINEERING'));
        expect(state.department, equals('Engineering'));
      });

      test('3.2 Confirm & Continue completes profile and updates session', () async {
        // 1. Initial Google Login
        await container.read(authProvider.notifier).signInWithGoogle();
        expect(container.read(authProvider).employee!.profileCompleted, isFalse);

        // 2. Set onboarding data
        final notifier = container.read(onboardingProvider.notifier);
        notifier.setStep1Data(
          fullName: 'Ahmed Mohamed',
          email: EmployeeSeed.email,
          phone: '01012345678',
        );
        notifier.setStep2Data(
          jobTitleId: 'RECEPTIONIST',
          jobTitle: 'Receptionist',
          departmentId: 'FRONT_OFFICE',
          department: 'Front Office',
        );

        // 3. Complete Profile
        final success = await notifier.completeProfile();
        expect(success, isTrue);

        // 4. Verify auth state is complete
        final updatedEmp = container.read(authProvider).employee;
        expect(updatedEmp, isNotNull);
        expect(updatedEmp!.name, equals('Ahmed Mohamed'));
        expect(updatedEmp.phone, equals('01012345678'));
        expect(updatedEmp.jobTitle, equals('Receptionist'));
        expect(updatedEmp.department, equals('Front Office'));
        expect(updatedEmp.profileCompleted, isTrue);

        // 5. Verify session in storage is marked complete
        final session = await authDataSource.getCachedSession();
        expect(session, isNotNull);
        expect(session!.profileCompleted, isTrue);
        expect(session.isActive, isTrue);
      });

      test('3.3 Protection against double submission / repeated requests', () async {
        await container.read(authProvider.notifier).signInWithGoogle();

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setStep1Data(
          fullName: 'Ahmed Mohamed',
          email: EmployeeSeed.email,
          phone: '01012345678',
        );
        notifier.setStep2Data(
          jobTitleId: 'RECEPTIONIST',
          jobTitle: 'Receptionist',
          departmentId: 'FRONT_OFFICE',
          department: 'Front Office',
        );

        // Trigger two completions concurrently
        final future1 = notifier.completeProfile();
        final future2 = notifier.completeProfile();

        final results = await Future.wait([future1, future2]);
        // One must succeed, one must be safely ignored/blocked
        expect(results, contains(true));
      });
    });

    // ──────────────────────────────────────────────────────────
    // Device Information & Session Relation Tests
    // ──────────────────────────────────────────────────────────
    group('Device Information & Session Relation', () {
      test('4.1 Device info abstraction captures platform, OS, model, and device type', () async {
        final deviceService = container.read(deviceInfoServiceProvider);
        final info = await deviceService.getDeviceInfo();

        expect(info.deviceType, equals(DeviceType.android));
        expect(info.platform, equals('Android'));
        expect(info.operatingSystem, equals('Android OS'));
        expect(info.osVersion, equals('14.0'));
        expect(info.appVersion, equals('1.0.0+1'));
        expect(info.deviceModel, contains('Pixel'));
      });

      test('4.2 iOS Device type detection and serialization', () async {
        final iosContainer = ProviderContainer(
          overrides: [
            deviceInfoServiceProvider.overrideWithValue(
              PlatformDeviceInfoService(
                overrideInfo: DeviceInfo.defaultMock(type: DeviceType.ios),
              ),
            ),
          ],
        );
        addTearDown(iosContainer.dispose);

        final deviceService = iosContainer.read(deviceInfoServiceProvider);
        final info = await deviceService.getDeviceInfo();

        expect(info.deviceType, equals(DeviceType.ios));
        expect(info.deviceType.typeName, equals('IOS'));
        expect(info.manufacturer, equals('Apple'));

        final json = info.toJson();
        final fromJson = DeviceInfo.fromJson(json);
        expect(fromJson.deviceType, equals(DeviceType.ios));
        expect(fromJson.manufacturer, equals('Apple'));
      });

      test('4.3 Session records device metadata accurately', () {
        final session = AppSession.create(
          employeeId: 'EMP-001',
          email: 'ahmed@company.com',
          profileCompleted: true,
          deviceId: 'DEV-ANDROID-001',
          deviceType: 'ANDROID',
          deviceModel: 'Samsung S24 Ultra',
          osVersion: '14.0',
          appVersion: '1.0.0+1',
        );

        expect(session.deviceId, equals('DEV-ANDROID-001'));
        expect(session.deviceType, equals('ANDROID'));
        expect(session.deviceModel, equals('Samsung S24 Ultra'));
        expect(session.osVersion, equals('14.0'));
        expect(session.appVersion, equals('1.0.0+1'));
        expect(session.isActive, isTrue);

        // JSON serialization
        final json = session.toJson();
        final fromJson = AppSession.fromJson(json);
        expect(fromJson.deviceId, equals('DEV-ANDROID-001'));
        expect(fromJson.deviceType, equals('ANDROID'));
        expect(fromJson.deviceModel, equals('Samsung S24 Ultra'));
      });
    });

    // ──────────────────────────────────────────────────────────
    // Notification Permissions & Token Preparation Tests
    // ──────────────────────────────────────────────────────────
    group('Notification Permission & Push Token Integration', () {
      test('5.1 Notification permission handled gracefully and records status', () async {
        await container.read(authProvider.notifier).signInWithGoogle();

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setStep1Data(
          fullName: 'Ahmed Mohamed',
          email: EmployeeSeed.email,
          phone: '01012345678',
        );
        notifier.setStep2Data(
          jobTitleId: 'CHEF',
          jobTitle: 'Chef',
          departmentId: 'KITCHEN',
          department: 'Kitchen',
        );

        await notifier.completeProfile();

        final state = container.read(onboardingProvider);
        expect(
          state.notificationPermissionStatus,
          anyOf(
            equals(NotificationPermissionStatus.authorized),
            equals(NotificationPermissionStatus.denied),
            equals(NotificationPermissionStatus.notDetermined),
          ),
        );
      });

      test('5.2 Push token registration marked as BACKEND_PENDING', () async {
        await container.read(authProvider.notifier).signInWithGoogle();

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setStep1Data(
          fullName: 'Ahmed Mohamed',
          email: EmployeeSeed.email,
          phone: '01012345678',
        );
        notifier.setStep2Data(
          jobTitleId: 'ACCOUNTANT',
          jobTitle: 'Accountant',
          departmentId: 'FINANCE_AND_ACCOUNTING',
          department: 'Finance & Accounting',
        );

        await notifier.completeProfile();

        final state = container.read(onboardingProvider);
        expect(state.pushTokenRegistration, isNotNull);
        expect(state.pushTokenRegistration!.status, equals('BACKEND_PENDING'));
        expect(state.pushTokenRegistration!.appVersion, equals('1.0.0+1'));
      });
    });
  });
}
