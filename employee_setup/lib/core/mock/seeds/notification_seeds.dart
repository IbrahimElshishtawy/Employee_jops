import '../../../features/notifications/domain/models/app_notification.dart';
import '../seeds/employee_seed.dart';

class NotificationSeeds {
  static const String _empId = EmployeeSeed.id;

  static List<AppNotification> get notifications => [
        AppNotification(
          id: 'NOTIF-001',
          title: 'تمت الموافقة على طلب الإجازة',
          message: 'تمت الموافقة على طلب إجازتك السنوية من 20 أغسطس إلى 21 أغسطس 2026.',
          category: NotificationCategory.requestUpdate,
          createdAt: DateTime(2026, 8, 16, 18, 30),
          isRead: false,
          relatedEntityId: 'VAC-001',
          actionRoute: '/requests/vacations/VAC-001',
        ),
        AppNotification(
          id: 'NOTIF-002',
          title: 'رسالة جديدة من HR',
          message: 'يرجى مراجعة قسم الموارد البشرية بخصوص ملف الحضور لشهر أغسطس.',
          category: NotificationCategory.hrMessage,
          createdAt: DateTime(2026, 8, 17, 10, 0),
          isRead: false,
          relatedEntityId: 'MSG-001',
          actionRoute: '/notifications/NOTIF-002',
        ),
        AppNotification(
          id: 'NOTIF-003',
          title: 'تم تسجيل خصم بقيمة 250 جنيه',
          message: 'تم تطبيق خصم بقيمة 250 جنيه مصري على راتبك بسبب التأخير في 15 أغسطس.',
          category: NotificationCategory.deduction,
          createdAt: DateTime(2026, 8, 16, 12, 0),
          isRead: true,
          relatedEntityId: 'DED-001',
          actionRoute: '/notifications/NOTIF-003',
        ),
        AppNotification(
          id: 'NOTIF-004',
          title: 'تم قبول طلب السُلفة',
          message: 'تمت الموافقة على طلب السُلفة رقم ADV-103 بمبلغ 1500 جنيه مصري.',
          category: NotificationCategory.advance,
          createdAt: DateTime(2026, 8, 16, 9, 0),
          isRead: true,
          relatedEntityId: 'ADV-103',
          actionRoute: '/requests/advances/ADV-103',
        ),
      ];
}
