import 'dart:async';
import 'token_storage.dart';

/// Session Lifecycle Manager for tracking inactivity timeout and secure session state
class SessionManager {
  final TokenStorage _tokenStorage;
  final Duration inactivityTimeout;
  DateTime? _lastActivityTime;
  Timer? _inactivityTimer;
  void Function()? onSessionExpired;

  SessionManager(
    this._tokenStorage, {
    this.inactivityTimeout = const Duration(minutes: 30),
  });

  DateTime? get lastActivityTime => _lastActivityTime;

  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () {
      _handleInactivityTimeout();
    });
  }

  void _handleInactivityTimeout() {
    _tokenStorage.clearTokens();
    onSessionExpired?.call();
  }

  Future<void> endSession() async {
    _inactivityTimer?.cancel();
    await _tokenStorage.clearTokens();
    _lastActivityTime = null;
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }
}
