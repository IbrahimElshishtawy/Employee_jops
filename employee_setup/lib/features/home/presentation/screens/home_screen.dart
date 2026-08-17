import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/widgets/attendance_card.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_list.dart';

/// Production-ready Home Dashboard screen.
///
/// Layout (top → bottom, scrollable):
///   1. [HomeHeader]        — gradient hero (employee info + stats strip)
///   2. [AttendanceCard]    — today's check-in/out + biometric action flow
///   3. [QuickActionsGrid]  — 4 navigational quick-action tiles
///   4. [RecentActivityList]— last 3 unified requests
///
/// Data flow:
///   MockDatabase → Riverpod providers → child widgets
///
/// All widgets are connected to the existing provider graph.
/// No local data is created here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // HomeHeader implements PreferredSizeWidget — used directly as the AppBar.
      appBar: const HomeHeader(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh(ref),
          displacement: 20,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── 2. Attendance Card ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AttendanceCard(
                    onHistoryTap: () => context.push('/attendance/history'),
                  ),
                ),

                const SizedBox(height: 20),

                // ── 3. Quick Actions ─────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: QuickActionsGrid(),
                ),

                const SizedBox(height: 20),

                // ── 4. Recent Activity ───────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: RecentActivityList(),
                ),

                // Bottom breathing room (accounts for bottom nav bar)
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Invalidates all reactive providers so pull-to-refresh fetches fresh data
  /// from MockDatabase. Providers automatically re-derive and notify listeners.
  Future<void> Function() _onRefresh(WidgetRef ref) {
    return () async {
      ref.invalidate(attendanceSummaryProvider);
      ref.invalidate(attendanceHistoryProvider);
      ref.invalidate(allRequestsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
      ref.invalidate(notificationsListProvider);
      // Small delay so the refresh indicator is visible
      await Future<void>.delayed(const Duration(milliseconds: 400));
    };
  }
}
