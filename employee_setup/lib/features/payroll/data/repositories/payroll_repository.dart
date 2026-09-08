import '../../domain/models/payslip_record.dart';
import '../../domain/models/salary_structure.dart';
import '../datasources/payroll_remote_data_source.dart';

abstract class PayrollRepository {
  Future<SalaryStructure> getSalaryStructure();
  Future<List<PayslipRecord>> getPayslips();
  Future<PayslipRecord?> getPayslipDetails(String id);
}

class RealPayrollRepository implements PayrollRepository {
  final PayrollRemoteDataSource remoteDataSource;

  const RealPayrollRepository(this.remoteDataSource);

  @override
  Future<SalaryStructure> getSalaryStructure() => remoteDataSource.getMySalaryStructure();

  @override
  Future<List<PayslipRecord>> getPayslips() => remoteDataSource.getMyPayslips();

  @override
  Future<PayslipRecord?> getPayslipDetails(String id) =>
      remoteDataSource.getPayslipRecordById(id);
}
