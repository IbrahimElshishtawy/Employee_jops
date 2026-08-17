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
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/permission_request.dart';

class NewPermissionScreen extends ConsumerStatefulWidget {
  const NewPermissionScreen({super.key});

  @override
  ConsumerState<NewPermissionScreen> createState() => _NewPermissionScreenState();
}

class _NewPermissionScreenState extends ConsumerState<NewPermissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _timeController = TextEditingController(text: 'ساعتان (من 3:00 م حتى 5:00 م)');

  PermissionType _selectedType = PermissionType.earlyLeave;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final emp = ref.read(currentEmployeeProvider);
    final empId = emp?.id ?? AppConstants.mockEmployeeId;

    await ref.read(permissionsRepositoryProvider).createPermission(
          employeeId: empId,
          type: _selectedType,
          date: _selectedDate,
          durationOrTime: _timeController.text.trim(),
          reason: _reasonController.text.trim(),
        );

    ref.invalidate(permissionsListProvider);
    ref.invalidate(allRequestsProvider);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.showSnackBar('تم إرسال طلب الاستئذان بنجاح');
    context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('permissions.new'),
        subtitle: 'طلب إذن استئذان للعمل',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Permission Type Selector
              Text(
                context.tr('permissions.type'),
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
                  _buildTypeChip(PermissionType.earlyLeave, context.tr('permissions.type_early_leave')),
                  _buildTypeChip(PermissionType.morningDelay, context.tr('permissions.type_delay')),
                  _buildTypeChip(PermissionType.halfDay, context.tr('permissions.type_half_day')),
                  _buildTypeChip(PermissionType.fullDayAbsence, context.tr('permissions.type_absence')),
                ],
              ),
              const SizedBox(height: 20),

              // Date Picker Field
              Text(
                context.tr('permissions.date'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
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
                        _selectedDate.toFormattedDate(context.l10n.locale.languageCode),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time / Duration Input
              AppTextField(
                label: context.tr('permissions.time'),
                hintText: 'مثال: ساعتان (من 2:00 م حتى 4:00 م)',
                controller: _timeController,
                validator: (val) => Validators.required(val, 'يرجى تحديد وقت أو مدة الاستئذان'),
              ),
              const SizedBox(height: 16),

              // Reason
              AppTextField(
                label: context.tr('permissions.reason'),
                hintText: 'يرجى كتابة سبب طلب الاستئذان بالتفصيل...',
                controller: _reasonController,
                maxLines: 3,
                validator: (val) => Validators.required(val, 'يرجى ذكر سبب الاستئذان'),
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

  Widget _buildTypeChip(PermissionType type, String label) {
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
