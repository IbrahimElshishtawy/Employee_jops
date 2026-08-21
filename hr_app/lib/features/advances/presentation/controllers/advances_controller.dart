import 'package:flutter/material.dart';
import '../../domain/entities/advance_entity.dart';

enum AdvancesViewStatus { initial, loading, loaded, error }

enum AdvancesTab {
  all('All Advances'),
  pending('Pending Review'),
  approved('Approved & Active'),
  rejected('Rejected & Cancelled');

  final String label;
  const AdvancesTab(this.label);
}

/// State controller for HR Salary Advances Management
class AdvancesController extends ChangeNotifier {
  final AdvancesRepository _repository;

  AdvancesViewStatus _status = AdvancesViewStatus.initial;
  List<AdvanceEntity> _advances = [];
  AdvanceKpiSummary? _kpis;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  AdvancesTab _activeTab = AdvancesTab.all;
  String? _searchQuery;
  AdvanceStatus? _statusFilter;
  String? _departmentFilter;
  DateTimeRange? _dateRange;
  String? _errorMessage;

  AdvancesController(this._repository) {
    fetchAdvances();
    fetchKpis();
  }

  AdvancesViewStatus get status => _status;
  bool get isLoading => _status == AdvancesViewStatus.loading;
  List<AdvanceEntity> get advances => _advances;
  AdvanceKpiSummary? get kpis => _kpis;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;

  AdvancesTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  AdvanceStatus? get statusFilter => _statusFilter;
  String? get departmentFilter => _departmentFilter;
  DateTimeRange? get dateRange => _dateRange;

  void setActiveTab(AdvancesTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchAdvances();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getAdvanceKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAdvances({int? page}) async {
    _status = AdvancesViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      AdvanceStatus? effectiveStatus = _statusFilter;
      if (_activeTab == AdvancesTab.pending) {
        effectiveStatus = AdvanceStatus.pending;
      } else if (_activeTab == AdvancesTab.approved) {
        effectiveStatus = AdvanceStatus.approved;
      }

      final filter = AdvanceFilter(
        searchQuery: _searchQuery,
        status: effectiveStatus,
        department: _departmentFilter,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getAdvances(filter);

      var items = result.items;
      if (_activeTab == AdvancesTab.rejected) {
        items = items.where((a) => a.status == AdvanceStatus.rejected || a.status == AdvanceStatus.cancelled).toList();
      }

      _advances = items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = AdvancesViewStatus.loaded;
    } catch (e) {
      _status = AdvancesViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchAdvances();
  }

  void onFilterStatus(AdvanceStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchAdvances();
  }

  void onFilterDepartment(String? department) {
    _departmentFilter = department;
    _currentPage = 1;
    fetchAdvances();
  }

  void onDateRangeSelected(DateTimeRange? range) {
    _dateRange = range;
    _currentPage = 1;
    fetchAdvances();
  }

  Future<bool> approveAdvance(
    String id, {
    required double approvedAmount,
    int? installmentCount,
    String? notes,
  }) async {
    try {
      await _repository.approveAdvance(
        id,
        approvedAmount: approvedAmount,
        installmentCount: installmentCount,
        notes: notes,
      );
      await fetchAdvances();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAdvance(String id, {required String reason}) async {
    try {
      await _repository.rejectAdvance(id, reason: reason);
      await fetchAdvances();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
