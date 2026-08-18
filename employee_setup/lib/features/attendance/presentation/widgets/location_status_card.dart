import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/services/mock_location_service.dart';

class LocationStatusCard extends ConsumerWidget {
  const LocationStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(mockDatabaseProvider);
    final flowState = ref.watch(attendanceFlowProvider);
    final demo = ref.watch(demoControlsProvider);
    final isDark = context.isDark;

    final locResult = flowState.locationResult;
    final distanceMeters = locResult?.distanceFromOfficeMeters ?? demo.simulatedDistance;
    final isInside = locResult?.isInsideRange ?? (demo.simulatedDistance <= 4.0);
    final isPermissionDenied = locResult?.isPermissionDenied ?? (demo.locationMode == MockLocationMode.permissionDenied);
    final isGpsDisabled = locResult?.isGpsDisabled ?? (demo.locationMode == MockLocationMode.gpsDisabled);
    final isUpdating = flowState.isLocationUpdating;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Title + Update Location Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('attendance.workplace_zone'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),

              // Localized "Update Location" Button
              TextButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => ref.read(attendanceFlowProvider.notifier).refreshLocation(),
                icon: isUpdating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  isUpdating
                      ? context.tr('attendance.updating_location')
                      : context.tr('attendance.update_location'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Workplace Details Box
          Container(
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
                Icon(
                  Icons.business_rounded,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        db.companyLocation.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${db.company.name} • ${db.company.address}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${context.tr('attendance.allowed_radius_label')}: ${db.companyLocation.radiusMeters.toInt()} ${context.tr('common.meters')}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Location Zone Evaluation Banner
          if (isPermissionDenied) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF78350F) : AppColors.warningLight,
                borderRadius: AppDimensions.borderRadiusMedium,
                border: Border.all(
                  color: isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_disabled_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إذن الموقع الجغرافي مطلوب',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFEF3C7) : AppColors.warningDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'يلزم تفعيل إذن الموقع للتحقق من وجودك في مقر العمل.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFFDE68A) : AppColors.warningDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => ref.read(attendanceFlowProvider.notifier).requestLocationPermission(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.tr('attendance.allow_location_permission'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isGpsDisabled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
                borderRadius: AppDimensions.borderRadiusMedium,
                border: Border.all(
                  color: isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_off_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'خدمة تحديد المواقع (GPS) معطلة. يرجى تفعيلها للمتابعة.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFEE2E2) : AppColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isInside
                    ? (isDark ? const Color(0xFF064E3B) : AppColors.successLight)
                    : (isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight),
                borderRadius: AppDimensions.borderRadiusMedium,
                border: Border.all(
                  color: isInside
                      ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
                      : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isInside ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isInside ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isInside
                              ? context.tr('attendance.inside_allowed_zone')
                              : context.tr('attendance.outside_allowed_zone'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isInside
                                ? (isDark ? const Color(0xFFA7F3D0) : AppColors.successDark)
                                : (isDark ? const Color(0xFFFEE2E2) : AppColors.errorDark),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isInside
                              ? '${context.tr('attendance.distance_label')}: ${distanceMeters.toStringAsFixed(1)} ${context.tr('common.meters')} (ضمن نطاق الـ 4 أمتار)'
                              : '${context.tr('attendance.distance_label')}: ${distanceMeters.toStringAsFixed(1)} ${context.tr('common.meters')} (تجاوزت الحد الأقصى 4 أمتار)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isInside
                                ? (isDark ? const Color(0xFFD1FAE5) : AppColors.successDark)
                                : (isDark ? const Color(0xFFFECACA) : AppColors.errorDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
