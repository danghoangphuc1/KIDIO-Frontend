import 'package:flutter/material.dart';
import '../models/kidio_models.dart';
import '../repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  ParentDashboardOverviewResponse? _overview;
  bool _isLoading = false;
  String? _errorMessage;

  ParentDashboardOverviewResponse? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardProvider(this._repository);

  Future<void> loadOverview({int weeks = 4}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _overview = await _repository.getOverview(weeks: weeks);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
