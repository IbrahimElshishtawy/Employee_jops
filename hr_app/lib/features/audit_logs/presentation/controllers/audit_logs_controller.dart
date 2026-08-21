import 'package:flutter/material.dart';
import '../../domain/entities/audit_log_entity.dart';

enum AuditLogsTab {
  all('All Activity'),
  security('Security & Auth'),
  hrActions('Employee & HR Actions'),
  financial('Financial & Payroll');

  final String label;
  const AuditLogsTab(this.label);
}

/// State controller for HR Audit Logs Management
class AuditLogsController extends ChangeNotifier {
  final AuditLogsRepository _repository;

  List<AuditLogItemEntity> _logs = [];
  AuditLogKpiSummary? _kpis;
  bool _isLoading = false;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 15;

  AuditLogsTab _activeTab = AuditLogsTab.all;
  String? _searchQuery;
  AuditActionCategory? _categoryFilter;
  AuditResultStatus? _resultFilter;
  String? _errorMessage;

  AuditLogsController(this._repository, {bool autoFetch = true}) {
    if (autoFetch) {
      fetchAuditLogs();
      fetchKpis();
    }
  }

  List<AuditLogItemEntity> get logs => _logs;
  AuditLogKpiSummary? get kpis => _kpis;
  bool get isLoading => _isLoading;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;

  AuditLogsTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  AuditActionCategory? get categoryFilter => _categoryFilter;
  AuditResultStatus? get resultFilter => _resultFilter;
  String? get errorMessage => _errorMessage;

  void setActiveTab(AuditLogsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchAuditLogs();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchAuditLogs();
  }

  void onFilterCategory(AuditActionCategory? category) {
    _categoryFilter = category;
    _currentPage = 1;
    fetchAuditLogs();
  }

  void onFilterResult(AuditResultStatus? result) {
    _resultFilter = result;
    _currentPage = 1;
    fetchAuditLogs();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getAuditLogKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAuditLogs({int? page}) async {
    _isLoading = true;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      AuditActionCategory? cat = _categoryFilter;
      if (_activeTab == AuditLogsTab.security) {
        cat = AuditActionCategory.security;
      } else if (_activeTab == AuditLogsTab.hrActions) {
        cat = AuditActionCategory.employees;
      } else if (_activeTab == AuditLogsTab.financial) {
        cat = AuditActionCategory.financial;
      }

      final filter = AuditLogFilter(
        searchQuery: _searchQuery,
        category: cat,
        result: _resultFilter,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getAuditLogs(filter);
      _logs = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
