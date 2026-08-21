import 'package:flutter/material.dart';
import '../../domain/entities/settings_entity.dart';

enum SettingsTab {
  general('General & Company'),
  attendance('Attendance Policy'),
  notifications('Notifications'),
  security('Security & Sessions'),
  appearance('Appearance & Theme'),
  rbac('RBAC Matrix');

  final String label;
  const SettingsTab(this.label);
}

/// State controller for System & HR Settings
class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;

  SystemSettingsBundle? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  SettingsTab _activeTab = SettingsTab.general;

  SettingsController(this._repository, {bool autoFetch = true}) {
    if (autoFetch) {
      fetchSettings();
    }
  }

  SystemSettingsBundle? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  SettingsTab get activeTab => _activeTab;

  void setActiveTab(SettingsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.getSettings();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCompanySettings(CompanySettingsEntity company) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCompanySettings(company);
      _settings = _settings?.copyWith(company: updated);
      _successMessage = 'Company settings updated successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveAttendancePolicy(AttendancePolicySettingsEntity policy) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateAttendancePolicySettings(policy);
      _settings = _settings?.copyWith(attendance: updated);
      _successMessage = 'Attendance policy settings updated successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveNotificationSettings(NotificationSettingsEntity notifications) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateNotificationSettings(notifications);
      _settings = _settings?.copyWith(notifications: updated);
      _successMessage = 'Notification rules updated successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSecuritySettings(SecuritySettingsEntity security) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateSecuritySettings(security);
      _settings = _settings?.copyWith(security: updated);
      _successMessage = 'Security policy updated successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
