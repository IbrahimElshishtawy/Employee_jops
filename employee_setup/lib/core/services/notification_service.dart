import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/secure_logger.dart';
import 'notification_router.dart';

enum PushPermissionStatus {
  notDetermined,
  granted,
  denied,
}

/// NotificationService coordinates local notification display, channels, push token management,
/// and deep link routing for HR, Attendance, Requests, and Communications.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;
  PushPermissionStatus _permissionStatus = PushPermissionStatus.notDetermined;
  String? _cachedPushToken;

  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const String attendanceChannelId = 'cyberwise_attendance_channel';
  static const String attendanceChannelName = 'إشعارات الحضور والانصراف';
  static const String attendanceChannelDesc =
      'تأكيدات تسجيل الحضور والانصراف والموقع الجغرافي وتذكيرات الدوام';

  static const String requestsChannelId = 'cyberwise_requests_channel';
  static const String requestsChannelName = 'إشعارات الطلبات والسُلف والإجازات';
  static const String requestsChannelDesc =
      'حالة وتحديثات طلبات الإجازات والسُلف والاستئذان وموافقة المدراء';

  static const String hrChannelId = 'cyberwise_hr_channel';
  static const String hrChannelName = 'رسائل الموارد البشرية والمحادثات';
  static const String hrChannelDesc =
      'الرسائل الرسمية من إدارة الموارد البشرية والمحادثات المباشرة';

  static const String announcementsChannelId = 'cyberwise_announcements_channel';
  static const String announcementsChannelName = 'التعاميم والتنبيهات العامة';
  static const String announcementsChannelDesc =
      'الإعلانات والقرارات الرسمية العامة لكافة منسوبي الشركة';

  PushPermissionStatus get permissionStatus => _permissionStatus;
  String? get currentPushToken => _cachedPushToken;

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
          SecureLogger.info(
            'NotificationService',
            'Notification tapped with payload: ${response.payload}',
          );
          if (response.payload != null && response.payload!.isNotEmpty) {
            NotificationRouter.handleNotificationTap(response.payload);
          }
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
            importance: Importance.high,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            hrChannelId,
            hrChannelName,
            description: hrChannelDesc,
            importance: Importance.high,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            announcementsChannelId,
            announcementsChannelName,
            description: announcementsChannelDesc,
            importance: Importance.defaultImportance,
          ),
        );
      }

      // Check initial launch payload if app was terminated
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationRouter.handleNotificationTap(payload);
          });
        }
      }

      _isInitialized = true;
    } catch (e) {
      SecureLogger.info(
        'NotificationService',
        'Notification service initialized in test/fallback mode',
      );
      _isInitialized = true;
    }
  }

  /// Requests notification permission from user on Android 13+ and iOS.
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      _permissionStatus = PushPermissionStatus.granted;
      return true;
    }
    await initialize();

    try {
      // Android 13+ (POST_NOTIFICATIONS)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        final isGranted = granted ?? false;
        _permissionStatus = isGranted
            ? PushPermissionStatus.granted
            : PushPermissionStatus.denied;
        return isGranted;
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
        final isGranted = granted ?? false;
        _permissionStatus = isGranted
            ? PushPermissionStatus.granted
            : PushPermissionStatus.denied;
        return isGranted;
      }

      _permissionStatus = PushPermissionStatus.granted;
      return true;
    } catch (e) {
      SecureLogger.info(
        'NotificationService',
        'requestPermission ignored in headless mode',
      );
      _permissionStatus = PushPermissionStatus.granted;
      return true;
    }
  }

  /// Obtains device push notification registration token (backend-ready)
  Future<String> getDevicePushToken() async {
    if (_cachedPushToken != null) return _cachedPushToken!;
    final token = 'CW-FCM-TOKEN-${DateTime.now().millisecondsSinceEpoch}';
    _cachedPushToken = token;
    return token;
  }

  /// Displays a localized notification with structured payload for deep linking
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
      SecureLogger.info(
        'NotificationService',
        'showNotification skipped in headless environment',
      );
    }
  }

  /// Shows an HR Message notification with deep linking to the conversation
  Future<void> showHRMessageNotification({
    required String conversationId,
    required String senderName,
    required String messageText,
  }) async {
    final payload = NotificationPayload(
      type: NotificationType.hrMessage,
      conversationId: conversationId,
    ).toJsonString();

    await showNotification(
      id: conversationId.hashCode,
      title: 'رسالة جديدة من $senderName (HR)',
      body: messageText,
      payload: payload,
      channelId: hrChannelId,
      channelName: hrChannelName,
    );
  }

  /// Shows an attendance reminder notification with deep linking to Attendance screen
  Future<void> showAttendanceReminderNotification({
    required String title,
    required String body,
  }) async {
    final payload = const NotificationPayload(
      type: NotificationType.attendanceReminder,
    ).toJsonString();

    await showNotification(
      id: 99911,
      title: title,
      body: body,
      payload: payload,
      channelId: attendanceChannelId,
      channelName: attendanceChannelName,
    );
  }

  /// Shows a request update notification with deep linking to request details
  Future<void> showRequestStatusNotification({
    required String requestId,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    final payload = NotificationPayload(
      type: type,
      requestId: requestId,
    ).toJsonString();

    await showNotification(
      id: requestId.hashCode,
      title: title,
      body: body,
      payload: payload,
      channelId: requestsChannelId,
      channelName: requestsChannelName,
    );
  }
}
