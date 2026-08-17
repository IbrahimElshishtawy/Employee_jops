import '../models/hr_message.dart';
import '../seeds/employee_seed.dart';

class HRMessageSeeds {
  static const String _empId = EmployeeSeed.id;

  static List<HRMessage> get messages => [
        HRMessage(
          id: 'MSG-001',
          employeeId: _empId,
          title: 'مراجعة سجل الحضور',
          message:
              'يرجى التواصل مع قسم الموارد البشرية لمراجعة سجل حضورك لشهر أغسطس 2026، '
              'وذلك في أقرب وقت ممكن خلال أوقات الدوام الرسمي.',
          senderName: 'Ahmed Mohamed — HR Manager',
          createdAt: DateTime(2026, 8, 17, 10, 0),
          status: HRMessageStatus.unread,
          priority: HRMessagePriority.normal,
        ),
        HRMessage(
          id: 'MSG-002',
          employeeId: _empId,
          title: 'تذكير: تسليم تقرير المصروفات',
          message:
              'يرجى تسليم تقرير المصروفات الخاص بسُلفة ADV-102 في موعد أقصاه 20 أغسطس 2026.',
          senderName: 'Sara Ali — Finance Department',
          createdAt: DateTime(2026, 8, 13, 14, 0),
          status: HRMessageStatus.read,
          priority: HRMessagePriority.high,
          actionRoute: '/requests/advances/ADV-102',
        ),
      ];
}
