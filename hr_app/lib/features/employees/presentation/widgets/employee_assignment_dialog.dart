import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../schedules/domain/entities/schedule_entity.dart';
import '../../../workplaces/domain/entities/workplace_entity.dart';
import '../../domain/entities/employee_entity.dart';

/// Quick Assignment Dialog to change Workplace & Shift Schedule for an employee
class EmployeeAssignmentDialog extends StatefulWidget {
  final EmployeeEntity employee;
  final Future<bool> Function({
    required String workplaceId,
    required String workplaceName,
    required String scheduleId,
    required String scheduleName,
  }) onSave;

  const EmployeeAssignmentDialog({
    super.key,
    required this.employee,
    required this.onSave,
  });

  @override
  State<EmployeeAssignmentDialog> createState() => _EmployeeAssignmentDialogState();
}

class _EmployeeAssignmentDialogState extends State<EmployeeAssignmentDialog> {
  late String _selectedWorkplaceId;
  late String _selectedWorkplaceName;
  late String _selectedScheduleId;
  late String _selectedScheduleName;

  List<WorkplaceEntity> _workplaces = [];
  List<WorkScheduleEntity> _schedules = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedWorkplaceId = widget.employee.workplaceId;
    _selectedWorkplaceName = widget.employee.workplaceName;
    _selectedScheduleId = widget.employee.scheduleId;
    _selectedScheduleName = widget.employee.scheduleName;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final wpRepo = context.read<WorkplacesRepository>();
      final schRepo = context.read<SchedulesRepository>();

      final wpResult = await wpRepo.getWorkplaces(const WorkplaceFilter(page: 1, pageSize: 50));
      final schResult = await schRepo.getSchedules(1, 50);

      if (mounted) {
        setState(() {
          _workplaces = wpResult.items;
          _schedules = schResult.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await widget.onSave(
      workplaceId: _selectedWorkplaceId,
      workplaceName: _selectedWorkplaceName,
      scheduleId: _selectedScheduleId,
      scheduleName: _selectedScheduleName,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to assign workplace & schedule.';
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
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
                    child: const Icon(Icons.transfer_within_a_station_outlined, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Workplace & Schedule', style: AppTypography.heading3),
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

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.space24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Workplace Dropdown
                Text('Authoritative Workplace', style: AppTypography.bodyBold),
                const SizedBox(height: AppDimensions.space8),
                DropdownButtonFormField<String>(
                  initialValue: _workplaces.any((w) => w.id == _selectedWorkplaceId) ? _selectedWorkplaceId : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.place_outlined, size: 18),
                    isDense: true,
                  ),
                  hint: const Text('Select Workplace'),
                  items: _workplaces.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text('${w.name} (${w.geofenceType.label})'),
                    );
                  }).toList(),
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
                const SizedBox(height: AppDimensions.space16),

                // Schedule Dropdown
                Text('Assigned Shift Schedule', style: AppTypography.bodyBold),
                const SizedBox(height: AppDimensions.space8),
                DropdownButtonFormField<String>(
                  initialValue: _schedules.any((s) => s.id == _selectedScheduleId) ? _selectedScheduleId : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.access_time_outlined, size: 18),
                    isDense: true,
                  ),
                  hint: const Text('Select Schedule'),
                  items: _schedules.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.startTime} - ${s.endTime})'),
                    );
                  }).toList(),
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
                const SizedBox(height: AppDimensions.space24),
              ],

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
                    label: 'Save Assignment',
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
    );
  }
}
