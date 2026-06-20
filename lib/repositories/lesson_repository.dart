import '../models/kidio_models.dart';
import '../services/lesson_api.dart';

class LessonRepository {
  final LessonApi _lessonApi;

  LessonRepository(this._lessonApi);

  Future<PagedResult<Lesson>> getAllLessons({
    int pageNumber = 1,
    int pageSize = 10,
    String? q,
  }) => _lessonApi.getAllLessons(pageNumber: pageNumber, pageSize: pageSize, q: q);

  Future<List<Lesson>> getLessonsByTopic(String topicId) => _lessonApi.getLessonsByTopic(topicId);

  Future<Lesson> getLessonById(String lessonId) => _lessonApi.getLessonById(lessonId);

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
  }) => _lessonApi.createLesson(
      title: title,
      topicId: topicId,
      description: description,
      lessonType: lessonType,
      difficulty: difficulty,
      skillFocus: skillFocus,
      durationSeconds: durationSeconds,
      thumbnailUrl: thumbnailUrl,
      audioUrl: audioUrl,
      orderIndex: orderIndex,
      contentJson: contentJson,
    );

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
  }) => _lessonApi.updateLesson(
      lessonId: lessonId,
      title: title,
      description: description,
      lessonType: lessonType,
      difficulty: difficulty,
      skillFocus: skillFocus,
      durationSeconds: durationSeconds,
      thumbnailUrl: thumbnailUrl,
      audioUrl: audioUrl,
      orderIndex: orderIndex,
      contentJson: contentJson,
      isPublished: isPublished,
    );

  Future<void> deleteLesson(String lessonId) => _lessonApi.deleteLesson(lessonId);

  Future<void> publishLesson(String lessonId) => _lessonApi.publishLesson(lessonId);

  Future<void> unpublishLesson(String lessonId) => _lessonApi.unpublishLesson(lessonId);

  Future<void> restoreLesson(String lessonId) => _lessonApi.restoreLesson(lessonId);

  Future<void> hardDeleteLesson(String lessonId) => _lessonApi.hardDeleteLesson(lessonId);
}
