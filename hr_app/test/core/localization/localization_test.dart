import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/localization/app_localizations.dart';
import 'package:hr_app/core/localization/locale_controller.dart';
import 'package:hr_app/core/localization/widgets/language_switcher.dart';
import 'package:hr_app/core/storage/local_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('LocaleController Unit Tests', () {
    late LocalStorage localStorage;
    late LocaleController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localStorage = LocalStorage(prefs);
      controller = LocaleController(localStorage);
    });

    test('Initializes with default English (LTR) locale', () {
      expect(controller.locale.languageCode, equals('en'));
      expect(controller.isArabic, isFalse);
      expect(controller.textDirection, equals(TextDirection.ltr));
    });

    test('Toggles to Arabic (RTL) and updates storage', () async {
      await controller.toggleLocale();

      expect(controller.locale.languageCode, equals('ar'));
      expect(controller.isArabic, isTrue);
      expect(controller.textDirection, equals(TextDirection.rtl));
      expect(localStorage.getString('selected_locale'), equals('ar'));

      await controller.toggleLocale();
      expect(controller.locale.languageCode, equals('en'));
      expect(controller.isArabic, isFalse);
      expect(controller.textDirection, equals(TextDirection.ltr));
    });

    test('Sets language explicitly by code', () async {
      await controller.setLanguage('ar');
      expect(controller.locale.languageCode, equals('ar'));

      await controller.setLanguage('en');
      expect(controller.locale.languageCode, equals('en'));
    });
  });

  group('AppLocalizations Dictionary & Formatter Unit Tests', () {
    test('Resolves English translations across navigation and modules', () {
      final l10nEn = AppLocalizations(const Locale('en'));

      expect(l10nEn.get('app_title'), equals('CyberWise IE'));
      expect(l10nEn.get('nav_dashboard'), equals('Executive Dashboard'));
      expect(l10nEn.get('nav_employees'), equals('Employees Directory'));
      expect(l10nEn.get('nav_attendance'), equals('Attendance & Live Punch'));
      expect(l10nEn.get('nav_requests'), equals('Requests & Approvals'));
      expect(l10nEn.get('nav_advances'), equals('Salary Advances'));
      expect(l10nEn.get('nav_deductions'), equals('Payroll Deductions'));
      expect(l10nEn.get('nav_schedules'), equals('Work Schedules & Shifts'));
      expect(l10nEn.get('nav_reports'), equals('Reports & Analytics'));
      expect(l10nEn.get('nav_notifications'), equals('HR Notifications'));
      expect(l10nEn.get('nav_messages'), equals('Direct HR Messages'));
      expect(l10nEn.get('nav_audit_logs'), equals('Audit Logs & Trail'));
      expect(l10nEn.get('nav_settings'), equals('System Settings'));
    });

    test('Resolves Arabic translations across navigation and modules', () {
      final l10nAr = AppLocalizations(const Locale('ar'));

      expect(l10nAr.get('app_title'), equals('سايبر وايز IE'));
      expect(l10nAr.get('nav_dashboard'), equals('لوحة المعلومات الرئيسية'));
      expect(l10nAr.get('nav_employees'), equals('سجل الموظفين'));
      expect(l10nAr.get('nav_attendance'), equals('سجل الحضور والبصمة الحية'));
      expect(l10nAr.get('nav_requests'), equals('الطلبات والموافقات'));
      expect(l10nAr.get('nav_advances'), equals('السلف المالية'));
      expect(l10nAr.get('nav_deductions'), equals('الخصومات والجزاءات'));
      expect(l10nAr.get('nav_schedules'), equals('جداول ومواعيد العمل'));
      expect(l10nAr.get('nav_reports'), equals('التقارير والإحصائيات'));
      expect(l10nAr.get('nav_notifications'), equals('إشعارات وتنبيهات HR'));
      expect(l10nAr.get('nav_messages'), equals('المراسلات الداخلية المباشرة'));
      expect(l10nAr.get('nav_audit_logs'), equals('سجل التدقيق والأمان'));
      expect(l10nAr.get('nav_settings'), equals('إعدادات النظام والسياسات'));
    });

    test('Translates backend enums without altering raw contract values', () {
      final l10nEn = AppLocalizations(const Locale('en'));
      final l10nAr = AppLocalizations(const Locale('ar'));

      // Status
      expect(l10nEn.translateStatus('ACTIVE'), equals('Active'));
      expect(l10nAr.translateStatus('ACTIVE'), equals('نشط'));
      expect(l10nEn.translateStatus('PENDING'), equals('Pending'));
      expect(l10nAr.translateStatus('PENDING'), equals('قيد الانتظار'));
      expect(l10nEn.translateStatus('APPROVED'), equals('Approved'));
      expect(l10nAr.translateStatus('APPROVED'), equals('معتمد'));
      expect(l10nEn.translateStatus('REJECTED'), equals('Rejected'));
      expect(l10nAr.translateStatus('REJECTED'), equals('مرفوض'));
      expect(l10nEn.translateStatus('PAID'), equals('Paid'));
      expect(l10nAr.translateStatus('PAID'), equals('تم السداد'));

      // Roles
      expect(l10nEn.translateRole('HR_ADMIN'), equals('HR Administrator'));
      expect(l10nAr.translateRole('HR_ADMIN'), contains('مدير الموارد البشرية'));
    });

    test('Formats currency, numbers, and dates accurately according to locale', () {
      final l10nEn = AppLocalizations(const Locale('en'));
      final l10nAr = AppLocalizations(const Locale('ar'));

      expect(l10nEn.formatCurrency(5000), contains('5,000.00'));
      expect(l10nAr.formatCurrency(5000), contains('5,000.00'));

      expect(l10nEn.formatNumber(1250), contains('1,250'));
      expect(l10nAr.formatNumber(1250), contains('1,250'));

      final testDate = DateTime(2026, 8, 21);
      expect(l10nEn.formatDate(testDate), equals('August 21, 2026'));
      expect(l10nAr.formatDate(testDate), contains('2026'));
    });
  });

  group('Language Switcher Widget Tests', () {
    late LocalStorage localStorage;
    late LocaleController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localStorage = LocalStorage(prefs);
      controller = LocaleController(localStorage);
    });

    testWidgets('Compact LanguageSwitcher toggles language on tap', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: LanguageSwitcher(compact: true),
              ),
            ),
          ),
        ),
      );

      expect(find.text('عربي'), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(controller.isArabic, isTrue);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('Segmented LanguageSwitcher selects Arabic and English', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: LanguageSwitcher(compact: false),
              ),
            ),
          ),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(controller.isArabic, isTrue);
    });
  });
}
