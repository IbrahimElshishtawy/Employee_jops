import 'package:employee_setup/app/app.dart';
import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots up, displays splash and navigates to login/home', (WidgetTester tester) async {
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
    expect(find.text('Employee App'), findsOneWidget);

    // Settle splash timer
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Should transition to Login screen
    expect(find.text('تسجيل الدخول باستخدام Google'), findsOneWidget);
  });
}
