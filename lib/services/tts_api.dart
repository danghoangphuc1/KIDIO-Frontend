import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class TtsApi {
  final Dio _dio;

  TtsApi(this._dio);

  Future<TtsResponse> synthesize(String text, {String? voiceName}) async {
    try {
      final response = await _dio.post('tts/synthesize', data: {
        'text': text,
        if (voiceName != null) 'voiceName': voiceName,
      });
      return TtsResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<TtsResponse> synthesizeLesson(String lessonId) async {
    try {
      final response = await _dio.post('tts/lesson/$lessonId', data: {});
      return TtsResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
