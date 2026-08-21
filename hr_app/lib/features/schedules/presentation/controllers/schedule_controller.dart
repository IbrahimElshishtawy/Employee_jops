import 'package:flutter/material.dart';
import '../../domain/entities/schedule_entity.dart';

enum SchedulesViewStatus { initial, loading, loaded, error }

enum SchedulesTab {
  all('All Schedules'),
  active('Active Shifts'),
  inactive('Inactive Shifts');

  final String label;
  const SchedulesTab(this.label);
}

/// State controller for HR Work Schedules Management
class ScheduleController extends ChangeNotifier {
  final SchedulesRepository _repository;

  SchedulesViewStatus _status = SchedulesViewStatus.initial;
  List<WorkScheduleEntity> _schedules = [];
  ScheduleKpiSummary? _kpis;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  SchedulesTab _activeTab = SchedulesTab.all;
  String? _searchQuery;
  String? _workingDayFilter;
  String? _departmentFilter;
  String? _errorMessage;

  ScheduleController(this._repository) {
    fetchSchedules();
    fetchKpis();
  }

  SchedulesViewStatus get status => _status;
  bool get isLoading => _status == SchedulesViewStatus.loading;
  List<WorkScheduleEntity> get schedules => _schedules;
  ScheduleKpiSummary? get kpis => _kpis;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;

  SchedulesTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  String? get workingDayFilter => _workingDayFilter;
  String? get departmentFilter => _departmentFilter;

  void setActiveTab(SchedulesTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchSchedules();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getScheduleKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchSchedules({int? page}) async {
    _status = SchedulesViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      bool? isActive;
      if (_activeTab == SchedulesTab.active) {
        isActive = true;
      } else if (_activeTab == SchedulesTab.inactive) {
        isActive = false;
      }

      final filter = ScheduleFilter(
        searchQuery: _searchQuery,
        isActive: isActive,
        workingDay: _workingDayFilter,
        department: _departmentFilter,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getSchedules(filter);

      _schedules = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = SchedulesViewStatus.loaded;
    } catch (e) {
      _status = SchedulesViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchSchedules();
  }

  void onFilterWorkingDay(String? day) {
    _workingDayFilter = day;
    _currentPage = 1;
    fetchSchedules();
  }

  void onFilterDepartment(String? department) {
    _departmentFilter = department;
    _currentPage = 1;
    fetchSchedules();
  }

  Future<bool> createSchedule(WorkScheduleEntity schedule) async {
    try {
      await _repository.createSchedule(schedule);
      await fetchSchedules();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule(WorkScheduleEntity schedule) async {
    try {
      await _repository.updateSchedule(schedule);
      await fetchSchedules();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      await _repository.toggleScheduleStatus(id, isActive);
      await fetchSchedules();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
