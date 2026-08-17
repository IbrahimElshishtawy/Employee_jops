import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/vacation_request.dart';

class VacationsListScreen extends ConsumerWidget {
  const VacationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacations = ref.watch(vacationsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('vacations.title'),
        subtitle: 'الإجازات السنوية، المرضية، والعارضة',
      ),
      body: vacations.isEmpty
          ? EmptyState(
              title: 'لا توجد طلبات إجازة سابقة',
              subtitle: 'يمكنك التخطيط لإجازتك القادمة وتقديم طلب جديد',
              actionLabel: context.tr('vacations.new'),
              onAction: () => context.push('/requests/vacations/new'),
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView.separated(
                padding: AppDimensions.pagePadding,
                itemCount: vacations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final vac = vacations[index];

                  final badge = switch (vac.status) {
                    VacationStatus.pending => BadgeStatus.pending,
                    VacationStatus.approved => BadgeStatus.approved,
                    VacationStatus.rejected => BadgeStatus.rejected,
                    VacationStatus.cancelled => BadgeStatus.cancelled,
                  };
                  final label = switch (vac.status) {
                    VacationStatus.pending => 'قيد المراجعة',
                    VacationStatus.approved => 'تمت الموافقة',
                    VacationStatus.rejected => 'مرفوض',
                    VacationStatus.cancelled => 'ملغي',
                  };
                  final typeName = switch (vac.type) {
                    VacationType.annual =>
                      'إجازة سنوية (${vac.daysCount} أيام)',
                    VacationType.sick => 'إجازة مرضية (${vac.daysCount} أيام)',
                    VacationType.casual => 'إجازة عارضة (${vac.daysCount} يوم)',
                    VacationType.unpaid => 'إجازة بدون راتب',
                  };

                  return RequestCard(
                    title: typeName,
                    subtitle:
                        '${vac.fromDate.toFormattedShortDate()} إلى ${vac.toDate.toFormattedShortDate()} • ${vac.reason}',
                    date: vac.createdAt,
                    badgeStatus: badge,
                    statusLabel: label,
                    icon: Icons.beach_access_outlined,
                    onTap: () => context.push('/requests/vacations/${vac.id}'),
                  );
                },
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton.primary(
            label: context.tr('vacations.new'),
            icon: Icons.add_rounded,
            onPressed: () => context.push('/requests/vacations/new'),
          ),
        ),
      ),
    );
  }
}
