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
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/advance_entity.dart';
import '../controllers/advances_controller.dart';
import '../widgets/advance_details_dialog.dart';
import '../widgets/advance_review_dialog.dart';

/// Salary Advances Management Screen
class AdvancesListScreen extends StatelessWidget {
  const AdvancesListScreen({super.key});

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

  void _showAdvanceDetails(BuildContext context, AdvanceEntity advance, bool canReview) {
    showDialog(
      context: context,
      builder: (ctx) => AdvanceDetailsDialog(
        advance: advance,
        canReview: canReview,
        onReview: ({required approve, approvedAmount, installmentCount, reasonOrNotes}) async {
          if (approve) {
            return await context.read<AdvancesController>().approveAdvance(
                  advance.id,
                  approvedAmount: approvedAmount ?? advance.amount,
                  installmentCount: installmentCount,
                  notes: reasonOrNotes,
                );
          } else {
            return await context.read<AdvancesController>().rejectAdvance(
                  advance.id,
                  reason: reasonOrNotes ?? 'Rejected by HR',
                );
          }
        },
      ),
    );
  }

  void _openReviewDialog(BuildContext context, AdvanceEntity advance, bool isApproval) {
    showDialog(
      context: context,
      builder: (ctx) => AdvanceReviewDialog(
        advance: advance,
        isApproval: isApproval,
        onReview: ({required approve, approvedAmount, installmentCount, reasonOrNotes}) async {
          final controller = context.read<AdvancesController>();
          bool success;
          if (approve) {
            success = await controller.approveAdvance(
              advance.id,
              approvedAmount: approvedAmount ?? advance.amount,
              installmentCount: installmentCount,
              notes: reasonOrNotes,
            );
          } else {
            success = await controller.rejectAdvance(
              advance.id,
              reason: reasonOrNotes ?? 'Rejected by HR',
            );
          }

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(approve
                    ? 'Salary advance for ${advance.employeeName} approved.'
                    : 'Salary advance for ${advance.employeeName} rejected.'),
                backgroundColor: approve ? AppColors.success : AppColors.danger,
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
    final controller = context.watch<AdvancesController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canApprove = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.advancesApprove);
    final canReject = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.advancesApprove);
    final canReview = canApprove || canReject;

    final kpis = controller.kpis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Salary Advances Management', style: AppTypography.heading1),
              const SizedBox(height: 4),
              Text(
                'Review employee advance requests, monitor installment schedules, and track outstanding balances',
                style: AppTypography.subtitleOf(context),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Financial KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending Review',
                  value: kpis != null ? '${kpis.pendingCount}' : '—',
                  subtitle: 'Action required by HR',
                  icon: Icons.hourglass_empty,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Active Disbursed',
                  value: kpis != null ? '${kpis.approvedCount}' : '—',
                  subtitle: 'Approved & active plans',
                  icon: Icons.verified_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Approved Volume',
                  value: kpis != null ? '\$${kpis.totalApprovedAmount.toStringAsFixed(0)}' : '—',
                  subtitle: 'Total principal disbursed',
                  icon: Icons.monetization_on_outlined,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Outstanding Balance',
                  value: kpis != null ? '\$${kpis.outstandingBalance.toStringAsFixed(0)}' : '—',
                  subtitle: 'Pending payroll collection',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational Sub-tabs
          Row(
            children: AdvancesTab.values.map((tab) {
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
            searchHint: 'Search employee name, code, reason...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchAdvances,
            filterActions: [
              // Status Filter (Only active on All tab)
              if (controller.activeTab == AdvancesTab.all) ...[
                DropdownButton<AdvanceStatus?>(
                  value: controller.statusFilter,
                  hint: const Text('All Advance Statuses'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Advance Statuses')),
                    ...AdvanceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
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

          // Advances Data Table
          HrDataTable<AdvanceEntity>(
            isLoading: controller.isLoading && controller.advances.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: controller.fetchAdvances,
            items: controller.advances,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchAdvances(page: page),
            onRowTap: (adv) => _showAdvanceDetails(context, adv, canReview),
            emptyMessage: 'No salary advances found matching the selected filters.',
            columns: [
              HrColumn<AdvanceEntity>(
                title: 'Employee',
                cellBuilder: (adv) => Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                      child: Text(
                        adv.employeeName.isNotEmpty ? adv.employeeName[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(adv.employeeName, style: AppTypography.bodyBold),
                        Text(
                          adv.department != null && adv.department!.isNotEmpty
                              ? '${adv.employeeCode} • ${adv.department}'
                              : adv.employeeCode,
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HrColumn<AdvanceEntity>(
                title: 'Requested vs Approved',
                cellBuilder: (adv) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${adv.currency} ${adv.amount.toStringAsFixed(2)} req.',
                      style: AppTypography.bodyBold,
                    ),
                    if (adv.approvedAmount != null)
                      Text(
                        '${adv.currency} ${adv.approvedAmount!.toStringAsFixed(2)} app.',
                        style: AppTypography.captionOf(context).copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              HrColumn<AdvanceEntity>(
                title: 'Installments',
                cellBuilder: (adv) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${adv.installmentCount} ${adv.installmentCount == 1 ? "Month" : "Months"}',
                      style: AppTypography.bodyBold,
                    ),
                    if (adv.status == AdvanceStatus.approved || adv.status == AdvanceStatus.paid)
                      Text(
                        '${adv.paidInstallmentCount} of ${adv.installmentCount} Paid',
                        style: AppTypography.captionOf(context),
                      ),
                  ],
                ),
              ),
              HrColumn<AdvanceEntity>(
                title: 'Remaining Balance',
                cellBuilder: (adv) => Text(
                  '${adv.currency} ${adv.remainingBalance.toStringAsFixed(2)}',
                  style: AppTypography.bodyBold.copyWith(
                    color: adv.remainingBalance > 0 ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
              HrColumn<AdvanceEntity>(
                title: 'Request Date',
                cellBuilder: (adv) => Text(DateFormatter.toDisplayDate(adv.requestedAt), style: AppTypography.body),
              ),
              HrColumn<AdvanceEntity>(
                title: 'Status',
                cellBuilder: (adv) {
                  switch (adv.status) {
                    case AdvanceStatus.pending:
                      return const StatusBadge(label: 'Pending', variant: BadgeVariant.warning, icon: Icons.hourglass_empty);
                    case AdvanceStatus.approved:
                      return const StatusBadge(label: 'Approved & Active', variant: BadgeVariant.info, icon: Icons.verified_outlined);
                    case AdvanceStatus.paid:
                      return const StatusBadge(label: 'Settled', variant: BadgeVariant.success, icon: Icons.check_circle_outline);
                    case AdvanceStatus.rejected:
                      return const StatusBadge(label: 'Rejected', variant: BadgeVariant.danger, icon: Icons.cancel_outlined);
                    case AdvanceStatus.cancelled:
                      return const StatusBadge(label: 'Cancelled', variant: BadgeVariant.neutral, icon: Icons.block);
                  }
                },
              ),
              HrColumn<AdvanceEntity>(
                title: 'Actions',
                cellBuilder: (adv) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details & Schedule',
                      onPressed: () => _showAdvanceDetails(context, adv, canReview),
                    ),
                    if (adv.status == AdvanceStatus.pending && canApprove)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                        tooltip: 'Approve Advance',
                        onPressed: () => _openReviewDialog(context, adv, true),
                      ),
                    if (adv.status == AdvanceStatus.pending && canReject)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                        tooltip: 'Reject Advance',
                        onPressed: () => _openReviewDialog(context, adv, false),
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
