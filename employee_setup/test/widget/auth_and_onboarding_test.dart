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
import 'package:shared_preferences/shared_preferences.dart';

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
      SharedPreferences.setMockInitialValues({});
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

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('CyberWise IE'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
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

      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 1 OF 3'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.byType(VerifiedField), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('WorkInfoScreen (Step 2) renders Job Title & Department selection in English LTR',
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

      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('Job & Department'), findsOneWidget);
      expect(find.text('Job Title'), findsOneWidget);
      expect(find.text('Select job title'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Select department'), findsOneWidget);
      expect(find.byType(SelectionField), findsNWidgets(2));
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('WorkInfoScreen (Step 2) renders in Arabic RTL with correct Arabic strings',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkInfoScreen(),
          locale: const Locale('ar'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('الخطوة 2 من 3'), findsOneWidget);
      expect(find.text('المسمى الوظيفي والقسم'), findsOneWidget);
      expect(find.text('المسمى الوظيفي'), findsOneWidget);
      expect(find.text('اختر المسمى الوظيفي'), findsOneWidget);
      expect(find.text('القسم / الإدارة'), findsOneWidget);
      expect(find.text('اختر القسم'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
    });

    testWidgets('WorkInfoScreen (Step 2) validation blocks empty continue and displays error message',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkInfoScreen(),
          locale: const Locale('ar'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Continue without making any selections
      final continueButton = find.widgetWithText(AppButton, 'متابعة');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Should show validation error for Job Title
      expect(find.text('من فضلك اختر المسمى الوظيفي'), findsWidgets);
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

      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      expect(find.text('Review & Confirm'), findsOneWidget);
      expect(find.text('Edit'), findsNWidgets(2));
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Confirm & Continue'), findsOneWidget);
    });
  });
}
