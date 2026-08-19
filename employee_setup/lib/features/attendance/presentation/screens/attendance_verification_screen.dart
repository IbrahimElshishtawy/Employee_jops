import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/early_leave_warning_banner.dart';
import '../widgets/verification_employee_card.dart';
import '../widgets/verification_pipeline_list.dart';
import '../widgets/verification_result_banner.dart';

class AttendanceVerificationScreen extends ConsumerStatefulWidget {
  final bool isCheckIn;

  const AttendanceVerificationScreen({
    super.key,
    required this.isCheckIn,
  });

  @override
  ConsumerState<AttendanceVerificationScreen> createState() =>
      _AttendanceVerificationScreenState();
}

class _AttendanceVerificationScreenState
    extends ConsumerState<AttendanceVerificationScreen> {
  bool _isSuccess = false;
  bool _showEarlyLeaveDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrerequisitesAndStart();
    });
  }

  void _checkPrerequisitesAndStart() {
    final workSchedule = ref.read(workScheduleProvider);
    final scheduleService = ref.read(workScheduleServiceProvider);

    // If Check-Out is attempted during work hours before shift end
    if (!widget.isCheckIn && scheduleService.isEarlyCheckout(workSchedule)) {
      setState(() {
        _showEarlyLeaveDialog = true;
      });
      return;
    }

    _startVerification();
  }

  Future<void> _startVerification() async {
    setState(() {
      _isSuccess = false;
    });

    final notifier = ref.read(attendanceFlowProvider.notifier);
    final success = widget.isCheckIn
        ? await notifier.executeCheckIn()
        : await notifier.executeCheckOut();

    if (mounted) {
      if (success) {
        setState(() => _isSuccess = true);
        ref.invalidate(attendanceSummaryProvider);
        ref.invalidate(attendanceHistoryProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(attendanceFlowProvider);
    final employee = ref.watch(employeeProvider);
    final workSchedule = ref.watch(workScheduleProvider);
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    final title = widget.isCheckIn
        ? (isRtl ? 'التحقق الذكي لتسجيل الحضور' : 'Smart Check-In Verification')
        : (isRtl ? 'التحقق الذكي لتسجيل الانصراف' : 'Smart Check-Out Verification');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(
        title: title,
        subtitle: isRtl
            ? 'التحقق متعدد العوامل (الموقع، البصمة، والأمان)'
            : 'Multi-factor verification (GPS, Biometrics, Security)',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Employee & Workplace Card
              VerificationEmployeeCard(
                employee: employee,
                isCheckIn: widget.isCheckIn,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // 2. Early Leave Warning Banner (if attempting checkout before shift end)
              if (_showEarlyLeaveDialog && !widget.isCheckIn) ...[
                EarlyLeaveWarningBanner(
                  workSchedule: workSchedule,
                  isDark: isDark,
                  isRtl: isRtl,
                  onProceedAnyway: () {
                    setState(() => _showEarlyLeaveDialog = false);
                    _startVerification();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 3. Verification Pipeline Progress Steps
              VerificationPipelineList(
                employee: employee,
                flowState: flowState,
                isSuccess: _isSuccess,
                isDark: isDark,
                isRtl: isRtl,
              ),
              const SizedBox(height: 16),

              // 4. Verification Result Banner (Success / Error / Progress)
              VerificationResultBanner(
                isSuccess: _isSuccess,
                isCheckIn: widget.isCheckIn,
                flowState: flowState,
                isDark: isDark,
                isRtl: isRtl,
                onRetry: _startVerification,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
