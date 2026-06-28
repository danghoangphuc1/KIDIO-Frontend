import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class AdminDashboardApi {
  final Dio _dio;

  AdminDashboardApi(this._dio);

  Future<AdminDashboardOverviewResponse> getOverview() async {
    final response = await _dio.get('admin/dashboard/overview');
    if (response.statusCode == 200) {
      return AdminDashboardOverviewResponse.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to load admin overview');
    }
  }

  Future<AdminDashboardDetailResponse> getDetail({
    int recentUsersCount = 10,
    int topLessonsCount = 10,
    int recentActivitiesCount = 10,
  }) async {
    final response = await _dio.get(
      'admin/dashboard/detail',
      queryParameters: {
        'recentUsersCount': recentUsersCount,
        'topLessonsCount': topLessonsCount,
        'recentActivitiesCount': recentActivitiesCount,
      },
    );
    if (response.statusCode == 200) {
      return AdminDashboardDetailResponse.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to load admin dashboard detail');
    }
  }
}
