import '../models/kidio_models.dart';
import '../services/vocabulary_api.dart';

class VocabularyRepository {
  final VocabularyApi _api;

  VocabularyRepository(this._api);

  Future<List<Vocabulary>> getByLesson(String lessonId) => _api.getByLesson(lessonId);
  Future<Vocabulary> getById(String vocabId) => _api.getById(vocabId);

  Future<List<Vocabulary>> search(String keyword, {String? lessonId}) =>
      _api.search(keyword, lessonId: lessonId);

  Future<PagedResult<Vocabulary>> getPaged({int pageNumber = 1, int pageSize = 10, String? lessonId}) =>
      _api.getPaged(pageNumber: pageNumber, pageSize: pageSize, lessonId: lessonId);

  Future<List<Vocabulary>> getAll() => _api.getAll();

  Future<Vocabulary> createVocabulary({
    required String word,
    required String meaning,
    String? phoneticText,
    String? audioUrl,
    String? imageUrl,
    int? orderIndex,
  }) => _api.createVocabulary(
      word: word,
      meaning: meaning,
      phoneticText: phoneticText,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      orderIndex: orderIndex,
    );

  Future<Vocabulary> updateVocabulary({
    required String vocabId,
    required String word,
    required String meaning,
    String? phoneticText,
    String? audioUrl,
    String? imageUrl,
    int? orderIndex,
  }) => _api.updateVocabulary(
      vocabId: vocabId,
      word: word,
      meaning: meaning,
      phoneticText: phoneticText,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      orderIndex: orderIndex,
    );

  Future<void> deleteVocabulary(String vocabId) => _api.deleteVocabulary(vocabId);

  Future<void> restoreVocabulary(String vocabId) => _api.restoreVocabulary(vocabId);

  Future<void> hardDeleteVocabulary(String vocabId) => _api.hardDeleteVocabulary(vocabId);
}
