import 'package:employee_setup/app/app.dart';
import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmployeeApp initial load test', (WidgetTester tester) async {
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

    expect(find.text('Employee App'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
  });
}
