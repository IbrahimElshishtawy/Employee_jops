import 'package:flutter/material.dart';
import '../../../../core/rbac/app_role.dart';
import '../../../../core/security/session_manager.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication State Controller
class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

  AuthStatus _status = AuthStatus.initial;
  AuthUser? _currentUser;
  String? _errorMessage;

  AuthController(this._authRepository, this._sessionManager) {
    _sessionManager.onSessionExpired = () {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      _errorMessage = 'Session expired. Please log in again.';
      notifyListeners();
    };
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;
  AuthUser? get currentUser => _currentUser;
  AppRole get currentRole => _currentUser?.role ?? AppRole.viewer;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _sessionManager.recordActivity();
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _authRepository.login(
        AuthCredentials(email: email, password: password),
      );
      _currentUser = session.user;
      _status = AuthStatus.authenticated;
      _sessionManager.recordActivity();
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authRepository.logout();
    await _sessionManager.endSession();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Switch user role dynamically (in mock mode for testing RBAC)
  void switchMockRole(AppRole role) {
    if (_currentUser != null) {
      _currentUser = AuthUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        fullName: _currentUser!.fullName,
        role: role,
        department: _currentUser!.department,
      );
      notifyListeners();
    }
  }
}
