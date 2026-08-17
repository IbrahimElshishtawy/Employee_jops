import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mock/mock_database.dart';
import '../../mock/models/hr_message.dart';
import 'hr_message_repository.dart';

class MockHRMessageRepository implements HRMessageRepository {
  final Ref _ref;
  MockHRMessageRepository(this._ref);

  MockDatabaseNotifier get _db => _ref.read(mockDatabaseProvider.notifier);
  MockDatabase get _state => _ref.read(mockDatabaseProvider);

  @override
  Future<List<HRMessage>> getMessages(String employeeId) async {
    return _state.hrMessages.where((m) => m.employeeId == employeeId).toList();
  }

  @override
  Future<HRMessage?> getMessageById(String id) async {
    try {
      return _state.hrMessages.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    _db.markHRMessageRead(id);
  }
}
