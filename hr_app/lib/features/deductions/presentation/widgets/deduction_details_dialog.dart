import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/deduction_entity.dart';

/// Modal dialog for inspecting complete deduction details, linkages, and cancellations
class DeductionDetailsDialog extends StatefulWidget {
  final DeductionEntity deduction;
  final bool canCancel;
  final Future<bool> Function(String reason)? onCancel;

  const DeductionDetailsDialog({
    super.key,
    required this.deduction,
    this.canCancel = false,
    this.onCancel,
  });

  @override
  State<DeductionDetailsDialog> createState() => _DeductionDetailsDialogState();
}

class _DeductionDetailsDialogState extends State<DeductionDetailsDialog> {
  bool _isCancelling = false;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.onCancel == null) return;

    setState(() => _isSubmitting = true);
    final success = await widget.onCancel!(_reasonController.text.trim());
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.deduction;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 750),
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
                    backgroundColor: AppColors.danger.withValues(alpha: isDark ? 0.25 : 0.15),
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.danger, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(d.employeeName, style: AppTypography.heading2, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            _buildStatusBadge(d.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.employeeCode}${d.department != null ? ' • ${d.department}' : ''}',
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
                      // Financial Metric Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Deduction Amount',
                              value: '- ${d.currency} ${d.amount.toStringAsFixed(2)}',
                              icon: Icons.money_off_outlined,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Payroll Period',
                              value: d.payrollPeriod,
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Deduction Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deduction Details', style: AppTypography.bodyBold),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(child: _buildInfoItem(context, 'Category / Type', d.type.label)),
                                  Expanded(child: _buildInfoItem(context, 'Created Date', DateFormatter.toDisplayDate(d.date))),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(child: _buildInfoItem(context, 'Created By', d.createdBy)),
                                  Expanded(
                                    child: _buildInfoItem(
                                      context,
                                      'Applied Date',
                                      d.appliedDate != null ? DateFormatter.toDisplayDateTime(d.appliedDate!) : 'Pending Payroll Run',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              Text('Reason / Justification:', style: AppTypography.captionOf(context)),
                              const SizedBox(height: 2),
                              Text(d.reason, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Linked Salary Advance Relation Card
                      if (d.type == DeductionType.salaryAdvance && d.relatedAdvanceId != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.link, size: 16, color: AppColors.primaryLight),
                                    const SizedBox(width: 8),
                                    Text('Linked Salary Advance Schedule', style: AppTypography.bodyBold),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space12),
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoItem(context, 'Advance Reference', d.relatedAdvanceId!)),
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        'Installment Progress',
                                        d.installmentNumber != null && d.totalInstallments != null
                                            ? 'Installment ${d.installmentNumber} of ${d.totalInstallments}'
                                            : 'Standard Repayment',
                                      ),
                                    ),
                                  ],
                                ),
                                if (d.remainingBalance != null) ...[
                                  const SizedBox(height: AppDimensions.space12),
                                  _buildInfoItem(
                                    context,
                                    'Remaining Advance Principal Balance',
                                    '${d.currency} ${d.remainingBalance!.toStringAsFixed(2)}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Cancellation Trail
                      if (d.status == DeductionStatus.cancelled) ...[
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.block, size: 16, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Text('Deduction Cancelled / Waived', style: AppTypography.bodyBold.copyWith(color: AppColors.danger)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                d.cancellationReason ?? 'No reason provided.',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Inline Cancellation Form
                      if (_isCancelling) ...[
                        Card(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cancel / Waive Deduction', style: AppTypography.bodyBold.copyWith(color: AppColors.danger)),
                                  const SizedBox(height: 8),
                                  HrTextField(
                                    label: 'Mandatory Cancellation Justification Reason',
                                    hint: 'State official justification (e.g. Employee provided approved doctor medical note)',
                                    controller: _reasonController,
                                    maxLines: 2,
                                    validator: (v) => Validator.requiredField(v, 'A justified cancellation reason is required'),
                                  ),
                                  const SizedBox(height: AppDimensions.space12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      HrButton(
                                        label: 'Back',
                                        variant: HrButtonVariant.ghost,
                                        onPressed: () => setState(() => _isCancelling = false),
                                      ),
                                      const SizedBox(width: 8),
                                      HrButton(
                                        label: 'Confirm Cancellation',
                                        variant: HrButtonVariant.danger,
                                        isLoading: _isSubmitting,
                                        onPressed: _handleCancel,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                  if (d.status == DeductionStatus.scheduled && widget.canCancel && widget.onCancel != null && !_isCancelling) ...[
                    HrButton(
                      label: 'Cancel Deduction',
                      variant: HrButtonVariant.danger,
                      icon: Icons.block,
                      onPressed: () => setState(() => _isCancelling = true),
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

  Widget _buildStatusBadge(DeductionStatus status) {
    switch (status) {
      case DeductionStatus.scheduled:
        return const StatusBadge(label: 'Scheduled', variant: BadgeVariant.warning, icon: Icons.schedule);
      case DeductionStatus.applied:
        return const StatusBadge(label: 'Applied & Deducted', variant: BadgeVariant.success, icon: Icons.check_circle_outline);
      case DeductionStatus.cancelled:
        return const StatusBadge(label: 'Cancelled / Waived', variant: BadgeVariant.neutral, icon: Icons.block);
      case DeductionStatus.reversed:
        return const StatusBadge(label: 'Reversed', variant: BadgeVariant.danger, icon: Icons.undo);
    }
  }
}
