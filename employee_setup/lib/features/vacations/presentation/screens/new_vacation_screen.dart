import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/vacation_request.dart';

class NewVacationScreen extends ConsumerStatefulWidget {
  const NewVacationScreen({super.key});

  @override
  ConsumerState<NewVacationScreen> createState() => _NewVacationScreenState();
}

class _NewVacationScreenState extends ConsumerState<NewVacationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  VacationType _selectedType = VacationType.annual;
  DateTime _fromDate = DateTime.now().add(const Duration(days: 3));
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));
  String? _attachedReportName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _calculatedDays {
    return _toDate.difference(_fromDate).inDays + 1;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _pickMockAttachment() {
    setState(() {
      _attachedReportName = 'medical_report_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf';
    });
    context.showSnackBar('تم إرفاق الملف بنجاح');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final emp = ref.read(currentEmployeeProvider);
    final empId = emp?.id ?? AppConstants.mockEmployeeId;

    await ref.read(vacationsRepositoryProvider).createVacation(
          employeeId: empId,
          type: _selectedType,
          fromDate: _fromDate,
          toDate: _toDate,
          daysCount: _calculatedDays,
          reason: _reasonController.text.trim(),
          attachmentName: _attachedReportName,
        );

    ref.invalidate(vacationsListProvider);
    ref.invalidate(allRequestsProvider);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.showSnackBar('تم إرسال طلب الإجازة بنجاح وهو قيد المراجعة');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('vacations.new'),
        subtitle: 'تقديم طلب إجازة رسمية',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vacation Type
              Text(
                context.tr('vacations.type'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip(VacationType.annual, context.tr('vacations.type_annual')),
                  _buildTypeChip(VacationType.casual, context.tr('vacations.type_casual')),
                  _buildTypeChip(VacationType.sick, context.tr('vacations.type_sick')),
                  _buildTypeChip(VacationType.unpaid, context.tr('vacations.type_unpaid')),
                ],
              ),
              const SizedBox(height: 20),

              // Date Range Picker
              Text(
                'فترة الإجازة (عدد الأيام: $_calculatedDays)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDateRange,
                borderRadius: AppDimensions.borderRadiusLarge,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppDimensions.borderRadiusLarge,
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_fromDate.toFormattedDate(context.l10n.locale.languageCode)}  ←  ${_toDate.toFormattedDate(context.l10n.locale.languageCode)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reason
              AppTextField(
                label: context.tr('vacations.reason'),
                hintText: 'اكتب سبب الإجازة هنا...',
                controller: _reasonController,
                maxLines: 3,
                validator: (val) => Validators.required(val, 'يرجى كتابة سبب الإجازة'),
              ),
              const SizedBox(height: 16),

              // Medical Attachment (Optional / for sick leave)
              Text(
                context.tr('vacations.attachment'),
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
                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachedReportName ?? 'إرفاق تقرير طبي (إن وجد)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _attachedReportName != null ? 'تم إرفاق التقرير بنجاح' : 'PDF أو صورة التقرير',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_attachedReportName != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _attachedReportName = null),
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

  Widget _buildTypeChip(VacationType type, String label) {
    final isSelected = _selectedType == type;
    final isDark = context.isDark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      showCheckmark: false,
    );
  }
}
