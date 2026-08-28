import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/conversation.dart';
import 'availability_indicator.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime? dt, bool isArabic) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${isArabic ? 'د' : 'm'}';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      return DateFormat('hh:mm a', isArabic ? 'ar' : 'en').format(dt);
    } else {
      return DateFormat('dd/MM', isArabic ? 'ar' : 'en').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;
    final contact = conversation.otherParticipant;

    final title = contact?.fullName ?? conversation.departmentId;
    final subtitle = conversation.lastMessage ?? (isArabic ? 'بدء محادثة جديدة' : 'Start a conversation');
    final jobTitle = contact?.localizedJobTitle(isArabic);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppDimensions.radiusLarge,
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.primaryLight,
                child: Text(
                  title.isNotEmpty
                      ? title
                          .split(' ')
                          .take(2)
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .join()
                          .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (contact != null)
                Positioned(
                  bottom: 0,
                  right: isArabic ? null : 0,
                  left: isArabic ? 0 : null,
                  child: AvailabilityIndicator(
                    availability: contact.availability,
                    showText: false,
                    dotSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Message Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(conversation.lastMessageAt, isArabic),
                      style: TextStyle(
                        fontSize: 11,
                        color: conversation.unreadCount > 0
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (jobTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    jobTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: conversation.unreadCount > 0
                              ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondaryLight),
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (conversation.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
