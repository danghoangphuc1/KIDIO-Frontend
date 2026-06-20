import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class LessonApi {
  final Dio _dio;

  LessonApi(this._dio);

  Future<PagedResult<Lesson>> getAllLessons({
    int pageNumber = 1,
    int pageSize = 10,
    String? q,
  }) async {
    try {
      final response = await _dio.get('Lesson/all', queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (q != null) 'q': q,
      });

      final data = response.data['data'];

      return PagedResult<Lesson>.fromJson(
        data,
        (json) => Lesson.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Lesson>> getLessonsByTopic(String topicId) async {
    try {
      final response = await _dio.get('Lesson/topic/$topicId');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Lesson.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Lesson> getLessonById(String lessonId) async {
    try {
      final response = await _dio.get('Lesson/$lessonId');
      return Lesson.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Lesson> createLesson({
    required String title,
    required String topicId,
    String? description,
    String? lessonType,
    String? difficulty,
    String? skillFocus,
    int? durationSeconds,
    String? thumbnailUrl,
    String? audioUrl,
    int? orderIndex,
    String? contentJson,
  }) async {
    try {
      final response = await _dio.post('Lesson', data: {
        'title': title,
        'topicId': topicId,
        'description': description,
        'lessonType': lessonType,
        'difficulty': difficulty,
        'skillFocus': skillFocus,
        'durationSeconds': durationSeconds,
        'thumbnailUrl': thumbnailUrl,
        'audioUrl': audioUrl,
        'orderIndex': orderIndex,
        'contentJson': contentJson,
      });
      return Lesson.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Lesson> updateLesson({
    required String lessonId,
    required String title,
    String? description,
    String? lessonType,
    String? difficulty,
    String? skillFocus,
    int? durationSeconds,
    String? thumbnailUrl,
    String? audioUrl,
    int? orderIndex,
    String? contentJson,
    bool? isPublished,
  }) async {
    try {
      final response = await _dio.put('Lesson/$lessonId', data: {
        'title': title,
        'description': description,
        'lessonType': lessonType,
        'difficulty': difficulty,
        'skillFocus': skillFocus,
        'durationSeconds': durationSeconds,
        'thumbnailUrl': thumbnailUrl,
        'audioUrl': audioUrl,
        'orderIndex': orderIndex,
        'contentJson': contentJson,
        'isPublished': isPublished ?? true,
      });
      return Lesson.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await _dio.delete('Lesson/$lessonId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> publishLesson(String lessonId) async {
    try {
      await _dio.patch('Lesson/$lessonId/publish');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unpublishLesson(String lessonId) async {
    try {
      await _dio.patch('Lesson/$lessonId/unpublish');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreLesson(String lessonId) async {
    try {
      await _dio.patch('Lesson/$lessonId/restore');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> hardDeleteLesson(String lessonId) async {
    try {
      await _dio.delete('Lesson/$lessonId/hard');
    } catch (e) {
      rethrow;
    }
  }
}
