import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mock/mock_database.dart';
import '../../mock/models/deduction.dart';
import 'deduction_repository.dart';

class MockDeductionRepository implements DeductionRepository {
  final Ref _ref;
  MockDeductionRepository(this._ref);

  MockDatabaseNotifier get _db => _ref.read(mockDatabaseProvider.notifier);
  MockDatabase get _state => _ref.read(mockDatabaseProvider);

  @override
  Future<List<Deduction>> getDeductions(String employeeId) async {
    return _state.deductions.where((d) => d.employeeId == employeeId).toList();
  }

  @override
  Future<Deduction?> getDeductionById(String id) async {
    try {
      return _state.deductions.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
