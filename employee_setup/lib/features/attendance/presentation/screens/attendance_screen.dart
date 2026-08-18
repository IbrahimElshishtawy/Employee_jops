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
import '../widgets/work_schedule_card.dart';

/// Full-featured, enterprise-grade Attendance Screen integrating:
/// 1. Authenticated Employee Profile & Session Verification
/// 2. Work Schedule Detection & Shift Status
/// 3. Device Location, Geofence (4-meter radius rule) & GPS Accuracy
/// 4. Biometric Identity Verification (Fingerprint / Face ID)
/// 5. Check-In & Check-Out State Management
/// 6. Offline Mode & Local Cache Synchronization
/// 7. Today's Attendance Timeline & Live Telemetry
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppHeader(
        title: context.tr('attendance.title'),
        subtitle: context.tr('attendance.header_subtitle'),
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
            ref.invalidate(workScheduleShiftStatusProvider);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: AppDimensions.pagePadding,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Authenticated Employee Header
                EmployeeHeaderCard(),
                SizedBox(height: 14),

                // 2. Today's Attendance Status Overview
                TodayAttendanceStatusCard(),
                SizedBox(height: 14),

                // 3. Work Schedule & Shift Timing Card
                WorkScheduleCard(),
                SizedBox(height: 14),

                // 4. Location, GPS Accuracy & 4-Meter Geofence Card
                LocationStatusCard(),
                SizedBox(height: 14),

                // 5. Biometric Identity Verification Status
                BiometricStatusCard(),
                SizedBox(height: 18),

                // 6. Primary Attendance Action Button & Live Feedback
                AttendanceActionSection(),
                SizedBox(height: 18),

                // 7. Today's Attendance Timeline (Milestones)
                AttendanceTodayTimeline(),
                SizedBox(height: 14),

                // 8. Security & Offline Policy Information
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
