import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_metrics.dart';

enum DashboardStatus { initial, loading, loaded, error }

/// State Controller for the Dashboard
class DashboardController extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardMetrics? _metrics;
  String? _errorMessage;

  DashboardController(this._repository) {
    loadMetrics();
  }

  DashboardStatus get status => _status;
  bool get isLoading => _status == DashboardStatus.loading;
  DashboardMetrics? get metrics => _metrics;
  String? get errorMessage => _errorMessage;

  Future<void> loadMetrics() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _metrics = await _repository.getMetrics();
      _status = DashboardStatus.loaded;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
