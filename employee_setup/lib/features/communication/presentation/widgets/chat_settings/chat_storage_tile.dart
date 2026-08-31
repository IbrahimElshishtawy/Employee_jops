import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/chat_settings.dart';

class ChatStorageTile extends StatelessWidget {
  final ChatStorageBreakdown breakdown;
  final VoidCallback onClearCache;
  final bool isClearing;

  const ChatStorageTile({
    super.key,
    required this.breakdown,
    required this.onClearCache,
    this.isClearing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Usage Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.info,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isArabic ? 'إجمالي المساحة المستخدمة' : 'Total Storage Usage',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ChatStorageBreakdown.formatBytes(breakdown.totalBytes),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: breakdown.cachedDataBytes > 0 ? 1 : 0,
                    child: Container(color: AppColors.primary),
                  ),
                  if (breakdown.totalBytes == 0)
                    Expanded(
                      child: Container(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Itemized Breakdown
          _buildItemRow(
            icon: Icons.image_outlined,
            label: isArabic ? 'الصور' : 'Images',
            bytes: breakdown.imagesBytes,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          _buildItemRow(
            icon: Icons.videocam_outlined,
            label: isArabic ? 'الفيديوهات' : 'Videos',
            bytes: breakdown.videosBytes,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          _buildItemRow(
            icon: Icons.insert_drive_file_outlined,
            label: isArabic ? 'الملفات والمستندات' : 'Files',
            bytes: breakdown.filesBytes,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildItemRow(
            icon: Icons.mic_none_rounded,
            label: isArabic ? 'الرسائل الصوتية' : 'Voice Messages',
            bytes: breakdown.voiceMessagesBytes,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          _buildItemRow(
            icon: Icons.cached_rounded,
            label: isArabic ? 'البيانات المؤقتة (Cache)' : 'Cached Data',
            bytes: breakdown.cachedDataBytes,
            color: const Color(0xFF64748B),
            isDark: isDark,
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Clear Cache Action
          InkWell(
            onTap: isClearing ? null : onClearCache,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cleaning_services_rounded,
                    size: 18,
                    color: isClearing ? Colors.grey : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic ? 'مسح الذاكرة المؤقتة (Clear Cache)' : 'Clear Cache',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isClearing ? Colors.grey : AppColors.error,
                      ),
                    ),
                  ),
                  if (isClearing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      isArabic
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppColors.error,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required IconData icon,
    required String label,
    required int bytes,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            ChatStorageBreakdown.formatBytes(bytes),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
