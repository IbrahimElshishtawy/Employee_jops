import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/attendance_card.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attendanceSummaryProvider);
            ref.invalidate(attendanceHistoryProvider);
            ref.invalidate(allRequestsProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppDimensions.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Avatar, Greeting, Live Date, Bell Badge)
                const HomeHeader(),
                const SizedBox(height: 20),

                // 2. Attendance Card (Full states & actions)
                AttendanceCard(
                  onHistoryTap: () => context.push('/attendance/history'),
                ),
                const SizedBox(height: 24),

                // 3. Quick Actions Grid
                const QuickActionsGrid(),
                const SizedBox(height: 24),

                // 4. Recent Activity Feed
                const RecentActivityList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
