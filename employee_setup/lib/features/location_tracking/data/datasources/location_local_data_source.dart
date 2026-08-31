import 'dart:convert';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/entities/employee_location.dart';
import '../models/employee_location_model.dart';

abstract class LocationLocalDataSource {
  Future<void> enqueueLocation(EmployeeLocation location);
  Future<List<EmployeeLocation>> getQueuedLocations();
  Future<void> removeLocations(List<EmployeeLocation> locations);
  Future<void> clearQueue();
  Future<int> getQueueSize();
}

class SharedPreferencesLocationLocalDataSource implements LocationLocalDataSource {
  final LocalStorage _storage;
  static const String _queueStorageKey = 'cyberwise_offline_location_queue_v1';
  static const int maxQueueCapacity = 100;

  SharedPreferencesLocationLocalDataSource(this._storage);

  @override
  Future<void> enqueueLocation(EmployeeLocation location) async {
    try {
      final currentList = await _loadQueue();

      // Bounded capacity: evict oldest if at max capacity
      if (currentList.length >= maxQueueCapacity) {
        currentList.removeAt(0);
      }

      currentList.add(EmployeeLocationModel.fromEntity(location));
      await _saveQueue(currentList);
    } catch (e) {
      SecureLogger.error('LocationLocalDataSource', 'enqueueLocation error', e);
    }
  }

  @override
  Future<List<EmployeeLocation>> getQueuedLocations() async {
    try {
      final list = await _loadQueue();
      return List<EmployeeLocation>.unmodifiable(list);
    } catch (e) {
      SecureLogger.error('LocationLocalDataSource', 'getQueuedLocations error', e);
      return const [];
    }
  }

  @override
  Future<void> removeLocations(List<EmployeeLocation> locations) async {
    try {
      final currentList = await _loadQueue();
      final toRemoveTimestamps = locations.map((l) => l.timestamp.millisecondsSinceEpoch).toSet();

      currentList.removeWhere((item) => toRemoveTimestamps.contains(item.timestamp.millisecondsSinceEpoch));
      await _saveQueue(currentList);
    } catch (e) {
      SecureLogger.error('LocationLocalDataSource', 'removeLocations error', e);
    }
  }

  @override
  Future<void> clearQueue() async {
    try {
      await _storage.remove(_queueStorageKey);
    } catch (e) {
      SecureLogger.error('LocationLocalDataSource', 'clearQueue error', e);
    }
  }

  @override
  Future<int> getQueueSize() async {
    final list = await _loadQueue();
    return list.length;
  }

  Future<List<EmployeeLocationModel>> _loadQueue() async {
    final rawJson = _storage.getString(_queueStorageKey);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => EmployeeLocationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      SecureLogger.warn('LocationLocalDataSource', 'Corrupted queue data reset');
      return [];
    }
  }

  Future<void> _saveQueue(List<EmployeeLocationModel> list) async {
    final encoded = jsonEncode(list.map((m) => m.toJson()).toList());
    await _storage.setString(_queueStorageKey, encoded);
  }
}
