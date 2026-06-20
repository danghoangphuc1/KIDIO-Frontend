import '../models/kidio_models.dart';
import '../services/tts_api.dart';

class TtsRepository {
  final TtsApi _api;

  TtsRepository(this._api);

  Future<TtsResponse> synthesize(String text, {String? voiceName}) =>
      _api.synthesize(text, voiceName: voiceName);

  Future<TtsResponse> synthesizeLesson(String lessonId) =>
      _api.synthesizeLesson(lessonId);

  Future<List<TtsVoice>> getVoices() => _api.getVoices();
}
