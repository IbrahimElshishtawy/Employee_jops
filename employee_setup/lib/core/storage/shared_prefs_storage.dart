import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';

class SharedPrefsStorage implements LocalStorage {
  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryFallback = {};

  @override
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Fallback in-memory for testing environments
    }
  }

  @override
  Future<bool> setString(String key, String value) async {
    _memoryFallback[key] = value;
    if (_prefs != null) {
      return await _prefs!.setString(key, value);
    }
    return true;
  }

  @override
  String? getString(String key) {
    if (_prefs != null) {
      return _prefs!.getString(key) ?? _memoryFallback[key] as String?;
    }
    return _memoryFallback[key] as String?;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _memoryFallback[key] = value;
    if (_prefs != null) {
      return await _prefs!.setBool(key, value);
    }
    return true;
  }

  @override
  bool? getBool(String key) {
    if (_prefs != null) {
      return _prefs!.getBool(key) ?? _memoryFallback[key] as bool?;
    }
    return _memoryFallback[key] as bool?;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _memoryFallback[key] = value;
    if (_prefs != null) {
      return await _prefs!.setStringList(key, value);
    }
    return true;
  }

  @override
  List<String>? getStringList(String key) {
    if (_prefs != null) {
      return _prefs!.getStringList(key) ?? _memoryFallback[key] as List<String>?;
    }
    return _memoryFallback[key] as List<String>?;
  }

  @override
  Future<bool> remove(String key) async {
    _memoryFallback.remove(key);
    if (_prefs != null) {
      return await _prefs!.remove(key);
    }
    return true;
  }

  @override
  Future<bool> clear() async {
    _memoryFallback.clear();
    if (_prefs != null) {
      return await _prefs!.clear();
    }
    return true;
  }
}
