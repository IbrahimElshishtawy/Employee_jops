import 'package:flutter/material.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

/// Reusable Container Card for charts and analytical breakdowns
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading3),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: AppTypography.caption),
                    ],
                  ],
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppDimensions.space20),
            child,
          ],
        ),
      ),
    );
  }
}
