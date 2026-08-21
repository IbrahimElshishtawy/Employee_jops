import 'package:flutter/material.dart';
import '../../domain/entities/hr_request_entity.dart';

enum RequestsViewStatus { initial, loading, loaded, error }

enum RequestsTab {
  all('All Requests'),
  pending('Pending Approval'),
  approved('Approved'),
  rejected('Rejected & Cancelled');

  final String label;
  const RequestsTab(this.label);
}

/// State controller for HR Requests Management
class RequestsController extends ChangeNotifier {
  final RequestsRepository _repository;

  RequestsViewStatus _status = RequestsViewStatus.initial;
  List<HrRequestEntity> _requests = [];
  RequestKpiSummary? _kpis;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  RequestsTab _activeTab = RequestsTab.all;
  String? _searchQuery;
  RequestType? _typeFilter;
  RequestStatus? _statusFilter;
  String? _departmentFilter;
  DateTimeRange? _dateRange;
  String? _errorMessage;

  RequestsController(this._repository) {
    fetchRequests();
    fetchKpis();
  }

  RequestsViewStatus get status => _status;
  bool get isLoading => _status == RequestsViewStatus.loading;
  List<HrRequestEntity> get requests => _requests;
  RequestKpiSummary? get kpis => _kpis;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;

  RequestsTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  RequestType? get typeFilter => _typeFilter;
  RequestStatus? get statusFilter => _statusFilter;
  String? get departmentFilter => _departmentFilter;
  DateTimeRange? get dateRange => _dateRange;

  void setActiveTab(RequestsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchRequests();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getRequestKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchRequests({int? page}) async {
    _status = RequestsViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      RequestStatus? effectiveStatus = _statusFilter;
      if (_activeTab == RequestsTab.pending) {
        effectiveStatus = RequestStatus.pending;
      } else if (_activeTab == RequestsTab.approved) {
        effectiveStatus = RequestStatus.approved;
      }

      final filter = RequestFilter(
        searchQuery: _searchQuery,
        type: _typeFilter,
        status: effectiveStatus,
        department: _departmentFilter,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getRequests(filter);

      var items = result.items;
      if (_activeTab == RequestsTab.rejected) {
        items = items.where((r) => r.status == RequestStatus.rejected || r.status == RequestStatus.cancelled).toList();
      }

      _requests = items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = RequestsViewStatus.loaded;
    } catch (e) {
      _status = RequestsViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchRequests();
  }

  void onFilterType(RequestType? type) {
    _typeFilter = type;
    _currentPage = 1;
    fetchRequests();
  }

  void onFilterStatus(RequestStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchRequests();
  }

  void onFilterDepartment(String? department) {
    _departmentFilter = department;
    _currentPage = 1;
    fetchRequests();
  }

  void onDateRangeSelected(DateTimeRange? range) {
    _dateRange = range;
    _currentPage = 1;
    fetchRequests();
  }

  Future<bool> reviewRequest(String id, {required bool approve, String? comment}) async {
    try {
      await _repository.reviewRequest(id, approve: approve, comment: comment);
      await fetchRequests();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
