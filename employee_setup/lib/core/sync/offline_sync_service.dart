import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../storage/local_storage.dart';
import '../utils/secure_logger.dart';

class SyncActionItem {
  final String id;
  final String actionType; // PUNCH_CHECK_IN, PUNCH_CHECK_OUT, TASK_STATUS, TASK_CHECKLIST
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncActionItem({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionType': actionType,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncActionItem.fromJson(Map<String, dynamic> json) => SyncActionItem(
        id: json['id'] as String? ?? const Uuid().v4(),
        actionType: json['actionType'] as String? ?? 'UNKNOWN',
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

class OfflineSyncService {
  final ApiClient apiClient;
  final LocalStorage storage;
  static const String _queueKey = 'offline_sync_action_queue';
  final Uuid _uuid = const Uuid();

  OfflineSyncService({
    required this.apiClient,
    required this.storage,
  });

  /// Adds an action to the persistent offline queue
  Future<void> enqueueAction(String actionType, Map<String, dynamic> payload) async {
    final item = SyncActionItem(
      id: _uuid.v4(),
      actionType: actionType,
      payload: payload,
      createdAt: DateTime.now(),
    );

    final queue = await getPendingQueue();
    queue.add(item);
    await _saveQueue(queue);
    SecureLogger.info('OfflineSyncService', 'Enqueued offline action: $actionType (ID: ${item.id})');
  }

  /// Retrieves all pending items in the offline queue
  Future<List<SyncActionItem>> getPendingQueue() async {
    final jsonStr = storage.getString(_queueKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => SyncActionItem.fromJson(e))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  /// Sends all pending items in batch to POST /api/v1/sync/batch
  Future<int> flushQueue() async {
    final queue = await getPendingQueue();
    if (queue.isEmpty) return 0;

    SecureLogger.info('OfflineSyncService', 'Flushing ${queue.length} pending offline actions');

    try {
      final batchData = queue.map((item) => item.toJson()).toList();
      final response = await apiClient.post(
        ApiEndpoints.syncBatch,
        data: {'actions': batchData},
      );

      if (response.success) {
        await storage.remove(_queueKey);
        SecureLogger.info('OfflineSyncService', 'Batch sync succeeded for ${queue.length} actions');
        return queue.length;
      }
    } on ApiException catch (e) {
      SecureLogger.error('OfflineSyncService', 'Batch sync failed', e);
    } catch (e) {
      SecureLogger.error('OfflineSyncService', 'Unexpected error syncing batch', e);
    }

    return 0;
  }

  Future<void> _saveQueue(List<SyncActionItem> queue) async {
    final str = jsonEncode(queue.map((e) => e.toJson()).toList());
    await storage.setString(_queueKey, str);
  }
}
