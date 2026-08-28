import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../../features/attendance/domain/models/attendance.dart';
import '../../features/attendance/domain/models/location_result.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../extensions/context_extensions.dart';
import '../extensions/date_extensions.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Clean, modular AttendanceCard presented on the Home dashboard.
class AttendanceCard extends ConsumerWidget {
  final VoidCallback? onHistoryTap;
  final VoidCallback? onDetailsTap;

  const AttendanceCard({
    super.key,
    this.onHistoryTap,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final demoState = ref.watch(demoControlsProvider);
    final employee = ref.watch(employeeProvider);
    final flowState = ref.watch(attendanceFlowProvider);
    final isDark = context.isDark;

    final isCheckedIn = summary.hasCheckedIn;
    final isCheckedOut = summary.hasCheckedOut;

    final allowedRadius = employee.allowedRadiusMeters > 0
        ? employee.allowedRadiusMeters
        : 4.0;

    final locResult = flowState.locationResult;
    final distanceMeters = locResult?.distanceFromOfficeMeters ??
        (demoState.useRealDeviceSensors ? 0.0 : demoState.simulatedDistance);
    final isInside = locResult != null
        ? locResult.isInsideRange
        : (distanceMeters <= allowedRadius);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          _AttendanceHeader(
            onDetailsTap: onDetailsTap,
            onHistoryTap: onHistoryTap,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 2. Main Status & Offline Badge
          _AttendanceStatusRow(
            summary: summary,
            isOnline: demoState.isOnline,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // 3. Geofence Boundary & Distance Indicator
          _AttendanceGeofenceBanner(
            isInside: isInside,
            distanceMeters: distanceMeters,
            allowedRadiusMeters: allowedRadius,
            locationResult: locResult,
            isUpdating: flowState.isLocationUpdating,
            onRefreshLocation: () =>
                ref.read(attendanceFlowProvider.notifier).refreshLocation(),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 4. Check-In / Check-Out Recorded Time Breakdown
          _AttendanceTimesRow(
            summary: summary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 5. Check-In / Check-Out Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: context.tr('attendance.check_in'),
                  icon: Icons.login_rounded,
                  onPressed: isCheckedIn
                      ? null
                      : () => context.push('/attendance/verify?type=checkIn'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.secondary(
                  label: context.tr('attendance.check_out'),
                  icon: Icons.logout_rounded,
                  onPressed: !isCheckedIn || isCheckedOut
                      ? null
                      : () => context.push('/attendance/verify?type=checkOut'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Private Modular Sub-widgets
// ──────────────────────────────────────────────────────────────

class _AttendanceHeader extends StatelessWidget {
  final VoidCallback? onDetailsTap;
  final VoidCallback? onHistoryTap;
  final bool isDark;

  const _AttendanceHeader({
    this.onDetailsTap,
    this.onHistoryTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onDetailsTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('home.today_status'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              if (onDetailsTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  context.isRtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ],
            ],
          ),
        ),
        if (onHistoryTap != null)
          TextButton.icon(
            onPressed: onHistoryTap,
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text(
              context.tr('attendance.history'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _AttendanceStatusRow extends StatelessWidget {
  final TodayAttendanceSummary summary;
  final bool isOnline;
  final bool isDark;

  const _AttendanceStatusRow({
    required this.summary,
    required this.isOnline,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = summary.hasCheckedIn;
    final isCheckedOut = summary.hasCheckedOut;

    String mainStatusText;
    Color statusColor;
    IconData statusIcon;

    if (isCheckedOut) {
      mainStatusText = context.tr('attendance.checked_out');
      statusColor = AppColors.info;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isCheckedIn) {
      final isPending = summary.checkIn?.isOffline == true;
      mainStatusText = isPending
          ? context.tr('attendance.pending_hr_verification')
          : context.tr('attendance.checked_in');
      statusColor = isPending ? AppColors.warning : AppColors.success;
      statusIcon = isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded;
    } else {
      mainStatusText = context.tr('attendance.not_checked_in');
      statusColor = isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          mainStatusText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
        const Spacer(),
        if (!isOnline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF78350F) : AppColors.warningLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'وضع بدون اتصال',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFDE68A) : AppColors.warningDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttendanceGeofenceBanner extends StatelessWidget {
  final bool isInside;
  final double distanceMeters;
  final double allowedRadiusMeters;
  final LocationResult? locationResult;
  final bool isUpdating;
  final VoidCallback onRefreshLocation;
  final bool isDark;

  const _AttendanceGeofenceBanner({
    required this.isInside,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    this.locationResult,
    this.isUpdating = false,
    required this.onRefreshLocation,
    required this.isDark,
  });

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} كم';
    }
    return '${meters.toStringAsFixed(1)} م';
  }

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied = locationResult?.isPermissionDenied == true;
    final isGpsDisabled = locationResult?.isGpsDisabled == true;
    final isMock = locationResult?.isMockLocation == true ||
        locationResult?.status == LocationStatus.mockLocationDetected;

    String bannerText;
    Color textColor;
    Color iconColor;
    IconData iconData;

    if (isUpdating && locationResult == null) {
      bannerText = 'جاري تحديد موقعك الجغرافي وحساب المسافة بدقة...';
      textColor = isDark ? Colors.white70 : AppColors.primaryDark;
      iconColor = AppColors.primary;
      iconData = Icons.location_searching_rounded;
    } else if (isPermissionDenied) {
      bannerText = '⚠️ إذن الموقع الجغرافي غير مفعل - انقر للتفعيل والتحديث';
      textColor = isDark ? const Color(0xFFFDE68A) : AppColors.warningDark;
      iconColor = AppColors.warning;
      iconData = Icons.location_disabled_rounded;
    } else if (isGpsDisabled) {
      bannerText = '⚠️ خدمة GPS معطلة على الجهاز - يرجى تشغيلها';
      textColor = isDark ? const Color(0xFFFECACA) : AppColors.errorDark;
      iconColor = AppColors.error;
      iconData = Icons.gps_off_rounded;
    } else if (isMock) {
      bannerText = '🚫 تم رصد موقع وهمي (Mock Location) - تم رفض الموقع';
      textColor = isDark ? const Color(0xFFFECACA) : AppColors.errorDark;
      iconColor = AppColors.error;
      iconData = Icons.security_update_warning_rounded;
    } else if (isInside) {
      bannerText =
          '📍 داخل نطاق موقع العمل (أنت على بعد ${_formatDistance(distanceMeters)})';
      textColor = isDark ? const Color(0xFFA7F3D0) : AppColors.successDark;
      iconColor = AppColors.success;
      iconData = Icons.location_on_rounded;
    } else {
      bannerText =
          '⚠️ خارج نطاق موقع العمل (أنت على بعد ${_formatDistance(distanceMeters)} - المسموح ${allowedRadiusMeters.toInt()} م)';
      textColor = isDark ? const Color(0xFFFECACA) : AppColors.errorDark;
      iconColor = AppColors.error;
      iconData = Icons.location_off_rounded;
    }

    return InkWell(
      onTap: isUpdating ? null : onRefreshLocation,
      borderRadius: AppDimensions.borderRadiusMedium,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
          borderRadius: AppDimensions.borderRadiusMedium,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            if (isUpdating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(iconData, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bannerText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.refresh_rounded,
              size: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTimesRow extends StatelessWidget {
  final TodayAttendanceSummary summary;
  final bool isDark;

  const _AttendanceTimesRow({
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppDimensions.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('attendance.check_in_time'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.checkIn != null
                      ? summary.checkIn!.timestamp.toFormattedTime()
                      : '--:--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('attendance.check_out_time'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.checkOut != null
                      ? summary.checkOut!.timestamp.toFormattedTime()
                      : '--:--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
