import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';

class NewAdvanceScreen extends ConsumerStatefulWidget {
  const NewAdvanceScreen({super.key});

  @override
  ConsumerState<NewAdvanceScreen> createState() => _NewAdvanceScreenState();
}

class _NewAdvanceScreenState extends ConsumerState<NewAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();

  int _selectedInstallments = 1;
  String? _attachedFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final emp = ref.read(currentEmployeeProvider);
    final empId = emp?.id ?? AppConstants.mockEmployeeId;

    await ref.read(advancesRepositoryProvider).createAdvance(
          employeeId: empId,
          amount: amount,
          reason: _reasonController.text.trim(),
          details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
          installments: _selectedInstallments,
          attachmentName: _attachedFileName,
        );

    ref.invalidate(advancesListProvider);
    ref.invalidate(allRequestsProvider);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.showSnackBar('تم تقديم طلب السُلفة بنجاح وهو قيد المراجعة');
    context.pop();
  }

  void _pickMockAttachment() {
    setState(() {
      _attachedFileName = 'receipt_invoice_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf';
    });
    context.showSnackBar('تم إرفاق الملف بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('advances.new'),
        subtitle: 'تقديم طلب سُلفة مالية للإدارة',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              AppTextField(
                label: '${context.tr('advances.amount')} (بالجنيه المصري)',
                hintText: 'مثال: 2000',
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primary),
                validator: (val) => Validators.positiveNumber(val, 'يرجى إدخال مبلغ صحيح'),
              ),
              const SizedBox(height: 16),

              // Reason Input
              AppTextField(
                label: context.tr('advances.reason'),
                hintText: 'مثال: سُلفة شراء أجهزة عمل ومستلزمات',
                controller: _reasonController,
                validator: (val) => Validators.required(val, 'يرجى ذكر سبب السُلفة'),
              ),
              const SizedBox(height: 16),

              // Installments Dropdown / Choice
              Text(
                context.tr('advances.installments'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [1, 2, 3, 6].map((months) {
                  final isSelected = _selectedInstallments == months;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ChoiceChip(
                      label: Text('$months ${months == 1 ? "شهر" : "أشهر"}'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedInstallments = months),
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Additional Details
              AppTextField(
                label: context.tr('advances.details'),
                hintText: 'أضف أي تفاصيل أو مبررات إضافية للطلب...',
                controller: _detailsController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Attachments
              Text(
                context.tr('advances.attachment'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                onTap: _pickMockAttachment,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.attach_file_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachedFileName ?? 'إرفاق فواتير أو مستندات داعمة',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _attachedFileName != null ? 'تم إرفاق المستند بنجاح' : 'PDF, JPG, PNG حتى 10MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_attachedFileName != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _attachedFileName = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              AppButton.primary(
                label: context.tr('common.submit'),
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
