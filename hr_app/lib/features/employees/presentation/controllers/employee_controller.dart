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
  EmployeeStatus? _statusFilter;
  String? _errorMessage;

  EmployeeController(this._repository) {
    fetchEmployees();
  }

  EmployeeViewStatus get status => _status;
  bool get isLoading => _status == EmployeeViewStatus.loading;
  List<EmployeeEntity> get employees => _employees;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;
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
    _searchQuery = query;
    _currentPage = 1;
    fetchEmployees();
  }

  void onFilterStatus(EmployeeStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchEmployees();
  }

  Future<void> updateEmployeeStatus(String id, EmployeeStatus status) async {
    try {
      await _repository.updateStatus(id, status);
      await fetchEmployees();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
