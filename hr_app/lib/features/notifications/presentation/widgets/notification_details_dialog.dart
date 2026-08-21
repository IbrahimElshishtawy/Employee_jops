import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/notification_entity.dart';

/// Modal dialog for inspecting notification details and mobile push preview
class NotificationDetailsDialog extends StatelessWidget {
  final NotificationItemEntity notification;
  final VoidCallback? onMarkRead;
  final VoidCallback? onCancelScheduled;

  const NotificationDetailsDialog({
    super.key,
    required this.notification,
    this.onMarkRead,
    this.onCancelScheduled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final n = notification;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(n.severity).withValues(alpha: isDark ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active_outlined, color: _getSeverityColor(n.severity), size: 22),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: AppTypography.heading3),
                        Text('Created by: ${n.createdBy}', style: AppTypography.captionOf(context)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              const Divider(),
              const SizedBox(height: AppDimensions.space12),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(
                            label: n.type.label,
                            variant: BadgeVariant.info,
                          ),
                          StatusBadge(
                            label: n.status.label,
                            variant: _getStatusVariant(n.status),
                          ),
                          StatusBadge(
                            label: 'Target: ${n.targetType.label}${n.targetName != null ? " (${n.targetName})" : ""}',
                            variant: BadgeVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Message Body
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Message Content', style: AppTypography.captionOf(context)),
                              const SizedBox(height: 8),
                              Text(n.message, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Delivery & Read Metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Target Audience',
                              value: '${n.targetCount} recipients',
                              icon: Icons.people_outline,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Read Engagements',
                              value: '${n.readCount} read',
                              icon: Icons.mark_email_read_outlined,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Dispatch Timing',
                              value: n.scheduledAt != null
                                  ? 'Scheduled'
                                  : DateFormatter.toDisplayDate(n.sentAt ?? n.createdAt),
                              icon: Icons.schedule,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Employee Device Push Notification Preview
                      Card(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          side: BorderSide(color: AppColors.border(context)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.phone_android, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 6),
                                  Text('Mobile Push Notification Preview', style: AppTypography.captionOf(context)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(AppDimensions.space12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.notifications_active, color: AppColors.primaryLight, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('CyberWise HR Portal', style: AppTypography.captionOf(context)),
                                              Text('now', style: AppTypography.captionOf(context)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(n.title, style: AppTypography.bodyBold),
                                          const SizedBox(height: 2),
                                          Text(n.message, style: AppTypography.captionOf(context)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (n.status == NotificationStatus.scheduled && onCancelScheduled != null)
                    HrButton(
                      label: 'Cancel Scheduled Broadcast',
                      variant: HrButtonVariant.danger,
                      icon: Icons.cancel_outlined,
                      onPressed: () {
                        onCancelScheduled!();
                        Navigator.of(context).pop();
                      },
                    )
                  else if (!n.isRead && onMarkRead != null)
                    HrButton(
                      label: 'Mark as Read',
                      variant: HrButtonVariant.outline,
                      icon: Icons.done,
                      onPressed: () {
                        onMarkRead!();
                        Navigator.of(context).pop();
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  HrButton(
                    label: 'Close',
                    variant: HrButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required IconData icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: AppTypography.captionOf(context), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.bodyBold.copyWith(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getSeverityColor(NotificationSeverity s) {
    switch (s) {
      case NotificationSeverity.info:
        return AppColors.info;
      case NotificationSeverity.warning:
        return AppColors.warning;
      case NotificationSeverity.success:
        return AppColors.success;
      case NotificationSeverity.danger:
        return AppColors.danger;
    }
  }

  BadgeVariant _getStatusVariant(NotificationStatus s) {
    switch (s) {
      case NotificationStatus.sent:
        return BadgeVariant.success;
      case NotificationStatus.scheduled:
        return BadgeVariant.warning;
      case NotificationStatus.sending:
        return BadgeVariant.info;
      case NotificationStatus.failed:
        return BadgeVariant.danger;
      case NotificationStatus.draft:
      case NotificationStatus.cancelled:
        return BadgeVariant.neutral;
    }
  }
}
