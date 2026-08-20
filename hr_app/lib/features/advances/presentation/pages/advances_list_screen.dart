import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/advance_entity.dart';
import '../controllers/advances_controller.dart';

/// Salary Advances Management Screen
class AdvancesListScreen extends StatelessWidget {
  const AdvancesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdvancesController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          searchHint: 'Search employee, amount, reason...',
          onSearchChanged: controller.onSearch,
          onRefresh: controller.fetchAdvances,
          filterActions: [
            DropdownButton<AdvanceStatus?>(
              value: controller.statusFilter,
              hint: const Text('All Advance Statuses'),
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Advance Statuses')),
                ...AdvanceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
              ],
              onChanged: controller.onFilterStatus,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),

        HrDataTable<AdvanceEntity>(
          isLoading: controller.isLoading && controller.advances.isEmpty,
          errorMessage: controller.errorMessage,
          onRetry: controller.fetchAdvances,
          items: controller.advances,
          totalItems: controller.totalCount,
          currentPage: controller.currentPage,
          totalPages: controller.totalPages,
          pageSize: controller.pageSize,
          onPageChanged: (page) => controller.fetchAdvances(page: page),
          columns: [
            HrColumn<AdvanceEntity>(
              title: 'Employee',
              cellBuilder: (adv) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(adv.employeeName, style: AppTypography.bodyBold),
                  Text(adv.employeeCode, style: AppTypography.caption),
                ],
              ),
            ),
            HrColumn<AdvanceEntity>(
              title: 'Requested Amount',
              cellBuilder: (adv) => Text(
                '${adv.currency} ${adv.amount.toStringAsFixed(2)}',
                style: AppTypography.bodyBold.copyWith(color: AppColors.primaryLight),
              ),
            ),
            HrColumn<AdvanceEntity>(
              title: 'Requested Date',
              cellBuilder: (adv) => Text(DateFormatter.toDisplayDate(adv.requestedAt), style: AppTypography.body),
            ),
            HrColumn<AdvanceEntity>(
              title: 'Reason',
              cellBuilder: (adv) => Text(adv.reason, style: AppTypography.body, overflow: TextOverflow.ellipsis),
            ),
            HrColumn<AdvanceEntity>(
              title: 'Status',
              cellBuilder: (adv) {
                switch (adv.status) {
                  case AdvanceStatus.pending:
                    return const StatusBadge(label: 'Pending', variant: BadgeVariant.warning);
                  case AdvanceStatus.approved:
                    return const StatusBadge(label: 'Approved', variant: BadgeVariant.info);
                  case AdvanceStatus.paid:
                    return const StatusBadge(label: 'Paid', variant: BadgeVariant.success);
                  case AdvanceStatus.rejected:
                    return const StatusBadge(label: 'Rejected', variant: BadgeVariant.danger);
                  case AdvanceStatus.cancelled:
                    return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral);
                }
              },
            ),
            HrColumn<AdvanceEntity>(
              title: 'Actions',
              cellBuilder: (adv) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (adv.status == AdvanceStatus.pending) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                      tooltip: 'Approve Advance',
                      onPressed: () => _showReviewDialog(context, controller, adv, approve: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
                      tooltip: 'Reject Advance',
                      onPressed: () => _showReviewDialog(context, controller, adv, approve: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showReviewDialog(
    BuildContext context,
    AdvancesController controller,
    AdvanceEntity adv, {
    required bool approve,
  }) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve ? 'Approve Advance' : 'Reject Advance',
          style: AppTypography.heading3.copyWith(
            color: approve ? AppColors.success : AppColors.danger,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee: ${adv.employeeName} (${adv.employeeCode})', style: AppTypography.bodyBold),
              Text('Amount: ${adv.currency} ${adv.amount.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
              Text('Reason: ${adv.reason}', style: AppTypography.caption),
              const SizedBox(height: AppDimensions.space16),
              HrTextField(
                label: 'Notes / Remarks (Optional)',
                hint: 'Enter remarks...',
                controller: noteCtrl,
              ),
            ],
          ),
        ),
        actions: [
          HrButton(label: 'Cancel', variant: HrButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
          HrButton(
            label: approve ? 'Confirm Approval' : 'Confirm Rejection',
            variant: approve ? HrButtonVariant.primary : HrButtonVariant.danger,
            onPressed: () {
              Navigator.pop(context);
              controller.reviewAdvance(
                adv.id,
                approve: approve,
                notes: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }
}
