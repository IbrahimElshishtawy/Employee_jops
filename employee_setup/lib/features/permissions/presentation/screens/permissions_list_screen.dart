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
    final perms = ref.watch(permissionsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('permissions.title'),
        subtitle: 'أذونات التأخير، الانصراف المبكر، ونصف اليوم',
      ),
      body: perms.isEmpty
          ? EmptyState(
              title: 'لا توجد أذونات استئذان سابقة',
              subtitle: 'يمكنك تقديم طلب إذن تأخير أو انصراف مبكر بسهولة',
              actionLabel: context.tr('permissions.new'),
              onAction: () => context.push('/requests/permissions/new'),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(permissionsListProvider),
              child: ListView.separated(
                padding: AppDimensions.pagePadding,
                itemCount: perms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final perm = perms[index];

                  final badge = switch (perm.status) {
                    PermissionStatus.pending => BadgeStatus.pending,
                    PermissionStatus.approved => BadgeStatus.approved,
                    PermissionStatus.rejected => BadgeStatus.rejected,
                    PermissionStatus.cancelled => BadgeStatus.cancelled,
                  };
                  final label = switch (perm.status) {
                    PermissionStatus.pending => 'قيد المراجعة',
                    PermissionStatus.approved => 'تمت الموافقة',
                    PermissionStatus.rejected => 'مرفوض',
                    PermissionStatus.cancelled => 'ملغي',
                  };
                  final typeName = switch (perm.type) {
                    PermissionType.morningDelay => 'إذن تأخير صباحي',
                    PermissionType.earlyLeave => 'إذن انصراف مبكر',
                    PermissionType.fullDayAbsence => 'إذن غياب يوم',
                    PermissionType.halfDay => 'إذن نصف يوم',
                  };

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
