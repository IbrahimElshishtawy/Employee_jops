import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/authorization_service.dart';
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

    final l10n = context.l10n;

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
                    Text(l10n.translate('ded_title'), style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('ded_subtitle'),
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              if (canCreate)
                HrButton(
                  label: l10n.translate('ded_new_btn'),
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
                  title: l10n.translate('ded_scheduled_ded'),
                  value: kpis != null ? l10n.formatNumber(kpis.scheduledCount) : '—',
                  subtitle: kpis != null ? '${l10n.formatCurrency(kpis.scheduledAmount)} ${l10n.translate("req_status_pending")}' : l10n.translate('req_status_pending'),
                  icon: Icons.schedule,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('ded_applied_payroll'),
                  value: kpis != null ? l10n.formatNumber(kpis.appliedCount) : '—',
                  subtitle: kpis != null ? l10n.formatCurrency(kpis.appliedAmount) : l10n.translate('verified_badge'),
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('ded_advance_rec'),
                  value: kpis != null ? l10n.formatCurrency(kpis.advanceDeductionTotal) : '—',
                  subtitle: l10n.translate('adv_title'),
                  icon: Icons.monetization_on_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('ded_workforce_pen'),
                  value: kpis != null ? l10n.formatCurrency(kpis.attendanceDeductionTotal) : '—',
                  subtitle: l10n.translate('att_title'),
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
            searchHint: l10n.translate('search_placeholder'),
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchDeductions,
            filterActions: [
              // Deduction Type Filter
              DropdownButton<DeductionType?>(
                value: controller.typeFilter,
                hint: Text(l10n.translate('ded_all_types')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('ded_all_types'))),
                  ...DeductionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                ],
                onChanged: controller.onFilterType,
              ),
              const SizedBox(width: 8),

              // Status Filter (Only visible on All tab)
              if (controller.activeTab == DeductionsTab.all) ...[
                DropdownButton<DeductionStatus?>(
                  value: controller.statusFilter,
                  hint: Text(l10n.translate('emp_all_statuses')),
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.translate('emp_all_statuses'))),
                    ...DeductionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(l10n.translateStatus(s.name)))),
                  ],
                  onChanged: controller.onFilterStatus,
                ),
                const SizedBox(width: 8),
              ],

              // Department Filter
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
            emptyMessage: l10n.translate('no_data'),
            columns: [
              HrColumn<DeductionEntity>(
                title: l10n.translate('emp_name'),
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
                title: l10n.translate('ded_title'),
                cellBuilder: (d) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.type.label, style: AppTypography.bodyBold),
                    if (d.relatedAdvanceId != null)
                      Text('${l10n.translate("adv_title")}: ${d.relatedAdvanceId}', style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<DeductionEntity>(
                title: l10n.translate('adv_amount'),
                cellBuilder: (d) => Text(
                  '- ${l10n.formatCurrency(d.amount)}',
                  style: AppTypography.bodyBold.copyWith(
                    color: d.status == DeductionStatus.cancelled ? AppColors.textSecondary(context) : AppColors.danger,
                  ),
                ),
              ),
              HrColumn<DeductionEntity>(
                title: l10n.translate('ded_period'),
                cellBuilder: (d) => Text(d.payrollPeriod, style: AppTypography.bodyMedium),
              ),
              HrColumn<DeductionEntity>(
                title: l10n.translate('emp_joined_date'),
                cellBuilder: (d) => Text(l10n.formatDate(d.date), style: AppTypography.body),
              ),
              HrColumn<DeductionEntity>(
                title: l10n.translate('status'),
                cellBuilder: (d) {
                  switch (d.status) {
                    case DeductionStatus.scheduled:
                      return StatusBadge(label: l10n.translateStatus(d.status.name), variant: BadgeVariant.warning, icon: Icons.schedule);
                    case DeductionStatus.applied:
                      return StatusBadge(label: l10n.translateStatus(d.status.name), variant: BadgeVariant.success, icon: Icons.check_circle_outline);
                    case DeductionStatus.cancelled:
                      return StatusBadge(label: l10n.translateStatus(d.status.name), variant: BadgeVariant.neutral, icon: Icons.block);
                    case DeductionStatus.reversed:
                      return StatusBadge(label: l10n.translateStatus(d.status.name), variant: BadgeVariant.danger, icon: Icons.undo);
                  }
                },
              ),
              HrColumn<DeductionEntity>(
                title: l10n.translate('actions'),
                cellBuilder: (d) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: l10n.translate('details'),
                      onPressed: () => _showDeductionDetails(context, d, canCreate),
                    ),
                    if (d.status == DeductionStatus.scheduled && canCreate)
                      IconButton(
                        icon: const Icon(Icons.block, size: 18, color: AppColors.danger),
                        tooltip: l10n.translate('ded_cancel_btn'),
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
