import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/request_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/advance_request.dart';

class AdvancesListScreen extends ConsumerWidget {
  const AdvancesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(advancesListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('advances.title'),
        subtitle: 'تفاصيل السلف الماليه',
      ),
      body: Builder(
        builder: (context) {
          final advances = listAsync;
          if (advances.isEmpty) {
            return EmptyState(
              title: 'مطلوب الموافق علي السلف  الماليه ',
              subtitle: 'مطلوب الموافق علي الماليه',
              actionLabel: context.tr('advances.new'),
              onAction: () => context.push('/requests/advances/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(advancesListProvider),
            child: ListView.separated(
              padding: AppDimensions.pagePadding,
              itemCount: advances.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final adv = advances[index];
                BadgeStatus statusBadge = BadgeStatus.pending;
                String statusLabel = 'قيد المراجعة';

                switch (adv.status) {
                  case AdvanceStatus.pending:
                    statusBadge = BadgeStatus.pending;
                    statusLabel = 'في الانتظار ';
                    break;
                  case AdvanceStatus.approved:
                    statusBadge = BadgeStatus.approved;
                    statusLabel = 'تم الموافقه ';
                    break;
                  case AdvanceStatus.paid:
                    statusBadge = BadgeStatus.paid;
                    statusLabel = 'قيد التنفيذ';
                    break;
                  case AdvanceStatus.rejected:
                    statusBadge = BadgeStatus.rejected;
                    statusLabel = 'تم الرفض ';
                    break;
                  case AdvanceStatus.reportRequired:
                    statusBadge = BadgeStatus.pending;
                    statusLabel = 'مطلوب المراجه ';
                    break;
                  case AdvanceStatus.reportSubmitted:
                    statusBadge = BadgeStatus.completed;
                    statusLabel = 'تم اكمال المهمه ';
                    break;
                }

                return RequestCard(
                  title: ' نعتذر في طلب : ${adv.amount.toInt()} السعر ',
                  subtitle: adv.reason,
                  date: adv.createdAt,
                  badgeStatus: statusBadge,
                  statusLabel: statusLabel,
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => context.push('/requests/advances/${adv.id}'),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton.primary(
            label: context.tr('advances.new'),
            icon: Icons.add_rounded,
            onPressed: () => context.push('/requests/advances/new'),
          ),
        ),
      ),
    );
  }
}
