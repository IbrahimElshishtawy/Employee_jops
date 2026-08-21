import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/advance_entity.dart';

/// Modal dialog for approving (with approved amount & installment count) or rejecting salary advances
class AdvanceReviewDialog extends StatefulWidget {
  final AdvanceEntity advance;
  final bool isApproval;
  final Future<bool> Function({
    required bool approve,
    double? approvedAmount,
    int? installmentCount,
    String? reasonOrNotes,
  }) onReview;

  const AdvanceReviewDialog({
    super.key,
    required this.advance,
    required this.isApproval,
    required this.onReview,
  });

  @override
  State<AdvanceReviewDialog> createState() => _AdvanceReviewDialogState();
}

class _AdvanceReviewDialogState extends State<AdvanceReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _approvedAmountController;
  final TextEditingController _notesOrReasonController = TextEditingController();
  int _installmentCount = 1;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _approvedAmountController = TextEditingController(
      text: widget.advance.amount.toStringAsFixed(2),
    );
    _installmentCount = widget.advance.installmentCount > 0 ? widget.advance.installmentCount : 1;
  }

  @override
  void dispose() {
    _approvedAmountController.dispose();
    _notesOrReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isApproval = widget.isApproval;
    final approvedAmount = double.tryParse(_approvedAmountController.text.trim()) ?? widget.advance.amount;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onReview(
      approve: isApproval,
      approvedAmount: isApproval ? approvedAmount : null,
      installmentCount: isApproval ? _installmentCount : null,
      reasonOrNotes: _notesOrReasonController.text.trim().isNotEmpty
          ? _notesOrReasonController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = isApproval
              ? 'Unable to approve salary advance.'
              : 'Unable to reject salary advance.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adv = widget.advance;
    final isApproval = widget.isApproval;

    final parsedAmount = double.tryParse(_approvedAmountController.text) ?? adv.amount;
    final monthlyDeduction = _installmentCount > 0 ? parsedAmount / _installmentCount : parsedAmount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: (isApproval ? AppColors.success : AppColors.danger).withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproval ? Icons.monetization_on_outlined : Icons.cancel_outlined,
                        color: isApproval ? AppColors.success : AppColors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproval ? 'Approve Salary Advance' : 'Reject Salary Advance',
                            style: AppTypography.heading3,
                          ),
                          Text(
                            '${adv.employeeName} (${adv.employeeCode})',
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

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                ],

                // Advance Financial Summary Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Requested Amount', '${adv.currency} ${adv.amount.toStringAsFixed(2)}'),
                      if (adv.currentSalary != null)
                        _buildSummaryRow('Current Monthly Salary', '${adv.currency} ${adv.currentSalary!.toStringAsFixed(2)}'),
                      _buildSummaryRow('Employee Justification', adv.reason),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                if (isApproval) ...[
                  // Approved Amount & Installment Count Row
                  Row(
                    children: [
                      Expanded(
                        child: HrTextField(
                          label: 'Approved Amount (${adv.currency})',
                          hint: '0.00',
                          controller: _approvedAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Approved amount is required';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Must be a positive amount';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Installment Period', style: AppTypography.captionOf(context)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              initialValue: _installmentCount,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                              ),
                              items: [1, 2, 3, 4, 5, 6, 8, 10, 12].map((i) {
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(i == 1 ? '1 Month (Lump Sum)' : '$i Months'),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _installmentCount = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Scheduled Monthly Deduction preview
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calculated Monthly Deduction:', style: AppTypography.captionOf(context)),
                        Text(
                          '${adv.currency} ${monthlyDeduction.toStringAsFixed(2)} / month',
                          style: AppTypography.bodyBold.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  HrTextField(
                    label: 'Approval Notes / Payroll Remarks (Optional)',
                    hint: 'e.g. Disbursed with upcoming mid-month payroll cycle',
                    controller: _notesOrReasonController,
                    maxLines: 2,
                  ),
                ] else ...[
                  HrTextField(
                    label: 'Mandatory Rejection Justification Reason',
                    hint: 'Explain reason for advance rejection (e.g. Exceeds max policy threshold)',
                    controller: _notesOrReasonController,
                    maxLines: 3,
                    validator: (v) => Validator.requiredField(v, 'A justified rejection reason is mandatory'),
                  ),
                ],
                const SizedBox(height: AppDimensions.space20),

                // Actions Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HrButton(
                      label: 'Cancel',
                      variant: HrButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    HrButton(
                      label: isApproval ? 'Confirm Approval' : 'Confirm Rejection',
                      variant: isApproval ? HrButtonVariant.primary : HrButtonVariant.danger,
                      icon: isApproval ? Icons.check_circle_outline : Icons.cancel,
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTypography.captionOf(context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTypography.bodyBold,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
