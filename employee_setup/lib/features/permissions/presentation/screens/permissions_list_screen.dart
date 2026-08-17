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
        subtitle: 'أذونات التأخير، الانصراف المبكر، ونصف اليوم',
      ),
      body: listAsync.when(
        data: (perms) {
          if (perms.isEmpty) {
            return EmptyState(
              title: 'لا توجد أذونات استئذان سابقة',
              subtitle: 'يمكنك تقديم طلب إذن تأخير أو انصراف مبكر بسهولة',
              actionLabel: context.tr('permissions.new'),
              onAction: () => context.push('/requests/permissions/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(permissionsListProvider),
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: perms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final perm = perms[index];
                BadgeStatus badge;
                String label;

                switch (perm.status) {
                  case PermissionStatus.pending:
                    badge = BadgeStatus.pending;
                    label = 'قيد المراجعة';
                    break;
                  case PermissionStatus.approved:
                    badge = BadgeStatus.approved;
                    label = 'تمت الموافقة';
                    break;
                  case PermissionStatus.rejected:
                    badge = BadgeStatus.rejected;
                    label = 'مرفوض';
                    break;
                  case PermissionStatus.cancelled:
                    badge = BadgeStatus.cancelled;
                    label = 'ملغي';
                    break;
                }

                String typeName;
                switch (perm.type) {
                  case PermissionType.morningDelay:
                    typeName = 'إذن تأخير صباحي';
                    break;
                  case PermissionType.earlyLeave:
                    typeName = 'إذن انصراف مبكر';
                    break;
                  case PermissionType.fullDayAbsence:
                    typeName = 'إذن غياب يوم';
                    break;
                  case PermissionType.halfDay:
                    typeName = 'إذن نصف يوم';
                    break;
                }

                return RequestCard(
                  title: typeName,
                  subtitle: '${perm.durationOrTime} • ${perm.reason}',
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
        loading: () => const LoadingState(message: 'جاري تحميل أذونات الاستئذان...'),
        error: (err, _) => Center(child: Text('خطأ: $err')),
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
