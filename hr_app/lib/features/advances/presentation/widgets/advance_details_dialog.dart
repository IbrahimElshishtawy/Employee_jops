import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/advance_entity.dart';
import 'advance_review_dialog.dart';

/// Modal dialog for inspecting complete salary advance details, installment schedules, and deductions
class AdvanceDetailsDialog extends StatelessWidget {
  final AdvanceEntity advance;
  final bool canReview;
  final Future<bool> Function({
    required bool approve,
    double? approvedAmount,
    int? installmentCount,
    String? reasonOrNotes,
  })? onReview;

  const AdvanceDetailsDialog({
    super.key,
    required this.advance,
    this.canReview = false,
    this.onReview,
  });

  void _openReviewDialog(BuildContext context, bool isApproval) {
    if (onReview == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AdvanceReviewDialog(
        advance: advance,
        isApproval: isApproval,
        onReview: onReview!,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adv = advance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                    child: Text(
                      adv.employeeName.isNotEmpty ? adv.employeeName[0].toUpperCase() : 'E',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(adv.employeeName, style: AppTypography.heading2),
                            const SizedBox(width: AppDimensions.space8),
                            _buildStatusBadge(adv.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${adv.employeeCode}${adv.department != null && adv.department!.isNotEmpty ? ' • ${adv.department}' : ''}',
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              const Divider(),
              const SizedBox(height: AppDimensions.space12),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Requested Amount',
                              value: '${adv.currency} ${adv.amount.toStringAsFixed(2)}',
                              icon: Icons.request_quote_outlined,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Approved Amount',
                              value: adv.approvedAmount != null
                                  ? '${adv.currency} ${adv.approvedAmount!.toStringAsFixed(2)}'
                                  : 'Pending Review',
                              icon: Icons.check_circle_outline,
                              color: adv.approvedAmount != null ? AppColors.success : null,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Outstanding Balance',
                              value: '${adv.currency} ${adv.remainingBalance.toStringAsFixed(2)}',
                              icon: Icons.account_balance_wallet_outlined,
                              color: adv.remainingBalance > 0 ? AppColors.warning : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Reason and Submission context
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Requested On: ${DateFormatter.toDisplayDate(adv.requestedAt)}', style: AppTypography.bodyBold),
                                  if (adv.currentSalary != null)
                                    Text('Monthly Salary: ${adv.currency} ${adv.currentSalary!.toStringAsFixed(2)}', style: AppTypography.captionOf(context)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Purpose / Justification:', style: AppTypography.captionOf(context)),
                              const SizedBox(height: 4),
                              Text(adv.reason, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Review Details (if reviewed)
                      if (adv.status != AdvanceStatus.pending) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      adv.status == AdvanceStatus.rejected ? Icons.cancel_outlined : Icons.verified_outlined,
                                      size: 16,
                                      color: adv.status == AdvanceStatus.rejected ? AppColors.danger : AppColors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Review Decision Outcome', style: AppTypography.bodyBold),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space12),
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoItem(context, 'Reviewed By', adv.reviewedBy ?? 'HR Administrator')),
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        'Review Date',
                                        adv.reviewedAt != null ? DateFormatter.toDisplayDateTime(adv.reviewedAt!) : '—',
                                      ),
                                    ),
                                  ],
                                ),
                                if (adv.rejectionReason != null && adv.rejectionReason!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Rejection Justification:', style: AppTypography.captionOf(context)),
                                  const SizedBox(height: 2),
                                  Text(
                                    adv.rejectionReason!,
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                                  ),
                                ],
                                if (adv.notes != null && adv.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Approval Notes:', style: AppTypography.captionOf(context)),
                                  const SizedBox(height: 2),
                                  Text(adv.notes!, style: AppTypography.bodyMedium),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Installment Plan Schedule Table
                      if (adv.installments.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primaryLight),
                                        const SizedBox(width: 8),
                                        Text('Installment Repayment Schedule', style: AppTypography.bodyBold),
                                      ],
                                    ),
                                    Text('${adv.paidInstallmentCount} of ${adv.installmentCount} Paid', style: AppTypography.captionOf(context)),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space12),
                                Table(
                                  border: TableBorder.all(color: AppColors.border(context), width: 0.5),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1),
                                    1: FlexColumnWidth(2),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2),
                                    4: FlexColumnWidth(2),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      children: const [
                                        Padding(padding: EdgeInsets.all(8), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Remaining', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                    ...adv.installments.map((inst) {
                                      return TableRow(
                                        children: [
                                          Padding(padding: const EdgeInsets.all(8), child: Text('${inst.installmentNumber}')),
                                          Padding(padding: const EdgeInsets.all(8), child: Text(DateFormatter.toDisplayDate(inst.dueDate))),
                                          Padding(padding: const EdgeInsets.all(8), child: Text('${adv.currency} ${inst.amount.toStringAsFixed(2)}')),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              inst.status.label,
                                              style: TextStyle(
                                                color: inst.status == InstallmentStatus.paid ? AppColors.success : AppColors.warning,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Padding(padding: const EdgeInsets.all(8), child: Text('${adv.currency} ${inst.remainingBalance.toStringAsFixed(2)}')),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Linked Payroll Deductions
                      if (adv.deductions.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.primaryLight),
                                    const SizedBox(width: 8),
                                    Text('Linked Payroll Deductions', style: AppTypography.bodyBold),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: adv.deductions.length,
                                  separatorBuilder: (_, _) => const Divider(height: 12),
                                  itemBuilder: (context, index) {
                                    final ded = adv.deductions[index];
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(ded.payrollPeriod, style: AppTypography.bodyBold),
                                            Text('Deduction on: ${DateFormatter.toDisplayDate(ded.deductionDate)}', style: AppTypography.captionOf(context)),
                                          ],
                                        ),
                                        Text(
                                          '- ${adv.currency} ${ded.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (adv.status == AdvanceStatus.pending && canReview && onReview != null) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        HrButton(
                          label: 'Reject',
                          variant: HrButtonVariant.danger,
                          icon: Icons.cancel_outlined,
                          onPressed: () => _openReviewDialog(context, false),
                        ),
                        HrButton(
                          label: 'Approve',
                          variant: HrButtonVariant.primary,
                          icon: Icons.monetization_on_outlined,
                          onPressed: () => _openReviewDialog(context, true),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                  HrButton(
                    label: 'Close',
                    variant: HrButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required IconData icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.captionOf(context)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.bodyBold.copyWith(color: color, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.captionOf(context)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }

  Widget _buildStatusBadge(AdvanceStatus status) {
    switch (status) {
      case AdvanceStatus.pending:
        return const StatusBadge(label: 'Pending Approval', variant: BadgeVariant.warning, icon: Icons.hourglass_empty);
      case AdvanceStatus.approved:
        return const StatusBadge(label: 'Approved & Active', variant: BadgeVariant.info, icon: Icons.verified_outlined);
      case AdvanceStatus.paid:
        return const StatusBadge(label: 'Fully Settled', variant: BadgeVariant.success, icon: Icons.check_circle_outline);
      case AdvanceStatus.rejected:
        return const StatusBadge(label: 'Rejected', variant: BadgeVariant.danger, icon: Icons.cancel_outlined);
      case AdvanceStatus.cancelled:
        return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral, icon: Icons.block);
    }
  }
}
