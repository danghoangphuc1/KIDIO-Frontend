import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class AchievementApi {
  final Dio _dio;

  AchievementApi(this._dio);

  Future<List<Achievement>> getByChild(String childId) async {
    try {
      final response = await _dio.get('Achievement/child/$childId');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
