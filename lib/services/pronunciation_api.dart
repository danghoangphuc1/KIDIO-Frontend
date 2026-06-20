import 'dart:io';
import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class PronunciationApi {
  final Dio _dio;

  PronunciationApi(this._dio);

  Future<PronunciationScore> submitPronunciation({
    required String vocabularyId,
    required File audioFile,
    String? lessonId,
  }) async {
    try {
      String fileName = audioFile.path.split('/').last;
      if (!fileName.toLowerCase().endsWith('.wav')) {
        fileName = '${fileName.split('.').first}.wav';
      }
      FormData formData = FormData.fromMap({
        'VocabularyId': vocabularyId,
        if (lessonId != null) 'LessonId': lessonId,
        'AudioFile': await MultipartFile.fromFile(audioFile.path, filename: fileName),
      });

      final response = await _dio.post('Pronunciation/submit', data: formData);
      return PronunciationScore.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PronunciationScore>> getChildHistory({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get('Pronunciation/history', queryParameters: {
        'pageNumber': page,
        'pageSize': pageSize,
      });
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => PronunciationScore.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PronunciationScore>> getVocabularyHistory(String vocabularyId) async {
    try {
      final response = await _dio.get('Pronunciation/vocabulary/$vocabularyId');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => PronunciationScore.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
