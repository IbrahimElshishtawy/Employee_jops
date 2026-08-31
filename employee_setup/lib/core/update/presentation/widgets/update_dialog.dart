import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../domain/entities/update_info.dart';
import '../providers/update_provider.dart';

class UpdateDialog extends ConsumerWidget {
  final UpdateCheckResult checkResult;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onLaterPressed;

  const UpdateDialog({
    super.key,
    required this.checkResult,
    this.onUpdatePressed,
    this.onLaterPressed,
  });

  static Future<void> show(
    BuildContext context, {
    required UpdateCheckResult checkResult,
  }) async {
    final isForce = checkResult.isForceUpdate;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isForce,
      builder: (dialogCtx) => PopScope(
        canPop: !isForce,
        child: UpdateDialog(
          checkResult: checkResult,
          onUpdatePressed: () {
            Navigator.of(dialogCtx).pop();
          },
          onLaterPressed: isForce
              ? null
              : () {
                  Navigator.of(dialogCtx).pop();
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;
    final isForce = checkResult.isForceUpdate;
    final config = checkResult.config;
    final notes = config.localizedNotes(isArabic);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppCard(
        padding: const EdgeInsets.all(24),
        borderRadius: AppDimensions.radiusLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header with decorative badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isForce ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isForce ? Icons.warning_amber_rounded : Icons.system_update_rounded,
                color: isForce ? AppColors.error : AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              isArabic ? 'تحديث جديد متاح' : 'New Update Available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),

            // Version Badges (Current -> Available)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVersionChip(
                  label: 'v${checkResult.currentVersion.userFacingVersion}',
                  isCurrent: true,
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isArabic
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                _buildVersionChip(
                  label: 'v${checkResult.availableVersion.userFacingVersion}',
                  isCurrent: false,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Message Body
            Text(
              isArabic
                  ? 'يتوفر إصدار جديد من التطبيق. حدّث التطبيق للحصول على أحدث التحسينات والإصلاحات.'
                  : 'A new version of the app is available. Update now to get the latest features, security patches, and improvements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),

            // Release Notes Box (if available)
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'أبرز التحديثات:' : "What's New:",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Forced Update Alert Note
            if (isForce) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isArabic
                          ? 'هذا التحديث إلزامي لمتابعة استخدام التطبيق'
                          : 'This update is mandatory to continue using the app',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),

            // Action Buttons
            AppButton(
              label: isArabic ? 'تحديث الآن' : 'Update Now',
              icon: Icons.download_rounded,
              onPressed: () {
                if (onUpdatePressed != null) {
                  onUpdatePressed!();
                } else {
                  final isAndroid =
                      Theme.of(context).platform == TargetPlatform.android;
                  final url = isAndroid
                      ? checkResult.config.androidStoreUrl
                      : checkResult.config.iosStoreUrl;
                  ref.read(updateStateProvider.notifier).launchUpdateUrl(url);
                  Navigator.of(context).pop();
                }
              },
            ),
            if (!isForce) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref
                      .read(updateStateProvider.notifier)
                      .dismissOptionalUpdate();
                  if (onLaterPressed != null) {
                    onLaterPressed!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  isArabic ? 'لاحقًا' : 'Later',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVersionChip({
    required String label,
    required bool isCurrent,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark ? AppColors.surfaceVariantDark : const Color(0xFFE2E8F0))
            : AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isCurrent
              ? (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight)
              : AppColors.primary,
        ),
      ),
    );
  }
}
