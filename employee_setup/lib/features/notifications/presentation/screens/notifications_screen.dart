import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/models/app_notification.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all'; // all, unread, requests, chat, attendance

  void _onNotificationTapped(AppNotification notif) async {
    // 1. Mark as read immediately
    await ref.read(notificationsRepositoryProvider).markAsRead(notif.id);
    ref.invalidate(unreadNotificationsCountProvider);

    if (!mounted) return;

    // 2. Direct Navigation to target screen
    if (notif.actionRoute != null && notif.actionRoute!.isNotEmpty) {
      context.push(notif.actionRoute!);
      return;
    }

    // Dynamic routing fallback based on category & entity ID
    switch (notif.category) {
      case NotificationCategory.hrMessage:
        if (notif.relatedEntityId != null &&
            notif.relatedEntityId!.startsWith('CONV-')) {
          context.push('/communication/chat/${notif.relatedEntityId}');
        } else {
          context.push('/communication/conversations');
        }
        break;

      case NotificationCategory.requestUpdate:
        if (notif.relatedEntityId != null &&
            notif.relatedEntityId!.startsWith('REQ-')) {
          context.push('/communication/request/${notif.relatedEntityId}');
        } else if (notif.relatedEntityId != null &&
            notif.relatedEntityId!.startsWith('VAC-')) {
          context.push('/requests/vacations');
        } else if (notif.relatedEntityId != null &&
            notif.relatedEntityId!.startsWith('PERM-')) {
          context.push('/requests/permissions');
        } else {
          context.push('/requests');
        }
        break;

      case NotificationCategory.advance:
        context.push('/requests/advances');
        break;

      case NotificationCategory.attendance:
        context.push('/attendance');
        break;

      case NotificationCategory.deduction:
      case NotificationCategory.system:
        context.push('/notifications/${notif.id}', extra: notif);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsListProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    // Filter notifications
    final filtered = notifications.where((n) {
      switch (_selectedFilter) {
        case 'unread':
          return !n.isRead;
        case 'requests':
          return n.category == NotificationCategory.requestUpdate ||
              n.category == NotificationCategory.advance;
        case 'chat':
          return n.category == NotificationCategory.hrMessage;
        case 'attendance':
          return n.category == NotificationCategory.attendance;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppHeader(
        title: isArabic ? 'التنبيهات والإشعارات' : 'Notifications',
        subtitle: isArabic
            ? 'متابعة كافة طلباتك، رسائلك، وحضورك اليومي'
            : 'Track requests, messages, and daily attendance',
        showBackButton: false,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () async {
                final emp = ref.read(currentEmployeeProvider);
                final empId = emp?.id ?? AppConstants.mockEmployeeId;
                await ref
                    .read(notificationsRepositoryProvider)
                    .markAllAsRead(empId);
                ref.invalidate(notificationsListProvider);
                ref.invalidate(unreadNotificationsCountProvider);
                if (context.mounted) {
                  context.showSnackBar(
                    isArabic
                        ? 'تم تحديد جميع التنبيهات كمقروءة'
                        : 'All notifications marked as read',
                  );
                }
              },
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: Text(
                isArabic ? 'تحديد الكل كمقروء' : 'Mark all read',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: isArabic ? 'الكل' : 'All',
                    count: notifications.length,
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: isArabic ? 'غير المقروءة' : 'Unread',
                    count: unreadCount,
                    isSelected: _selectedFilter == 'unread',
                    badgeColor: AppColors.primary,
                    onTap: () => setState(() => _selectedFilter = 'unread'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: isArabic ? 'الطلبات' : 'Requests',
                    isSelected: _selectedFilter == 'requests',
                    onTap: () => setState(() => _selectedFilter = 'requests'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: isArabic ? 'المحادثات' : 'Messages',
                    isSelected: _selectedFilter == 'chat',
                    onTap: () => setState(() => _selectedFilter = 'chat'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: isArabic ? 'الحضور' : 'Attendance',
                    isSelected: _selectedFilter == 'attendance',
                    onTap: () => setState(() => _selectedFilter = 'attendance'),
                  ),
                ],
              ),
            ),
          ),

          // Background & Push Service Status Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'خدمة الإشعارات والعمل في الخلفية'
                            : 'Background & Notification Service',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic
                            ? 'النظام نشط ويتابع مواعيد الحضور والطلبات تلقائياً'
                            : 'Active: Tracking attendance & request updates',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final notifService = ref.read(notificationServiceProvider);
                    await notifService.requestPermission();
                    await notifService.showNotification(
                      id: DateTime.now().millisecondsSinceEpoch % 100000,
                      title: isArabic
                          ? 'تنبيه تجريبي من تطبيق الموظف 🔔'
                          : 'Test Notification from Employee App',
                      body: isArabic
                          ? 'الإشعارات وتتبع الدوام يعملان في الخلفية بشكل ممتاز.'
                          : 'Notifications and background tracking are functioning perfectly.',
                    );
                    if (context.mounted) {
                      context.showSnackBar(
                        isArabic
                            ? 'تم إرسال إشعار تجريبي بنجاح!'
                            : 'Test notification sent successfully!',
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isArabic ? 'تجربة إشعار' : 'Test',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    title: isArabic
                        ? 'لا توجد إشعارات في هذا القسم'
                        : 'No notifications',
                    subtitle: isArabic
                        ? 'ستتلقى هنا جميع التحديثات فور حدوثها في النظام'
                        : 'You will receive updates here as events occur',
                    icon: Icons.notifications_none_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsListProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = filtered[index];
                        return NotificationTile(
                          notification: notif,
                          onTap: () => _onNotificationTapped(notif),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    this.count,
    required this.isSelected,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (badgeColor ?? AppColors.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
