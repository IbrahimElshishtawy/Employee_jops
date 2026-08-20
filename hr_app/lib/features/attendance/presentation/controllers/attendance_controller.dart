import 'package:flutter/material.dart';
import '../../domain/entities/attendance_record.dart';

enum AttendanceViewStatus { initial, loading, loaded, error }

/// State controller for Attendance Records
class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _repository;

  AttendanceViewStatus _status = AttendanceViewStatus.initial;
  List<AttendanceRecord> _records = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  String? _searchQuery;
  AttendanceStatus? _statusFilter;
  DateTimeRange? _dateRange;
  String? _errorMessage;

  AttendanceController(this._repository) {
    fetchRecords();
  }

  AttendanceViewStatus get status => _status;
  bool get isLoading => _status == AttendanceViewStatus.loading;
  List<AttendanceRecord> get records => _records;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;
  AttendanceStatus? get statusFilter => _statusFilter;
  DateTimeRange? get dateRange => _dateRange;

  Future<void> fetchRecords({int? page}) async {
    _status = AttendanceViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      final result = await _repository.getAttendanceRecords(
        AttendanceFilter(
          searchQuery: _searchQuery,
          status: _statusFilter,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          page: _currentPage,
          pageSize: _pageSize,
        ),
      );
      _records = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = AttendanceViewStatus.loaded;
    } catch (e) {
      _status = AttendanceViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchRecords();
  }

  void onFilterStatus(AttendanceStatus? status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchRecords();
  }

  void onDateRangeSelected(DateTimeRange? range) {
    _dateRange = range;
    _currentPage = 1;
    fetchRecords();
  }
}
