import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class VocabularyApi {
  final Dio _dio;

  VocabularyApi(this._dio);

  Future<List<Vocabulary>> getByLesson(String lessonId) async {
    try {
      final response = await _dio.get('Vocabulary/lesson/$lessonId');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Vocabulary.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Vocabulary> getById(String vocabId) async {
    try {
      final response = await _dio.get('Vocabulary/$vocabId');
      return Vocabulary.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Vocabulary>> search(String keyword, {String? lessonId, int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get('Vocabulary/search', queryParameters: {
        'keyword': keyword,
        if (lessonId != null) 'lessonId': lessonId,
        'pageNumber': page,
        'pageSize': pageSize,
      });
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Vocabulary.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
