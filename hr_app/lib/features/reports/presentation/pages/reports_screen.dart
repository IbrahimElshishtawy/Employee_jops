import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
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
    final l10n = context.l10n;

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
                    Text(l10n.translate('rep_title'), style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('rep_subtitle'),
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              HrButton(
                label: l10n.translate('rep_export_btn'),
                icon: Icons.file_download_outlined,
                variant: HrButtonVariant.primary,
                onPressed: () => _openExportDialog(context, controller),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Date Preset & Department Global Filters
          FilterBar(
            searchHint: l10n.translate('search_placeholder'),
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
                hint: Text(l10n.translate('emp_all_departments')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l10n.translate('emp_all_departments'))),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportsTab.values.map((tab) {
              final isSelected = controller.activeTab == tab;
              return ChoiceChip(
                label: Text(tab.label),
                selected: isSelected,
                selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15),
                onSelected: (selected) {
                  if (selected) controller.setActiveTab(tab);
                },
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
                      label: l10n.translate('retry'),
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Row 1: Attendance & Punctuality
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_attendance_rate'),
                value: '${l10n.formatNumber(o.attendanceRate)}%',
                subtitle: '${l10n.formatNumber(o.presentCount)} / ${l10n.formatNumber(o.totalEmployees)}',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_punctuality'),
                value: '${l10n.formatNumber(o.punctualityRate)}%',
                subtitle: '${l10n.formatNumber(o.presentCount - o.lateCount)} ${l10n.translate("rep_on_time")}',
                icon: Icons.timer_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_late_arrivals'),
                value: l10n.formatNumber(o.lateCount),
                subtitle: l10n.translate('rep_late'),
                icon: Icons.warning_amber_outlined,
                iconColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_absences'),
                value: l10n.formatNumber(o.absentCount),
                subtitle: l10n.translate('rep_absent'),
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
                title: l10n.translate('rep_pending_requests'),
                value: l10n.formatNumber(o.pendingRequestsCount),
                subtitle: l10n.translate('req_title'),
                icon: Icons.assignment_outlined,
                iconColor: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_total_advances'),
                value: l10n.formatCurrency(o.approvedAdvancesAmount),
                subtitle: l10n.translate('adv_approved_volume'),
                icon: Icons.payments_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_total_deductions'),
                value: l10n.formatCurrency(o.totalDeductionsAmount),
                subtitle: l10n.translate('ded_applied_payroll'),
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
                    Text(l10n.translate('rep_presence_breakdown'), style: AppTypography.heading3),
                    Text('${l10n.translate("emp_total")}: ${l10n.formatNumber(o.totalEmployees)}', style: AppTypography.captionOf(context)),
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
                    _buildLegendItem('${l10n.translate("rep_on_time")}: ${l10n.formatNumber(o.presentCount - o.lateCount)}', AppColors.success),
                    _buildLegendItem('${l10n.translate("rep_late")}: ${l10n.formatNumber(o.lateCount)}', AppColors.warning),
                    _buildLegendItem('${l10n.translate("rep_absent")}: ${l10n.formatNumber(o.absentCount)}', AppColors.danger),
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDataTable<AttendanceDailyTrend>(
          isLoading: controller.isLoading,
          items: controller.trends,
          totalItems: controller.trends.length,
          columns: [
            HrColumn<AttendanceDailyTrend>(
              title: l10n.translate('emp_joined_date'),
              cellBuilder: (t) => Text(
                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
                style: AppTypography.bodyBold,
              ),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: l10n.translate('rep_present_headcount'),
              cellBuilder: (t) => Text(l10n.formatNumber(t.present), style: AppTypography.body),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: l10n.translate('rep_late_arrivals'),
              cellBuilder: (t) => Text(l10n.formatNumber(t.late), style: AppTypography.body.copyWith(color: AppColors.warning)),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: l10n.translate('rep_absences'),
              cellBuilder: (t) => Text(l10n.formatNumber(t.absent), style: AppTypography.body.copyWith(color: AppColors.danger)),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: l10n.translate('rep_early_checkouts'),
              cellBuilder: (t) => Text(l10n.formatNumber(t.earlyCheckout), style: AppTypography.body),
            ),
            HrColumn<AttendanceDailyTrend>(
              title: l10n.translate('rep_attendance_rate'),
              cellBuilder: (t) => StatusBadge(
                label: '${l10n.formatNumber(t.attendanceRate)}%',
                variant: t.attendanceRate >= 90 ? BadgeVariant.success : BadgeVariant.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLateArrivalsTab(BuildContext context, ReportsController controller, bool isDark) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDataTable<LateArrivalReportItem>(
          isLoading: controller.isLoading,
          items: controller.lateArrivals,
          totalItems: controller.lateArrivals.length,
          columns: [
            HrColumn<LateArrivalReportItem>(
              title: l10n.translate('emp_name'),
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
              title: l10n.translate('emp_department'),
              cellBuilder: (item) => Text(item.department, style: AppTypography.body),
            ),
            HrColumn<LateArrivalReportItem>(
              title: l10n.translate('emp_joined_date'),
              cellBuilder: (item) => Text(
                '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
                style: AppTypography.bodyMedium,
              ),
            ),
            HrColumn<LateArrivalReportItem>(
              title: l10n.translate('rep_scheduled_start'),
              cellBuilder: (item) => Text(item.scheduledStartTime, style: AppTypography.body),
            ),
            HrColumn<LateArrivalReportItem>(
              title: l10n.translate('rep_actual_checkin'),
              cellBuilder: (item) => Text(item.actualCheckInTime, style: AppTypography.bodyBold),
            ),
            HrColumn<LateArrivalReportItem>(
              title: l10n.translate('rep_late_duration'),
              cellBuilder: (item) => StatusBadge(
                label: '+${l10n.formatNumber(item.lateMinutes)} ${l10n.isArabic ? "د" : "mins"}',
                variant: BadgeVariant.danger,
              ),
            ),
            HrColumn<LateArrivalReportItem>(
              title: l10n.translate('rep_permission_status'),
              cellBuilder: (item) => item.hasApprovedExcuse
                  ? StatusBadge(label: l10n.translate('rep_excused'), variant: BadgeVariant.info)
                  : StatusBadge(label: l10n.translate('rep_unexcused'), variant: BadgeVariant.neutral),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentsTab(BuildContext context, ReportsController controller, bool isDark) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDataTable<DepartmentAttendanceMetric>(
          isLoading: controller.isLoading,
          items: controller.departments,
          totalItems: controller.departments.length,
          columns: [
            HrColumn<DepartmentAttendanceMetric>(
              title: l10n.translate('emp_department'),
              cellBuilder: (d) => Text(d.department, style: AppTypography.bodyBold),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: l10n.translate('emp_total'),
              cellBuilder: (d) => Text(l10n.formatNumber(d.headcount), style: AppTypography.body),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: l10n.translate('rep_attendance_rate'),
              cellBuilder: (d) => StatusBadge(
                label: '${l10n.formatNumber(d.presentRate)}%',
                variant: d.presentRate >= 90 ? BadgeVariant.success : BadgeVariant.warning,
              ),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: l10n.translate('rep_late_incidents'),
              cellBuilder: (d) => Text(l10n.formatNumber(d.lateCount), style: AppTypography.body),
            ),
            HrColumn<DepartmentAttendanceMetric>(
              title: l10n.translate('rep_absences'),
              cellBuilder: (d) => Text(l10n.formatNumber(d.absenceCount), style: AppTypography.body),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialsTab(BuildContext context, ReportsController controller, bool isDark) {
    final o = controller.overview!;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_disbursed_advances'),
                value: l10n.formatCurrency(o.approvedAdvancesAmount),
                subtitle: l10n.translate('adv_approved_volume'),
                icon: Icons.payments_outlined,
                iconColor: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_collected_deductions'),
                value: l10n.formatCurrency(o.totalDeductionsAmount),
                subtitle: l10n.translate('ded_applied_payroll'),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                title: l10n.translate('rep_net_recovery'),
                value: l10n.formatCurrency(o.approvedAdvancesAmount - o.totalDeductionsAmount),
                subtitle: l10n.translate('adv_remaining_col'),
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
