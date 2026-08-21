import 'package:flutter/material.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/workplace_entity.dart';

/// State Management Controller for Workplaces in CyberWise IE HR Portal
class WorkplaceController extends ChangeNotifier {
  final WorkplacesRepository _repository;
  final EmployeeRepository _employeeRepository;

  WorkplaceController(this._repository, this._employeeRepository);

  List<WorkplaceEntity> _workplaces = [];
  List<WorkplaceEntity> get workplaces => _workplaces;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _searchQuery;
  String? get searchQuery => _searchQuery;

  GeofenceType? _geofenceTypeFilter;
  GeofenceType? get geofenceTypeFilter => _geofenceTypeFilter;

  bool? _statusFilter;
  bool? get statusFilter => _statusFilter;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  final int _pageSize = 10;
  int get pageSize => _pageSize;

  // KPI Metrics
  int get activeGeofenceCount => _workplaces.where((w) => w.isActive).length;
  int get polygonCount => _workplaces.where((w) => w.geofenceType == GeofenceType.polygon).length;
  int get circleCount => _workplaces.where((w) => w.geofenceType == GeofenceType.circle).length;

  Future<void> fetchWorkplaces({int page = 1}) async {
    _currentPage = page;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getWorkplaces(
        WorkplaceFilter(
          searchQuery: _searchQuery,
          geofenceType: _geofenceTypeFilter,
          isActive: _statusFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
      );
      _workplaces = res.items;
      _totalCount = res.totalCount;
      _totalPages = res.totalPages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSearch(String query) {
    _searchQuery = query.isEmpty ? null : query;
    fetchWorkplaces(page: 1);
  }

  void onFilterGeofenceType(GeofenceType? type) {
    _geofenceTypeFilter = type;
    fetchWorkplaces(page: 1);
  }

  void onFilterStatus(bool? isActive) {
    _statusFilter = isActive;
    fetchWorkplaces(page: 1);
  }

  Future<bool> createWorkplace(WorkplaceEntity workplace) async {
    try {
      await _repository.createWorkplace(workplace);
      await fetchWorkplaces(page: 1);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorkplace(WorkplaceEntity workplace) async {
    try {
      await _repository.updateWorkplace(workplace);
      await fetchWorkplaces(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleWorkplaceStatus(String id, bool isActive) async {
    try {
      await _repository.toggleStatus(id, isActive);
      final index = _workplaces.indexWhere((w) => w.id == id);
      if (index != -1) {
        _workplaces[index] = _workplaces[index].copyWith(isActive: isActive);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkplace(String id) async {
    try {
      await _repository.deleteWorkplace(id);
      await fetchWorkplaces(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<EmployeeEntity>> fetchAllEmployees() async {
    try {
      final res = await _employeeRepository.getEmployees(
        const EmployeeFilter(page: 1, pageSize: 100),
      );
      return res.items;
    } catch (_) {
      return [];
    }
  }

  Future<List<EmployeeEntity>> fetchAssignedEmployees(String workplaceId) async {
    try {
      return await _repository.getAssignedEmployees(workplaceId);
    } catch (_) {
      return [];
    }
  }

  Future<bool> assignEmployees(String workplaceId, List<String> employeeIds) async {
    try {
      await _repository.assignEmployees(workplaceId, employeeIds);
      await fetchWorkplaces(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
