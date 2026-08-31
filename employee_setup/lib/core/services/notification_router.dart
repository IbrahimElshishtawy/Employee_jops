import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_routes.dart';
import '../utils/secure_logger.dart';

/// Centralized Notification Types
enum NotificationType {
  hrMessage,
  hrAnnouncement,
  communicationMessage,
  departmentRequest,
  requestAccepted,
  requestRejected,
  requestCompleted,
  attendanceReminder,
  systemAlert,
  unknown;

  static NotificationType fromString(String? typeStr) {
    if (typeStr == null) return NotificationType.unknown;
    switch (typeStr.toUpperCase()) {
      case 'HR_MESSAGE':
        return NotificationType.hrMessage;
      case 'HR_ANNOUNCEMENT':
        return NotificationType.hrAnnouncement;
      case 'COMMUNICATION_MESSAGE':
        return NotificationType.communicationMessage;
      case 'DEPARTMENT_REQUEST':
        return NotificationType.departmentRequest;
      case 'REQUEST_ACCEPTED':
        return NotificationType.requestAccepted;
      case 'REQUEST_REJECTED':
        return NotificationType.requestRejected;
      case 'REQUEST_COMPLETED':
        return NotificationType.requestCompleted;
      case 'ATTENDANCE_REMINDER':
        return NotificationType.attendanceReminder;
      case 'SYSTEM_ALERT':
        return NotificationType.systemAlert;
      default:
        return NotificationType.unknown;
    }
  }

  String get typeCode => name.toUpperCase();
}

/// Standardized notification payload structure
class NotificationPayload {
  final NotificationType type;
  final String? targetId;
  final String? conversationId;
  final String? requestId;
  final String? actionRoute;
  final Map<String, dynamic> extraData;

  const NotificationPayload({
    required this.type,
    this.targetId,
    this.conversationId,
    this.requestId,
    this.actionRoute,
    this.extraData = const {},
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: NotificationType.fromString(json['type'] as String?),
      targetId: json['targetId'] as String?,
      conversationId: json['conversationId'] as String?,
      requestId: json['requestId'] as String?,
      actionRoute: json['actionRoute'] as String?,
      extraData: (json['extraData'] as Map<String, dynamic>?) ?? {},
    );
  }

  factory NotificationPayload.fromRawPayload(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const NotificationPayload(type: NotificationType.unknown);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return NotificationPayload.fromJson(decoded);
      }
    } catch (_) {
      // If raw is simple route string
      if (raw.startsWith('/')) {
        return NotificationPayload(
          type: NotificationType.unknown,
          actionRoute: raw,
        );
      }
    }
    return const NotificationPayload(type: NotificationType.unknown);
  }

  String toJsonString() => jsonEncode({
        'type': type.typeCode,
        'targetId': targetId,
        'conversationId': conversationId,
        'requestId': requestId,
        'actionRoute': actionRoute,
        'extraData': extraData,
      });

  /// Computes target route with validation to avoid trusting payloads blindly
  String getResolvedRoute() {
    if (actionRoute != null && actionRoute!.isNotEmpty && actionRoute!.startsWith('/')) {
      return actionRoute!;
    }

    switch (type) {
      case NotificationType.hrMessage:
      case NotificationType.communicationMessage:
        if (conversationId != null && conversationId!.isNotEmpty) {
          final cleanId = Uri.encodeComponent(conversationId!);
          return '/communication/chat/$cleanId';
        }
        return AppRoutes.conversations;

      case NotificationType.departmentRequest:
      case NotificationType.requestAccepted:
      case NotificationType.requestRejected:
      case NotificationType.requestCompleted:
        if (requestId != null && requestId!.isNotEmpty) {
          final cleanId = Uri.encodeComponent(requestId!);
          if (requestId!.startsWith('VAC-')) return AppRoutes.vacations;
          if (requestId!.startsWith('PERM-')) return AppRoutes.permissions;
          if (requestId!.startsWith('ADV-')) return AppRoutes.advances;
          return '/communication/request/$cleanId';
        }
        return AppRoutes.myDepartmentRequests;

      case NotificationType.attendanceReminder:
        return AppRoutes.attendance;

      case NotificationType.hrAnnouncement:
      case NotificationType.systemAlert:
      case NotificationType.unknown:
        if (targetId != null && targetId!.isNotEmpty) {
          final cleanId = Uri.encodeComponent(targetId!);
          return '/notifications/$cleanId';
        }
        return AppRoutes.notifications;
    }
  }
}

/// Centralized deep linking & notification router
class NotificationRouter {
  static GlobalKey<NavigatorState>? rootNavigatorKey;

  static void handleNotificationTap(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return;

    try {
      final payload = NotificationPayload.fromRawPayload(rawPayload);
      final route = payload.getResolvedRoute();

      SecureLogger.info('NotificationRouter', 'Dispatching notification navigation to: $route');

      final context = rootNavigatorKey?.currentContext;
      if (context != null && context.mounted) {
        context.push(route);
      }
    } catch (e) {
      SecureLogger.error('NotificationRouter', 'Failed to navigate from notification payload', e);
    }
  }
}
