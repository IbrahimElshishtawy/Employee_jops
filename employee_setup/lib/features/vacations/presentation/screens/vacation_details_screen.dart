import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/vacation_request.dart';

class VacationDetailsScreen extends ConsumerWidget {
  final String vacationId;

  const VacationDetailsScreen({super.key, required this.vacationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacAsync = ref.watch(vacationsListProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: const AppHeader(title: 'تفاصيل طلب الإجازة'),
      body: Builder(
        builder: (context) {
          final list = vacAsync;
          final vac = list.isEmpty
              ? VacationRequest(
                  id: vacationId,
                  employeeId: 'EMP-1024',
                  type: VacationType.annual,
                  fromDate: DateTime.now(),
                  toDate: DateTime.now(),
                  daysCount: 1,
                  reason: 'إجازة',
                  status: VacationStatus.pending,
                  createdAt: DateTime.now(),
                )
              : list.firstWhere(
                  (e) => e.id == vacationId,
                  orElse: () => VacationRequest(
                    id: vacationId,
                    employeeId: 'EMP-1024',
                    type: VacationType.annual,
                    fromDate: DateTime.now(),
                    toDate: DateTime.now(),
                    daysCount: 1,
                    reason: 'إجازة',
                    status: VacationStatus.pending,
                    createdAt: DateTime.now(),
                  ),
                );

          BadgeStatus badge = BadgeStatus.pending;
          String label = 'قيد المراجعة';
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

          String typeName = 'إجازة';
          switch (vac.type) {
            case VacationType.annual:
              typeName = 'إجازة سنوية';
              break;
            case VacationType.sick:
              typeName = 'إجازة مرضية';
              break;
            case VacationType.casual:
              typeName = 'إجازة عارضة';
              break;
            case VacationType.unpaid:
              typeName = 'إجازة بدون راتب';
              break;
          }

          return SingleChildScrollView(
            padding: AppDimensions.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vac.daysCount} أيام عمل',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(label: label, status: badge),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      _buildInfoRow('رقم الطلب', vac.id, isDark),
                      const Divider(),
                      _buildInfoRow(
                        'من تاريخ',
                        vac.fromDate.toFormattedDate(
                          context.l10n.locale.languageCode,
                        ),
                        isDark,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'إلى تاريخ',
                        vac.toDate.toFormattedDate(
                          context.l10n.locale.languageCode,
                        ),
                        isDark,
                      ),
                      const Divider(),
                      _buildInfoRow('سبب الإجازة', vac.reason, isDark),
                      const Divider(),
                      _buildInfoRow(
                        'تاريخ التقديم',
                        vac.createdAt.toFormattedDateTime(),
                        isDark,
                      ),
                      if (vac.approvedAt != null) ...[
                        const Divider(),
                        _buildInfoRow(
                          'تاريخ الاعتماد',
                          vac.approvedAt!.toFormattedDateTime(),
                          isDark,
                        ),
                      ],
                      if (vac.attachmentName != null) ...[
                        const Divider(),
                        _buildInfoRow(
                          'المرفق',
                          vac.attachmentName!,
                          isDark,
                          isLink: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    bool isLink = false,
  }) {
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
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
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
