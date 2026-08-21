import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/feedback/status_badge.dart';
import '../../../../core/widgets/tables/hr_data_table.dart';

/// Immutable Audit Log Entry representing an administrative event
class AuditLogEntry {
  final String id;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final DateTime timestamp;
  final String result;
  final String ipAddress;

  const AuditLogEntry({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.timestamp,
    required this.result,
    required this.ipAddress,
  });
}

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  static final List<AuditLogEntry> _mockLogs = [
    AuditLogEntry(
      id: 'AUD-001',
      actorName: 'Super Administrator (Test)',
      actorRole: 'SUPER_ADMIN',
      action: 'LEAVE_APPROVED',
      targetType: 'REQUEST',
      targetId: 'TEST-REQ-002',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      result: 'SUCCESS',
      ipAddress: '192.168.1.45',
    ),
    AuditLogEntry(
      id: 'AUD-002',
      actorName: 'HR Admin (Test)',
      actorRole: 'HR_ADMIN',
      action: 'EMPLOYEE_SUSPENDED',
      targetType: 'EMPLOYEE',
      targetId: 'TEST-EMP-003',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      result: 'SUCCESS',
      ipAddress: '192.168.1.12',
    ),
    AuditLogEntry(
      id: 'AUD-003',
      actorName: 'HR Admin (Test)',
      actorRole: 'HR_ADMIN',
      action: 'ADVANCE_APPROVED',
      targetType: 'ADVANCE',
      targetId: 'TEST-ADV-002',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      result: 'SUCCESS',
      ipAddress: '192.168.1.12',
    ),
    AuditLogEntry(
      id: 'AUD-004',
      actorName: 'Super Administrator (Test)',
      actorRole: 'SUPER_ADMIN',
      action: 'WORKPLACE_UPDATED',
      targetType: 'WORKPLACE',
      targetId: 'WP-001',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      result: 'SUCCESS',
      ipAddress: '192.168.1.45',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('System Audit Logs & Security Trail', style: AppTypography.heading2),
          const SizedBox(height: AppDimensions.space8),
          Text('Immutable, tamper-evident record of all administrative HR actions.', style: AppTypography.subtitle),
          const SizedBox(height: AppDimensions.space24),
          HrDataTable<AuditLogEntry>(
            items: _mockLogs,
            totalItems: _mockLogs.length,
            columns: [
              HrColumn<AuditLogEntry>(
                title: 'Timestamp',
                cellBuilder: (l) => Text(DateFormatter.toDisplayDateTime(l.timestamp), style: AppTypography.body),
              ),
              HrColumn<AuditLogEntry>(
                title: 'Actor (User)',
                cellBuilder: (l) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.actorName, style: AppTypography.bodyBold),
                    Text(l.actorRole, style: AppTypography.caption),
                  ],
                ),
              ),
              HrColumn<AuditLogEntry>(
                title: 'Action Performed',
                cellBuilder: (l) => Text(l.action, style: AppTypography.bodyMedium),
              ),
              HrColumn<AuditLogEntry>(
                title: 'Target Entity',
                cellBuilder: (l) => Text('${l.targetType}: ${l.targetId}', style: AppTypography.body),
              ),
              HrColumn<AuditLogEntry>(
                title: 'IP Address',
                cellBuilder: (l) => Text(l.ipAddress, style: AppTypography.caption),
              ),
              HrColumn<AuditLogEntry>(
                title: 'Status',
                cellBuilder: (l) => const StatusBadge(label: 'VERIFIED', variant: BadgeVariant.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
