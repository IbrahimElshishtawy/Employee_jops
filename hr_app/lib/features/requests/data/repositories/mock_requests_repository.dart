import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/hr_request_entity.dart';

/// Mock Requests Repository with safe test records & history audit logs
class MockRequestsRepository implements RequestsRepository {
  final List<HrRequestEntity> _mockRequests = [
    HrRequestEntity(
      id: 'TEST-REQ-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      department: 'Engineering',
      type: RequestType.leave,
      reason: 'Annual family holiday leave',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      status: RequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      history: [
        RequestHistoryEvent(
          id: 'HIST-001',
          action: 'SUBMITTED',
          actor: 'Alex Vance (Test)',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          comment: 'Submitted 4-day annual leave request via Mobile App',
        ),
      ],
    ),
    HrRequestEntity(
      id: 'TEST-REQ-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      department: 'Human Resources',
      type: RequestType.permission,
      reason: 'Medical consultation appointment',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      startTime: '10:00',
      endTime: '12:30',
      status: RequestStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedAt: DateTime.now().subtract(const Duration(hours: 12)),
      reviewedBy: 'HR Admin (Test)',
      reviewComment: 'Approved within monthly quota allowance',
      history: [
        RequestHistoryEvent(
          id: 'HIST-002',
          action: 'SUBMITTED',
          actor: 'Jordan Miller (Test)',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          comment: '2.5 hour personal medical permission requested',
        ),
        RequestHistoryEvent(
          id: 'HIST-003',
          action: 'APPROVED',
          actor: 'HR Admin (Test)',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          comment: 'Approved within monthly quota allowance',
        ),
      ],
    ),
    HrRequestEntity(
      id: 'TEST-REQ-003',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      department: 'Operations',
      type: RequestType.late,
      reason: 'Severe traffic congestion on main arterial highway',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      startTime: '09:00',
      endTime: '09:45',
      status: RequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      history: [
        RequestHistoryEvent(
          id: 'HIST-004',
          action: 'SUBMITTED',
          actor: 'Taylor Morgan (Test)',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          comment: 'Submitted 45m late arrival justification',
        ),
      ],
    ),
    HrRequestEntity(
      id: 'TEST-REQ-004',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      department: 'Finance',
      type: RequestType.halfDay,
      reason: 'Personal urgent requirement and bank paperwork',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 1)),
      status: RequestStatus.rejected,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedBy: 'HR Admin (Test)',
      reviewComment: 'Insufficient notice period for critical quarterly closing cycle',
      history: [
        RequestHistoryEvent(
          id: 'HIST-005',
          action: 'SUBMITTED',
          actor: 'Samira Khan (Test)',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          comment: 'Half-day leave requested',
        ),
        RequestHistoryEvent(
          id: 'HIST-006',
          action: 'REJECTED',
          actor: 'HR Admin (Test)',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          comment: 'Insufficient notice period for critical quarterly closing cycle',
        ),
      ],
    ),
    HrRequestEntity(
      id: 'TEST-REQ-005',
      employeeId: 'TEST-EMP-005',
      employeeName: 'Casey Davis (Test)',
      employeeCode: 'CW-005',
      department: 'Marketing',
      type: RequestType.absence,
      reason: 'Emergency home plumbing repairs',
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().subtract(const Duration(days: 3)),
      status: RequestStatus.cancelled,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      reviewedAt: null,
      reviewComment: 'Employee self-cancelled request prior to HR review',
      history: [
        RequestHistoryEvent(
          id: 'HIST-007',
          action: 'SUBMITTED',
          actor: 'Casey Davis (Test)',
          timestamp: DateTime.now().subtract(const Duration(days: 4)),
          comment: 'Absence justification submitted',
        ),
        RequestHistoryEvent(
          id: 'HIST-008',
          action: 'CANCELLED',
          actor: 'Casey Davis (Test)',
          timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 20)),
          comment: 'Employee self-cancelled request prior to HR review',
        ),
      ],
    ),
  ];

  @override
  Future<PaginatedList<HrRequestEntity>> getRequests(RequestFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var results = List<HrRequestEntity>.from(_mockRequests);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      results = results.where((r) =>
          r.employeeName.toLowerCase().contains(q) ||
          r.employeeCode.toLowerCase().contains(q) ||
          (r.department?.toLowerCase().contains(q) ?? false) ||
          r.reason.toLowerCase().contains(q)).toList();
    }

    if (filter.type != null) {
      results = results.where((r) => r.type == filter.type).toList();
    }

    if (filter.status != null) {
      results = results.where((r) => r.status == filter.status).toList();
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      results = results.where((r) => r.department?.toLowerCase() == filter.department!.toLowerCase()).toList();
    }

    if (filter.startDate != null) {
      results = results.where((r) => r.startDate.isAfter(filter.startDate!.subtract(const Duration(seconds: 1)))).toList();
    }

    if (filter.endDate != null) {
      results = results.where((r) => r.endDate.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<HrRequestEntity>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<HrRequestEntity> getRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockRequests.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Request not found with ID: $id'),
    );
  }

  @override
  Future<RequestKpiSummary> getRequestKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return RequestKpiSummary(
      totalCount: _mockRequests.length,
      pendingCount: _mockRequests.where((r) => r.status == RequestStatus.pending).length,
      approvedCount: _mockRequests.where((r) => r.status == RequestStatus.approved).length,
      rejectedCount: _mockRequests.where((r) => r.status == RequestStatus.rejected).length,
      cancelledCount: _mockRequests.where((r) => r.status == RequestStatus.cancelled).length,
    );
  }

  @override
  Future<void> reviewRequest(String id, {required bool approve, String? comment}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final existing = _mockRequests[index];
      final newStatus = approve ? RequestStatus.approved : RequestStatus.rejected;
      final event = RequestHistoryEvent(
        id: 'HIST-${DateTime.now().millisecondsSinceEpoch}',
        action: approve ? 'APPROVED' : 'REJECTED',
        actor: 'HR Admin (Test)',
        timestamp: DateTime.now(),
        comment: comment,
      );

      _mockRequests[index] = existing.copyWith(
        status: newStatus,
        reviewedAt: DateTime.now(),
        reviewedBy: 'HR Admin (Test)',
        reviewComment: comment,
        history: [...existing.history, event],
      );
    }
  }
}
