import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/audit_log_entity.dart';

/// Mock repository with realistic security and administrative audit logs
class MockAuditLogsRepository implements AuditLogsRepository {
  final List<AuditLogItemEntity> _mockLogs = [
    AuditLogItemEntity(
      id: 'AUD-001',
      actorId: 'USR-ADMIN-1',
      actorName: 'Sara Mostafa (HR Admin)',
      actorRole: 'HR_ADMIN',
      action: 'LEAVE_REQUEST_APPROVED',
      category: AuditActionCategory.requests,
      targetType: 'REQUEST',
      targetId: 'REQ-1002',
      targetSummary: 'Annual Leave for Ahmed Hassan (4 days)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      result: AuditResultStatus.success,
      ipAddress: '192.168.1.15',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0',
      reason: 'Sufficient leave balance and project coverage arranged.',
      metadata: {'daysRequested': 4, 'deductedFromAnnual': true},
    ),
    AuditLogItemEntity(
      id: 'AUD-002',
      actorId: 'SYSTEM',
      actorName: 'Security Rule Engine',
      actorRole: 'SYSTEM_BOT',
      action: 'SUSPICIOUS_TOKEN_REPLAY_BLOCKED',
      category: AuditActionCategory.security,
      targetType: 'SESSION',
      targetId: 'SESS-9921',
      targetSummary: 'Revoked refresh token reuse attempt from unrecognized IP',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      result: AuditResultStatus.warning,
      ipAddress: '197.34.120.89',
      userAgent: 'CyberWise-Mobile-App/2.4.1 (Android 14)',
      reason: 'Token was previously invalidated during logout.',
      metadata: {'riskScore': 92, 'familyRevocationTriggered': true},
    ),
    AuditLogItemEntity(
      id: 'AUD-003',
      actorId: 'USR-ADMIN-2',
      actorName: 'Tarek Ibrahim (HR Manager)',
      actorRole: 'HR_MANAGER',
      action: 'SALARY_ADVANCE_APPROVED',
      category: AuditActionCategory.financial,
      targetType: 'ADVANCE',
      targetId: 'ADV-1001',
      targetSummary: 'Advance of 5,000 EGP for Ahmed Hassan',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      result: AuditResultStatus.success,
      ipAddress: '192.168.1.22',
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
      reason: 'Compliance with 50% basic salary advance cap verified.',
      metadata: {'amount': 5000, 'installments': 2, 'currency': 'EGP'},
    ),
    AuditLogItemEntity(
      id: 'AUD-004',
      actorId: 'USR-ADMIN-1',
      actorName: 'Sara Mostafa (HR Admin)',
      actorRole: 'HR_ADMIN',
      action: 'MANUAL_ATTENDANCE_CORRECTED',
      category: AuditActionCategory.attendance,
      targetType: 'ATTENDANCE',
      targetId: 'ATT-20260821-003',
      targetSummary: 'Adjusted check-in timestamp for Youssef Ali',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      result: AuditResultStatus.success,
      ipAddress: '192.168.1.15',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      reason: 'Smart Village biometric scanner WiFi sync delay.',
      metadata: {'originalPunch': '09:02', 'adjustedPunch': '08:58', 'statusChangedTo': 'PRESENT_ON_TIME'},
    ),
    AuditLogItemEntity(
      id: 'AUD-005',
      actorId: 'USR-ADMIN-3',
      actorName: 'Super Admin (CyberWise)',
      actorRole: 'SUPER_ADMIN',
      action: 'WORKPLACE_GEOFENCE_UPDATED',
      category: AuditActionCategory.security,
      targetType: 'WORKPLACE',
      targetId: 'WP-001',
      targetSummary: 'Adjusted HQ Cairo radius from 100m to 120m',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      result: AuditResultStatus.success,
      ipAddress: '192.168.1.5',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      reason: 'Expansion of annex office building.',
      metadata: {'previousRadius': 100, 'newRadius': 120},
    ),
    AuditLogItemEntity(
      id: 'AUD-006',
      actorId: 'USR-UNKNOWN',
      actorName: 'Anonymous IP',
      actorRole: 'UNAUTHENTICATED',
      action: 'FAILED_ADMIN_LOGIN',
      category: AuditActionCategory.authentication,
      targetType: 'AUTH',
      targetId: 'AUTH-FAIL-1',
      targetSummary: 'Invalid credentials attempted for admin@cyberwise.test',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      result: AuditResultStatus.failure,
      ipAddress: '41.233.10.4',
      userAgent: 'Python-urllib/3.10',
      reason: 'Password mismatch. Rate limiter counter incremented.',
      metadata: {'failedAttemptCount': 3},
    ),
  ];

  @override
  Future<PaginatedList<AuditLogItemEntity>> getAuditLogs(AuditLogFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var list = List<AuditLogItemEntity>.from(_mockLogs);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      list = list.where((l) =>
          l.action.toLowerCase().contains(q) ||
          l.actorName.toLowerCase().contains(q) ||
          l.targetId.toLowerCase().contains(q) ||
          (l.targetSummary?.toLowerCase().contains(q) ?? false) ||
          l.ipAddress.toLowerCase().contains(q)).toList();
    }

    if (filter.category != null) {
      list = list.where((l) => l.category == filter.category).toList();
    }

    if (filter.result != null) {
      list = list.where((l) => l.result == filter.result).toList();
    }

    if (filter.actorRole != null && filter.actorRole!.isNotEmpty) {
      list = list.where((l) => l.actorRole == filter.actorRole).toList();
    }

    final totalCount = list.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<AuditLogItemEntity>(
      items: list.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<AuditLogItemEntity> getAuditLogById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockLogs.firstWhere(
      (l) => l.id == id,
      orElse: () => throw Exception('Audit log entry not found: $id'),
    );
  }

  @override
  Future<AuditLogKpiSummary> getAuditLogKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final total = _mockLogs.length;
    final securityEvents = _mockLogs.where((l) => l.category == AuditActionCategory.security || l.category == AuditActionCategory.authentication).length;
    final adminActions = _mockLogs.where((l) => l.actorRole.contains('ADMIN') || l.actorRole.contains('MANAGER')).length;
    final failedOps = _mockLogs.where((l) => l.result == AuditResultStatus.failure || l.result == AuditResultStatus.warning).length;

    return AuditLogKpiSummary(
      totalLogs: total,
      securityEvents: securityEvents,
      adminActions: adminActions,
      failedOperations: failedOps,
    );
  }
}
