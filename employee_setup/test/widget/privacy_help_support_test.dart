import 'package:employee_setup/core/constants/app_constants.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/core/widgets/app_button.dart';
import 'package:employee_setup/features/settings/presentation/screens/help_center_screen.dart';
import 'package:employee_setup/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:employee_setup/features/settings/presentation/screens/support_screen.dart';
import 'package:employee_setup/features/settings/presentation/widgets/help_faq_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  required Widget child,
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
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = SharedPrefsStorage();
    await storage.init();
  });

  group('PrivacyPolicyScreen Widget Tests', () {
    testWidgets('renders PrivacyPolicyScreen correctly in Arabic RTL',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const PrivacyPolicyScreen(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('سياسة الخصوصية'), findsWidgets);
      expect(find.text(AppConstants.appName), findsWidgets);
      expect(find.textContaining('آخر تحديث'), findsWidgets);
      expect(find.text('1. المقدمة ونطاق التطبيق'), findsOneWidget);
      expect(find.text('2. البيانات التي نقوم بمعالجتها'), findsOneWidget);
    });

    testWidgets('renders PrivacyPolicyScreen correctly in English LTR & Dark Mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const PrivacyPolicyScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.text('1. Introduction & Scope'), findsOneWidget);
      expect(find.text('2. Information We Process'), findsOneWidget);
    });
  });

  group('HelpCenterScreen Widget Tests', () {
    testWidgets('renders search, categories, and expands FAQ on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const HelpCenterScreen(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HelpCenterScreen), findsOneWidget);
      expect(find.text('مركز المساعدة'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify FAQ items present
      expect(find.byType(HelpFaqItem), findsWidgets);

      // Tap on first FAQ item to expand
      final firstFaq = find.byType(HelpFaqItem).first;
      await tester.tap(firstFaq);
      await tester.pumpAndSettle();

      // Verify Category filter selection
      final attendanceFilter = find.widgetWithText(FilterChip, 'الحضور والانصراف');
      expect(attendanceFilter, findsOneWidget);
      await tester.tap(attendanceFilter);
      await tester.pumpAndSettle();

      expect(find.byType(HelpFaqItem), findsWidgets);
    });

    testWidgets('searches FAQs and shows empty state when no match',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const HelpCenterScreen(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query with no match
      await tester.enterText(find.byType(TextField), 'xyz_nonexistent_query_123');
      await tester.pumpAndSettle();

      expect(find.text('لم يتم العثور على نتائج تطابق بحثك'), findsOneWidget);

      // Reset search via button
      await tester.tap(find.text('إعادة ضبط البحث'));
      await tester.pumpAndSettle();

      expect(find.byType(HelpFaqItem), findsWidgets);
    });
  });

  group('SupportScreen Widget Tests', () {
    testWidgets('renders SupportScreen tabs and form elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const SupportScreen(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SupportScreen), findsOneWidget);
      expect(find.text('الدعم الفني والمساعدة'), findsOneWidget);
      expect(find.text('تقديم بلاغ أو مشكلة'), findsOneWidget);
      expect(find.textContaining('سجل بلاغاتي'), findsOneWidget);
      expect(find.text('نوع المشكلة أو الاستفسار'), findsOneWidget);
    });

    testWidgets('submits problem report and shows ticket reference dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const SupportScreen(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Select Problem Type Dropdown
      final dropdown = find.byType(DropdownButton<String>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('مشكلة في تسجيل الدخول أو المصادقة').last);
      await tester.pumpAndSettle();

      // Enter Subject & Description by precise TextField indices
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'تعذر التحقق من البصمة البيومترية');
      await tester.enterText(
        textFields.at(1),
        'تظهر رسالة فشل مطابقة البصمة عند محاولة تسجيل الحضور الصباحي.',
      );
      await tester.pumpAndSettle();

      // Toggle attachment
      final attachmentTile = find.text('إرفاق لقطة شاشة توضيحية');
      await tester.ensureVisible(attachmentTile);
      await tester.pumpAndSettle();
      await tester.tap(attachmentTile);
      await tester.pump(const Duration(seconds: 4)); // Let SnackBar dismiss
      await tester.pumpAndSettle();

      // Submit form
      final submitBtn = find.byType(AppButton);
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Verify Success Dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('تم استلام بلاغك بنجاح'), findsOneWidget);

      // Close dialog & switch to tickets
      await tester.tap(find.text('سجل بلاغاتي السابقة'));
      await tester.pumpAndSettle();

      expect(find.text('تعذر التحقق من البصمة البيومترية'), findsOneWidget);
    });
  });
}
