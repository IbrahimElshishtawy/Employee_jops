import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

/// Premium 2×2 quick-action grid for the Home Dashboard.
///
/// Actions are static UI items that navigate to existing routes.
/// No Riverpod dependency needed — navigation targets are constant.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    final actions = [
      _QuickActionItem(
        title: context.tr('requests.advances'),
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF10B981),
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
        route: '/requests/advances',
      ),
      _QuickActionItem(
        title: context.tr('requests.permissions'),
        icon: Icons.timer_rounded,
        color: const Color(0xFF3B82F6),
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        route: '/requests/permissions',
      ),
      _QuickActionItem(
        title: context.tr('requests.vacations'),
        icon: Icons.beach_access_rounded,
        color: const Color(0xFFF59E0B),
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        route: '/requests/vacations',
      ),
      _QuickActionItem(
        title: isRtl ? 'دليل وسياسة الحضور' : 'Attendance Guide & Policy',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF8B5CF6),
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        route: '/attendance',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ─────────────────────────────────────
        _SectionTitle(
          label: context.tr('home.quick_actions'),
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // ── 2×2 Grid ─────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.85,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _QuickActionTile(
              item: actions[index],
              isDark: isDark,
              isRtl: isRtl,
            );
          },
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Private sub-widgets
// ──────────────────────────────────────────────────────────────

/// Left-accented section title, consistent with [RecentActivityList].
class _SectionTitle extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionTitle({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

/// Individual quick-action tile with a gradient icon container and chevron.
class _QuickActionTile extends StatelessWidget {
  final _QuickActionItem item;
  final bool isDark;
  final bool isRtl;

  const _QuickActionTile({
    required this.item,
    required this.isDark,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => context.push(item.route),
      child: Row(
        children: [
          // Gradient icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradientColors,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),

          // Label
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // RTL-aware chevron
          Icon(
            isRtl
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_forward_ios_rounded,
            size: 12,
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Data model (private to this file)
// ──────────────────────────────────────────────────────────────

class _QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final String route;

  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.route,
  });
}
