// ignore_for_file: unnecessary_non_null_assertion

import 'package:flutter/material.dart';

/// Abstract service providing the current time across the application.
///
/// In MVP: delegates to device clock.
/// In Production: can be replaced by ServerTimeService to synchronize with NTP / backend API.
abstract class TimeService {
  /// Returns the current DateTime.
  DateTime now();

  /// Returns the current date (with 00:00:00 time).
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Returns the current TimeOfDay.
  TimeOfDay currentTimeOfDay() {
    final n = now();
    return TimeOfDay(hour: n.hour, minute: n.minute);
  }

  /// Calculates elapsed duration between given timestamp and now.
  Duration differenceFromNow(DateTime timestamp) {
    return now().difference(timestamp);
  }

  /// Checks if a timestamp is considered stale (e.g. older than threshold).
  bool isStale(DateTime timestamp, {Duration threshold = const Duration(seconds: 60)}) {
    final diff = differenceFromNow(timestamp).abs();
    return diff > threshold;
  }
}

/// Default device clock implementation of [TimeService].
class DeviceTimeService implements TimeService {
  final DateTime? Function()? _customNowProvider;

  DeviceTimeService([this._customNowProvider]);

  @override
  DateTime now() {
    if (_customNowProvider != null) {
      final custom = _customNowProvider!();
      if (custom != null) return custom;
    }
    return DateTime.now();
  }

  @override
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  TimeOfDay currentTimeOfDay() {
    final n = now();
    return TimeOfDay(hour: n.hour, minute: n.minute);
  }

  @override
  Duration differenceFromNow(DateTime timestamp) {
    return now().difference(timestamp);
  }

  @override
  bool isStale(DateTime timestamp, {Duration threshold = const Duration(seconds: 60)}) {
    final diff = differenceFromNow(timestamp).abs();
    return diff > threshold;
  }
}
