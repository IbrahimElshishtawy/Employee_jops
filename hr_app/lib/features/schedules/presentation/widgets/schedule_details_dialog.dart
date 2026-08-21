import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/schedule_entity.dart';
import 'schedule_form_dialog.dart';

/// Modal dialog for inspecting work schedule details, working days strip, and attendance rules
class ScheduleDetailsDialog extends StatelessWidget {
  final WorkScheduleEntity schedule;
  final bool canEdit;
  final Future<bool> Function(WorkScheduleEntity updated)? onUpdate;

  const ScheduleDetailsDialog({
    super.key,
    required this.schedule,
    this.canEdit = false,
    this.onUpdate,
  });

  static const List<String> kAllWeekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _openEditDialog(BuildContext context) {
    if (onUpdate == null) return;

    showDialog(
      context: context,
      builder: (ctx) => ScheduleFormDialog(
        initialSchedule: schedule,
        onSave: onUpdate!,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = schedule;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(s.name, style: AppTypography.heading2, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: AppDimensions.space8),
                            StatusBadge(
                              label: s.isActive ? 'Active Shift' : 'Inactive Shift',
                              variant: s.isActive ? BadgeVariant.success : BadgeVariant.neutral,
                              icon: s.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                            ),
                          ],
                        ),
                        if (s.department != null && s.department!.isNotEmpty)
                          Text('Department: ${s.department}', style: AppTypography.captionOf(context)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              const Divider(),
              const SizedBox(height: AppDimensions.space12),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.description != null && s.description!.isNotEmpty) ...[
                        Text(s.description!, style: AppTypography.bodyMedium),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Shift Time Breakdown Metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Shift Start',
                              value: s.startTime,
                              icon: Icons.login_outlined,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Shift End',
                              value: s.endTime,
                              icon: Icons.logout_outlined,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Grace Window',
                              value: '${s.gracePeriodMinutes} mins',
                              icon: Icons.timer_outlined,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // 7-Day Working Days Visual Strip
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Working Days Schedule', style: AppTypography.bodyBold),
                                  Text('${s.workingDays.length} of 7 Days Active', style: AppTypography.captionOf(context)),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: kAllWeekDays.map((day) {
                                  final isWorking = s.workingDays.contains(day);
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isWorking
                                            ? AppColors.primaryLight.withValues(alpha: isDark ? 0.3 : 0.15)
                                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                        border: Border.all(
                                          color: isWorking
                                              ? AppColors.primaryLight.withValues(alpha: 0.5)
                                              : AppColors.border(context),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            day,
                                            style: TextStyle(
                                              fontWeight: isWorking ? FontWeight.bold : FontWeight.normal,
                                              color: isWorking ? AppColors.primaryLight : AppColors.textSecondary(context),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Icon(
                                            isWorking ? Icons.check_circle : Icons.remove,
                                            size: 14,
                                            color: isWorking ? AppColors.primaryLight : AppColors.textSecondary(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Attendance Engine Rule Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.rule, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Attendance Engine Punch Evaluation Rules', style: AppTypography.bodyBold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              _buildRuleRow(
                                context,
                                label: 'On-Time Punch Window',
                                detail: 'Check-in recorded up to ${s.startTime} is classified as On-Time.',
                                icon: Icons.check,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 8),
                              _buildRuleRow(
                                context,
                                label: 'Grace Period Window',
                                detail: 'Check-in between ${s.startTime} and +${s.gracePeriodMinutes} mins is within grace.',
                                icon: Icons.timelapse,
                                color: AppColors.warning,
                              ),
                              const SizedBox(height: 8),
                              _buildRuleRow(
                                context,
                                label: 'Late Arrival Status',
                                detail: 'Check-in after +${s.gracePeriodMinutes} mins is classified as Late.',
                                icon: Icons.warning_amber,
                                color: AppColors.danger,
                              ),
                              const SizedBox(height: 8),
                              _buildRuleRow(
                                context,
                                label: 'Non-Working Day Rule',
                                detail: 'Punch attempts on non-scheduled days return NOT_A_WORKING_DAY.',
                                icon: Icons.block,
                                color: AppColors.neutral,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Assigned Workforce Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, color: AppColors.primaryLight, size: 24),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Assigned Workforce Headcount', style: AppTypography.bodyBold),
                                    Text(
                                      '${s.assignedCount} active employees are currently bound to this shift',
                                      style: AppTypography.captionOf(context),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${s.assignedCount}',
                                style: AppTypography.heading2.copyWith(color: AppColors.primaryLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canEdit && onUpdate != null)
                    HrButton(
                      label: 'Edit Schedule',
                      variant: HrButtonVariant.primary,
                      icon: Icons.edit_outlined,
                      onPressed: () => _openEditDialog(context),
                    )
                  else
                    const SizedBox.shrink(),
                  HrButton(
                    label: 'Close',
                    variant: HrButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required IconData icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? AppColors.primaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.captionOf(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.bodyBold.copyWith(color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRuleRow(BuildContext context, {required String label, required String detail, required IconData icon, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodyBold.copyWith(fontSize: 12)),
              Text(detail, style: AppTypography.captionOf(context)),
            ],
          ),
        ),
      ],
    );
  }
}
