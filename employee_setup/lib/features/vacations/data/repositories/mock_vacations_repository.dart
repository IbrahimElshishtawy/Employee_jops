import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/vacation_request.dart';
import '../../domain/repositories/vacations_repository.dart';

class MockVacationsRepository implements VacationsRepository {
  final Uuid _uuid = const Uuid();
  final List<VacationRequest> _vacations = [];

  MockVacationsRepository() {
    _initMockData();
  }

  void _initMockData() {
    _vacations.clear();
    final now = DateTime.now();

    _vacations.addAll([
      VacationRequest(
        id: 'vac-001',
        employeeId: AppConstants.mockEmployeeId,
        type: VacationType.annual,
        fromDate: now.add(const Duration(days: 10)),
        toDate: now.add(const Duration(days: 14)),
        daysCount: 5,
        reason: 'إجازة صيفية سنوية مع العائلة',
        status: VacationStatus.approved,
        createdAt: now.subtract(const Duration(days: 5)),
        approvedAt: now.subtract(const Duration(days: 3)),
      ),
      VacationRequest(
        id: 'vac-002',
        employeeId: AppConstants.mockEmployeeId,
        type: VacationType.sick,
        fromDate: now.subtract(const Duration(days: 20)),
        toDate: now.subtract(const Duration(days: 19)),
        daysCount: 2,
        reason: 'وعكة صحية طارئة والراحة بتوصية الطبيب',
        status: VacationStatus.approved,
        createdAt: now.subtract(const Duration(days: 21)),
        approvedAt: now.subtract(const Duration(days: 20)),
        attachmentName: 'medical_report.pdf',
      ),
      VacationRequest(
        id: 'vac-003',
        employeeId: AppConstants.mockEmployeeId,
        type: VacationType.casual,
        fromDate: now.add(const Duration(days: 25)),
        toDate: now.add(const Duration(days: 25)),
        daysCount: 1,
        reason: 'ظرف شخصي عاجل',
        status: VacationStatus.pending,
        createdAt: now,
      ),
    ]);
  }

  @override
  Future<List<VacationRequest>> getVacations(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_vacations);
  }

  @override
  Future<VacationRequest?> getVacationById(String id) async {
    try {
      return _vacations.firstWhere((element) => element.id == id);
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
    await Future.delayed(const Duration(milliseconds: 350));

    final newVacation = VacationRequest(
      id: 'vac-${_uuid.v4().substring(0, 6)}',
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

    _vacations.insert(0, newVacation);
    return newVacation;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _initMockData();
  }
}
