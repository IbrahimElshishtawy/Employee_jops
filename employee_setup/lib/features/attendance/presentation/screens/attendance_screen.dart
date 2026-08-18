import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/attendance_action_section.dart';
import '../widgets/attendance_security_info_card.dart';
import '../widgets/attendance_today_timeline.dart';
import '../widgets/biometric_status_card.dart';
import '../widgets/employee_header_card.dart';
import '../widgets/location_status_card.dart';
import '../widgets/today_attendance_status_card.dart';

/// Full-featured, production-ready Attendance Screen for:
/// 1. Check-In
/// 2. Check-Out
/// 3. Biometric Authentication
/// 4. GPS Geofence Verification (4-meter rule)
/// 5. Offline Attendance & Sync
/// 6. Live Timeline & Status
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppHeader(
        title: context.tr('attendance.title'),
        subtitle: 'تسجيل الحضور والانصراف الذكي',
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: context.tr('attendance.history'),
            onPressed: () => context.push('/attendance/history'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(attendanceFlowProvider.notifier).refreshLocation();
            ref.invalidate(attendanceSummaryProvider);
            ref.invalidate(attendanceHistoryProvider);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: AppDimensions.pagePadding,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Employee Header
                EmployeeHeaderCard(),
                SizedBox(height: 14),

                // 2. Today's Attendance Overview
                TodayAttendanceStatusCard(),
                SizedBox(height: 14),

                // 3. Location & 4-Meter Geofence Card
                LocationStatusCard(),
                SizedBox(height: 14),

                // 4. Biometric Status Card
                BiometricStatusCard(),
                SizedBox(height: 18),

                // 5. Main Attendance Action Button & State Messages
                AttendanceActionSection(),
                SizedBox(height: 18),

                // 6. Today's Attendance Timeline
                AttendanceTodayTimeline(),
                SizedBox(height: 14),

                // 7. Security & Offline Info
                AttendanceSecurityInfoCard(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
