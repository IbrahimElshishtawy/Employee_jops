import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/feedback/loading_state_view.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/workplace_entity.dart';
import '../controllers/workplace_controller.dart';

/// Modal dialog for assigning employees to a workplace
class WorkplaceAssignStaffDialog extends StatefulWidget {
  final WorkplaceEntity workplace;
  final WorkplaceController controller;

  const WorkplaceAssignStaffDialog({
    super.key,
    required this.workplace,
    required this.controller,
  });

  @override
  State<WorkplaceAssignStaffDialog> createState() => _WorkplaceAssignStaffDialogState();
}

class _WorkplaceAssignStaffDialogState extends State<WorkplaceAssignStaffDialog> {
  List<EmployeeEntity> _allEmployees = [];
  Set<String> _selectedEmployeeIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedEmployeeIds = Set<String>.from(widget.workplace.assignedEmployeeIds);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    final all = await widget.controller.fetchAllEmployees();
    setState(() {
      _allEmployees = all;
      _isLoading = false;
    });
  }

  Future<void> _onSave() async {
    setState(() => _isSaving = true);
    final success = await widget.controller.assignEmployees(
      widget.workplace.id,
      _selectedEmployeeIds.toList(),
    );
    if (mounted && success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _allEmployees.where((emp) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return emp.fullName.toLowerCase().contains(q) ||
          emp.employeeCode.toLowerCase().contains(q) ||
          emp.department.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: Container(
        width: 620,
        height: 600,
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: AppColors.primaryLight, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign Staff to Workplace', style: AppTypography.heading2),
                      Text(widget.workplace.name, style: AppTypography.caption),
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

            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Search employees by name, ID, or department...',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Selected Counter & Quick Selection
            Row(
              children: [
                Text(
                  '${_selectedEmployeeIds.length} employees assigned',
                  style: AppTypography.bodyBold,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedEmployeeIds = _allEmployees.map((e) => e.id).toSet();
                    });
                  },
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedEmployeeIds.clear();
                    });
                  },
                  child: const Text('Deselect All'),
                ),
              ],
            ),
            const Divider(),

            // Employee List
            Expanded(
              child: _isLoading
                  ? const LoadingStateView(message: 'Loading employee directory...')
                  : filtered.isEmpty
                      ? const Center(child: Text('No employees found.'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final emp = filtered[index];
                            final isChecked = _selectedEmployeeIds.contains(emp.id);

                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: AppColors.primaryLight,
                              secondary: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                                child: Text(
                                  emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              title: Text(emp.fullName, style: AppTypography.bodyBold),
                              subtitle: Text(
                                '${emp.employeeCode} • ${emp.department} • ${emp.jobTitle}',
                                style: AppTypography.caption,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedEmployeeIds.add(emp.id);
                                  } else {
                                    _selectedEmployeeIds.remove(emp.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Footer
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
                  label: 'Save Assignments',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
