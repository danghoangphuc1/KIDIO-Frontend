import 'package:flutter/material.dart';
import '../models/kidio_models.dart';
import '../repositories/progress_repository.dart';
import '../repositories/achievement_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _progressRepository;
  final AchievementRepository _achievementRepository;

  ProgressProvider(this._progressRepository, this._achievementRepository);

  List<LessonProgress> _recentActivities = [];
  List<Achievement> _achievements = [];
  ChildProgressSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  List<LessonProgress> get recentActivities => _recentActivities;
  List<Achievement> get achievements => _achievements;
  ChildProgressSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadChildProgress(String childId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _progressRepository.getRecentActivities(childId),
        _achievementRepository.getByChild(childId),
        _progressRepository.getChildSummary(childId),
      ]);
      
      _recentActivities = results[0] as List<LessonProgress>;
      _achievements = results[1] as List<Achievement>;
      _summary = results[2] as ChildProgressSummary;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LessonProgress?> submitProgress({
    required String childId,
    required String lessonId,
    required int scorePercent,
    required int timeSpentSeconds,
  }) async {
    try {
      final result = await _progressRepository.submitProgress(
        childId: childId,
        lessonId: lessonId,
        scorePercent: scorePercent,
        timeSpentSeconds: timeSpentSeconds,
      );
      
      // Reload everything to get updated stars, streaks, and badges
      await loadChildProgress(childId);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<LessonProgress?> checkLessonCompletion(String childId, String lessonId) async {
    return await _progressRepository.getLessonProgress(childId, lessonId);
  }
}
