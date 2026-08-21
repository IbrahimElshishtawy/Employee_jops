import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../schedules/domain/entities/schedule_entity.dart';
import '../../../workplaces/domain/entities/workplace_entity.dart';
import '../../domain/entities/employee_entity.dart';

/// Modal dialog for adding or editing an employee
class EmployeeFormDialog extends StatefulWidget {
  final EmployeeEntity? employee;
  final Future<bool> Function(EmployeeEntity employee) onSave;

  const EmployeeFormDialog({
    super.key,
    this.employee,
    required this.onSave,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _employeeCodeController;
  late TextEditingController _jobTitleController;
  late TextEditingController _departmentController;
  late TextEditingController _nationalIdController;
  late TextEditingController _basicSalaryController;
  late TextEditingController _allowancesController;
  late TextEditingController _bankAccountController;

  EmployeeStatus _status = EmployeeStatus.active;
  String? _selectedWorkplaceId;
  String? _selectedWorkplaceName;
  String? _selectedScheduleId;
  String? _selectedScheduleName;

  List<WorkplaceEntity> _workplaces = [];
  List<WorkScheduleEntity> _schedules = [];
  bool _isLoadingLookups = true;
  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> kDepartments = [
    'Engineering',
    'Human Resources',
    'Operations',
    'Finance',
    'Marketing',
    'Legal',
    'Administration',
    'Information Technology',
  ];

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _fullNameController = TextEditingController(text: emp?.fullName ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _phoneController = TextEditingController(text: emp?.phone ?? '');
    _employeeCodeController = TextEditingController(text: emp?.employeeCode ?? 'CW-00${DateTime.now().millisecond % 90 + 10}');
    _jobTitleController = TextEditingController(text: emp?.jobTitle ?? '');
    _departmentController = TextEditingController(text: emp?.department ?? kDepartments.first);
    _nationalIdController = TextEditingController(text: emp?.nationalId ?? '');
    _basicSalaryController = TextEditingController(text: emp?.basicSalary != null ? emp!.basicSalary!.toStringAsFixed(2) : '');
    _allowancesController = TextEditingController(text: emp?.allowances != null ? emp!.allowances!.toStringAsFixed(2) : '');
    _bankAccountController = TextEditingController(text: emp?.bankAccountNumber ?? '');

    if (emp != null) {
      _status = emp.status;
      _selectedWorkplaceId = emp.workplaceId;
      _selectedWorkplaceName = emp.workplaceName;
      _selectedScheduleId = emp.scheduleId;
      _selectedScheduleName = emp.scheduleName;
    }

    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final wpRepo = context.read<WorkplacesRepository>();
      final schRepo = context.read<SchedulesRepository>();

      final wpResult = await wpRepo.getWorkplaces(const WorkplaceFilter(page: 1, pageSize: 50));
      final schResult = await schRepo.getSchedules(const ScheduleFilter(page: 1, pageSize: 50));

      if (mounted) {
        setState(() {
          _workplaces = wpResult.items;
          _schedules = schResult.items;
          _isLoadingLookups = false;

          if (_selectedWorkplaceId == null && _workplaces.isNotEmpty) {
            _selectedWorkplaceId = _workplaces.first.id;
            _selectedWorkplaceName = _workplaces.first.name;
          }
          if (_selectedScheduleId == null && _schedules.isNotEmpty) {
            _selectedScheduleId = _schedules.first.id;
            _selectedScheduleName = _schedules.first.name;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLookups = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeCodeController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _nationalIdController.dispose();
    _basicSalaryController.dispose();
    _allowancesController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final entity = EmployeeEntity(
      id: widget.employee?.id ?? '',
      employeeCode: _employeeCodeController.text.trim(),
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      department: _departmentController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      workplaceId: _selectedWorkplaceId ?? 'WP-001',
      workplaceName: _selectedWorkplaceName ?? 'HQ Main Tower',
      scheduleId: _selectedScheduleId ?? 'SCH-001',
      scheduleName: _selectedScheduleName ?? 'Standard Core',
      status: _status,
      joinedDate: widget.employee?.joinedDate ?? DateTime.now(),
      nationalId: _nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null,
      basicSalary: double.tryParse(_basicSalaryController.text.trim()),
      allowances: double.tryParse(_allowancesController.text.trim()),
      bankAccountNumber: _bankAccountController.text.trim().isNotEmpty ? _bankAccountController.text.trim() : null,
    );

    final success = await widget.onSave(entity);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save employee. Please verify details.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_outlined : Icons.person_add_alt_1_outlined,
                        color: AppColors.primaryLight,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Employee Profile' : 'Register New Employee',
                            style: AppTypography.heading2,
                          ),
                          Text(
                            isEdit
                                ? 'Update workforce record for ${widget.employee!.fullName}'
                                : 'Add a new verified employee to company registry',
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
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                ],

                // Form Scroll Area
                Expanded(
                  child: _isLoadingLookups
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section 1: Personal Details
                              _buildSectionHeader(context, 'Personal Information', Icons.badge_outlined),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: HrTextField(
                                      label: 'Full Legal Name',
                                      hint: 'e.g. Alex Vance',
                                      controller: _fullNameController,
                                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                                      validator: (v) => Validator.requiredField(v, 'Full name is required'),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    flex: 2,
                                    child: HrTextField(
                                      label: 'National ID',
                                      hint: '14-digit National ID',
                                      controller: _nationalIdController,
                                      prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Email Address (Google Auth)',
                                      hint: 'e.g. alex.vance@company.com',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                      validator: Validator.email,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Phone Number',
                                      hint: 'e.g. +201000000001',
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                      validator: (v) => Validator.requiredField(v, 'Phone is required'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space20),

                              // Section 2: Employment Info
                              _buildSectionHeader(context, 'Employment Information', Icons.work_outline),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Employee Code',
                                      hint: 'CW-001',
                                      controller: _employeeCodeController,
                                      prefixIcon: const Icon(Icons.tag_outlined, size: 18),
                                      validator: (v) => Validator.requiredField(v, 'Employee code is required'),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Job Title / Position',
                                      hint: 'e.g. Senior Software Engineer',
                                      controller: _jobTitleController,
                                      prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                      validator: (v) => Validator.requiredField(v, 'Job title is required'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Department', style: AppTypography.bodyBold),
                                        const SizedBox(height: AppDimensions.space8),
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: kDepartments.contains(_departmentController.text)
                                              ? _departmentController.text
                                              : kDepartments.first,
                                          decoration: const InputDecoration(isDense: true),
                                          items: kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _departmentController.text = val);
                                            }
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
                                        Text('Employment Status', style: AppTypography.bodyBold),
                                        const SizedBox(height: AppDimensions.space8),
                                        DropdownButtonFormField<EmployeeStatus>(
                                          initialValue: _status,
                                          decoration: const InputDecoration(isDense: true),
                                          items: EmployeeStatus.values
                                              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _status = val);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space20),

                              // Section 3: Work Assignment (Workplace & Schedule)
                              _buildSectionHeader(context, 'Workplace & Schedule Assignment', Icons.place_outlined),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Assigned Workplace', style: AppTypography.bodyBold),
                                        const SizedBox(height: AppDimensions.space8),
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: _selectedWorkplaceId,
                                          decoration: const InputDecoration(isDense: true),
                                          hint: const Text('Select workplace'),
                                          items: _workplaces
                                              .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              final wp = _workplaces.firstWhere((w) => w.id == val);
                                              setState(() {
                                                _selectedWorkplaceId = wp.id;
                                                _selectedWorkplaceName = wp.name;
                                              });
                                            }
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
                                        Text('Assigned Schedule', style: AppTypography.bodyBold),
                                        const SizedBox(height: AppDimensions.space8),
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: _selectedScheduleId,
                                          decoration: const InputDecoration(isDense: true),
                                          hint: const Text('Select schedule'),
                                          items: _schedules
                                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              final sch = _schedules.firstWhere((s) => s.id == val);
                                              setState(() {
                                                _selectedScheduleId = sch.id;
                                                _selectedScheduleName = sch.name;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space20),

                              // Section 4: Compensation & Banking (Optional / Sensitive)
                              _buildSectionHeader(context, 'Compensation & Banking (Optional)', Icons.account_balance_wallet_outlined),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Basic Salary (USD)',
                                      hint: 'e.g. 2500.00',
                                      controller: _basicSalaryController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      prefixIcon: const Icon(Icons.attach_money, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Allowances (USD)',
                                      hint: 'e.g. 400.00',
                                      controller: _allowancesController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    child: HrTextField(
                                      label: 'Bank Account / IBAN',
                                      hint: 'EG...',
                                      controller: _bankAccountController,
                                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppDimensions.space16),

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
                      label: isEdit ? 'Save Changes' : 'Create Employee',
                      icon: Icons.check,
                      isLoading: _isSaving,
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.bodyBold.copyWith(
            color: AppColors.primaryLight,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
