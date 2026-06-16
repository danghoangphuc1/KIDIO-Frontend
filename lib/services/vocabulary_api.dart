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

  Future<PagedResult<Vocabulary>> getPaged({int pageNumber = 1, int pageSize = 10, String? lessonId}) async {
    try {
      final response = await _dio.get('Vocabulary/paged', queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (lessonId != null) 'lessonId': lessonId,
      });
      final data = response.data['data'];
      return PagedResult<Vocabulary>.fromJson(
        data,
        (json) => Vocabulary.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Vocabulary>> getAll() async {
    try {
      final response = await _dio.get('Vocabulary/all');
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

  Future<Vocabulary> createVocabulary({
    required String word,
    required String meaning,
    String? phoneticText,
    String? audioUrl,
    String? imageUrl,
    int? orderIndex,
  }) async {
    try {
      final response = await _dio.post('Vocabulary', data: {
        'word': word,
        'meaning': meaning,
        'phoneticText': phoneticText,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'orderIndex': orderIndex,
      });
      return Vocabulary.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Vocabulary> updateVocabulary({
    required String vocabId,
    required String word,
    required String meaning,
    String? phoneticText,
    String? audioUrl,
    String? imageUrl,
    int? orderIndex,
  }) async {
    try {
      final response = await _dio.put('Vocabulary/$vocabId', data: {
        'word': word,
        'meaning': meaning,
        'phoneticText': phoneticText,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'orderIndex': orderIndex,
      });
      return Vocabulary.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVocabulary(String vocabId) async {
    try {
      await _dio.delete('Vocabulary/$vocabId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreVocabulary(String vocabId) async {
    try {
      await _dio.patch('Vocabulary/$vocabId/restore');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> hardDeleteVocabulary(String vocabId) async {
    try {
      await _dio.delete('Vocabulary/$vocabId/hard');
    } catch (e) {
      rethrow;
    }
  }
}
