import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validator.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/forms/hr_text_field.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../domain/entities/employee_entity.dart';

/// Modal dialog for recording a manual attendance punch correction with mandatory reason
class ManualAttendanceDialog extends StatefulWidget {
  final EmployeeEntity employee;
  final Future<bool> Function({
    required DateTime date,
    required AttendanceStatus status,
    required TimeOfDay checkIn,
    required TimeOfDay checkOut,
    required String reason,
  }) onSave;

  const ManualAttendanceDialog({
    super.key,
    required this.employee,
    required this.onSave,
  });

  @override
  State<ManualAttendanceDialog> createState() => _ManualAttendanceDialogState();
}

class _ManualAttendanceDialogState extends State<ManualAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  AttendanceStatus _status = AttendanceStatus.present;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 17, minute: 0);
  final TextEditingController _reasonController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await widget.onSave(
      date: _selectedDate,
      status: _status,
      checkIn: _checkInTime,
      checkOut: _checkOutTime,
      reason: _reasonController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to submit manual attendance entry.';
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
                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_calendar_outlined, color: AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Manual Attendance Correction', style: AppTypography.heading3),
                          Text(
                            '${widget.employee.fullName} (${widget.employee.employeeCode})',
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

                // Date Selection & Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record Date', style: AppTypography.bodyBold),
                          const SizedBox(height: AppDimensions.space8),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border(context)),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary(context)),
                                  const SizedBox(width: 8),
                                  Text(DateFormatter.toDisplayDate(_selectedDate), style: AppTypography.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attendance Status', style: AppTypography.bodyBold),
                          const SizedBox(height: AppDimensions.space8),
                          DropdownButtonFormField<AttendanceStatus>(
                            value: _status,
                            decoration: const InputDecoration(isDense: true),
                            items: AttendanceStatus.values
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                // Times: Check-in & Check-out
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-in Time', style: AppTypography.bodyBold),
                          const SizedBox(height: AppDimensions.space8),
                          InkWell(
                            onTap: () => _selectTime(true),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border(context)),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary(context)),
                                  const SizedBox(width: 8),
                                  Text(_checkInTime.format(context), style: AppTypography.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-out Time', style: AppTypography.bodyBold),
                          const SizedBox(height: AppDimensions.space8),
                          InkWell(
                            onTap: () => _selectTime(false),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border(context)),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary(context)),
                                  const SizedBox(width: 8),
                                  Text(_checkOutTime.format(context), style: AppTypography.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                // Mandatory Reason Field
                HrTextField(
                  label: 'Mandatory Adjustment Reason',
                  hint: 'e.g. Employee biometric terminal network outage / Approved remote work',
                  controller: _reasonController,
                  maxLines: 3,
                  validator: (v) => Validator.requiredField(v, 'A justified adjustment reason is mandatory'),
                ),
                const SizedBox(height: AppDimensions.space24),

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
                      label: 'Submit Correction',
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
}
