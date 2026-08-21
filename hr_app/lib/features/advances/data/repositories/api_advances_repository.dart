import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/advance_entity.dart';

/// Live Production Advances Repository
class ApiAdvancesRepository implements AdvancesRepository {
  final ApiClient _apiClient;

  ApiAdvancesRepository(this._apiClient);

  @override
  Future<PaginatedList<AdvanceEntity>> getAdvances(AdvanceFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.status != null) queryParams['status'] = filter.status!.key;
      if (filter.department != null) queryParams['department'] = filter.department!;
      if (filter.startDate != null) queryParams['startDate'] = filter.startDate!.toIso8601String();
      if (filter.endDate != null) queryParams['endDate'] = filter.endDate!.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.advances,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapAdvance(e as Map<String, dynamic>)).toList();

          return PaginatedList<AdvanceEntity>(
            items: items,
            totalCount: json['totalCount'] as int? ?? items.length,
            page: json['page'] as int? ?? filter.page,
            pageSize: json['pageSize'] as int? ?? filter.pageSize,
            totalPages: json['totalPages'] as int? ?? 1,
          );
        },
      );

      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AdvanceEntity> getAdvanceById(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.advances}/$id',
        parser: (data) => _mapAdvance(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AdvanceKpiSummary> getAdvanceKpis() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.advances}/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return AdvanceKpiSummary(
            totalCount: json['totalCount'] as int? ?? 0,
            pendingCount: json['pendingCount'] as int? ?? 0,
            approvedCount: json['approvedCount'] as int? ?? 0,
            rejectedCount: json['rejectedCount'] as int? ?? 0,
            totalRequestedAmount: (json['totalRequestedAmount'] as num?)?.toDouble() ?? 0.0,
            totalApprovedAmount: (json['totalApprovedAmount'] as num?)?.toDouble() ?? 0.0,
            outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
            monthlyDeductionTotal: (json['monthlyDeductionTotal'] as num?)?.toDouble() ?? 0.0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> approveAdvance(
    String id, {
    required double approvedAmount,
    int? installmentCount,
    String? notes,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.advanceReview(id),
        body: {
          'status': 'APPROVED',
          'approvedAmount': approvedAmount,
          'installmentCount': ?installmentCount,
          'notes': ?notes,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> rejectAdvance(String id, {required String reason}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.advanceReview(id),
        body: {
          'status': 'REJECTED',
          'reason': reason,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static AdvanceEntity _mapAdvance(Map<String, dynamic> map) {
    final rawInst = (map['installments'] as List<dynamic>?) ?? [];
    final installments = rawInst.map((i) {
      final im = i as Map<String, dynamic>;
      return AdvanceInstallment(
        installmentNumber: im['installmentNumber'] as int? ?? 1,
        dueDate: DateTime.parse(im['dueDate'] as String),
        amount: (im['amount'] as num?)?.toDouble() ?? 0.0,
        status: InstallmentStatus.fromKey(im['status'] as String?),
        paidDate: im['paidDate'] != null ? DateTime.parse(im['paidDate'] as String) : null,
        remainingBalance: (im['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final rawDed = (map['deductions'] as List<dynamic>?) ?? [];
    final deductions = rawDed.map((d) {
      final dm = d as Map<String, dynamic>;
      return AdvanceDeduction(
        id: dm['id'] as String? ?? 'DED-${DateTime.now().millisecond}',
        payrollPeriod: dm['payrollPeriod'] as String? ?? 'Monthly Payroll',
        deductionDate: DateTime.parse(dm['deductionDate'] as String),
        amount: (dm['amount'] as num?)?.toDouble() ?? 0.0,
        status: dm['status'] as String? ?? 'DEDUCTED',
        remainingBalance: (dm['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return AdvanceEntity(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String? ?? '',
      employeeCode: map['employeeCode'] as String? ?? '',
      department: map['department'] as String?,
      currentSalary: (map['currentSalary'] as num?)?.toDouble(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      approvedAmount: (map['approvedAmount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      reason: map['reason'] as String? ?? '',
      status: AdvanceStatus.fromKey(map['status'] as String?),
      requestedAt: DateTime.parse(map['requestedAt'] as String),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
      reviewedBy: map['reviewedBy'] as String?,
      notes: map['notes'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      installmentCount: map['installmentCount'] as int? ?? 1,
      installmentAmount: (map['installmentAmount'] as num?)?.toDouble(),
      paidInstallmentCount: map['paidInstallmentCount'] as int? ?? 0,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      installments: installments,
      deductions: deductions,
    );
  }
}
