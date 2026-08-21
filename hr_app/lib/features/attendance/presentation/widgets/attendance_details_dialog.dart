import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/forms/hr_button.dart';
import '../../domain/entities/attendance_record.dart';
import 'attendance_event_timeline.dart';

/// Comprehensive modal dialog for inspecting an attendance record and telemetry
class AttendanceDetailsDialog extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceDetailsDialog({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 0.15),
                    child: Text(
                      record.employeeName.isNotEmpty ? record.employeeName[0].toUpperCase() : 'E',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(record.employeeName, style: AppTypography.heading2),
                            const SizedBox(width: AppDimensions.space8),
                            _buildStatusBadge(record.status),
                            if (record.securityStatus != SecurityStatus.normal) ...[
                              const SizedBox(width: 6),
                              StatusBadge(
                                label: record.securityStatus.label,
                                variant: record.securityStatus == SecurityStatus.rejected ? BadgeVariant.danger : BadgeVariant.warning,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.employeeCode}${record.department != null && record.department!.isNotEmpty ? ' • ${record.department}' : ''} • ${record.workplaceName}',
                          style: AppTypography.captionOf(context),
                        ),
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
                      // Section 1: Check-in & Check-out Telemetry Cards
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Check-in Telemetry Card
                          Expanded(
                            child: _buildTelemetryCard(
                              context,
                              title: 'Check-In Telemetry',
                              icon: Icons.login_outlined,
                              timeStr: record.checkInTime != null ? DateFormatter.toTimeOnly(record.checkInTime) : 'Not Punched',
                              lat: record.checkInLat,
                              lng: record.checkInLng,
                              accuracy: record.checkInAccuracy,
                              distance: record.checkInDistanceMeters,
                              geofenceValid: record.checkInGeofenceValid,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),

                          // Check-out Telemetry Card
                          Expanded(
                            child: _buildTelemetryCard(
                              context,
                              title: 'Check-Out Telemetry',
                              icon: Icons.logout_outlined,
                              timeStr: record.checkOutTime != null ? DateFormatter.toTimeOnly(record.checkOutTime) : 'Not Punched',
                              lat: record.checkOutLat,
                              lng: record.checkOutLng,
                              accuracy: record.checkOutAccuracy,
                              distance: record.checkOutDistanceMeters,
                              geofenceValid: record.checkOutGeofenceValid,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Section 2: Workplace & Shift Schedule Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardHeader(Icons.schedule_outlined, 'Shift Schedule & Rule Engine Decisions'),
                              const SizedBox(height: AppDimensions.space12),
                              Row(
                                children: [
                                  Expanded(child: _buildInfoItem(context, 'Assigned Workplace', record.workplaceName)),
                                  Expanded(child: _buildInfoItem(context, 'Assigned Shift', record.scheduleName ?? 'Standard Core')),
                                  Expanded(
                                    child: _buildInfoItem(
                                      context,
                                      'Shift Window',
                                      '${record.shiftStart ?? "09:00"} - ${record.shiftEnd ?? "17:00"}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      context,
                                      'Grace Period',
                                      '${record.gracePeriodMinutes ?? 15} minutes',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Section 3: Device Integrity & Security Signals (if present)
                      if (record.securitySignals.isNotEmpty || record.deviceModel != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCardHeader(Icons.security_outlined, 'Device Signals & Telemetry Security'),
                                const SizedBox(height: AppDimensions.space12),
                                if (record.deviceModel != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Device: ${record.deviceModel} (${record.deviceOs ?? "Unknown OS"})',
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                if (record.securitySignals.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: record.securitySignals.map((sig) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                                            const SizedBox(width: 6),
                                            Text(
                                              sig,
                                              style: const TextStyle(
                                                color: AppColors.danger,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Section 4: Granular Event Lifecycle Timeline
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardHeader(Icons.history_edu_outlined, 'Attendance Event Lifecycle & Audit Trail'),
                              const SizedBox(height: AppDimensions.space12),
                              AttendanceEventTimeline(events: record.events),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

  Widget _buildTelemetryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String timeStr,
    double? lat,
    double? lng,
    double? accuracy,
    double? distance,
    bool? geofenceValid,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(title, style: AppTypography.bodyBold),
                const Spacer(),
                Text(timeStr, style: AppTypography.bodyBold.copyWith(color: AppColors.primaryLight)),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),
            if (lat != null && lng != null) ...[
              _buildMetricRow('Coordinates', '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
              _buildMetricRow('GPS Accuracy', '±${accuracy?.toStringAsFixed(1) ?? "0"} meters'),
              _buildMetricRow('Perimeter Distance', '${distance?.toStringAsFixed(1) ?? "0"} meters'),
              _buildMetricRow(
                'Geofence Result',
                geofenceValid == true ? 'INSIDE BOUNDARY' : 'OUTSIDE GEOFENCE',
                color: geofenceValid == true ? AppColors.success : AppColors.danger,
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No telemetry captured for this event', style: AppTypography.captionOf(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.bodyBold),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.captionOf(context)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const StatusBadge(label: 'Present', variant: BadgeVariant.success);
      case AttendanceStatus.late:
        return const StatusBadge(label: 'Late', variant: BadgeVariant.warning);
      case AttendanceStatus.absent:
        return const StatusBadge(label: 'Absent', variant: BadgeVariant.danger);
      case AttendanceStatus.earlyDeparture:
        return const StatusBadge(label: 'Early Departure', variant: BadgeVariant.warning);
      case AttendanceStatus.overtime:
        return const StatusBadge(label: 'Overtime', variant: BadgeVariant.info);
    }
  }
}
