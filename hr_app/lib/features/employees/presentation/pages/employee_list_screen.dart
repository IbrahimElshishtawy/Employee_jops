import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/employee_entity.dart';
import '../controllers/employee_controller.dart';

/// Employee Directory List Screen
class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmployeeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar
        FilterBar(
          searchHint: 'Search by name, ID, department...',
          onSearchChanged: controller.onSearch,
          onRefresh: controller.fetchEmployees,
          filterActions: [
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
          onRowTap: (emp) => _showEmployeeDetails(context, emp),
          columns: [
            HrColumn<EmployeeEntity>(
              title: 'Employee',
              cellBuilder: (emp) => Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
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
                      Text(emp.employeeCode, style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
            HrColumn<EmployeeEntity>(
              title: 'Department / Role',
              cellBuilder: (emp) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emp.department, style: AppTypography.bodyMedium),
                  Text(emp.jobTitle, style: AppTypography.caption),
                ],
              ),
            ),
            HrColumn<EmployeeEntity>(
              title: 'Workplace',
              cellBuilder: (emp) => Text(emp.workplaceName, style: AppTypography.body),
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
                    tooltip: 'View Details',
                    onPressed: () => _showEmployeeDetails(context, emp),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (action) {
                      if (action == 'activate') {
                        controller.updateEmployeeStatus(emp.id, EmployeeStatus.active);
                      } else if (action == 'suspend') {
                        controller.updateEmployeeStatus(emp.id, EmployeeStatus.suspended);
                      } else if (action == 'deactivate') {
                        controller.updateEmployeeStatus(emp.id, EmployeeStatus.deactivated);
                      }
                    },
                    itemBuilder: (context) => [
                      if (emp.status != EmployeeStatus.active)
                        const PopupMenuItem(value: 'activate', child: Text('Activate')),
                      if (emp.status != EmployeeStatus.suspended)
                        const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                      if (emp.status != EmployeeStatus.deactivated)
                        const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEmployeeDetails(BuildContext context, EmployeeEntity emp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${emp.fullName} (${emp.employeeCode})', style: AppTypography.heading3),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', emp.email),
              _buildDetailRow('Phone', emp.phone),
              _buildDetailRow('Department', emp.department),
              _buildDetailRow('Job Title', emp.jobTitle),
              _buildDetailRow('Workplace', emp.workplaceName),
              _buildDetailRow('Work Schedule', emp.scheduleName),
              if (emp.managerName != null) _buildDetailRow('Manager', emp.managerName!),
              _buildDetailRow('Joined Date', DateFormatter.toDisplayDate(emp.joinedDate)),
              _buildDetailRow('Status', emp.status.label),
            ],
          ),
        ),
        actions: [
          HrButton(
            label: 'Close',
            variant: HrButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: AppTypography.bodyBold)),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}
