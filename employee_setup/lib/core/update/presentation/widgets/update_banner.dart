import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/app_card.dart';
import '../providers/update_provider.dart';
import 'update_dialog.dart';

class UpdateBanner extends ConsumerWidget {
  final bool showIfUpToDate;

  const UpdateBanner({
    super.key,
    this.showIfUpToDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;
    final updateState = ref.watch(updateStateProvider);
    final notifier = ref.read(updateStateProvider.notifier);

    if (updateState.isChecking) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: AppDimensions.radiusMedium,
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              isArabic ? 'جاري التحقق من وجود تحديثات...' : 'Checking for updates...',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (updateState.hasStoreUpdate) {
      final result = updateState.checkResult!;
      final isForce = result.isForceUpdate;

      return AppCard(
        padding: const EdgeInsets.all(14),
        borderRadius: AppDimensions.radiusMedium,
        backgroundColor: (isForce ? AppColors.error : AppColors.primary)
            .withValues(alpha: 0.08),
        borderColor: (isForce ? AppColors.error : AppColors.primary)
            .withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isForce ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isForce ? Icons.warning_amber_rounded : Icons.system_update_rounded,
                color: isForce ? AppColors.error : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'تحديث جديد متاح' : 'Update Available',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v${result.availableVersion.userFacingVersion}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isForce ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                UpdateDialog.show(context, checkResult: result);
              },
              child: Text(
                isArabic ? 'تحديث' : 'Update',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (updateState.hasShorebirdPatch) {
      final patchNum = updateState.checkResult?.shorebirdPatchNumber ?? 1;
      return AppCard(
        padding: const EdgeInsets.all(12),
        borderRadius: AppDimensions.radiusMedium,
        backgroundColor: AppColors.success.withValues(alpha: 0.08),
        borderColor: AppColors.success.withValues(alpha: 0.3),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isArabic
                    ? 'تم تطبيق التحديث السريع (Patch #$patchNum) بنجاح'
                    : 'Code Push patch #$patchNum applied successfully',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (showIfUpToDate) {
      return AppCard(
        padding: const EdgeInsets.all(12),
        borderRadius: AppDimensions.radiusMedium,
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isArabic
                    ? 'التطبيق محدث إلى آخر إصدار'
                    : 'The app is up to date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              tooltip: isArabic ? 'تحقق من التحديثات' : 'Check for updates',
              onPressed: () => notifier.checkForUpdate(isManual: true),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
