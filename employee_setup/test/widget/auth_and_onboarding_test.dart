import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/core/widgets/app_button.dart';
import 'package:employee_setup/core/widgets/app_logo.dart';
import 'package:employee_setup/features/auth/presentation/screens/login_screen.dart';
import 'package:employee_setup/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:employee_setup/features/onboarding/presentation/screens/personal_info_screen.dart';
import 'package:employee_setup/features/onboarding/presentation/screens/work_info_screen.dart';
import 'package:employee_setup/features/onboarding/presentation/screens/work_location_screen.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/hr_contact_card.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/location_permission_card.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/selection_field.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/verified_field.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/workplace_card.dart';
import 'package:employee_setup/features/attendance/data/services/mock_biometric_service.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('Auth & Onboarding UI/UX Tests', () {
    late SharedPrefsStorage storage;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();
    });

    testWidgets('LoginScreen renders logo, header, Google button, security badge',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const LoginScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppLogo
      expect(find.byType(AppLogo), findsOneWidget);

      // Check Welcome text
      expect(find.text('Welcome Back'), findsOneWidget);

      // Check Google Sign-In Button
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Check Security badge
      expect(find.text('Secure employee access'), findsOneWidget);
    });

    testWidgets('LoginScreen renders properly in Arabic RTL and Dark Mode',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const LoginScreen(),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.textContaining('مرحب'), findsOneWidget);
      expect(find.textContaining('Google'), findsAtLeastNWidgets(1));
      expect(find.textContaining('دخول آمن'), findsOneWidget);
    });

    testWidgets('PersonalInfoScreen (Step 1) renders all components and verified fields',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const PersonalInfoScreen(),
          locale: const Locale('en'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // OnboardingHeader
      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 1 OF 3'), findsOneWidget);
      expect(find.text('Confirm your information'), findsOneWidget);

      // Verified Fields (Full Name and Email)
      expect(find.byType(VerifiedField), findsNWidgets(2));
      expect(find.text('Google'), findsNWidgets(2));

      // Continue Button
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('WorkInfoScreen (Step 2) renders 4 selection fields and progress step 2',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkInfoScreen(),
          locale: const Locale('en'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // OnboardingHeader
      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('Your work information'), findsOneWidget);

      // 4 Selection Fields
      expect(find.byType(SelectionField), findsNWidgets(4));

      // Continue button
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('WorkLocationScreen (Step 3) renders WorkplaceCard, LocationPermissionCard, HrContactCard',
        (tester) async {
      final locService = MockLocationService(
        mode: MockLocationMode.insideRange,
        customDistance: 2.5,
      );
      final bioService = MockBiometricService(
        mode: MockBiometricMode.alwaysSuccess,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkLocationScreen(),
          locale: const Locale('en'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            mockLocationServiceProvider.overrideWithValue(locService),
            mockBiometricServiceProvider.overrideWithValue(bioService),
          ],
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // OnboardingHeader
      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      expect(find.text('Your workplace'), findsOneWidget);

      // WorkplaceCard
      expect(find.byType(WorkplaceCard), findsOneWidget);
      expect(find.text('Workplace assigned'), findsOneWidget);

      // LocationPermissionCard
      expect(find.byType(LocationPermissionCard), findsOneWidget);

      // HrContactCard
      expect(find.byType(HrContactCard), findsOneWidget);

      // Complete Setup button
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);
    });
  });
}
