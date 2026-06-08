import '../models/kidio_models.dart';
import '../services/dashboard_api.dart';

class DashboardRepository {
  final DashboardApi _dashboardApi;

  DashboardRepository(this._dashboardApi);

  Future<ParentDashboardOverviewResponse> getOverview({int weeks = 4}) =>
      _dashboardApi.getOverview(weeks: weeks);
}
