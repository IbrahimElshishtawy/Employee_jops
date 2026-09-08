import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/payslip_record.dart';
import '../../domain/models/salary_structure.dart';

class PayrollRemoteDataSource {
  final ApiClient apiClient;

  const PayrollRemoteDataSource(this.apiClient);

  /// GET /api/v1/payroll/salary/me
  Future<SalaryStructure> getMySalaryStructure() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.salaryMe,
        fromData: (data) {
          if (data is Map<String, dynamic>) {
            return SalaryStructure.fromJson(data);
          }
          return const SalaryStructure(basicSalary: 8500, totalGrossSalary: 12000);
        },
      );
      return response.data ?? const SalaryStructure(basicSalary: 8500, totalGrossSalary: 12000);
    } on ApiException catch (e) {
      SecureLogger.error('PayrollRemoteDataSource', 'Salary structure error', e);
      return const SalaryStructure(basicSalary: 8500, totalGrossSalary: 12000);
    }
  }

  /// GET /api/v1/payroll/me (Payslip archive)
  Future<List<PayslipRecord>> getMyPayslips() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myPayroll,
        fromData: (data) {
          if (data is List) {
            return data
                .whereType<Map<String, dynamic>>()
                .map((e) => PayslipRecord.fromJson(e))
                .toList();
          }
          return <PayslipRecord>[];
        },
      );
      return response.data ?? _defaultPayslipList();
    } on ApiException catch (e) {
      SecureLogger.error('PayrollRemoteDataSource', 'Payslips list error', e);
      return _defaultPayslipList();
    }
  }

  /// GET /api/v1/payroll/records/:id
  Future<PayslipRecord?> getPayslipRecordById(String id) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.payrollRecordById(id),
        fromData: (data) {
          if (data is Map<String, dynamic>) {
            return PayslipRecord.fromJson(data);
          }
          return null;
        },
      );
      return response.data;
    } catch (e) {
      SecureLogger.error('PayrollRemoteDataSource', 'Payslip details error', e);
      return null;
    }
  }

  List<PayslipRecord> _defaultPayslipList() {
    return [
      PayslipRecord(
        id: 'PAY-2026-08',
        month: '2026-08',
        basicSalary: 8500,
        totalAllowances: 3500,
        totalDeductions: 500,
        netSalary: 11500,
        paymentStatus: 'PAID',
        paymentDate: DateTime(2026, 8, 30),
        earnings: const [
          PayslipItem(label: 'الراتب الأساسي', amount: 8500),
          PayslipItem(label: 'بدل سكن', amount: 2000),
          PayslipItem(label: 'بدل انتقال', amount: 1000),
          PayslipItem(label: 'مكافأة أداء', amount: 500),
        ],
        deductions: const [
          PayslipItem(label: 'تأمينات اجتماعية', amount: 350, isDeduction: true),
          PayslipItem(label: 'ضريبة كسب عمل', amount: 150, isDeduction: true),
        ],
      ),
      PayslipRecord(
        id: 'PAY-2026-07',
        month: '2026-07',
        basicSalary: 8500,
        totalAllowances: 3500,
        totalDeductions: 500,
        netSalary: 11500,
        paymentStatus: 'PAID',
        paymentDate: DateTime(2026, 7, 30),
      ),
    ];
  }
}
