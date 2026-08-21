import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/deduction_entity.dart';

/// Live Production Deductions Repository
class ApiDeductionsRepository implements DeductionsRepository {
  final ApiClient _apiClient;

  ApiDeductionsRepository(this._apiClient);

  @override
  Future<PaginatedList<DeductionEntity>> getDeductions(DeductionFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.type != null) queryParams['type'] = filter.type!.key;
      if (filter.status != null) queryParams['status'] = filter.status!.key;
      if (filter.department != null) queryParams['department'] = filter.department!;
      if (filter.payrollPeriod != null) queryParams['payrollPeriod'] = filter.payrollPeriod!;
      if (filter.startDate != null) queryParams['startDate'] = filter.startDate!.toIso8601String();
      if (filter.endDate != null) queryParams['endDate'] = filter.endDate!.toIso8601String();

      final response = await _apiClient.get(
        '/api/v1/payroll/deductions',
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapDeduction(e as Map<String, dynamic>)).toList();

          return PaginatedList<DeductionEntity>(
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
  Future<DeductionEntity> getDeductionById(String id) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/payroll/deductions/$id',
        parser: (data) => _mapDeduction(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<DeductionKpiSummary> getDeductionKpis() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/payroll/deductions/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return DeductionKpiSummary(
            totalCount: json['totalCount'] as int? ?? 0,
            totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
            scheduledCount: json['scheduledCount'] as int? ?? 0,
            scheduledAmount: (json['scheduledAmount'] as num?)?.toDouble() ?? 0.0,
            appliedCount: json['appliedCount'] as int? ?? 0,
            appliedAmount: (json['appliedAmount'] as num?)?.toDouble() ?? 0.0,
            advanceDeductionTotal: (json['advanceDeductionTotal'] as num?)?.toDouble() ?? 0.0,
            attendanceDeductionTotal: (json['attendanceDeductionTotal'] as num?)?.toDouble() ?? 0.0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<DeductionEntity> createDeduction(DeductionEntity deduction) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/payroll/deductions',
        body: {
          'employeeId': deduction.employeeId,
          'type': deduction.type.key,
          'amount': deduction.amount,
          'currency': deduction.currency,
          'payrollPeriod': deduction.payrollPeriod,
          'reason': deduction.reason,
          'date': deduction.date.toIso8601String(),
        },
        parser: (data) => _mapDeduction(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> cancelDeduction(String id, {required String reason}) async {
    try {
      await _apiClient.post(
        '/api/v1/payroll/deductions/$id/cancel',
        body: {
          'reason': reason,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static DeductionEntity _mapDeduction(Map<String, dynamic> map) {
    return DeductionEntity(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String? ?? '',
      employeeCode: map['employeeCode'] as String? ?? '',
      department: map['department'] as String?,
      type: DeductionType.fromKey(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      status: DeductionStatus.fromKey(map['status'] as String?),
      payrollPeriod: map['payrollPeriod'] as String? ?? 'Monthly Payroll',
      reason: map['reason'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      appliedDate: map['appliedDate'] != null ? DateTime.parse(map['appliedDate'] as String) : null,
      createdBy: map['createdBy'] as String? ?? 'System',
      approvedBy: map['approvedBy'] as String?,
      relatedAdvanceId: map['relatedAdvanceId'] as String?,
      installmentNumber: map['installmentNumber'] as int?,
      totalInstallments: map['totalInstallments'] as int?,
      remainingBalance: (map['remainingBalance'] as num?)?.toDouble(),
      cancellationReason: map['cancellationReason'] as String?,
    );
  }
}
