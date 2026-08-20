import 'package:flutter/material.dart';
import '../../domain/entities/hr_request_entity.dart';

enum RequestsViewStatus { initial, loading, loaded, error }

/// State controller for Requests & Approvals
class RequestsController extends ChangeNotifier {
  final RequestsRepository _repository;

  RequestsViewStatus _status = RequestsViewStatus.initial;
  List<HrRequestEntity> _requests = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  String? _searchQuery;
  RequestType? _typeFilter;
  RequestStatus? _statusFilter;
  String? _errorMessage;

  RequestsController(this._repository) {
    fetchRequests();
  }

  RequestsViewStatus get status => _status;
  bool get isLoading => _status == RequestsViewStatus.loading;
  List<HrRequestEntity> get requests => _requests;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;
  RequestType? get typeFilter => _typeFilter;
  RequestStatus? get statusFilter => _statusFilter;

  Future<void> fetchRequests({int? page}) async {
    _status = RequestsViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      final result = await _repository.getRequests(
        RequestFilter(
          searchQuery: _searchQuery,
          type: _typeFilter,
          status: _statusFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
      );
      _requests = result.items;
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
    _searchQuery = query;
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

  Future<void> reviewRequest(String id, {required bool approve, String? comment}) async {
    try {
      await _repository.reviewRequest(id, approve: approve, comment: comment);
      await fetchRequests();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
