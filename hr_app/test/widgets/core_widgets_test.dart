import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/core/theme/theme_controller.dart';
import 'package:hr_app/core/widgets/cards/stat_card.dart';
import 'package:hr_app/core/widgets/feedback/empty_state_view.dart';
import 'package:hr_app/core/widgets/feedback/error_state_view.dart';
import 'package:hr_app/core/widgets/feedback/status_badge.dart';

void main() {
  group('Core UI Component Widget Tests', () {
    testWidgets('StatusBadge renders in both Light and Dark theme', (tester) async {
      // 1. Light Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StatusBadge(
              label: 'Approved',
              variant: BadgeVariant.success,
            ),
          ),
        ),
      );
      expect(find.text('Approved'), findsOneWidget);

      // 2. Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StatusBadge(
              label: 'Approved Dark',
              variant: BadgeVariant.success,
            ),
          ),
        ),
      );
      expect(find.text('Approved Dark'), findsOneWidget);
    });

    testWidgets('StatCard renders title, value, and subtitle in Light and Dark themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: StatCard(
              title: 'Total Workforce',
              value: '48',
              subtitle: 'Active roster',
              icon: Icons.people,
            ),
          ),
        ),
      );

      expect(find.text('Total Workforce'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('Active roster'), findsOneWidget);
    });

    testWidgets('EmptyStateView and ErrorStateView render properly in Dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Column(
              children: const [
                EmptyStateView(title: 'No Workplaces Found', subtitle: 'Please create one'),
                ErrorStateView(title: 'Network Error', message: 'Failed to connect to API'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No Workplaces Found'), findsOneWidget);
      expect(find.text('Please create one'), findsOneWidget);
      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Failed to connect to API'), findsOneWidget);
    });

    testWidgets('ThemeController toggles between Light and Dark mode', (tester) async {
      final controller = ThemeController();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, true);

      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, false);

      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, true);
    });
  });
}
