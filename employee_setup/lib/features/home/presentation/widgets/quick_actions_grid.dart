import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final actions = [
      _QuickActionItem(
        title: context.tr('requests.advances'),
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF10B981),
        route: '/requests/advances',
      ),
      _QuickActionItem(
        title: context.tr('requests.permissions'),
        icon: Icons.timer_outlined,
        color: const Color(0xFF3B82F6),
        route: '/requests/permissions',
      ),
      _QuickActionItem(
        title: context.tr('requests.vacations'),
        icon: Icons.beach_access_outlined,
        color: const Color(0xFFF59E0B),
        route: '/requests/vacations',
      ),
      _QuickActionItem(
        title: context.tr('attendance.history'),
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF8B5CF6),
        route: '/attendance/history',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('home.quick_actions'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final item = actions[index];
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => context.push(item.route),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

