import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';

enum NotificationsViewStatus { initial, loading, loaded, error }

enum NotificationsTab {
  all('All Notifications'),
  broadcasts('HR Broadcasts'),
  alerts('System Alerts'),
  scheduled('Scheduled');

  final String label;
  const NotificationsTab(this.label);
}

/// State controller for HR Notifications Management
class NotificationsController extends ChangeNotifier {
  final NotificationsRepository _repository;

  NotificationsViewStatus _status = NotificationsViewStatus.initial;
  List<NotificationItemEntity> _notifications = [];
  NotificationKpiSummary? _kpis;
  int _totalCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  NotificationsTab _activeTab = NotificationsTab.all;
  String? _searchQuery;
  NotificationType? _typeFilter;
  String? _errorMessage;

  NotificationsController(this._repository, {bool autoFetch = true}) {
    if (autoFetch) {
      fetchNotifications();
      fetchKpis();
    }
  }

  NotificationsViewStatus get status => _status;
  bool get isLoading => _status == NotificationsViewStatus.loading;
  List<NotificationItemEntity> get notifications => _notifications;
  NotificationKpiSummary? get kpis => _kpis;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String? get errorMessage => _errorMessage;

  NotificationsTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  NotificationType? get typeFilter => _typeFilter;

  void setActiveTab(NotificationsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentPage = 1;
    fetchNotifications();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getNotificationKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchNotifications({int? page}) async {
    _status = NotificationsViewStatus.loading;
    _errorMessage = null;
    if (page != null) _currentPage = page;
    notifyListeners();

    try {
      NotificationType? type = _typeFilter;
      NotificationStatus? status;

      if (_activeTab == NotificationsTab.broadcasts) {
        type = NotificationType.companyAnnouncement;
      } else if (_activeTab == NotificationsTab.alerts) {
        type = NotificationType.systemAlert;
      } else if (_activeTab == NotificationsTab.scheduled) {
        status = NotificationStatus.scheduled;
      }

      final filter = NotificationFilter(
        searchQuery: _searchQuery,
        type: type,
        status: status,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final result = await _repository.getNotifications(filter);

      _notifications = result.items;
      _totalCount = result.totalCount;
      _totalPages = result.totalPages;
      _status = NotificationsViewStatus.loaded;
    } catch (e) {
      _status = NotificationsViewStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    fetchNotifications();
  }

  void onFilterType(NotificationType? type) {
    _typeFilter = type;
    _currentPage = 1;
    fetchNotifications();
  }

  Future<bool> createNotification(NotificationItemEntity notification) async {
    try {
      await _repository.createNotification(notification);
      await fetchNotifications();
      await fetchKpis();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      await fetchNotifications();
      await fetchKpis();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      await fetchNotifications();
      await fetchKpis();
    } catch (_) {}
  }

  Future<void> cancelScheduled(String id) async {
    try {
      await _repository.cancelScheduledNotification(id);
      await fetchNotifications();
      await fetchKpis();
    } catch (_) {}
  }
}
