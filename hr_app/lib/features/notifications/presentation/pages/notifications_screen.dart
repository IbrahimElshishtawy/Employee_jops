import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_details_dialog.dart';
import '../widgets/notification_form_dialog.dart';

/// Comprehensive HR Notifications and Announcements Management Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _showDetails(BuildContext context, NotificationItemEntity item, NotificationsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => NotificationDetailsDialog(
        notification: item,
        onMarkRead: () => controller.markAsRead(item.id),
        onCancelScheduled: () => controller.cancelScheduled(item.id),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, NotificationsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => NotificationFormDialog(
        onSend: (notification) async {
          final success = await controller.createNotification(notification);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notification.scheduledAt != null
                    ? 'Broadcast scheduled successfully.'
                    : 'Announcement dispatched successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canManage = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.notificationsManage);
    final kpis = controller.kpis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HR Notifications & Announcements Management', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Broadcast company notices, manage system alerts, and track push delivery status to employee devices',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  HrButton(
                    label: 'Mark All Read',
                    icon: Icons.done_all,
                    variant: HrButtonVariant.outline,
                    onPressed: controller.markAllAsRead,
                  ),
                  if (canManage) ...[
                    const SizedBox(width: AppDimensions.space12),
                    HrButton(
                      label: 'New Announcement',
                      icon: Icons.campaign_outlined,
                      variant: HrButtonVariant.primary,
                      onPressed: () => _showCreateDialog(context, controller),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Notifications',
                  value: kpis != null ? '${kpis.totalCount}' : '—',
                  subtitle: 'All notices & alerts',
                  icon: Icons.notifications_none_outlined,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Sent Broadcasts',
                  value: kpis != null ? '${kpis.sentCount}' : '—',
                  subtitle: 'Delivered to devices',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Scheduled',
                  value: kpis != null ? '${kpis.scheduledCount}' : '—',
                  subtitle: 'Pending dispatch',
                  icon: Icons.alarm,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Unread Alerts',
                  value: kpis != null ? '${kpis.unreadCount}' : '—',
                  subtitle: 'Requires attention',
                  icon: Icons.mark_email_unread_outlined,
                  iconColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Subtabs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NotificationsTab.values.map((tab) {
              final isSelected = controller.activeTab == tab;
              return ChoiceChip(
                label: Text(tab.label),
                selected: isSelected,
                selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                onSelected: (selected) {
                  if (selected) controller.setActiveTab(tab);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Filter Bar
          FilterBar(
            searchHint: 'Search notifications by title, message, creator...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchNotifications,
            filterActions: [
              // Category Filter
              DropdownButton<NotificationType?>(
                value: controller.typeFilter,
                hint: const Text('All Categories'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...NotificationType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                ],
                onChanged: controller.onFilterType,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Notifications Data Table
          HrDataTable<NotificationItemEntity>(
            isLoading: controller.isLoading && controller.notifications.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: controller.fetchNotifications,
            items: controller.notifications,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchNotifications(page: page),
            onRowTap: (item) => _showDetails(context, item, controller),
            emptyMessage: 'No notifications found matching the selected filters.',
            columns: [
              HrColumn<NotificationItemEntity>(
                title: 'Notification Title & Message',
                cellBuilder: (item) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            item.title,
                            style: item.isRead ? AppTypography.body : AppTypography.bodyBold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.message,
                      style: AppTypography.captionOf(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              HrColumn<NotificationItemEntity>(
                title: 'Category',
                cellBuilder: (item) => StatusBadge(
                  label: item.type.label,
                  variant: _getTypeVariant(item.type),
                ),
              ),
              HrColumn<NotificationItemEntity>(
                title: 'Target Audience',
                cellBuilder: (item) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.targetType.label, style: AppTypography.bodyBold),
                    Text('${item.targetCount} recipients', style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<NotificationItemEntity>(
                title: 'Status',
                cellBuilder: (item) => StatusBadge(
                  label: item.status.label,
                  variant: _getStatusVariant(item.status),
                ),
              ),
              HrColumn<NotificationItemEntity>(
                title: 'Date & Time',
                cellBuilder: (item) => Text(
                  DateFormatter.toDisplayDateTime(item.scheduledAt ?? item.sentAt ?? item.createdAt),
                  style: AppTypography.bodyMedium,
                ),
              ),
              HrColumn<NotificationItemEntity>(
                title: 'Read Count',
                cellBuilder: (item) => Text('${item.readCount} read', style: AppTypography.body),
              ),
              HrColumn<NotificationItemEntity>(
                title: 'Actions',
                cellBuilder: (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details & Preview',
                      onPressed: () => _showDetails(context, item, controller),
                    ),
                    if (item.status == NotificationStatus.scheduled && canManage)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                        tooltip: 'Cancel Scheduled Broadcast',
                        onPressed: () => controller.cancelScheduled(item.id),
                      )
                    else if (!item.isRead)
                      IconButton(
                        icon: const Icon(Icons.done, size: 18),
                        tooltip: 'Mark as Read',
                        onPressed: () => controller.markAsRead(item.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeVariant _getTypeVariant(NotificationType t) {
    switch (t) {
      case NotificationType.companyAnnouncement:
      case NotificationType.holidayNotice:
        return BadgeVariant.info;
      case NotificationType.attendanceReminder:
      case NotificationType.workplaceNotice:
        return BadgeVariant.warning;
      case NotificationType.systemAlert:
        return BadgeVariant.danger;
      case NotificationType.payrollNotice:
        return BadgeVariant.success;
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
