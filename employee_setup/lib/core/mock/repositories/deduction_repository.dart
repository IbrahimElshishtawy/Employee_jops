import '../../mock/models/deduction.dart';

abstract class DeductionRepository {
  Future<List<Deduction>> getDeductions(String employeeId);
  Future<Deduction?> getDeductionById(String id);
}
