import 'dart:io';
import '../models/kidio_models.dart';
import '../services/pronunciation_api.dart';

class PronunciationRepository {
  final PronunciationApi _api;

  PronunciationRepository(this._api);

  Future<PronunciationScore> submitPronunciation({
    required String vocabularyId,
    required File audioFile,
    String? lessonId,
  }) => _api.submitPronunciation(
    vocabularyId: vocabularyId,
    audioFile: audioFile,
    lessonId: lessonId,
  );

  Future<List<PronunciationScore>> getChildHistory({int page = 1, int pageSize = 10}) =>
      _api.getChildHistory(page: page, pageSize: pageSize);

  Future<List<PronunciationScore>> getVocabularyHistory(String vocabularyId) =>
      _api.getVocabularyHistory(vocabularyId);
}
