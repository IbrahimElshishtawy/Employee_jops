import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('notifications.title'),
        subtitle:
            'Ø§Ù„ØªØ­Ø¯ÙŠØ«Ø§ØªØŒ Ø±Ø³Ø§Ø¦Ù„ Ø§Ù„Ù…ÙˆØ§Ø±Ø¯ Ø§Ù„Ø¨Ø´Ø±ÙŠØ©ØŒ ÙˆØ§Ù„Ø®ØµÙˆÙ…Ø§Øª',
        showBackButton: false,
        actions: [
          TextButton(
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
                  'ØªÙ… ØªØ­Ø¯ÙŠØ¯ Ø¬Ù…ÙŠØ¹ Ø§Ù„ØªÙ†Ø¨ÙŠÙ‡Ø§Øª ÙƒÙ…Ù‚Ø±ÙˆØ¡Ø©',
                );
              }
            },
            child: Text(
              context.tr('notifications.mark_all_read'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? EmptyState(
              title: context.tr('notifications.empty'),
              subtitle:
                  'ستتلقى هنا جميع الإشعارات الخاصة بالطلبات والحضور والخصومات',
              icon: Icons.notifications_none_rounded,
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView.separated(
                padding: AppDimensions.pagePadding,
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return NotificationTile(
                    notification: notif,
                    onTap: () async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markAsRead(notif.id);
                      if (context.mounted) {
                        context.push(
                          '/notifications/${notif.id}',
                          extra: notif,
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
