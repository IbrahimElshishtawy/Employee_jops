import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/secure_logger.dart';
import 'local_storage.dart';

/// SecureSessionStorage provides encrypted storage on mobile devices (Android Keystore / iOS Keychain)
/// with safe fallback to SharedPreferences for Web and testing environments.
class SecureSessionStorage implements LocalStorage {
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;
  bool _initialized = false;

  SecureSessionStorage({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    } catch (e) {
      SecureLogger.error('SecureSessionStorage', 'SharedPreferences init error', e);
    }
  }

  bool get _useSecureStorage => !kIsWeb;

  @override
  Future<bool> setString(String key, String value) async {
    await init();
    try {
      if (_useSecureStorage) {
        await _secureStorage.write(key: key, value: value);
      }
      // Keep SharedPreferences in sync for non-sensitive reads / web fallback
      await _prefs?.setString(key, value);
      return true;
    } catch (e) {
      SecureLogger.error('SecureSessionStorage', 'setString error', e);
      return await _prefs?.setString(key, value) ?? false;
    }
  }

  @override
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Asynchronous read directly from secure hardware storage (Android Keystore / iOS Keychain)
  Future<String?> getSecureString(String key) async {
    await init();
    if (_useSecureStorage) {
      try {
        final val = await _secureStorage.read(key: key);
        if (val != null) return val;
      } catch (e) {
        SecureLogger.error('SecureSessionStorage', 'getSecureString error', e);
      }
    }
    return _prefs?.getString(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await init();
    try {
      if (_useSecureStorage) {
        await _secureStorage.write(key: key, value: value.toString());
      }
      await _prefs?.setBool(key, value);
      return true;
    } catch (e) {
      return await _prefs?.setBool(key, value) ?? false;
    }
  }

  @override
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    await init();
    return await _prefs?.setStringList(key, value) ?? false;
  }

  @override
  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  @override
  Future<bool> remove(String key) async {
    await init();
    try {
      if (_useSecureStorage) {
        await _secureStorage.delete(key: key);
      }
    } catch (_) {}
    return await _prefs?.remove(key) ?? false;
  }

  @override
  Future<bool> clear() async {
    await init();
    try {
      if (_useSecureStorage) {
        await _secureStorage.deleteAll();
      }
    } catch (_) {}
    return await _prefs?.clear() ?? false;
  }
}
