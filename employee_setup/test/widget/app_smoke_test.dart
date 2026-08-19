import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/features/attendance/presentation/widgets/employee_header_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmployeeHeaderCard renders employee details correctly', (WidgetTester tester) async {
    final storage = SharedPrefsStorage();
    await storage.init();
    await storage.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: EmployeeHeaderCard()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(EmployeeHeaderCard), findsOneWidget);
  });
}
