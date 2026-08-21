import 'package:flutter/material.dart';
import '../../domain/entities/deduction_entity.dart';

enum DeductionsViewStatus { initial, loading, loaded, error }

enum DeductionsTab {
  all('All Deductions'),
  scheduled('Scheduled'),
  applied('Applied & Processed'),
  cancelled('Cancelled / Waived');

  final String label;
  const DeductionsTab(this.label);
}

/// State controller for HR Deductions Management
class DeductionsController extends ChangeNotifier {
  final DeductionsRepository _repository;

  DeductionsViewStatus _status = DeductionsViewStatus.initial;
  List<DeductionEntity> _deductions = [];
  DeductionKpiSummary? _kpis;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  DeductionsTab _activeTab = DeductionsTab.all;
  String? _searchQuery;
  DeductionType? _typeFilter;
  DeductionStatus? _statusFilter;
  String? _departmentFilter;
  DateTimeRange? _dateRange;
  String? _errorMessage;

  DeductionsController(this._repository) {
    fetchDeductions();
    fetchKpis();
  }

  DeductionsViewStatus get status => _status;
  bool get isLoading => _status == DeductionsViewStatus.loading;
  List<DeductionEntity> get deductions => _deductions;
  DeductionKpiSummary? get kpis => _kpis;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;

  DeductionsTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  DeductionType? get typeFilter => _typeFilter;
  DeductionStatus? get statusFilter => _statusFilter;
  String? get departmentFilter => _departmentFilter;
  DateTimeRange? get dateRange => _dateRange;

  void setActiveTab(DeductionsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchDeductions();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getDeductionKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchDeductions({int? page}) async {
    _status = DeductionsViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      DeductionStatus? effectiveStatus = _statusFilter;
      if (_activeTab == DeductionsTab.scheduled) {
        effectiveStatus = DeductionStatus.scheduled;
      } else if (_activeTab == DeductionsTab.applied) {
        effectiveStatus = DeductionStatus.applied;
      } else if (_activeTab == DeductionsTab.cancelled) {
        effectiveStatus = DeductionStatus.cancelled;
      }

      final filter = DeductionFilter(
        searchQuery: _searchQuery,
        type: _typeFilter,
        status: effectiveStatus,
        department: _departmentFilter,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getDeductions(filter);

      _deductions = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = DeductionsViewStatus.loaded;
    } catch (e) {
      _status = DeductionsViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchDeductions();
  }

  void onFilterType(DeductionType? type) {
    _typeFilter = type;
    _currentPage = 1;
    fetchDeductions();
  }

  void onFilterStatus(DeductionStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchDeductions();
  }

  void onFilterDepartment(String? department) {
    _departmentFilter = department;
    _currentPage = 1;
    fetchDeductions();
  }

  void onDateRangeSelected(DateTimeRange? range) {
    _dateRange = range;
    _currentPage = 1;
    fetchDeductions();
  }

  Future<bool> createDeduction(DeductionEntity deduction) async {
    try {
      await _repository.createDeduction(deduction);
      await fetchDeductions();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelDeduction(String id, {required String reason}) async {
    try {
      await _repository.cancelDeduction(id, reason: reason);
      await fetchDeductions();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
