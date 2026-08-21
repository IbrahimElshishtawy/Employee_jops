import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
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
                    Text('Work Schedules & Shifts Management', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Define operational working hours, grace periods, and working day configurations for workforce attendance',
                      style: AppTypography.subtitleOf(context),
                    ),
                  ],
                ),
              ),
              if (canCreate)
                HrButton(
                  label: 'New Schedule',
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
                  title: 'Active Shifts',
                  value: kpis != null ? '${kpis.activeCount}' : '—',
                  subtitle: 'Operational schedules',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Total Schedules',
                  value: kpis != null ? '${kpis.totalCount}' : '—',
                  subtitle: 'All configured shifts',
                  icon: Icons.schedule,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Assigned Workforce',
                  value: kpis != null ? '${kpis.assignedEmployeesCount}' : '—',
                  subtitle: 'Staff bound to shifts',
                  icon: Icons.people_outline,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Inactive Shifts',
                  value: kpis != null ? '${kpis.inactiveCount}' : '—',
                  subtitle: 'Disabled/archived',
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
            searchHint: 'Search schedule name, department, workplace...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchSchedules,
            filterActions: [
              // Working Day Filter
              DropdownButton<String?>(
                value: controller.workingDayFilter,
                hint: const Text('All Working Days'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Working Days')),
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
            emptyMessage: 'No work schedules found matching the selected filters.',
            columns: [
              HrColumn<WorkScheduleEntity>(
                title: 'Schedule Name',
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
                title: 'Working Hours',
                cellBuilder: (s) => Text(
                  '${s.startTime} - ${s.endTime}',
                  style: AppTypography.bodyBold.copyWith(color: AppColors.primaryLight),
                ),
              ),
              HrColumn<WorkScheduleEntity>(
                title: 'Working Days',
                cellBuilder: (s) => Text(s.workingDays.join(', '), style: AppTypography.body),
              ),
              HrColumn<WorkScheduleEntity>(
                title: 'Grace Period',
                cellBuilder: (s) => Text('${s.gracePeriodMinutes} mins', style: AppTypography.bodyMedium),
              ),
              HrColumn<WorkScheduleEntity>(
                title: 'Assigned Staff',
                cellBuilder: (s) => Text('${s.assignedCount} employees', style: AppTypography.body),
              ),
              HrColumn<WorkScheduleEntity>(
                title: 'Status',
                cellBuilder: (s) => s.isActive
                    ? const StatusBadge(label: 'Active', variant: BadgeVariant.success, icon: Icons.check_circle_outline)
                    : const StatusBadge(label: 'Inactive', variant: BadgeVariant.neutral, icon: Icons.pause_circle_outline),
              ),
              HrColumn<WorkScheduleEntity>(
                title: 'Actions',
                cellBuilder: (s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details & Rules',
                      onPressed: () => _showScheduleDetails(context, s, canUpdate),
                    ),
                    if (canUpdate) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Schedule',
                        onPressed: () => _showEditScheduleDialog(context, s),
                      ),
                      IconButton(
                        icon: Icon(
                          s.isActive ? Icons.toggle_on : Icons.toggle_off,
                          size: 24,
                          color: s.isActive ? AppColors.success : AppColors.neutral,
                        ),
                        tooltip: s.isActive ? 'Deactivate Shift' : 'Activate Shift',
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
