import 'package:employee_setup/app/app.dart';
import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots up, displays splash and navigates to login', (WidgetTester tester) async {
    final storage = SharedPrefsStorage();
    await storage.init();
    await storage.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: const EmployeeApp(),
      ),
    );

    // Initial Splash Screen Render
    expect(find.text('EMPLOYEE PORTAL'), findsOneWidget);

    // Advance past splash timer (900ms) and pump transition
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 200));

    // Should transition to Login screen
    expect(find.text('تسجيل الدخول باستخدام Google'), findsOneWidget);
  });
}
