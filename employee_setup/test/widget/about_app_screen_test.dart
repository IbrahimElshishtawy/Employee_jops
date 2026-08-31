import 'package:employee_setup/core/constants/app_constants.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/features/settings/presentation/screens/about_app_screen.dart';
import 'package:employee_setup/features/settings/presentation/widgets/about_action_tile.dart';
import 'package:employee_setup/features/settings/presentation/widgets/about_feature_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildAboutTestApp({
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
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
      home: const AboutAppScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = SharedPrefsStorage();
    await storage.init();
  });

  group('AboutAppScreen Widget Tests', () {
    testWidgets('renders correctly in Arabic (RTL)', (WidgetTester tester) async {
      await tester.pumpWidget(_buildAboutTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify Screen and App Name
      expect(find.byType(AboutAppScreen), findsOneWidget);
      expect(find.text(AppConstants.appName), findsWidgets);

      // Verify Feature Items
      expect(find.byType(AboutFeatureItem), findsNWidgets(5));
      expect(find.text('تسجيل الحضور والانصراف'), findsOneWidget);
      expect(find.text('طلبات الموظفين'), findsOneWidget);
      expect(find.text('التواصل مع الموارد البشرية'), findsOneWidget);
      expect(find.text('التنبيهات والإشعارات'), findsOneWidget);
      expect(find.text('الملف الشخصي والبيانات'), findsOneWidget);

      // Verify Support and Legal Action Tiles
      expect(find.byType(AboutActionTile), findsWidgets);
      expect(find.text('مركز المساعدة'), findsOneWidget);
      expect(find.text('سياسة الخصوصية'), findsOneWidget);
      expect(find.text('شروط الاستخدام'), findsOneWidget);
      expect(find.text('تراخيص المصادر المفتوحة'), findsOneWidget);
    });

    testWidgets('renders correctly in English (LTR) and Dark Mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildAboutTestApp(
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AboutAppScreen), findsOneWidget);
      expect(find.text('About App'), findsWidgets);
      expect(find.text('Employee Management & HR Platform'), findsWidgets);

      // Verify Features in English
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Employee Requests'), findsOneWidget);
      expect(find.text('HR Communication'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Legal in English
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);
    });

    testWidgets('opens Privacy Policy modal dialog when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildAboutTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final privacyTile = find.text('سياسة الخصوصية');
      expect(privacyTile, findsOneWidget);

      await tester.ensureVisible(privacyTile);
      await tester.pumpAndSettle();

      await tester.tap(privacyTile);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('سياسة الخصوصية وأمان البيانات'), findsOneWidget);

      // Close Dialog
      await tester.tap(find.text('رجوع'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
