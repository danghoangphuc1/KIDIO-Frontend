import '../models/kidio_models.dart';
import '../services/admin_dashboard_api.dart';

class AdminDashboardRepository {
  final AdminDashboardApi _api;

  AdminDashboardRepository(this._api);

  Future<AdminDashboardOverviewResponse> getOverview() => _api.getOverview();

  Future<AdminDashboardDetailResponse> getDetail({
    int recentUsersCount = 10,
    int topLessonsCount = 10,
    int recentActivitiesCount = 10,
  }) => _api.getDetail(
    recentUsersCount: recentUsersCount,
    topLessonsCount: topLessonsCount,
    recentActivitiesCount: recentActivitiesCount,
  );
}
