import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/models/attendance_state_type.dart';
import '../../domain/models/work_schedule.dart';

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
  bool _hasStarted = false;
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
      _hasStarted = true;
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
              // 1. Employee & Target Workplace Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.isCheckIn
                              ? [AppColors.primary, AppColors.primaryDark]
                              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                        ),
                      ),
                      child: Icon(
                        widget.isCheckIn
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.jobTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  employee.workplaceName ?? 'CyberWise IE - Test Office',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Early Leave Warning Banner (if attempting checkout before shift end)
              if (_showEarlyLeaveDialog && !widget.isCheckIn) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                    borderRadius: AppDimensions.borderRadiusLarge,
                    border: Border.all(
                      color: isDark ? const Color(0xFFD97706) : const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isRtl
                                  ? 'تنبيه: انصراف أثناء ساعات العمل الرسمية'
                                  : 'Warning: Early Departure During Shift Hours',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRtl
                            ? 'مواعيد عملك المعتمدة تنتهي في الساعة ${workSchedule.formattedEndTime}. تسجيل الانصراف الآن يعتبر انصرافاً مبكراً يتطلب تقديم طلب إذن خروج وموافقة المسؤول.'
                            : 'Your scheduled shift ends at ${workSchedule.formattedEndTime}. Checking out now requires an approved early departure permission.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.primary(
                              label: isRtl ? 'تقديم طلب إذن خروج' : 'Request Early Leave',
                              icon: Icons.timer_outlined,
                              onPressed: () {
                                context.push('/requests/permissions/new');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppButton.secondary(
                            label: isRtl ? 'متابعة على أي حال' : 'Proceed Anyway',
                            onPressed: () {
                              setState(() => _showEarlyLeaveDialog = false);
                              _startVerification();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Verification Steps Live Status
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'مراحل التحقق الأمني الذكي' : 'Security Verification Pipeline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1: Location & Geofence
                    _buildPipelineStep(
                      stepNumber: 1,
                      title: isRtl ? 'الموقع الجغرافي والنطاق (Geofence)' : 'GPS & Geofence Radius',
                      description: isRtl
                          ? 'التحقق من التواجد ضمن نطاق ${employee.allowedRadiusMeters.toInt()}م من موقع العمل ودقة الإشارة'
                          : 'Validating presence within ${employee.allowedRadiusMeters.toInt()}m office radius',
                      icon: Icons.location_on_rounded,
                      status: _getStepStatus(1, flowState),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // Step 2: Screen Overlay & Device Security
                    _buildPipelineStep(
                      stepNumber: 2,
                      title: isRtl ? 'فحص أمان الشاشة والتراكب' : 'Screen Overlay & App Security',
                      description: isRtl
                          ? 'التأكد من عدم وجود تطبيقات تراكب ضارة أو تزييف للموقع'
                          : 'Verifying no malicious overlays or mock location apps active',
                      icon: Icons.security_rounded,
                      status: _getStepStatus(2, flowState),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // Step 3: Biometric Identity Authentication
                    _buildPipelineStep(
                      stepNumber: 3,
                      title: isRtl ? 'المصادقة البيومترية الحية' : 'Live Biometric Authentication',
                      description: isRtl
                          ? 'تأكيد بصمة الإصبع أو التعرف على الوجه Face ID على الجهاز'
                          : 'Validating device Fingerprint or Face ID identity token',
                      icon: Icons.fingerprint_rounded,
                      status: _getStepStatus(3, flowState),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // Step 4: Server Evaluation & Final Record
                    _buildPipelineStep(
                      stepNumber: 4,
                      title: isRtl ? 'الاعتماد السحابي والتسجيل' : 'Cloud Server Record & Sync',
                      description: isRtl
                          ? 'حساب المسافة والتسجيل المعتمد وإصدار الرمز الآمن'
                          : 'Server-side evaluation, cryptographically signed record',
                      icon: Icons.cloud_done_rounded,
                      status: _getStepStatus(4, flowState),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Status Outcome Banner & Actions
              if (_isSuccess) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                    borderRadius: AppDimensions.borderRadiusLarge,
                    border: Border.all(
                      color: isDark ? const Color(0xFF059669) : const Color(0xFF6EE7B7),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 48,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isCheckIn
                            ? (isRtl ? 'تم تسجيل الحضور بنجاح!' : 'Check-In Recorded Successfully!')
                            : (isRtl ? 'تم تسجيل الانصراف بنجاح!' : 'Check-Out Recorded Successfully!'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.successDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateTime.now().toFormattedDate(isRtl ? 'ar' : 'en')} — ${DateTime.now().toFormattedTime()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFA7F3D0) : AppColors.successDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton.primary(
                        label: isRtl ? 'العودة إلى الصفحة الرئيسية' : 'Return to Home Dashboard',
                        icon: Icons.home_rounded,
                        onPressed: () {
                          context.go('/home');
                        },
                      ),
                    ],
                  ),
                ),
              ] else if (flowState.processState == AttendanceProcessState.error) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
                    borderRadius: AppDimensions.borderRadiusLarge,
                    border: Border.all(
                      color: isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              flowState.message ?? (isRtl ? 'تعذر إتمام العملية' : 'Verification Failed'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.errorDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppButton.primary(
                        label: isRtl ? 'إعادة المحاولة' : 'Try Again',
                        icon: Icons.refresh_rounded,
                        onPressed: _startVerification,
                      ),
                    ],
                  ),
                ),
              ] else if (flowState.isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                    borderRadius: AppDimensions.borderRadiusLarge,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          flowState.message ?? (isRtl ? 'جاري التحقق...' : 'Verifying...'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _StepUiStatus _getStepStatus(int stepNumber, AttendanceFlowState flowState) {
    if (_isSuccess) return _StepUiStatus.completed;

    switch (stepNumber) {
      case 1: // Location
        if (flowState.processState == AttendanceProcessState.checkingLocation) {
          return _StepUiStatus.inProgress;
        }
        if (flowState.stateType == AttendanceStateType.locationServiceDisabled ||
            flowState.stateType == AttendanceStateType.locationPermissionDenied ||
            flowState.stateType == AttendanceStateType.lowLocationAccuracy ||
            flowState.stateType == AttendanceStateType.outsideWorkplace) {
          return _StepUiStatus.failed;
        }
        if (flowState.locationResult != null) return _StepUiStatus.completed;
        return _StepUiStatus.pending;

      case 2: // Overlay & Security
        if (flowState.stateType == AttendanceStateType.deviceIntegrityFailed) {
          return _StepUiStatus.failed;
        }
        if (flowState.locationResult != null &&
            flowState.processState != AttendanceProcessState.checkingLocation) {
          return _StepUiStatus.completed;
        }
        return _StepUiStatus.pending;

      case 3: // Biometrics
        if (flowState.processState == AttendanceProcessState.authenticatingBiometric) {
          return _StepUiStatus.inProgress;
        }
        if (flowState.stateType == AttendanceStateType.biometricFailed ||
            flowState.stateType == AttendanceStateType.biometricUnavailable) {
          return _StepUiStatus.failed;
        }
        if (flowState.processState == AttendanceProcessState.submitting || _isSuccess) {
          return _StepUiStatus.completed;
        }
        return _StepUiStatus.pending;

      case 4: // Server Sync
        if (flowState.processState == AttendanceProcessState.submitting) {
          return _StepUiStatus.inProgress;
        }
        if (_isSuccess) return _StepUiStatus.completed;
        return _StepUiStatus.pending;

      default:
        return _StepUiStatus.pending;
    }
  }

  Widget _buildPipelineStep({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required _StepUiStatus status,
    required bool isDark,
  }) {
    Color badgeColor;
    Widget statusIcon;

    switch (status) {
      case _StepUiStatus.completed:
        badgeColor = AppColors.success;
        statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
        break;
      case _StepUiStatus.inProgress:
        badgeColor = AppColors.primary;
        statusIcon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case _StepUiStatus.failed:
        badgeColor = AppColors.error;
        statusIcon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
        break;
      case _StepUiStatus.pending:
        badgeColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
        statusIcon = Icon(
          Icons.radio_button_unchecked_rounded,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          size: 18,
        );
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: badgeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        statusIcon,
      ],
    );
  }
}

enum _StepUiStatus {
  pending,
  inProgress,
  completed,
  failed,
}
