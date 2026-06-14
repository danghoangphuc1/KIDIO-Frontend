import '../models/kidio_models.dart';
import '../services/progress_api.dart';

class ProgressRepository {
  final ProgressApi _progressApi;

  ProgressRepository(this._progressApi);

  Future<LessonProgress> submitProgress({
    required String childId,
    required String lessonId,
    required int scorePercent,
    required int timeSpentSeconds,
  }) => _progressApi.submitProgress(
      childId: childId,
      lessonId: lessonId,
      scorePercent: scorePercent,
      timeSpentSeconds: timeSpentSeconds);

  Future<List<LessonProgress>> getRecentActivities(String childId) =>
      _progressApi.getRecentActivities(childId);

  Future<LessonProgress?> getLessonProgress(String childId, String lessonId) =>
      _progressApi.getLessonProgress(childId, lessonId);

  Future<ChildProgressSummary> getChildSummary(String childId) =>
      _progressApi.getChildSummary(childId);

  Future<List<LessonProgress>> getCompletedLessons(String childId) =>
      _progressApi.getCompletedLessons(childId);
}
