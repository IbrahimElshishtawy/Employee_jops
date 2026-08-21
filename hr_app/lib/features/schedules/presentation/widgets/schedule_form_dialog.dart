import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../domain/entities/schedule_entity.dart';

/// Modal dialog for creating or editing work schedules
class ScheduleFormDialog extends StatefulWidget {
  final WorkScheduleEntity? initialSchedule;
  final Future<bool> Function(WorkScheduleEntity schedule) onSave;

  const ScheduleFormDialog({
    super.key,
    this.initialSchedule,
    required this.onSave,
  });

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  int _gracePeriodMinutes = 15;
  List<String> _workingDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  String _department = 'Engineering';
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> kAllWeekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialSchedule;
    _nameController = TextEditingController(text: init?.name ?? '');
    _descController = TextEditingController(text: init?.description ?? '');
    _startController = TextEditingController(text: init?.startTime ?? '09:00');
    _endController = TextEditingController(text: init?.endTime ?? '17:00');
    if (init != null) {
      _gracePeriodMinutes = init.gracePeriodMinutes;
      _workingDays = List<String>.from(init.workingDays);
      _department = init.department ?? 'Engineering';
      _isActive = init.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _toggleWorkingDay(String day) {
    setState(() {
      if (_workingDays.contains(day)) {
        if (_workingDays.length > 1) {
          _workingDays.remove(day);
        }
      } else {
        _workingDays.add(day);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_workingDays.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one working day.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final entity = WorkScheduleEntity(
      id: widget.initialSchedule?.id ?? 'SCH-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      startTime: _startController.text.trim(),
      endTime: _endController.text.trim(),
      workingDays: _workingDays,
      gracePeriodMinutes: _gracePeriodMinutes,
      assignedCount: widget.initialSchedule?.assignedCount ?? 0,
      isActive: _isActive,
      department: _department,
      createdAt: widget.initialSchedule?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await widget.onSave(entity);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Unable to save schedule configuration.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialSchedule != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_calendar_outlined : Icons.add_alarm_outlined,
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
                            isEditing ? 'Edit Work Schedule' : 'Create Work Schedule',
                            style: AppTypography.heading3,
                          ),
                          Text(
                            'Configure working hours, working days, and grace period',
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

                // Schedule Name & Department
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: HrTextField(
                        label: 'Schedule Name',
                        hint: 'e.g. Standard Core Business Hours',
                        controller: _nameController,
                        validator: (v) => Validator.requiredField(v, 'Schedule name is required'),
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
                            isExpanded: true,
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
                              'Administration',
                              'Information Technology',
                            ].map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
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

                HrTextField(
                  label: 'Description (Optional)',
                  hint: 'Explain shift coverage purpose...',
                  controller: _descController,
                ),
                const SizedBox(height: AppDimensions.space12),

                // Shift Start & End Time & Grace Period
                Row(
                  children: [
                    Expanded(
                      child: HrTextField(
                        label: 'Start Time (HH:MM)',
                        hint: '09:00',
                        controller: _startController,
                        validator: (v) => Validator.requiredField(v, 'Start time required'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: HrTextField(
                        label: 'End Time (HH:MM)',
                        hint: '17:00',
                        controller: _endController,
                        validator: (v) => Validator.requiredField(v, 'End time required'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grace Period', style: AppTypography.captionOf(context)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            initialValue: _gracePeriodMinutes,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                            ),
                            items: [0, 5, 10, 15, 20, 30, 45, 60].map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(m == 0 ? 'No Grace' : '$m mins'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _gracePeriodMinutes = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                // Working Days Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Working Days (Select at least 1 day)', style: AppTypography.captionOf(context)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kAllWeekDays.map((day) {
                        final isSelected = _workingDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.35 : 0.2),
                          onSelected: (_) => _toggleWorkingDay(day),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Active Switch
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Shift Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Inactive schedules cannot be assigned to new staff', style: AppTypography.captionOf(context)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AppColors.primaryLight,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
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
                      label: isEditing ? 'Save Changes' : 'Create Schedule',
                      variant: HrButtonVariant.primary,
                      icon: isEditing ? Icons.save_outlined : Icons.add,
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
