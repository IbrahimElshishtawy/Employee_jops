import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  final LocalStorage storage;
  final Uuid _uuid = const Uuid();
  final List<AppNotification> _notifications = [];

  MockNotificationsRepository(this.storage) {
    _initMockData();
  }

  void _initMockData() {
    _notifications.clear();
    final now = DateTime.now();

    _notifications.addAll([
      AppNotification(
        id: 'notif-001',
        title: 'تمت الموافقة على طلب الإجازة',
        message: 'تمت الموافقة على طلب إجازتك السنوية القادمة من قبل الإدارة المباشرة وقسم الموارد البشرية.',
        category: NotificationCategory.requestUpdate,
        createdAt: now.subtract(const Duration(minutes: 25)),
        isRead: false,
        actionRoute: '/requests/vacations',
      ),
      AppNotification(
        id: 'notif-002',
        title: 'لديك رسالة جديدة من HR',
        message: 'يرجى مراجعة وتحديث نموذج التأمين الصحي السنوي قبل نهاية الأسبوع الحالي.',
        category: NotificationCategory.hrMessage,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-003',
        title: 'تم قبول طلب السُلفة المالية',
        message: 'تمت الموافقة على طلب السُلفة بقيمة 1,500 ج.م وجاري تحويل المبلغ إلى حسابك البنكي.',
        category: NotificationCategory.advance,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
        actionRoute: '/requests/advances',
      ),
      AppNotification(
        id: 'notif-004',
        title: 'إشعار كشف الراتب والخصومات',
        message: 'تم تسجيل خصم بقيمة 250 جنيه بسبب تأخير غير مبرر يوم الثلاثاء الماضي.',
        category: NotificationCategory.deduction,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-005',
        title: 'تأكيد تسجيل الحضور الذاتي',
        message: 'تم تسجيل حضورك بنجاح بالأمس الساعة 08:45 ص داخل النطاق الجغرافي للشركة.',
        category: NotificationCategory.attendance,
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-006',
        title: 'تحديث نظام وأمان التطبيق',
        message: 'تم تفعيل التحديث رقم 1.0.0 لدعم المصادقة البيومترية السريعة والعمل دون اتصال.',
        category: NotificationCategory.system,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);

    // Apply read IDs from storage if any
    final readIds = storage.getStringList(AppConstants.keyReadNotifications) ?? [];
    for (int i = 0; i < _notifications.length; i++) {
      if (readIds.contains(_notifications[i].id)) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  Future<void> _persistReadIds() async {
    final readIds = _notifications.where((n) => n.isRead).map((n) => n.id).toList();
    await storage.setStringList(AppConstants.keyReadNotifications, readIds);
  }

  @override
  Future<List<AppNotification>> getNotifications(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_notifications);
  }

  @override
  Future<int> getUnreadCount(String employeeId) async {
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _persistReadIds();
    }
  }

  @override
  Future<void> markAllAsRead(String employeeId) async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _persistReadIds();
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
  }

  @override
  Future<void> resetToDefaultMock() async {
    await storage.remove(AppConstants.keyReadNotifications);
    _initMockData();
  }
}
