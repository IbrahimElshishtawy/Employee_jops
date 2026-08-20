import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

/// Notifier for managing active ThemeMode (Light, Dark, System)
class ThemeController extends ChangeNotifier {
  static const String _themePrefKey = 'cw_hr_theme_mode';
  final LocalStorage? _storage;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeController([this._storage]) {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadThemePreference() {
    if (_storage == null) return;
    final savedMode = _storage.getString(_themePrefKey);
    if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    if (_storage != null) {
      String value = 'system';
      if (mode == ThemeMode.dark) value = 'dark';
      if (mode == ThemeMode.light) value = 'light';
      await _storage.setString(_themePrefKey, value);
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
