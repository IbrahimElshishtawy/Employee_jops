import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/filters/date_range_picker.dart';
import '../../../../core/widgets/filters/filter_bar.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';
import '../../domain/entities/attendance_record.dart';
import '../controllers/attendance_controller.dart';

/// Attendance Management & Logs Screen
class AttendanceListScreen extends StatelessWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AttendanceController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Bar with Date Range and Status Filter
        FilterBar(
          searchHint: 'Search employee name, workplace...',
          onSearchChanged: controller.onSearch,
          onRefresh: controller.fetchRecords,
          filterActions: [
            DateRangePickerField(
              startDate: controller.dateRange?.start,
              endDate: controller.dateRange?.end,
              onRangeSelected: controller.onDateRangeSelected,
            ),
            DropdownButton<AttendanceStatus?>(
              value: controller.statusFilter,
              hint: const Text('All Attendance'),
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Attendance')),
                ...AttendanceStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                ),
              ],
              onChanged: controller.onFilterStatus,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space20),

        // Attendance Table
        HrDataTable<AttendanceRecord>(
          isLoading: controller.isLoading && controller.records.isEmpty,
          errorMessage: controller.errorMessage,
          onRetry: controller.fetchRecords,
          items: controller.records,
          totalItems: controller.totalCount,
          currentPage: controller.currentPage,
          totalPages: controller.totalPages,
          pageSize: controller.pageSize,
          onPageChanged: (page) => controller.fetchRecords(page: page),
          columns: [
            HrColumn<AttendanceRecord>(
              title: 'Employee',
              cellBuilder: (rec) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(rec.employeeName, style: AppTypography.bodyBold),
                  Text('${rec.employeeCode} • ${rec.workplaceName}', style: AppTypography.caption),
                ],
              ),
            ),
            HrColumn<AttendanceRecord>(
              title: 'Date',
              cellBuilder: (rec) => Text(DateFormatter.toDisplayDate(rec.date), style: AppTypography.body),
            ),
            HrColumn<AttendanceRecord>(
              title: 'Check-In',
              cellBuilder: (rec) => Text(
                rec.checkInTime != null ? DateFormatter.toTimeOnly(rec.checkInTime) : '—',
                style: AppTypography.body,
              ),
            ),
            HrColumn<AttendanceRecord>(
              title: 'Check-Out',
              cellBuilder: (rec) => Text(
                rec.checkOutTime != null ? DateFormatter.toTimeOnly(rec.checkOutTime) : '—',
                style: AppTypography.body,
              ),
            ),
            HrColumn<AttendanceRecord>(
              title: 'Status',
              cellBuilder: (rec) {
                switch (rec.status) {
                  case AttendanceStatus.present:
                    return const StatusBadge(label: 'Present', variant: BadgeVariant.success);
                  case AttendanceStatus.late:
                    return StatusBadge(
                      label: 'Late (${rec.lateMinutes ?? 0}m)',
                      variant: BadgeVariant.warning,
                      icon: Icons.timer,
                    );
                  case AttendanceStatus.absent:
                    return const StatusBadge(label: 'Absent', variant: BadgeVariant.danger);
                  case AttendanceStatus.earlyDeparture:
                    return const StatusBadge(label: 'Early Departure', variant: BadgeVariant.warning);
                  case AttendanceStatus.overtime:
                    return StatusBadge(
                      label: 'Overtime (+${rec.overtimeMinutes ?? 0}m)',
                      variant: BadgeVariant.info,
                      icon: Icons.add_circle_outline,
                    );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
