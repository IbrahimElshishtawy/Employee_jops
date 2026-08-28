import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/mock/mock_database.dart';
import 'package:employee_setup/core/mock/seeds/employee_seed.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/features/attendance/presentation/widgets/employee_header_card.dart';
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('EmployeeHeaderCard renders employee details correctly',
      (WidgetTester tester) async {
    final storage = SharedPrefsStorage();
    await storage.init();
    await storage.clear();

    final dbNotifier = MockDatabaseNotifier();
    dbNotifier.replaceState(
      MockDatabase.seed().copyWith(
        employee: EmployeeSeed.employee.copyWith(avatarUrl: ''),
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        child: const EmployeeHeaderCard(),
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          mockDatabaseProvider.overrideWith((ref) => dbNotifier),
        ],
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(EmployeeHeaderCard), findsOneWidget);
  });
}
