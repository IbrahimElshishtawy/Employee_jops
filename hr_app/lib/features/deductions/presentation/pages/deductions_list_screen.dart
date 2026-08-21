import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/date_range_picker.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/deduction_entity.dart';
import '../controllers/deductions_controller.dart';
import '../widgets/deduction_details_dialog.dart';
import '../widgets/deduction_form_dialog.dart';

/// Deductions Management Screen
class DeductionsListScreen extends StatelessWidget {
  const DeductionsListScreen({super.key});

  static const List<String> kDepartments = [
    'Engineering',
    'Human Resources',
    'Operations',
    'Finance',
    'Marketing',
    'Legal',
  ];

  void _showDeductionDetails(BuildContext context, DeductionEntity deduction, bool canCancel) {
    showDialog(
      context: context,
      builder: (ctx) => DeductionDetailsDialog(
        deduction: deduction,
        canCancel: canCancel,
        onCancel: (reason) async {
          final success = await context.read<DeductionsController>().cancelDeduction(deduction.id, reason: reason);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deduction for ${deduction.employeeName} cancelled.'),
                backgroundColor: AppColors.neutral,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  void _showCreateDeductionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DeductionFormDialog(
        onCreate: (newDeduction) async {
          final success = await context.read<DeductionsController>().createDeduction(newDeduction);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deduction of \$${newDeduction.amount.toStringAsFixed(2)} scheduled for ${newDeduction.employeeName}.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeductionsController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canCreate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.deductionsCreate);
    final kpis = controller.kpis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payroll Deductions Management', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Track scheduled salary deductions, advance installment recoveries, and attendance adjustments',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              if (canCreate)
                HrButton(
                  label: 'New Deduction',
                  icon: Icons.add,
                  variant: HrButtonVariant.primary,
                  onPressed: () => _showCreateDeductionDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Financial KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Scheduled Deductions',
                  value: kpis != null ? '${kpis.scheduledCount}' : '—',
                  subtitle: kpis != null ? '\$${kpis.scheduledAmount.toStringAsFixed(0)} pending' : 'Pending payroll',
                  icon: Icons.schedule,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Applied in Payroll',
                  value: kpis != null ? '${kpis.appliedCount}' : '—',
                  subtitle: kpis != null ? '\$${kpis.appliedAmount.toStringAsFixed(0)} deducted' : 'Processed cycles',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Advance Recoveries',
                  value: kpis != null ? '\$${kpis.advanceDeductionTotal.toStringAsFixed(0)}' : '—',
                  subtitle: 'Salary advance repayment',
                  icon: Icons.monetization_on_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Workforce Penalties',
                  value: kpis != null ? '\$${kpis.attendanceDeductionTotal.toStringAsFixed(0)}' : '—',
                  subtitle: 'Absence / late arrival',
                  icon: Icons.report_problem_outlined,
                  iconColor: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational Sub-tabs
          Row(
            children: DeductionsTab.values.map((tab) {
              final isSelected = controller.activeTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab.label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                  onSelected: (selected) {
                    if (selected) controller.setActiveTab(tab);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Filter Bar
          FilterBar(
            searchHint: 'Search employee name, code, reason, period...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchDeductions,
            filterActions: [
              // Deduction Type Filter
              DropdownButton<DeductionType?>(
                value: controller.typeFilter,
                hint: const Text('All Deduction Types'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Deduction Types')),
                  ...DeductionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                ],
                onChanged: controller.onFilterType,
              ),
              const SizedBox(width: 8),

              // Status Filter (Only visible on All tab)
              if (controller.activeTab == DeductionsTab.all) ...[
                DropdownButton<DeductionStatus?>(
                  value: controller.statusFilter,
                  hint: const Text('All Statuses'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...DeductionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                  ],
                  onChanged: controller.onFilterStatus,
                ),
                const SizedBox(width: 8),
              ],

              // Department Filter
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

              // Date Range Picker
              DateRangePickerField(
                startDate: controller.dateRange?.start,
                endDate: controller.dateRange?.end,
                onRangeSelected: controller.onDateRangeSelected,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Deductions Data Table
          HrDataTable<DeductionEntity>(
            isLoading: controller.isLoading && controller.deductions.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: controller.fetchDeductions,
            items: controller.deductions,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchDeductions(page: page),
            onRowTap: (d) => _showDeductionDetails(context, d, canCreate),
            emptyMessage: 'No deduction records found matching the selected filters.',
            columns: [
              HrColumn<DeductionEntity>(
                title: 'Employee',
                cellBuilder: (d) => Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.danger.withValues(alpha: isDark ? 0.25 : 0.15),
                      child: Text(
                        d.employeeName.isNotEmpty ? d.employeeName[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(d.employeeName, style: AppTypography.bodyBold),
                        Text(
                          d.department != null ? '${d.employeeCode} • ${d.department}' : d.employeeCode,
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HrColumn<DeductionEntity>(
                title: 'Deduction Type',
                cellBuilder: (d) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.type.label, style: AppTypography.bodyBold),
                    if (d.relatedAdvanceId != null)
                      Text('Advance: ${d.relatedAdvanceId}', style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<DeductionEntity>(
                title: 'Amount',
                cellBuilder: (d) => Text(
                  '- ${d.currency} ${d.amount.toStringAsFixed(2)}',
                  style: AppTypography.bodyBold.copyWith(
                    color: d.status == DeductionStatus.cancelled ? AppColors.textSecondary(context) : AppColors.danger,
                  ),
                ),
              ),
              HrColumn<DeductionEntity>(
                title: 'Payroll Period',
                cellBuilder: (d) => Text(d.payrollPeriod, style: AppTypography.bodyMedium),
              ),
              HrColumn<DeductionEntity>(
                title: 'Date',
                cellBuilder: (d) => Text(DateFormatter.toDisplayDate(d.date), style: AppTypography.body),
              ),
              HrColumn<DeductionEntity>(
                title: 'Status',
                cellBuilder: (d) {
                  switch (d.status) {
                    case DeductionStatus.scheduled:
                      return const StatusBadge(label: 'Scheduled', variant: BadgeVariant.warning, icon: Icons.schedule);
                    case DeductionStatus.applied:
                      return const StatusBadge(label: 'Applied', variant: BadgeVariant.success, icon: Icons.check_circle_outline);
                    case DeductionStatus.cancelled:
                      return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral, icon: Icons.block);
                    case DeductionStatus.reversed:
                      return const StatusBadge(label: 'Reversed', variant: BadgeVariant.danger, icon: Icons.undo);
                  }
                },
              ),
              HrColumn<DeductionEntity>(
                title: 'Actions',
                cellBuilder: (d) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => _showDeductionDetails(context, d, canCreate),
                    ),
                    if (d.status == DeductionStatus.scheduled && canCreate)
                      IconButton(
                        icon: const Icon(Icons.block, size: 18, color: AppColors.danger),
                        tooltip: 'Cancel / Waive',
                        onPressed: () => _showDeductionDetails(context, d, true),
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
