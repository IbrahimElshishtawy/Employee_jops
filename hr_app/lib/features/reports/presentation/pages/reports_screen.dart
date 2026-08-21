import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/report_entities.dart';
import '../controllers/reports_controller.dart';
import '../widgets/report_export_dialog.dart';

/// Operational & Analytical Reports Screen
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _openExportDialog(BuildContext context, ReportsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => ReportExportDialog(
        reportTitle: controller.activeTab.label,
        reportType: controller.activeTab.name,
        activeFilter: controller.filter,
        onExport: (type, filter, format) => controller.exportReport(type, format),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overview = controller.overview;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Executive Reports & Workforce Analytics', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Aggregated workforce attendance, punctuality trends, late arrival audits, and financial summaries',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              HrButton(
                label: 'Export Report',
                icon: Icons.file_download_outlined,
                variant: HrButtonVariant.primary,
                onPressed: () => _openExportDialog(context, controller),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Date Preset & Department Global Filters
          FilterBar(
            searchHint: 'Filter reports...',
            onRefresh: controller.loadReports,
            filterActions: [
              // Date Presets
              DropdownButton<DateRangePreset>(
                value: controller.filter.datePreset,
                underline: const SizedBox.shrink(),
                items: DateRangePreset.values.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) controller.setDatePreset(v);
                },
              ),
              const SizedBox(width: AppDimensions.space12),
              // Department Filter
              DropdownButton<String?>(
                value: controller.filter.department,
                hint: const Text('All Departments'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
                  ...[
                    'Engineering',
                    'Operations',
                    'Human Resources',
                    'Finance',
                    'Marketing',
                    'Administration',
                  ].map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
                ],
                onChanged: controller.setDepartment,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Subtabs
          Row(
            children: ReportsTab.values.map((tab) {
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
          const SizedBox(height: AppDimensions.space20),

          // Content based on active tab
          if (controller.isLoading && overview == null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.space40),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (controller.errorMessage != null && overview == null) ...[
            Card(
              color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space20),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(controller.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                    ),
                    HrButton(
                      label: 'Retry',
                      variant: HrButtonVariant.outline,
                      onPressed: controller.loadReports,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildTabContent(context, controller, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ReportsController controller, bool isDark) {
    switch (controller.activeTab) {
      case ReportsTab.overview:
        return _buildOverviewTab(context, controller, isDark);
      case ReportsTab.attendance:
        return _buildAttendanceTab(context, controller, isDark);
      case ReportsTab.lateArrivals:
        return _buildLateArrivalsTab(context, controller, isDark);
      case ReportsTab.departments:
        return _buildDepartmentsTab(context, controller, isDark);
      case ReportsTab.financials:
        return _buildFinancialsTab(context, controller, isDark);
    }
  }

  Widget _buildOverviewTab(BuildContext context, ReportsController controller, bool isDark) {
    final o = controller.overview!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Row 1: Attendance & Punctuality
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Attendance Rate',
                value: '${o.attendanceRate.toStringAsFixed(1)}%',
                subtitle: '${o.presentCount} of ${o.totalEmployees} present',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Punctuality Rate',
                value: '${o.punctualityRate.toStringAsFixed(1)}%',
                subtitle: '${o.presentCount - o.lateCount} arrived on time',
                icon: Icons.timer_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Late Arrivals',
                value: '${o.lateCount}',
                subtitle: 'Checked in past grace',
                icon: Icons.warning_amber_outlined,
                iconColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Absences',
                value: '${o.absentCount}',
                subtitle: 'Unexcused / unscheduled',
                icon: Icons.cancel_outlined,
                iconColor: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space16),

        // KPI Row 2: Operational Volume
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Pending Requests',
                value: '${o.pendingRequestsCount}',
                subtitle: 'Leaves & permissions pending',
                icon: Icons.assignment_outlined,
                iconColor: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Salary Advances',
                value: 'EGP ${o.approvedAdvancesAmount.toStringAsFixed(0)}',
                subtitle: 'Approved advance disbursements',
                icon: Icons.payments_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Total Deductions',
                value: 'EGP ${o.totalDeductionsAmount.toStringAsFixed(0)}',
                subtitle: 'Applied payroll adjustments',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.neutral,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),

        // Attendance Compliance Progress Meter Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Workforce Presence Breakdown', style: AppTypography.heading3),
                    Text('Total: ${o.totalEmployees} Active Headcount', style: AppTypography.captionOf(context)),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (o.presentCount - o.lateCount).clamp(1, 999),
                          child: Container(color: AppColors.success),
                        ),
                        Expanded(
                          flex: o.lateCount.clamp(1, 999),
                          child: Container(color: AppColors.warning),
                        ),
                        Expanded(
                          flex: o.absentCount.clamp(1, 999),
                          child: Container(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('On-Time: ${o.presentCount - o.lateCount}', AppColors.success),
                    _buildLegendItem('Late: ${o.lateCount}', AppColors.warning),
                    _buildLegendItem('Absent: ${o.absentCount}', AppColors.danger),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(BuildContext context, ReportsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDataTable<AttendanceDailyTrend>(
          isLoading: controller.isLoading,
          items: controller.trends,
          totalItems: controller.trends.length,
          columns: [
            HrColumn<AttendanceDailyTrend>(
              title: 'Date',
              cellBuilder: (t) => Text(
                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
                style: AppTypography.bodyBold,
              ),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: 'Present Headcount',
              cellBuilder: (t) => Text('${t.present}', style: AppTypography.body),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: 'Late Arrivals',
              cellBuilder: (t) => Text('${t.late}', style: AppTypography.body.copyWith(color: AppColors.warning)),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: 'Absences',
              cellBuilder: (t) => Text('${t.absent}', style: AppTypography.body.copyWith(color: AppColors.danger)),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: 'Early Checkouts',
              cellBuilder: (t) => Text('${t.earlyCheckout}', style: AppTypography.body),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: 'Attendance Rate',
              cellBuilder: (t) => StatusBadge(
                label: '${t.attendanceRate.toStringAsFixed(1)}%',
                variant: t.attendanceRate >= 90 ? BadgeVariant.success : BadgeVariant.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLateArrivalsTab(BuildContext context, ReportsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDataTable<LateArrivalReportItem>(
          isLoading: controller.isLoading,
          items: controller.lateArrivals,
          totalItems: controller.lateArrivals.length,
          columns: [
            HrColumn<LateArrivalReportItem>(
              title: 'Employee',
              cellBuilder: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.employeeName, style: AppTypography.bodyBold),
                  Text(item.employeeCode, style: AppTypography.captionOf(context)),
                ],
              ),
            ),
            HrColumn<LateArrivalReportItem>(
              title: 'Department',
              cellBuilder: (item) => Text(item.department, style: AppTypography.body),
            ),
            HrColumn<LateArrivalReportItem>(
              title: 'Date',
              cellBuilder: (item) => Text(
                '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
                style: AppTypography.bodyMedium,
              ),
            ),
            HrColumn<LateArrivalReportItem>(
              title: 'Scheduled Start',
              cellBuilder: (item) => Text(item.scheduledStartTime, style: AppTypography.body),
            ),
            HrColumn<LateArrivalReportItem>(
              title: 'Actual Check-in',
              cellBuilder: (item) => Text(item.actualCheckInTime, style: AppTypography.bodyBold),
            ),
            HrColumn<LateArrivalReportItem>(
              title: 'Late Duration',
              cellBuilder: (item) => StatusBadge(
                label: '+${item.lateMinutes} mins',
                variant: BadgeVariant.danger,
              ),
            ),
            HrColumn<LateArrivalReportItem>(
              title: 'Permission Status',
              cellBuilder: (item) => item.hasApprovedExcuse
                  ? const StatusBadge(label: 'Excused', variant: BadgeVariant.info)
                  : const StatusBadge(label: 'Unexcused', variant: BadgeVariant.neutral),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentsTab(BuildContext context, ReportsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDataTable<DepartmentAttendanceMetric>(
          isLoading: controller.isLoading,
          items: controller.departments,
          totalItems: controller.departments.length,
          columns: [
            HrColumn<DepartmentAttendanceMetric>(
              title: 'Department',
              cellBuilder: (d) => Text(d.department, style: AppTypography.bodyBold),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: 'Active Headcount',
              cellBuilder: (d) => Text('${d.headcount}', style: AppTypography.body),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: 'Attendance Rate',
              cellBuilder: (d) => StatusBadge(
                label: '${d.presentRate.toStringAsFixed(1)}%',
                variant: d.presentRate >= 90 ? BadgeVariant.success : BadgeVariant.warning,
              ),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: 'Late Occurrences',
              cellBuilder: (d) => Text('${d.lateCount}', style: AppTypography.body),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: 'Absences',
              cellBuilder: (d) => Text('${d.absenceCount}', style: AppTypography.body),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialsTab(BuildContext context, ReportsController controller, bool isDark) {
    final o = controller.overview!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Disbursed Salary Advances',
                value: 'EGP ${o.approvedAdvancesAmount.toStringAsFixed(2)}',
                subtitle: 'Approved employee advances',
                icon: Icons.payments_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Collected Deductions',
                value: 'EGP ${o.totalDeductionsAmount.toStringAsFixed(2)}',
                subtitle: 'Applied payroll adjustments',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: 'Net Recovery Balance',
                value: 'EGP ${(o.approvedAdvancesAmount - o.totalDeductionsAmount).toStringAsFixed(2)}',
                subtitle: 'Outstanding advance balance',
                icon: Icons.trending_up_outlined,
                iconColor: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
