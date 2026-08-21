import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../workplaces/domain/entities/workplace_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../controllers/employee_controller.dart';
import '../widgets/employee_assignment_dialog.dart';
import '../widgets/employee_form_dialog.dart';

/// Authoritative Employee Directory List Screen
class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<WorkplaceEntity> _workplaces = [];

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
    _loadWorkplaces();
  }

  Future<void> _loadWorkplaces() async {
    try {
      final wpRepo = context.read<WorkplacesRepository>();
      final wpResult = await wpRepo.getWorkplaces(const WorkplaceFilter(page: 1, pageSize: 50));
      if (mounted) {
        setState(() => _workplaces = wpResult.items);
      }
    } catch (_) {}
  }

  void _openCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeFormDialog(
        onSave: (employee) async {
          return await context.read<EmployeeController>().createEmployee(employee);
        },
      ),
    );
  }

  void _openEditDialog(BuildContext context, EmployeeEntity emp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeFormDialog(
        employee: emp,
        onSave: (updated) async {
          return await context.read<EmployeeController>().updateEmployee(updated);
        },
      ),
    );
  }

  void _openAssignmentDialog(BuildContext context, EmployeeEntity emp) {
    showDialog(
      context: context,
      builder: (context) => EmployeeAssignmentDialog(
        employee: emp,
        onSave: ({
          required String workplaceId,
          required String workplaceName,
          required String scheduleId,
          required String scheduleName,
        }) async {
          return await context.read<EmployeeController>().assignWorkplaceAndSchedule(
                emp.id,
                workplaceId: workplaceId,
                workplaceName: workplaceName,
                scheduleId: scheduleId,
                scheduleName: scheduleName,
              );
        },
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, EmployeeEntity emp, EmployeeStatus newStatus) {
    final actionLabel = newStatus.label;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel Employee'),
        content: Text('Are you sure you want to change the status of ${emp.fullName} (${emp.employeeCode}) to $actionLabel?'),
        actions: [
          HrButton(
            label: 'Cancel',
            variant: HrButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
          HrButton(
            label: 'Confirm $actionLabel',
            variant: newStatus == EmployeeStatus.deactivated ? HrButtonVariant.danger : HrButtonVariant.primary,
            onPressed: () {
              Navigator.pop(context);
              context.read<EmployeeController>().updateEmployeeStatus(emp.id, newStatus);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmployeeController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canCreate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.employeesCreate);
    final canUpdate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.employeesUpdate);
    final canAssign = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.workplacesUpdate) || canUpdate;

    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Quick Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('nav_employees'), style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('emp_directory_subtitle'),
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space16),
              if (canCreate)
                HrButton(
                  label: l10n.translate('emp_add_btn'),
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () => _openCreateDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Filter Bar
          FilterBar(
            searchHint: l10n.translate('search_placeholder'),
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchEmployees,
            filterActions: [
              // Department Filter Dropdown
              DropdownButton<String?>(
                value: controller.departmentFilter,
                hint: Text(l10n.translate('emp_all_departments')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_departments'))),
                  ...kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
                onChanged: controller.onFilterDepartment,
              ),
              const SizedBox(width: 8),

              // Workplace Filter Dropdown
              DropdownButton<String?>(
                value: controller.workplaceFilter,
                hint: Text(l10n.translate('emp_all_workplaces')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_workplaces'))),
                  ..._workplaces.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))),
                ],
                onChanged: controller.onFilterWorkplace,
              ),
              const SizedBox(width: 8),

              // Status Filter Dropdown
              DropdownButton<EmployeeStatus?>(
                value: controller.statusFilter,
                hint: Text(l10n.translate('emp_all_statuses')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_statuses'))),
                  ...EmployeeStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(l10n.translateStatus(s.name))),
                  ),
                ],
                onChanged: controller.onFilterStatus,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Data Table
          HrDataTable<EmployeeEntity>(
            isLoading: controller.isLoading && controller.employees.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: controller.fetchEmployees,
            items: controller.employees,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchEmployees(page: page),
            onRowTap: (emp) => context.go('/employees/${emp.id}'),
            emptyMessage: l10n.translate('no_data'),
            columns: [
              HrColumn<EmployeeEntity>(
                title: l10n.translate('emp_name'),
                cellBuilder: (emp) => Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                      child: Text(
                        emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emp.fullName, style: AppTypography.bodyBold),
                        Text(emp.employeeCode, style: AppTypography.captionOf(context)),
                      ],
                    ),
                  ],
                ),
              ),
              HrColumn<EmployeeEntity>(
                title: l10n.translate('emp_dept_role'),
                cellBuilder: (emp) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emp.department, style: AppTypography.bodyMedium),
                    Text(emp.jobTitle, style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<EmployeeEntity>(
                title: l10n.translate('emp_workplace'),
                cellBuilder: (emp) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 4),
                    Text(emp.workplaceName, style: AppTypography.body),
                  ],
                ),
              ),
              HrColumn<EmployeeEntity>(
                title: l10n.translate('emp_schedule'),
                cellBuilder: (emp) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 4),
                    Text(emp.scheduleName, style: AppTypography.body),
                  ],
                ),
              ),
              HrColumn<EmployeeEntity>(
                title: l10n.translate('emp_joined_date'),
                cellBuilder: (emp) => Text(l10n.formatDate(emp.joinedDate), style: AppTypography.body),
              ),
              HrColumn<EmployeeEntity>(
                title: l10n.translate('status'),
                cellBuilder: (emp) {
                  switch (emp.status) {
                    case EmployeeStatus.active:
                      return StatusBadge(label: l10n.translateStatus(emp.status.name), variant: BadgeVariant.success);
                    case EmployeeStatus.suspended:
                      return StatusBadge(label: l10n.translateStatus(emp.status.name), variant: BadgeVariant.warning);
                    case EmployeeStatus.deactivated:
                      return StatusBadge(label: l10n.translateStatus(emp.status.name), variant: BadgeVariant.danger);
                  }
                },
              ),
              HrColumn<EmployeeEntity>(
                title: l10n.translate('actions'),
                cellBuilder: (emp) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: l10n.translate('emp_view_profile'),
                      onPressed: () => context.go('/employees/${emp.id}'),
                    ),
                    if (canUpdate)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: l10n.translate('emp_edit'),
                        onPressed: () => _openEditDialog(context, emp),
                      ),
                    if (canAssign)
                      IconButton(
                        icon: const Icon(Icons.transfer_within_a_station_outlined, size: 18),
                        tooltip: l10n.translate('emp_assign'),
                        onPressed: () => _openAssignmentDialog(context, emp),
                      ),
                    if (canUpdate)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        tooltip: l10n.translate('emp_status_management'),
                        onSelected: (action) {
                          if (action == 'activate') {
                            _confirmStatusChange(context, emp, EmployeeStatus.active);
                          } else if (action == 'suspend') {
                            _confirmStatusChange(context, emp, EmployeeStatus.suspended);
                          } else if (action == 'deactivate') {
                            _confirmStatusChange(context, emp, EmployeeStatus.deactivated);
                          }
                        },
                        itemBuilder: (context) => [
                          if (emp.status != EmployeeStatus.active)
                            PopupMenuItem(
                              value: 'activate',
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Text(l10n.translate('emp_activate')),
                                ],
                              ),
                            ),
                          if (emp.status != EmployeeStatus.suspended)
                            PopupMenuItem(
                              value: 'suspend',
                              child: Row(
                                children: [
                                  const Icon(Icons.pause_circle_outline, size: 16, color: AppColors.warning),
                                  const SizedBox(width: 8),
                                  Text(l10n.translate('emp_suspend')),
                                ],
                              ),
                            ),
                          if (emp.status != EmployeeStatus.deactivated)
                            PopupMenuItem(
                              value: 'deactivate',
                              child: Row(
                                children: [
                                  const Icon(Icons.block_outlined, size: 16, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Text(l10n.translate('emp_deactivate'), style: const TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
