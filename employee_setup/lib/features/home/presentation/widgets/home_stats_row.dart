import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/status_badge.dart';

/// A compact 3-column stats strip, designed to be embedded inside the
/// HomeHeader gradient card.
///
/// Data sources (all reactive via Riverpod):
/// - [attendanceSummaryProvider]       → today's check-in time
/// - [allRequestsProvider]             → count of pending requests
/// - [unreadNotificationsCountProvider] → unread notification count
class HomeStatsRow extends ConsumerWidget {
  const HomeStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final requests = ref.watch(allRequestsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    final isArabic = context.isArabic;
    final locale = context.l10n.locale.languageCode;

    // ── Derived values ────────────────────────────────────────
    final checkInTime = summary.checkIn != null
        ? summary.checkIn!.timestamp.toFormattedTime(locale)
        : '--:--';

    final pendingCount = requests
        .where((r) => r.badgeStatus == BadgeStatus.pending)
        .length;

    final unreadDisplay = unread > 99 ? '99+' : '$unread';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.login_rounded,
            value: checkInTime,
            label: isArabic ? 'وقت الدخول' : 'Check In',
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.assignment_late_outlined,
            value: '$pendingCount',
            label: isArabic ? 'طلبات معلقة' : 'Pending',
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.notifications_active_outlined,
            value: unreadDisplay,
            label: isArabic ? 'تنبيهات جديدة' : 'Notifications',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Private helpers
// ──────────────────────────────────────────────────────────────

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
