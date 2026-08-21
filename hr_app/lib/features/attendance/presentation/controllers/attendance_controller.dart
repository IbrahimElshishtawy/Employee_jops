import 'package:flutter/material.dart';
import '../../domain/entities/attendance_record.dart';

enum AttendanceViewStatus { initial, loading, loaded, error }

enum DatePreset {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom Range');

  final String label;
  const DatePreset(this.label);
}

enum AttendanceTab {
  all('All Attendance Records'),
  suspicious('Suspicious & Security Flags'),
  offline('Pending Offline Review');

  final String label;
  const AttendanceTab(this.label);
}

/// Central state controller for HR Attendance operations
class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _repository;

  AttendanceViewStatus _status = AttendanceViewStatus.initial;
  List<AttendanceRecord> _records = [];
  AttendanceKpiSummary? _kpis;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  AttendanceTab _activeTab = AttendanceTab.all;
  DatePreset _datePreset = DatePreset.today;
  DateTimeRange? _dateRange;

  String? _searchQuery;
  AttendanceStatus? _statusFilter;
  SecurityStatus? _securityFilter;
  String? _departmentFilter;
  String? _workplaceFilter;
  String? _errorMessage;
  bool _isExporting = false;

  AttendanceController(this._repository) {
    _setDatePresetRange(DatePreset.today);
    fetchRecords();
    fetchKpis();
  }

  AttendanceViewStatus get status => _status;
  bool get isLoading => _status == AttendanceViewStatus.loading;
  bool get isExporting => _isExporting;
  List<AttendanceRecord> get records => _records;
  AttendanceKpiSummary? get kpis => _kpis;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;

  AttendanceTab get activeTab => _activeTab;
  DatePreset get datePreset => _datePreset;
  DateTimeRange? get dateRange => _dateRange;
  String? get searchQuery => _searchQuery;
  AttendanceStatus? get statusFilter => _statusFilter;
  SecurityStatus? get securityFilter => _securityFilter;
  String? get departmentFilter => _departmentFilter;
  String? get workplaceFilter => _workplaceFilter;

  void setActiveTab(AttendanceTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchRecords();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getAttendanceKpis(date: _dateRange?.start);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchRecords({int? page}) async {
    _status = AttendanceViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      final filter = AttendanceFilter(
        searchQuery: _searchQuery,
        status: _statusFilter,
        securityStatus: _securityFilter,
        department: _departmentFilter,
        workplaceId: _workplaceFilter,
        isSuspicious: _activeTab == AttendanceTab.suspicious ? true : null,
        isOfflinePending: _activeTab == AttendanceTab.offline ? true : null,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getAttendanceRecords(filter);
      _records = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = AttendanceViewStatus.loaded;
    } catch (e) {
      _status = AttendanceViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSelectDatePreset(DatePreset preset) {
    _datePreset = preset;
    _setDatePresetRange(preset);
    _currentPage = 1;
    fetchRecords();
    fetchKpis();
  }

  void _setDatePresetRange(DatePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case DatePreset.today:
        _dateRange = DateTimeRange(start: today, end: today);
        break;
      case DatePreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        _dateRange = DateTimeRange(start: yesterday, end: yesterday);
        break;
      case DatePreset.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        _dateRange = DateTimeRange(start: weekStart, end: today);
        break;
      case DatePreset.thisMonth:
        final monthStart = DateTime(today.year, today.month, 1);
        _dateRange = DateTimeRange(start: monthStart, end: today);
        break;
      case DatePreset.custom:
        break;
    }
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchRecords();
  }

  void onFilterStatus(AttendanceStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchRecords();
  }

  void onFilterSecurity(SecurityStatus? status) {
    _securityFilter = status;
    _currentPage = 1;
    fetchRecords();
  }

  void onFilterDepartment(String? department) {
    _departmentFilter = department;
    _currentPage = 1;
    fetchRecords();
  }

  void onFilterWorkplace(String? workplaceId) {
    _workplaceFilter = workplaceId;
    _currentPage = 1;
    fetchRecords();
  }

  void onDateRangeSelected(DateTimeRange? range) {
    _datePreset = DatePreset.custom;
    _dateRange = range;
    _currentPage = 1;
    fetchRecords();
    fetchKpis();
  }

  Future<bool> reviewOfflineRecord(String id, {required bool approve, String? reason}) async {
    try {
      await _repository.reviewOfflineRecord(id, approve: approve, reason: reason);
      await fetchRecords();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> manualCorrection({
    required String employeeId,
    required DateTime date,
    required AttendanceStatus status,
    required DateTime checkInTime,
    required DateTime checkOutTime,
    required String reason,
  }) async {
    try {
      await _repository.manualCorrection(
        employeeId: employeeId,
        date: date,
        status: status,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        reason: reason,
      );
      await fetchRecords();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> exportReport() async {
    _isExporting = true;
    notifyListeners();

    try {
      final downloadUrl = await _repository.exportAttendanceReport(
        AttendanceFilter(
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          status: _statusFilter,
          workplaceId: _workplaceFilter,
        ),
      );
      _isExporting = false;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      _isExporting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
