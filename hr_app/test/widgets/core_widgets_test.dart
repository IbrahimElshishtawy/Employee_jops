import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/widgets/cards/stat_card.dart';
import 'package:hr_app/core/widgets/feedback/status_badge.dart';

void main() {
  group('Core UI Component Widget Tests', () {
    testWidgets('StatusBadge renders label and variant correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'Approved',
              variant: BadgeVariant.success,
            ),
          ),
        ),
      );

      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('StatCard renders title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
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
  });
}
