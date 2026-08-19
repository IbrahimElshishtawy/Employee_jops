import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService coordinates local notification display, channels, and platform permissions.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const String attendanceChannelId = 'cyberwise_attendance_channel';
  static const String attendanceChannelName = 'إشعارات الحضور والانصراف';
  static const String attendanceChannelDesc =
      'تأكيدات تسجيل الحضور والانصراف والموقع الجغرافي';

  static const String requestsChannelId = 'cyberwise_requests_channel';
  static const String requestsChannelName = 'إشعارات الطلبات والسُلف والإجازات';
  static const String requestsChannelDesc =
      'حالة وتحديثات طلبات الإجازات والسُلف والاستئذان';

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
              '[NotificationService] Notification clicked payload: ${response.payload}');
        },
      );

      // Create Android Notification Channels
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            attendanceChannelId,
            attendanceChannelName,
            description: attendanceChannelDesc,
            importance: Importance.high,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            requestsChannelId,
            requestsChannelName,
            description: requestsChannelDesc,
            importance: Importance.defaultImportance,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] initialize error: $e');
    }
  }

  /// Requests notification permission from user on Android 13+ and iOS.
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    await initialize();

    try {
      // Android 13+ (POST_NOTIFICATIONS)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
      return false;
    }
  }

  /// Displays an immediate local notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = attendanceChannelId,
    String channelName = attendanceChannelName,
  }) async {
    if (kIsWeb) return;
    await initialize();

    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: attendanceChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNotification error: $e');
    }
  }
}
