import 'package:flutter/material.dart';
import '../../domain/entities/advance_entity.dart';

enum AdvancesViewStatus { initial, loading, loaded, error }

/// State controller for salary advances
class AdvancesController extends ChangeNotifier {
  final AdvancesRepository _repository;

  AdvancesViewStatus _status = AdvancesViewStatus.initial;
  List<AdvanceEntity> _advances = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  String? _searchQuery;
  AdvanceStatus? _statusFilter;
  String? _errorMessage;

  AdvancesController(this._repository) {
    fetchAdvances();
  }

  AdvancesViewStatus get status => _status;
  bool get isLoading => _status == AdvancesViewStatus.loading;
  List<AdvanceEntity> get advances => _advances;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;
  AdvanceStatus? get statusFilter => _statusFilter;

  Future<void> fetchAdvances({int? page}) async {
    _status = AdvancesViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      final result = await _repository.getAdvances(
        AdvanceFilter(
          searchQuery: _searchQuery,
          status: _statusFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
      );
      _advances = result.items;
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
    _searchQuery = query;
    _currentPage = 1;
    fetchAdvances();
  }

  void onFilterStatus(AdvanceStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchAdvances();
  }

  Future<void> reviewAdvance(String id, {required bool approve, String? notes}) async {
    try {
      await _repository.reviewAdvance(id, approve: approve, notes: notes);
      await fetchAdvances();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
