import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final bool notificationsEnabled;
  final bool biometricAuthEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ar'),
    this.notificationsEnabled = true,
    this.biometricAuthEnabled = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notificationsEnabled,
    bool? biometricAuthEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
    );
  }
}
