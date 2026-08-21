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
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../domain/entities/schedule_entity.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/schedule_details_dialog.dart';
import '../widgets/schedule_form_dialog.dart';

/// Work Schedules Management Screen
class SchedulesListScreen extends StatelessWidget {
  const SchedulesListScreen({super.key});

  static const List<String> kWeekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _showScheduleDetails(BuildContext context, WorkScheduleEntity schedule, bool canEdit) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleDetailsDialog(
        schedule: schedule,
        canEdit: canEdit,
        onUpdate: (updated) async {
          final success = await context.read<ScheduleController>().updateSchedule(updated);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule "${updated.name}" updated successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  void _showCreateScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleFormDialog(
        onSave: (newSchedule) async {
          final success = await context.read<ScheduleController>().createSchedule(newSchedule);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule "${newSchedule.name}" created successfully.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, WorkScheduleEntity schedule) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleFormDialog(
        initialSchedule: schedule,
        onSave: (updated) async {
          final success = await context.read<ScheduleController>().updateSchedule(updated);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule "${updated.name}" updated successfully.'),
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
    final controller = context.watch<ScheduleController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canCreate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.schedulesCreate);
    final canUpdate = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.schedulesUpdate);
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
                    Text(l10n.translate('sch_title'), style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('sch_subtitle'),
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              if (canCreate)
                HrButton(
                  label: l10n.translate('sch_new_btn'),
                  icon: Icons.add_alarm_outlined,
                  variant: HrButtonVariant.primary,
                  onPressed: () => _showCreateScheduleDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: l10n.translate('sch_active_shifts'),
                  value: kpis != null ? l10n.formatNumber(kpis.activeCount) : '—',
                  subtitle: l10n.translate('verified_badge'),
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('sch_total_schedules'),
                  value: kpis != null ? l10n.formatNumber(kpis.totalCount) : '—',
                  subtitle: l10n.translate('sch_title'),
                  icon: Icons.schedule,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('sch_assigned_workforce'),
                  value: kpis != null ? l10n.formatNumber(kpis.assignedEmployeesCount) : '—',
                  subtitle: l10n.translate('emp_total'),
                  icon: Icons.people_outline,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: l10n.translate('sch_inactive_shifts'),
                  value: kpis != null ? l10n.formatNumber(kpis.inactiveCount) : '—',
                  subtitle: l10n.translate('wp_inactive_only'),
                  icon: Icons.pause_circle_outline,
                  iconColor: AppColors.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Operational Sub-tabs
          Row(
            children: SchedulesTab.values.map((tab) {
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
            onRefresh: controller.fetchSchedules,
            filterActions: [
              // Working Day Filter
              DropdownButton<String?>(
                value: controller.workingDayFilter,
                hint: Text(l10n.translate('sch_all_working_days')),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.translate('sch_all_working_days'))),
                  ...kWeekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
                onChanged: controller.onFilterWorkingDay,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Schedules Data Table
          HrDataTable<WorkScheduleEntity>(
            isLoading: controller.isLoading && controller.schedules.isEmpty,
            errorMessage: controller.errorMessage,
            onRetry: controller.fetchSchedules,
            items: controller.schedules,
            totalItems: controller.totalCount,
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            pageSize: controller.pageSize,
            onPageChanged: (page) => controller.fetchSchedules(page: page),
            onRowTap: (s) => _showScheduleDetails(context, s, canUpdate),
            emptyMessage: l10n.translate('no_data'),
            columns: [
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('sch_name_col'),
                cellBuilder: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.name, style: AppTypography.bodyBold),
                    if (s.department != null && s.department!.isNotEmpty)
                      Text(s.department!, style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('sch_working_hours'),
                cellBuilder: (s) => Text(
                  '${s.startTime} - ${s.endTime}',
                  style: AppTypography.bodyBold.copyWith(color: AppColors.primaryLight),
                ),
              ),
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('sch_working_days'),
                cellBuilder: (s) => Text(s.workingDays.join(', '), style: AppTypography.body),
              ),
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('sch_grace_period'),
                cellBuilder: (s) => Text('${l10n.formatNumber(s.gracePeriodMinutes)} ${l10n.isArabic ? "دقيقة" : "mins"}', style: AppTypography.bodyMedium),
              ),
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('wp_assigned_staff'),
                cellBuilder: (s) => Text(l10n.formatNumber(s.assignedCount), style: AppTypography.body),
              ),
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('status'),
                cellBuilder: (s) => s.isActive
                    ? StatusBadge(label: l10n.translate('wp_active_only'), variant: BadgeVariant.success, icon: Icons.check_circle_outline)
                    : StatusBadge(label: l10n.translate('wp_inactive_only'), variant: BadgeVariant.neutral, icon: Icons.pause_circle_outline),
              ),
              HrColumn<WorkScheduleEntity>(
                title: l10n.translate('actions'),
                cellBuilder: (s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: l10n.translate('sch_view_details'),
                      onPressed: () => _showScheduleDetails(context, s, canUpdate),
                    ),
                    if (canUpdate) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: l10n.translate('sch_edit'),
                        onPressed: () => _showEditScheduleDialog(context, s),
                      ),
                      IconButton(
                        icon: Icon(
                          s.isActive ? Icons.toggle_on : Icons.toggle_off,
                          size: 24,
                          color: s.isActive ? AppColors.success : AppColors.neutral,
                        ),
                        tooltip: s.isActive ? l10n.translate('emp_deactivate') : l10n.translate('emp_activate'),
                        onPressed: () => controller.toggleStatus(s.id, !s.isActive),
                      ),
                    ],
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
