import 'package:flutter/material.dart';
import '../../domain/entities/employee_entity.dart';

enum EmployeeViewStatus { initial, loading, loaded, error }

/// State controller for employee directory
class EmployeeController extends ChangeNotifier {
  final EmployeeRepository _repository;

  EmployeeViewStatus _status = EmployeeViewStatus.initial;
  List<EmployeeEntity> _employees = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  String? _searchQuery;
  String? _departmentFilter;
  String? _workplaceFilter;
  String? _scheduleFilter;
  EmployeeStatus? _statusFilter;
  String? _errorMessage;
  bool _isSaving = false;

  EmployeeController(this._repository) {
    fetchEmployees();
  }

  EmployeeViewStatus get status => _status;
  bool get isLoading => _status == EmployeeViewStatus.loading;
  bool get isSaving => _isSaving;
  List<EmployeeEntity> get employees => _employees;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  String? get departmentFilter => _departmentFilter;
  String? get workplaceFilter => _workplaceFilter;
  String? get scheduleFilter => _scheduleFilter;
  EmployeeStatus? get statusFilter => _statusFilter;

  Future<void> fetchEmployees({int? page}) async {
    _status = EmployeeViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      final result = await _repository.getEmployees(
        EmployeeFilter(
          searchQuery: _searchQuery,
          department: _departmentFilter,
          workplaceId: _workplaceFilter,
          scheduleId: _scheduleFilter,
          status: _statusFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
      );
      _employees = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = EmployeeViewStatus.loaded;
    } catch (e) {
      _status = EmployeeViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _currentPage = 1;
    fetchEmployees();
  }

  void onFilterDepartment(String? department) {
    _departmentFilter = department;
    _currentPage = 1;
    fetchEmployees();
  }

  void onFilterWorkplace(String? workplaceId) {
    _workplaceFilter = workplaceId;
    _currentPage = 1;
    fetchEmployees();
  }

  void onFilterSchedule(String? scheduleId) {
    _scheduleFilter = scheduleId;
    _currentPage = 1;
    fetchEmployees();
  }

  void onFilterStatus(EmployeeStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchEmployees();
  }

  Future<bool> createEmployee(EmployeeEntity employee) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createEmployee(employee);
      _isSaving = false;
      await fetchEmployees(page: 1);
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(EmployeeEntity employee) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateEmployee(employee);
      _isSaving = false;
      await fetchEmployees();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployeeStatus(String id, EmployeeStatus status) async {
    try {
      await _repository.updateStatus(id, status);
      await fetchEmployees();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignWorkplaceAndSchedule(
    String id, {
    required String workplaceId,
    required String workplaceName,
    required String scheduleId,
    required String scheduleName,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.assignWorkplaceAndSchedule(
        id,
        workplaceId: workplaceId,
        workplaceName: workplaceName,
        scheduleId: scheduleId,
        scheduleName: scheduleName,
      );
      _isSaving = false;
      await fetchEmployees();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
