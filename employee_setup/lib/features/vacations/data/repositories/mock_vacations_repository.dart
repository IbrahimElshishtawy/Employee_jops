import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/models/vacation_request.dart';
import '../../domain/repositories/vacations_repository.dart';

class MockVacationsRepository implements VacationsRepository {
  final Ref? _ref;
  final _uuid = const Uuid();

  MockVacationsRepository([Ref? ref]) : _ref = ref;

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;
  MockDatabase get _state =>
      _ref?.read(mockDatabaseProvider) ?? fallbackMockDatabaseNotifier.state;

  @override
  Future<List<VacationRequest>> getVacations(String employeeId) async {
    return _state.vacations.where((v) => v.employeeId == employeeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<VacationRequest?> getVacationById(String id) async {
    try {
      return _state.vacations.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<VacationRequest> createVacation({
    required String employeeId,
    required VacationType type,
    required DateTime fromDate,
    required DateTime toDate,
    required int daysCount,
    required String reason,
    String? attachmentName,
  }) async {
    final vac = VacationRequest(
      id: 'VAC-${_uuid.v4().substring(0, 6).toUpperCase()}',
      employeeId: employeeId,
      type: type,
      fromDate: fromDate,
      toDate: toDate,
      daysCount: daysCount,
      reason: reason,
      status: VacationStatus.pending,
      createdAt: DateTime.now(),
      attachmentName: attachmentName,
    );
    _db.addVacation(vac);
    return vac;
  }

  @override
  Future<void> resetToDefaultMock() async {
    // Handled by MockDatabaseNotifier.resetDataKeepSession()
  }
}
