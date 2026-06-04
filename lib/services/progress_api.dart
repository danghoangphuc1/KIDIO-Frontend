import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class ProgressApi {
  final Dio _dio;

  ProgressApi(this._dio);

  Future<LessonProgress> submitProgress({
    required String childId,
    required String lessonId,
    required int scorePercent,
    required int timeSpentSeconds,
  }) async {
    try {
      final response = await _dio.post('Progress/submit', data: {
        'childId': childId,
        'lessonId': lessonId,
        'scorePercent': scorePercent,
        'timeSpentSeconds': timeSpentSeconds,
      });
      return LessonProgress.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LessonProgress>> getRecentActivities(String childId) async {
    try {
      final response = await _dio.get('Progress/child/$childId/recent-activities');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => LessonProgress.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
