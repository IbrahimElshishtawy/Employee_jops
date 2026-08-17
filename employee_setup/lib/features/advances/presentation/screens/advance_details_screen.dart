import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/advance_request.dart';

class AdvanceDetailsScreen extends ConsumerWidget {
  final String advanceId;

  const AdvanceDetailsScreen({super.key, required this.advanceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancesAsync = ref.watch(advancesListProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: const AppHeader(
        title: 'تفاصيل السُلفة المالية',
      ),
      body: advancesAsync.when(
        data: (list) {
          final adv = list.firstWhere(
            (e) => e.id == advanceId,
            orElse: () => AdvanceRequest(
              id: advanceId,
              employeeId: 'EMP-1024',
              amount: 2500,
              reason: 'سُلفة مالية',
              createdAt: DateTime.now(),
              status: AdvanceStatus.pending,
            ),
          );

          BadgeStatus badge;
          String label;
          switch (adv.status) {
            case AdvanceStatus.pending:
              badge = BadgeStatus.pending;
              label = 'قيد المراجعة';
              break;
            case AdvanceStatus.approved:
              badge = BadgeStatus.approved;
              label = 'تمت الموافقة';
              break;
            case AdvanceStatus.paid:
              badge = BadgeStatus.paid;
              label = 'تم الصرف';
              break;
            case AdvanceStatus.rejected:
              badge = BadgeStatus.rejected;
              label = 'مرفوض';
              break;
            case AdvanceStatus.reportRequired:
              badge = BadgeStatus.pending;
              label = 'مطلوب تقرير مصروفات';
              break;
            case AdvanceStatus.reportSubmitted:
              badge = BadgeStatus.completed;
              label = 'تم تقديم التقرير';
              break;
          }

          return SingleChildScrollView(
            padding: AppDimensions.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المبلغ المطلوب',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          StatusBadge(label: label, status: badge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            adv.amount.toInt().toString(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'جنيه مصري',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Details List
                AppCard(
                  child: Column(
                    children: [
                      _buildInfoRow('رقم الطلب', adv.id, isDark),
                      const Divider(),
                      _buildInfoRow('سبب السلفة', adv.reason, isDark),
                      if (adv.details != null) ...[
                        const Divider(),
                        _buildInfoRow('تفاصيل إضافية', adv.details!, isDark),
                      ],
                      const Divider(),
                      _buildInfoRow('أقساط السداد', '${adv.installments} أشهر', isDark),
                      const Divider(),
                      _buildInfoRow('تاريخ التقديم', adv.createdAt.toFormattedDateTime(), isDark),
                      if (adv.approvedAt != null) ...[
                        const Divider(),
                        _buildInfoRow('تاريخ الموافقة', adv.approvedAt!.toFormattedDateTime(), isDark),
                      ],
                      if (adv.attachmentName != null) ...[
                        const Divider(),
                        _buildInfoRow('المرفق', adv.attachmentName!, isDark, isLink: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action if report is required
                if (adv.status == AdvanceStatus.reportRequired || adv.status == AdvanceStatus.approved) ...[
                  AppButton.primary(
                    label: context.tr('advances.submit_report'),
                    icon: Icons.receipt_long_rounded,
                    onPressed: () => context.push('/requests/advances/${adv.id}/report'),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isLink
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
