import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import 'home_stats_row.dart';

/// Premium gradient hero header for the Home Dashboard.
///
/// Data sources (all reactive via Riverpod):
/// - [currentEmployeeProvider]          → name, job title
/// - [unreadNotificationsCountProvider] → bell badge count
///
/// Layout:
///   ┌─────────────────────────────────────────────────┐
///   │  gradient (primary → primaryDark)               │
///   │  [avatar]  Greeting + Name + Title  [🔔 badge]  │
///   │            Live date                            │
///   │  ┌────────────────────────────────────────┐    │
///   │  │  check-in │ pending reqs │ notifications│    │
///   │  └────────────────────────────────────────┘    │
///   └─────────────────────────────────────────────────┘
class HomeHeader extends ConsumerWidget implements PreferredSizeWidget {
  const HomeHeader({super.key});

  /// Fixed height: top row (~70) + stats strip (~52) + padding (32) + status bar.
  @override
  Size get preferredSize => const Size.fromHeight(190);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isDark = context.isDark;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = (hour >= 5 && hour < 12)
        ? context.tr('home.greeting_morning')
        : context.tr('home.greeting_evening');

    final firstName = employee?.name.split(' ').first ?? '...';
    final jobTitle = employee?.jobTitle ?? '';
    final locale = context.l10n.locale.languageCode;
    final dateStr = now.toFormattedDate(locale);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A5CB5), Color(0xFF1043A0), Color(0xFF0A2D6E)]
              : const [
                  AppColors.primary, // #1A73E8
                  AppColors.primaryDark, // #1557B0
                  Color(0xFF0F3D8A),
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // ── Decorative background circles ──────────────────
          Positioned(top: -40, right: -40, child: _DecorativeCircle(size: 120)),
          Positioned(
            bottom: -25,
            left: -25,
            child: _DecorativeCircle(size: 100, opacity: 0.05),
          ),
          Positioned(
            top: 20,
            right: 100,
            child: _DecorativeCircle(size: 40, opacity: 0.07),
          ),

          // ── Main content ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 75, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + info + bell
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Employee avatar
                    _EmployeeAvatar(name: employee?.name ?? ''),
                    const SizedBox(width: 12),

                    // Greeting, job title, date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting، $firstName 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              jobTitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.80),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification bell with badge
                    _BellButton(
                      count: unreadCount,
                      onTap: () => context.go('/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats strip
                const HomeStatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Private sub-widgets
// ──────────────────────────────────────────────────────────────

/// Circular decorative element placed behind the header content.
class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({required this.size, this.opacity = 0.08});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Circular avatar showing the first letter of the employee's name.
class _EmployeeAvatar extends StatelessWidget {
  final String name;

  const _EmployeeAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0] : 'E';

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2.5,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Square icon button with notification badge.
/// RTL-aware: badge is anchored to the logical "end" side.
class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _BellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (count > 0)
            PositionedDirectional(
              top: -5,
              end: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
