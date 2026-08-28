import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/department_request.dart';
import '../providers/departments_provider.dart';
import '../providers/department_requests_provider.dart';
import '../widgets/request_type_selector.dart';
import '../widgets/priority_selector.dart';
import '../widgets/request_summary.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String? initialDepartmentId;
  final String? initialRecipientId;

  const CreateRequestScreen({
    super.key,
    this.initialDepartmentId,
    this.initialRecipientId,
  });

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  String? _selectedDepartmentId;
  String? _selectedRequestTypeId;
  RequestPriority _selectedPriority = RequestPriority.normal;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedDepartmentId = widget.initialDepartmentId ?? 'SECURITY';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final isArabic = context.isArabic;
    setState(() {
      _validationError = null;
    });

    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      setState(() {
        _validationError = isArabic ? 'يرجى اختيار القسم' : 'Please select department';
      });
      return;
    }

    if (_selectedRequestTypeId == null || _selectedRequestTypeId!.isEmpty) {
      setState(() {
        _validationError = isArabic ? 'يرجى اختيار نوع الطلب' : 'Please select request type';
      });
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _validationError = isArabic ? 'يرجى كتابة تفاصيل الطلب' : 'Please enter request message';
      });
      return;
    }

    final notifier = ref.read(departmentRequestActionProvider.notifier);
    final result = await notifier.createRequest(
      departmentId: _selectedDepartmentId!,
      requestTypeId: _selectedRequestTypeId!,
      priority: _selectedPriority,
      message: message,
      locationContext: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      recipientId: widget.initialRecipientId,
    );

    if (result != null && mounted) {
      context.showSnackBar(
        isArabic ? 'تم إرسال الطلب التشغيلي بنجاح' : 'Request submitted successfully',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final departmentsAsync = ref.watch(departmentsListProvider);
    final requestTypesAsync =
        ref.watch(requestTypesProvider(_selectedDepartmentId));
    final actionState = ref.watch(departmentRequestActionProvider);
    final isLoading = actionState.isLoading;

    final depts = departmentsAsync.asData?.value ?? [];
    final selectedDept = depts.where((d) => d.id == _selectedDepartmentId).firstOrNull ??
        (depts.isNotEmpty ? depts.first : null);

    final reqTypes = requestTypesAsync.asData?.value ?? [];
    if (_selectedRequestTypeId == null && reqTypes.isNotEmpty) {
      _selectedRequestTypeId = reqTypes.first.id;
    }

    final selectedType = reqTypes.where((t) => t.id == _selectedRequestTypeId).firstOrNull ??
        (reqTypes.isNotEmpty ? reqTypes.first : null);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? 'إنشاء طلب تشغيلي' : 'New Department Request',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Department Selection
              Text(
                isArabic ? 'القسم المستهدف' : 'Target Department',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedDepartmentId,
                    dropdownColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    items: depts.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept.id,
                        child: Text(
                          dept.localizedName(isArabic),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDepartmentId = val;
                          _selectedRequestTypeId = null;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Request Type Selector
              RequestTypeSelector(
                requestTypes: reqTypes,
                selectedTypeId: _selectedRequestTypeId,
                onSelected: (val) {
                  setState(() {
                    _selectedRequestTypeId = val;
                  });
                },
              ),
              const SizedBox(height: 18),

              // 3. Priority Selector
              PrioritySelector(
                selectedPriority: _selectedPriority,
                onSelected: (priority) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
              ),
              const SizedBox(height: 18),

              // 4. Location Context Field (Optional)
              Text(
                isArabic ? 'الموقع أو السياق (اختياري)' : 'Location / Context (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _locationController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'مثال: بهو الاستقبال - بجوار البوابة الرئيسية'
                        : 'e.g., Reception Lobby - Near Main Entrance',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textSecondaryLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 5. Message Field
              Text(
                isArabic ? 'تفاصيل الطلب' : 'Request Details & Message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 3,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'اكتب تفاصيل ما تحتاجه بدقة...'
                        : 'Describe what you need in detail...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textSecondaryLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // 6. Summary Box
              RequestSummary(
                department: selectedDept,
                requestType: selectedType,
                priority: _selectedPriority,
                message: _messageController.text,
                locationContext: _locationController.text,
              ),

              const SizedBox(height: 24),

              // 7. Submit Button
              AppButton(
                label: isArabic ? 'إرسال الطلب التشغيلي' : 'Submit Request',
                icon: Icons.send_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submitRequest,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
