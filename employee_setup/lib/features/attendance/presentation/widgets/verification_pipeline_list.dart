import 'package:flutter/material.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/models/employee.dart';
import '../../domain/models/attendance_state_type.dart';

enum StepUiStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Widget rendering the multi-factor security pipeline progress steps.
class VerificationPipelineList extends StatelessWidget {
  final Employee employee;
  final AttendanceFlowState flowState;
  final bool isSuccess;
  final bool isDark;
  final bool isRtl;

  const VerificationPipelineList({
    super.key,
    required this.employee,
    required this.flowState,
    required this.isSuccess,
    required this.isDark,
    required this.isRtl,
  });

  StepUiStatus _getStepStatus(int stepNumber) {
    if (isSuccess) return StepUiStatus.completed;

    switch (stepNumber) {
      case 1: // Location & Geofence
        if (flowState.geofenceStatus.isSuccess) {
          return StepUiStatus.completed;
        }
        if (flowState.geofenceStatus.isInProgress ||
            flowState.processState == AttendanceProcessState.checkingLocation) {
          return StepUiStatus.inProgress;
        }
        if (flowState.geofenceStatus.isFailed ||
            flowState.stateType == AttendanceStateType.locationServiceDisabled ||
            flowState.stateType == AttendanceStateType.locationPermissionDenied ||
            flowState.stateType == AttendanceStateType.lowLocationAccuracy ||
            flowState.stateType == AttendanceStateType.outsideWorkplace ||
            flowState.stateType == AttendanceStateType.mockLocationDetected) {
          return StepUiStatus.failed;
        }
        if (flowState.locationResult != null && flowState.locationResult!.isInsideRange) {
          return StepUiStatus.completed;
        }
        return StepUiStatus.pending;

      case 2: // Screen Overlay & Security
        if (flowState.screenSecurityStatus.isSuccess) {
          return StepUiStatus.completed;
        }
        if (flowState.screenSecurityStatus.isInProgress) {
          return StepUiStatus.inProgress;
        }
        if (flowState.screenSecurityStatus.isFailed ||
            flowState.stateType == AttendanceStateType.deviceIntegrityFailed) {
          return StepUiStatus.failed;
        }
        return StepUiStatus.pending;

      case 3: // Biometrics
        if (flowState.biometricStatus.isSuccess) {
          return StepUiStatus.completed;
        }
        if (flowState.biometricStatus.isInProgress ||
            flowState.processState == AttendanceProcessState.authenticatingBiometric) {
          return StepUiStatus.inProgress;
        }
        if (flowState.biometricStatus.isFailed ||
            flowState.stateType == AttendanceStateType.biometricFailed ||
            flowState.stateType == AttendanceStateType.biometricUnavailable) {
          return StepUiStatus.failed;
        }
        return StepUiStatus.pending;

      case 4: // Cloud Server Record & Sync
        if (flowState.attendanceRegistrationStatus.isSuccess || isSuccess) {
          return StepUiStatus.completed;
        }
        if (flowState.attendanceRegistrationStatus.isInProgress ||
            flowState.processState == AttendanceProcessState.submitting) {
          return StepUiStatus.inProgress;
        }
        if (flowState.attendanceRegistrationStatus.isFailed ||
            flowState.stateType == AttendanceStateType.serverRejected) {
          return StepUiStatus.failed;
        }
        return StepUiStatus.pending;

      default:
        return StepUiStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
            title: isRtl ? 'الموقع الجغرافي والنطاق (Geofence)' : 'GPS & Geofence Radius',
            description: isRtl
                ? 'التحقق من التواجد ضمن نطاق ${employee.allowedRadiusMeters.toInt()}م من موقع العمل ودقة الإشارة'
                : 'Validating presence within ${employee.allowedRadiusMeters.toInt()}m office radius',
            icon: Icons.location_on_rounded,
            status: _getStepStatus(1),
          ),
          const SizedBox(height: 14),

          // Step 2: Screen Overlay & Device Security
          _buildPipelineStep(
            title: isRtl ? 'فحص أمان الشاشة والتراكب' : 'Screen Overlay & App Security',
            description: isRtl
                ? 'التأكد من عدم وجود تطبيقات تراكب ضارة أو تزييف للموقع'
                : 'Verifying no malicious overlays or mock location apps active',
            icon: Icons.security_rounded,
            status: _getStepStatus(2),
          ),
          const SizedBox(height: 14),

          // Step 3: Biometric Identity Authentication
          _buildPipelineStep(
            title: isRtl ? 'المصادقة البيومترية الحية' : 'Live Biometric Authentication',
            description: isRtl
                ? 'تأكيد بصمة الإصبع أو التعرف على الوجه Face ID على الجهاز'
                : 'Validating device Fingerprint or Face ID identity token',
            icon: Icons.fingerprint_rounded,
            status: _getStepStatus(3),
          ),
          const SizedBox(height: 14),

          // Step 4: Server Evaluation & Final Record
          _buildPipelineStep(
            title: isRtl ? 'الاعتماد السحابي والتسجيل' : 'Cloud Server Record & Sync',
            description: isRtl
                ? 'حساب المسافة والتسجيل المعتمد وإصدار الرمز الآمن'
                : 'Server-side evaluation, cryptographically signed record',
            icon: Icons.cloud_done_rounded,
            status: _getStepStatus(4),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required String title,
    required String description,
    required IconData icon,
    required StepUiStatus status,
  }) {
    Color badgeColor;
    Widget statusIcon;

    switch (status) {
      case StepUiStatus.completed:
        badgeColor = AppColors.success;
        statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
        break;
      case StepUiStatus.inProgress:
        badgeColor = AppColors.primary;
        statusIcon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case StepUiStatus.failed:
        badgeColor = AppColors.error;
        statusIcon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
        break;
      case StepUiStatus.pending:
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
