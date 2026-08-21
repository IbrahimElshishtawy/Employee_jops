import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/utils/date_formatter.dart';
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
                    Text('Employees Directory', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Manage employee profiles, assignments, attendance logs, and operational records',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space16),
              if (canCreate)
                HrButton(
                  label: 'Add Employee',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () => _openCreateDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Filter Bar
          FilterBar(
            searchHint: 'Search by name, ID, department, email...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchEmployees,
            filterActions: [
              // Department Filter Dropdown
              DropdownButton<String?>(
                value: controller.departmentFilter,
                hint: const Text('All Departments'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Departments')),
                  ...kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
                onChanged: controller.onFilterDepartment,
              ),
              const SizedBox(width: 8),

              // Workplace Filter Dropdown
              DropdownButton<String?>(
                value: controller.workplaceFilter,
                hint: const Text('All Workplaces'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Workplaces')),
                  ..._workplaces.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))),
                ],
                onChanged: controller.onFilterWorkplace,
              ),
              const SizedBox(width: 8),

              // Status Filter Dropdown
              DropdownButton<EmployeeStatus?>(
                value: controller.statusFilter,
                hint: const Text('All Statuses'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Statuses')),
                  ...EmployeeStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
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
            emptyMessage: 'No employees match the current search query or active filter settings.',
            columns: [
              HrColumn<EmployeeEntity>(
                title: 'Employee',
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
                title: 'Department & Role',
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
                title: 'Workplace',
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
                title: 'Schedule',
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
                title: 'Joined Date',
                cellBuilder: (emp) => Text(DateFormatter.toDisplayDate(emp.joinedDate), style: AppTypography.body),
              ),
              HrColumn<EmployeeEntity>(
                title: 'Status',
                cellBuilder: (emp) {
                  switch (emp.status) {
                    case EmployeeStatus.active:
                      return const StatusBadge(label: 'Active', variant: BadgeVariant.success);
                    case EmployeeStatus.suspended:
                      return const StatusBadge(label: 'Suspended', variant: BadgeVariant.warning);
                    case EmployeeStatus.deactivated:
                      return const StatusBadge(label: 'Deactivated', variant: BadgeVariant.danger);
                  }
                },
              ),
              HrColumn<EmployeeEntity>(
                title: 'Actions',
                cellBuilder: (emp) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Full Profile',
                      onPressed: () => context.go('/employees/${emp.id}'),
                    ),
                    if (canUpdate)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Employee',
                        onPressed: () => _openEditDialog(context, emp),
                      ),
                    if (canAssign)
                      IconButton(
                        icon: const Icon(Icons.transfer_within_a_station_outlined, size: 18),
                        tooltip: 'Assign Workplace / Schedule',
                        onPressed: () => _openAssignmentDialog(context, emp),
                      ),
                    if (canUpdate)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        tooltip: 'Status Management',
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
                            const PopupMenuItem(
                              value: 'activate',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Text('Activate'),
                                ],
                              ),
                            ),
                          if (emp.status != EmployeeStatus.suspended)
                            const PopupMenuItem(
                              value: 'suspend',
                              child: Row(
                                children: [
                                  Icon(Icons.pause_circle_outline, size: 16, color: AppColors.warning),
                                  SizedBox(width: 8),
                                  Text('Suspend'),
                                ],
                              ),
                            ),
                          if (emp.status != EmployeeStatus.deactivated)
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Row(
                                children: [
                                  Icon(Icons.block_outlined, size: 16, color: AppColors.danger),
                                  SizedBox(width: 8),
                                  Text('Deactivate', style: TextStyle(color: AppColors.danger)),
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
