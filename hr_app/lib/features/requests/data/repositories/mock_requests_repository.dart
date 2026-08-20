import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/hr_request_entity.dart';

/// Mock Requests Repository with safe test records
class MockRequestsRepository implements RequestsRepository {
  final List<HrRequestEntity> _mockRequests = [
    HrRequestEntity(
      id: 'TEST-REQ-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      type: RequestType.leave,
      reason: 'Annual family holiday leave',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      status: RequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    HrRequestEntity(
      id: 'TEST-REQ-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      type: RequestType.permission,
      reason: 'Medical appointment',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      status: RequestStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedAt: DateTime.now().subtract(const Duration(hours: 12)),
      reviewedBy: 'HR Admin (Test)',
      reviewComment: 'Approved as per allowance',
    ),
    HrRequestEntity(
      id: 'TEST-REQ-003',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      type: RequestType.late,
      reason: 'Traffic congestion on main highway',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      status: RequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    HrRequestEntity(
      id: 'TEST-REQ-004',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      type: RequestType.halfDay,
      reason: 'Personal urgent requirement',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 1)),
      status: RequestStatus.rejected,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedBy: 'HR Admin (Test)',
      reviewComment: 'Insufficient notice period',
    ),
  ];

  @override
  Future<PaginatedList<HrRequestEntity>> getRequests(RequestFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var results = List<HrRequestEntity>.from(_mockRequests);

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      results = results.where((r) =>
          r.employeeName.toLowerCase().contains(q) ||
          r.employeeCode.toLowerCase().contains(q) ||
          r.reason.toLowerCase().contains(q)).toList();
    }

    if (filter.type != null) {
      results = results.where((r) => r.type == filter.type).toList();
    }

    if (filter.status != null) {
      results = results.where((r) => r.status == filter.status).toList();
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
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockRequests.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> reviewRequest(String id, {required bool approve, String? comment}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final existing = _mockRequests[index];
      _mockRequests[index] = HrRequestEntity(
        id: existing.id,
        employeeId: existing.employeeId,
        employeeName: existing.employeeName,
        employeeCode: existing.employeeCode,
        type: existing.type,
        reason: existing.reason,
        startDate: existing.startDate,
        endDate: existing.endDate,
        status: approve ? RequestStatus.approved : RequestStatus.rejected,
        createdAt: existing.createdAt,
        reviewedAt: DateTime.now(),
        reviewedBy: 'HR Admin (Test)',
        reviewComment: comment,
      );
    }
  }
}
