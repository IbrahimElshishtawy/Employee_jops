import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/schedule_entity.dart';

/// Work Schedules Screen
class SchedulesListScreen extends StatefulWidget {
  final SchedulesRepository repository;

  const SchedulesListScreen({super.key, required this.repository});

  @override
  State<SchedulesListScreen> createState() => _SchedulesListScreenState();
}

class _SchedulesListScreenState extends State<SchedulesListScreen> {
  List<WorkScheduleEntity> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final res = await widget.repository.getSchedules(1, 10);
    setState(() {
      _items = res.items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        FilterBar(
          searchHint: 'Search schedules...',
          onRefresh: _loadSchedules,
          filterActions: [
            HrButton(
              label: 'New Schedule',
              icon: Icons.add_alarm_outlined,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),
        HrDataTable<WorkScheduleEntity>(
          isLoading: _isLoading,
          items: _items,
          totalItems: _items.length,
          columns: [
            HrColumn<WorkScheduleEntity>(
              title: 'Schedule Name',
              cellBuilder: (s) => Text(s.name, style: AppTypography.bodyBold),
            ),
            HrColumn<WorkScheduleEntity>(
              title: 'Working Hours',
              cellBuilder: (s) => Text('${s.startTime} - ${s.endTime}', style: AppTypography.bodyMedium),
            ),
            HrColumn<WorkScheduleEntity>(
              title: 'Working Days',
              cellBuilder: (s) => Text(s.workingDays.join(', '), style: AppTypography.body),
            ),
            HrColumn<WorkScheduleEntity>(
              title: 'Grace Period',
              cellBuilder: (s) => Text('${s.gracePeriodMinutes} mins', style: AppTypography.body),
            ),
            HrColumn<WorkScheduleEntity>(
              title: 'Assigned Staff',
              cellBuilder: (s) => Text('${s.assignedCount} employees', style: AppTypography.body),
            ),
            HrColumn<WorkScheduleEntity>(
              title: 'Status',
              cellBuilder: (s) => s.isActive
                  ? const StatusBadge(label: 'Active', variant: BadgeVariant.success)
                  : const StatusBadge(label: 'Inactive', variant: BadgeVariant.neutral),
            ),
          ],
        ),
      ],
      ),
    );
  }
}
