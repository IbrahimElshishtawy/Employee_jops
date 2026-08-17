/// Storage interface to isolate local cache and persistence from UI.
abstract class LocalStorage {
  Future<void> init();
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  Future<bool> setStringList(String key, List<String> value);
  List<String>? getStringList(String key);
  Future<bool> remove(String key);
  Future<bool> clear();
}
