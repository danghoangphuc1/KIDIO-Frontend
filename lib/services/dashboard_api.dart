import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class DashboardApi {
  final Dio _dio;

  DashboardApi(this._dio);

  Future<ParentDashboardOverviewResponse> getOverview({int weeks = 4}) async {
    try {
      final response = await _dio.get('ParentDashboard/overview', queryParameters: {
        'weeks': weeks,
      });
      return ParentDashboardOverviewResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
