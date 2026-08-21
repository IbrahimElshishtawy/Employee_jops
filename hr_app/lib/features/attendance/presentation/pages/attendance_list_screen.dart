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
import '../../../employees/domain/entities/employee_entity.dart';
import '../../../employees/presentation/widgets/manual_attendance_dialog.dart';
import '../../../workplaces/domain/entities/workplace_entity.dart';
import '../../domain/entities/attendance_record.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_details_dialog.dart';
import '../widgets/offline_review_dialog.dart';

/// Central Attendance Control Center Screen
class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  List<WorkplaceEntity> _workplaces = [];

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

  @override
  void initState() {
    super.initState();
    _loadWorkplaces();
  }

  Future<void> _loadWorkplaces() async {
    try {
      final wpRepo = context.read<WorkplacesRepository>();
      final wpResult = await wpRepo.getWorkplaces(const WorkplaceFilter(page: 1, pageSize: 50));
      if (mounted) {
        setState(() => _workplaces = wpResult.items);
      }
    } catch (_) {}
  }

  void _showRecordDetails(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AttendanceDetailsDialog(record: record),
    );
  }

  void _showOfflineReview(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => OfflineReviewDialog(
        record: record,
        onReview: ({required approve, reason}) async {
          return await context.read<AttendanceController>().reviewOfflineRecord(
                record.id,
                approve: approve,
                reason: reason,
              );
        },
      ),
    );
  }

  void _openManualCorrection() {
    final sampleEmp = EmployeeEntity(
      id: 'TEST-EMP-001',
      employeeCode: 'CW-001',
      fullName: 'Alex Vance (Test)',
      email: 'alex.vance@example.test',
      phone: '+201000000001',
      department: 'Engineering',
      jobTitle: 'Senior Systems Engineer',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Core',
      status: EmployeeStatus.active,
      joinedDate: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) => ManualAttendanceDialog(
        employee: sampleEmp,
        onSave: ({required checkIn, required checkOut, required date, required reason, required status}) async {
          final checkInDt = DateTime(date.year, date.month, date.day, checkIn.hour, checkIn.minute);
          final checkOutDt = DateTime(date.year, date.month, date.day, checkOut.hour, checkOut.minute);

          return await context.read<AttendanceController>().manualCorrection(
                employeeId: sampleEmp.id,
                date: date,
                status: status,
                checkInTime: checkInDt,
                checkOutTime: checkOutDt,
                reason: reason,
              );
        },
      ),
    );
  }

  Future<void> _exportReport() async {
    final controller = context.read<AttendanceController>();
    final url = await controller.exportReport();
    if (mounted) {
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance report generated successfully: $url'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to generate attendance export report.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AttendanceController>();
    final authCtrl = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canExport = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.attendanceExport);
    final canCorrect = AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.employeesUpdate) ||
        AuthorizationService.hasPermission(authCtrl.currentRole, AppPermission.attendanceRead);

    final kpis = controller.kpis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Top Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Control Center', style: AppTypography.heading1),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor employee punches, GPS accuracy, geofence compliance, and security signals',
                    style: AppTypography.subtitleOf(context),
                  ),
                ],
              ),
              Wrap(
                spacing: AppDimensions.space12,
                children: [
                  if (canCorrect)
                    HrButton(
                      label: 'Manual Correction',
                      icon: Icons.edit_calendar_outlined,
                      variant: HrButtonVariant.outline,
                      onPressed: _openManualCorrection,
                    ),
                  if (canExport)
                    HrButton(
                      label: 'Export Report',
                      icon: Icons.file_download_outlined,
                      isLoading: controller.isExporting,
                      onPressed: _exportReport,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Aggregated KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Present Today',
                  value: kpis != null ? '${kpis.presentCount}' : '—',
                  subtitle: 'On-time punches',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Late Arrivals',
                  value: kpis != null ? '${kpis.lateCount}' : '—',
                  subtitle: 'Past grace window',
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Absences',
                  value: kpis != null ? '${kpis.absentCount}' : '—',
                  subtitle: 'Unregistered punches',
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Early Departures',
                  value: kpis != null ? '${kpis.earlyDepartureCount}' : '—',
                  subtitle: 'Prior to shift end',
                  icon: Icons.logout_outlined,
                  iconColor: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Offline Pending',
                  value: kpis != null ? '${kpis.offlinePendingCount}' : '—',
                  subtitle: 'Requires HR review',
                  icon: Icons.cloud_sync_outlined,
                  iconColor: AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  title: 'Security Flags',
                  value: kpis != null ? '${kpis.suspiciousCount}' : '—',
                  subtitle: 'VPN / Mock Location',
                  icon: Icons.security,
                  iconColor: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Date Presets & Range Picker Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 18, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text('Date Filter:', style: AppTypography.bodyBold),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  children: DatePreset.values.map((preset) {
                    final isSelected = controller.datePreset == preset;
                    return ChoiceChip(
                      label: Text(preset.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) controller.onSelectDatePreset(preset);
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                DateRangePickerField(
                  startDate: controller.dateRange?.start,
                  endDate: controller.dateRange?.end,
                  onRangeSelected: controller.onDateRangeSelected,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Operational Sub-tabs
          Row(
            children: AttendanceTab.values.map((tab) {
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
            searchHint: 'Search employee name, code, workplace, department...',
            onSearchChanged: controller.onSearch,
            onRefresh: controller.fetchRecords,
            filterActions: [
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

              // Workplace Filter
              DropdownButton<String?>(
                value: controller.workplaceFilter,
                hint: const Text('All Workplaces'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Workplaces')),
                  ..._workplaces.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))),
                ],
                onChanged: controller.onFilterWorkplace,
              ),
              const SizedBox(width: 8),

              // Attendance Status Filter
              DropdownButton<AttendanceStatus?>(
                value: controller.statusFilter,
                hint: const Text('All Statuses'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Statuses')),
                  ...AttendanceStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: controller.onFilterStatus,
              ),
              const SizedBox(width: 8),

              // Security Status Filter
              DropdownButton<SecurityStatus?>(
                value: controller.securityFilter,
                hint: const Text('All Security States'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Security States')),
                  ...SecurityStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: controller.onFilterSecurity,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),

          // Attendance Records Table
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
            onRowTap: _showRecordDetails,
            emptyMessage: 'No attendance records match the selected dates and filter settings.',
            columns: [
              HrColumn<AttendanceRecord>(
                title: 'Employee',
                cellBuilder: (rec) => Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                      child: Text(
                        rec.employeeName.isNotEmpty ? rec.employeeName[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(rec.employeeName, style: AppTypography.bodyBold),
                        Text(
                          rec.department != null && rec.department!.isNotEmpty
                              ? '${rec.employeeCode} • ${rec.department}'
                              : rec.employeeCode,
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HrColumn<AttendanceRecord>(
                title: 'Date & Shift',
                cellBuilder: (rec) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormatter.toDisplayDate(rec.date), style: AppTypography.bodyBold),
                    Text(rec.scheduleName ?? 'Standard Core', style: AppTypography.captionOf(context)),
                  ],
                ),
              ),
              HrColumn<AttendanceRecord>(
                title: 'Check-In',
                cellBuilder: (rec) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rec.checkInTime != null ? DateFormatter.toTimeOnly(rec.checkInTime) : '—',
                      style: AppTypography.bodyBold,
                    ),
                    if (rec.checkInAccuracy != null)
                      Text(
                        'GPS ±${rec.checkInAccuracy!.toStringAsFixed(1)}m • ${rec.checkInDistanceMeters?.toStringAsFixed(0) ?? "0"}m to WP',
                        style: AppTypography.captionOf(context),
                      ),
                  ],
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
                title: 'Workplace',
                cellBuilder: (rec) => Text(rec.workplaceName, style: AppTypography.body),
              ),
              HrColumn<AttendanceRecord>(
                title: 'Attendance Status',
                cellBuilder: (rec) {
                  switch (rec.status) {
                    case AttendanceStatus.present:
                      return const StatusBadge(label: 'Present', variant: BadgeVariant.success);
                    case AttendanceStatus.late:
                      return StatusBadge(label: 'Late (${rec.lateMinutes ?? 0}m)', variant: BadgeVariant.warning);
                    case AttendanceStatus.absent:
                      return const StatusBadge(label: 'Absent', variant: BadgeVariant.danger);
                    case AttendanceStatus.earlyDeparture:
                      return const StatusBadge(label: 'Early Departure', variant: BadgeVariant.warning);
                    case AttendanceStatus.overtime:
                      return StatusBadge(label: 'Overtime (+${rec.overtimeMinutes ?? 0}m)', variant: BadgeVariant.info);
                  }
                },
              ),
              HrColumn<AttendanceRecord>(
                title: 'Security & Integrity',
                cellBuilder: (rec) {
                  if (rec.isOfflinePending) {
                    return const StatusBadge(label: 'Offline Pending', variant: BadgeVariant.warning);
                  }
                  if (rec.securityStatus == SecurityStatus.suspicious || rec.isFlagged) {
                    return const StatusBadge(label: 'Security Flagged', variant: BadgeVariant.danger);
                  }
                  return const StatusBadge(label: 'Verified Secure', variant: BadgeVariant.success);
                },
              ),
              HrColumn<AttendanceRecord>(
                title: 'Actions',
                cellBuilder: (rec) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Full Telemetry & Timeline',
                      onPressed: () => _showRecordDetails(rec),
                    ),
                    if (rec.isOfflinePending)
                      IconButton(
                        icon: const Icon(Icons.rate_review_outlined, size: 18, color: AppColors.warning),
                        tooltip: 'Review Offline Submission',
                        onPressed: () => _showOfflineReview(rec),
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
