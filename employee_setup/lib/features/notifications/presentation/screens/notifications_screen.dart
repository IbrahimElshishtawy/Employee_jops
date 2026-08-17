import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('notifications.title'),
        subtitle: 'التحديثات، رسائل الموارد البشرية، والخصومات',
        showBackButton: false,
        actions: [
          TextButton(
            onPressed: () async {
              final emp = ref.read(currentEmployeeProvider);
              final empId = emp?.id ?? AppConstants.mockEmployeeId;
              await ref.read(notificationsRepositoryProvider).markAllAsRead(empId);
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              if (context.mounted) {
                context.showSnackBar('تم تحديد جميع التنبيهات كمقروءة');
              }
            },
            child: Text(
              context.tr('notifications.mark_all_read'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return EmptyState(
              title: context.tr('notifications.empty'),
              subtitle: 'ستتلقى هنا جميع الإشعارات الخاصة بالطلبات والحضور والخصومات',
              icon: Icons.notifications_none_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return NotificationTile(
                  notification: notif,
                  onTap: () async {
                    await ref.read(notificationsRepositoryProvider).markAsRead(notif.id);
                    ref.invalidate(notificationsListProvider);
                    ref.invalidate(unreadNotificationsCountProvider);

                    if (context.mounted) {
                      context.push('/notifications/${notif.id}', extra: notif);
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const LoadingState(message: 'جاري تحميل التنبيهات...'),
        error: (err, _) => Center(child: Text('خطأ: $err')),
      ),
    );
  }
}
