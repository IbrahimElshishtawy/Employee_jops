import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/deduction_entity.dart';

/// Modal dialog for creating manual discretionary deductions
class DeductionFormDialog extends StatefulWidget {
  final Future<bool> Function(DeductionEntity deduction) onCreate;

  const DeductionFormDialog({
    super.key,
    required this.onCreate,
  });

  @override
  State<DeductionFormDialog> createState() => _DeductionFormDialogState();
}

class _DeductionFormDialogState extends State<DeductionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _employeeNameController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _payrollPeriodController = TextEditingController(text: 'August 2026 Payroll');
  DeductionType _selectedType = DeductionType.penalty;
  String _department = 'Engineering';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeCodeController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _payrollPeriodController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive deduction amount.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final newDeduction = DeductionEntity(
      id: 'DED-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: 'EMP-${_employeeCodeController.text.trim()}',
      employeeName: _employeeNameController.text.trim(),
      employeeCode: _employeeCodeController.text.trim(),
      department: _department,
      type: _selectedType,
      amount: amount,
      currency: 'USD',
      status: DeductionStatus.scheduled,
      payrollPeriod: _payrollPeriodController.text.trim(),
      reason: _reasonController.text.trim(),
      date: DateTime.now(),
      createdBy: 'HR Administrator (Manual Entry)',
    );

    final success = await widget.onCreate(newDeduction);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Unable to create deduction record.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        color: AppColors.danger.withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_card_outlined, color: AppColors.danger, size: 22),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Discretionary Deduction', style: AppTypography.heading3),
                          Text('Schedule a deduction for upcoming payroll', style: AppTypography.captionOf(context)),
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

                // Employee Fields
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: HrTextField(
                        label: 'Employee Name',
                        hint: 'e.g. Alex Vance',
                        controller: _employeeNameController,
                        validator: (v) => Validator.requiredField(v, 'Employee name is required'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: HrTextField(
                        label: 'Employee Code',
                        hint: 'e.g. CW-001',
                        controller: _employeeCodeController,
                        validator: (v) => Validator.requiredField(v, 'Code is required'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Category & Department
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deduction Category', style: AppTypography.captionOf(context)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<DeductionType>(
                            initialValue: _selectedType,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                            ),
                            items: [
                              DeductionType.penalty,
                              DeductionType.absence,
                              DeductionType.lateArrival,
                              DeductionType.damage,
                              DeductionType.other,
                            ].map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedType = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Department', style: AppTypography.captionOf(context)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _department,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                            ),
                            items: [
                              'Engineering',
                              'Human Resources',
                              'Operations',
                              'Finance',
                              'Marketing',
                              'Legal',
                            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _department = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Amount & Payroll Period
                Row(
                  children: [
                    Expanded(
                      child: HrTextField(
                        label: 'Deduction Amount (USD)',
                        hint: '0.00',
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => Validator.requiredField(v, 'Amount is required'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: HrTextField(
                        label: 'Target Payroll Period',
                        hint: 'e.g. August 2026 Payroll',
                        controller: _payrollPeriodController,
                        validator: (v) => Validator.requiredField(v, 'Payroll period is required'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Justification Reason
                HrTextField(
                  label: 'Mandatory Policy Justification Reason',
                  hint: 'Explain reason for deduction (e.g. Asset loss or unexcused absence)',
                  controller: _reasonController,
                  maxLines: 2,
                  validator: (v) => Validator.requiredField(v, 'Reason justification is required'),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Action buttons
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
                      label: 'Schedule Deduction',
                      variant: HrButtonVariant.primary,
                      icon: Icons.check,
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
}
