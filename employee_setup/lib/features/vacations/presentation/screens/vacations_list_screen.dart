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
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/vacation_request.dart';

class VacationsListScreen extends ConsumerWidget {
  const VacationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(vacationsListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('vacations.title'),
        subtitle: 'الإجازات السنوية، المرضية، والعارضة',
      ),
      body: listAsync.when(
        data: (vacations) {
          if (vacations.isEmpty) {
            return EmptyState(
              title: 'لا توجد طلبات إجازة سابقة',
              subtitle: 'يمكنك التخطيط لإجازتك القادمة وتقديم طلب جديد',
              actionLabel: context.tr('vacations.new'),
              onAction: () => context.push('/requests/vacations/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(vacationsListProvider),
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: vacations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vac = vacations[index];
                BadgeStatus badge;
                String label;

                switch (vac.status) {
                  case VacationStatus.pending:
                    badge = BadgeStatus.pending;
                    label = 'قيد المراجعة';
                    break;
                  case VacationStatus.approved:
                    badge = BadgeStatus.approved;
                    label = 'تمت الموافقة';
                    break;
                  case VacationStatus.rejected:
                    badge = BadgeStatus.rejected;
                    label = 'مرفوض';
                    break;
                  case VacationStatus.cancelled:
                    badge = BadgeStatus.cancelled;
                    label = 'ملغي';
                    break;
                }

                String typeName;
                switch (vac.type) {
                  case VacationType.annual:
                    typeName = 'إجازة سنوية (${vac.daysCount} أيام)';
                    break;
                  case VacationType.sick:
                    typeName = 'إجازة مرضية (${vac.daysCount} أيام)';
                    break;
                  case VacationType.casual:
                    typeName = 'إجازة عارضة (${vac.daysCount} يوم)';
                    break;
                  case VacationType.unpaid:
                    typeName = 'إجازة بدون راتب';
                    break;
                }

                return RequestCard(
                  title: typeName,
                  subtitle: '${vac.fromDate.toFormattedShortDate()} إلى ${vac.toDate.toFormattedShortDate()} • ${vac.reason}',
                  date: vac.createdAt,
                  badgeStatus: badge,
                  statusLabel: label,
                  icon: Icons.beach_access_outlined,
                  onTap: () => context.push('/requests/vacations/${vac.id}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingState(message: 'جاري تحميل الإجازات...'),
        error: (err, _) => Center(child: Text('خطأ: $err')),
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
