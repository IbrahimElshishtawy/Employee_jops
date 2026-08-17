import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/permission_request.dart';

class PermissionsListScreen extends ConsumerWidget {
  const PermissionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(permissionsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('permissions.title'),
        subtitle: 'Ø£Ø°ÙˆÙ†Ø§Øª Ø§Ù„ØªØ£Ø®ÙŠØ±ØŒ Ø§Ù„Ø§Ù†ØµØ±Ø§Ù Ø§Ù„Ù…Ø¨ÙƒØ±ØŒ ÙˆÙ†ØµÙ Ø§Ù„ÙŠÙˆÙ…',
      ),
      body: listAsync.when(
        data: (perms) {
          if (perms.isEmpty) {
            return EmptyState(
              title: 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø£Ø°ÙˆÙ†Ø§Øª Ø§Ø³ØªØ¦Ø°Ø§Ù† Ø³Ø§Ø¨Ù‚Ø©',
              subtitle: 'ÙŠÙ…ÙƒÙ†Ùƒ ØªÙ‚Ø¯ÙŠÙ… Ø·Ù„Ø¨ Ø¥Ø°Ù† ØªØ£Ø®ÙŠØ± Ø£Ùˆ Ø§Ù†ØµØ±Ø§Ù Ù…Ø¨ÙƒØ± Ø¨Ø³Ù‡ÙˆÙ„Ø©',
              actionLabel: context.tr('permissions.new'),
              onAction: () => context.push('/requests/permissions/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(permissionsListProvider),
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: perms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final perm = perms[index];
                BadgeStatus badge;
                String label;

                switch (perm.status) {
                  case PermissionStatus.pending:
                    badge = BadgeStatus.pending;
                    label = 'Ù‚ÙŠØ¯ Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©';
                    break;
                  case PermissionStatus.approved:
                    badge = BadgeStatus.approved;
                    label = 'ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø©';
                    break;
                  case PermissionStatus.rejected:
                    badge = BadgeStatus.rejected;
                    label = 'Ù…Ø±ÙÙˆØ¶';
                    break;
                  case PermissionStatus.cancelled:
                    badge = BadgeStatus.cancelled;
                    label = 'Ù…Ù„ØºÙŠ';
                    break;
                }

                String typeName;
                switch (perm.type) {
                  case PermissionType.morningDelay:
                    typeName = 'Ø¥Ø°Ù† ØªØ£Ø®ÙŠØ± ØµØ¨Ø§Ø­ÙŠ';
                    break;
                  case PermissionType.earlyLeave:
                    typeName = 'Ø¥Ø°Ù† Ø§Ù†ØµØ±Ø§Ù Ù…Ø¨ÙƒØ±';
                    break;
                  case PermissionType.fullDayAbsence:
                    typeName = 'Ø¥Ø°Ù† ØºÙŠØ§Ø¨ ÙŠÙˆÙ…';
                    break;
                  case PermissionType.halfDay:
                    typeName = 'Ø¥Ø°Ù† Ù†ØµÙ ÙŠÙˆÙ…';
                    break;
                }

                return RequestCard(
                  title: typeName,
                  subtitle: '${perm.durationOrTime} â€¢ ${perm.reason}',
                  date: perm.date,
                  badgeStatus: badge,
                  statusLabel: label,
                  icon: Icons.timer_outlined,
                  onTap: () => context.push('/requests/permissions/${perm.id}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingState(message: 'Ø¬Ø§Ø±ÙŠ ØªØ­Ù…ÙŠÙ„ Ø£Ø°ÙˆÙ†Ø§Øª Ø§Ù„Ø§Ø³ØªØ¦Ø°Ø§Ù†...'),
        error: (err, _) => Center(child: Text('Ø®Ø·Ø£: $err')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton.primary(
            label: context.tr('permissions.new'),
            icon: Icons.add_rounded,
            onPressed: () => context.push('/requests/permissions/new'),
          ),
        ),
      ),
    );
  }
}
