import '../models/kidio_models.dart';
import '../services/vocabulary_api.dart';

class VocabularyRepository {
  final VocabularyApi _api;

  VocabularyRepository(this._api);

  Future<List<Vocabulary>> getByLesson(String lessonId) => _api.getByLesson(lessonId);
  Future<Vocabulary> getById(String vocabId) => _api.getById(vocabId);

  Future<List<Vocabulary>> search(String keyword, {String? lessonId}) =>
      _api.search(keyword, lessonId: lessonId);
}
