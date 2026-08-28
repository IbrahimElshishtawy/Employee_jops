import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/core/widgets/app_button.dart';
import 'package:employee_setup/core/widgets/app_logo.dart';
import 'package:employee_setup/core/widgets/app_text_field.dart';
import 'package:employee_setup/features/auth/presentation/screens/login_screen.dart';
import 'package:employee_setup/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:employee_setup/features/onboarding/presentation/screens/personal_info_screen.dart';
import 'package:employee_setup/features/onboarding/presentation/screens/review_screen.dart';
import 'package:employee_setup/features/onboarding/presentation/screens/work_info_screen.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/selection_field.dart';
import 'package:employee_setup/features/onboarding/presentation/widgets/verified_field.dart';
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

      // Check App Name Branding text
      expect(find.text('CyberWise IE'), findsOneWidget);

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
      expect(find.text('CyberWise IE'), findsOneWidget);
      expect(find.textContaining('Google'), findsAtLeastNWidgets(1));
      expect(find.textContaining('دخول آمن'), findsOneWidget);
    });

    testWidgets('PersonalInfoScreen (Step 1) renders editable name, read-only email, and phone input',
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
      expect(find.text('Basic Information'), findsOneWidget);

      // AppTextFields (Full Name and Phone Number)
      expect(find.byType(AppTextField), findsNWidgets(2));

      // Verified Read-Only Email
      expect(find.byType(VerifiedField), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);

      // Continue Button
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('WorkInfoScreen (Step 2) renders 2 selection fields (Job Title & Department)',
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
      expect(find.text('Job & Department'), findsOneWidget);

      // 2 Selection Fields (Job Title and Department)
      expect(find.byType(SelectionField), findsNWidgets(2));

      // Continue button
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('ReviewScreen (Step 3) renders all review sections, edit buttons, and confirm button',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const ReviewScreen(),
          locale: const Locale('en'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // OnboardingHeader
      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      expect(find.text('Review & Confirm'), findsOneWidget);

      // Edit buttons for sections
      expect(find.text('Edit'), findsNWidgets(2));

      // Confirm & Continue Button
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Confirm & Continue'), findsOneWidget);
    });
  });
}
