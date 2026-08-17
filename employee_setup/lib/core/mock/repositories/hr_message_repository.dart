import '../../mock/models/hr_message.dart';

abstract class HRMessageRepository {
  Future<List<HRMessage>> getMessages(String employeeId);
  Future<HRMessage?> getMessageById(String id);
  Future<void> markAsRead(String id);
}
