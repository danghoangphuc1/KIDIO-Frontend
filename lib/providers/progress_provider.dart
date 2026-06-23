import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/kidio_models.dart';
import '../repositories/progress_repository.dart';
import '../repositories/achievement_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _progressRepository;
  final AchievementRepository _achievementRepository;

  ProgressProvider(this._progressRepository, this._achievementRepository);

  List<LessonProgress> _recentActivities = [];
  List<Achievement> _achievements = [];
  List<AchievementDefinition> _activeDefinitions = [];
  List<LessonProgress> _completedLessons = [];
  ChildProgressSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  List<LessonProgress> get recentActivities => _recentActivities;
  List<Achievement> get achievements => _achievements;
  List<AchievementDefinition> get activeDefinitions => _activeDefinitions;
  List<LessonProgress> get completedLessons => _completedLessons;
  ChildProgressSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearProgress() {
    _recentActivities = [];
    _achievements = [];
    _activeDefinitions = [];
    _completedLessons = [];
    _summary = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadChildProgress(String childId) async {
    _isLoading = true;
    _errorMessage = null;
    _recentActivities = [];
    _achievements = [];
    _completedLessons = [];
    _summary = null;
    notifyListeners();

    final box = Hive.box('kidio_cache');

    // 1. Try to sync pending progress entries if any exist
    try {
      final List<dynamic>? pendingRaw = box.get('offline_pending_progress_$childId');
      if (pendingRaw != null && pendingRaw.isNotEmpty) {
        final pending = List<Map<String, dynamic>>.from(pendingRaw.map((e) => Map<String, dynamic>.from(e)));
        final List<Map<String, dynamic>> remaining = List.from(pending);
        
        for (var item in pending) {
          try {
            await _progressRepository.submitProgress(
              childId: item['childId'],
              lessonId: item['lessonId'],
              scorePercent: item['scorePercent'],
              timeSpentSeconds: item['timeSpentSeconds'],
            );
            remaining.removeWhere((e) => e['lessonId'] == item['lessonId']);
          } catch (apiError) {
            debugPrint("Connection still offline or sync failed: $apiError");
            break; // Stop syncing remaining if we are still offline
          }
        }
        await box.put('offline_pending_progress_$childId', remaining);
      }
    } catch (e) {
      debugPrint("Error syncing offline progress: $e");
    }

    // 2. Load latest progress from API
    try {
      final results = await Future.wait([
        _progressRepository.getRecentActivities(childId),
        _achievementRepository.getByChild(childId),
        _progressRepository.getChildSummary(childId),
        _progressRepository.getCompletedLessons(childId),
        _achievementRepository.getActiveDefinitions(),
      ]);
      
      _recentActivities = results[0] as List<LessonProgress>;
      _achievements = results[1] as List<Achievement>;
      _summary = results[2] as ChildProgressSummary;
      _completedLessons = results[3] as List<LessonProgress>;
      _activeDefinitions = results[4] as List<AchievementDefinition>;

      // Cache the loaded data
      await box.put('cached_recent_activities_$childId', _recentActivities.map((e) => e.toJson()).toList());
      await box.put('cached_achievements_$childId', _achievements.map((e) => e.toJson()).toList());
      await box.put('cached_active_definitions_$childId', _activeDefinitions.map((e) => e.toJson()).toList());
      await box.put('cached_summary_$childId', _summary!.toJson());
      await box.put('cached_completed_lessons_$childId', _completedLessons.map((e) => e.toJson()).toList());
    } catch (e) {
      _errorMessage = e.toString();
      // Fallback to offline cached data
      _loadOfflineFallback(childId);
    } finally {
      // 3. Merge remaining offline unsynced progress entries to ensure correct UI feedback
      _mergeOfflineProgress(childId);
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
    final box = Hive.box('kidio_cache');

    // Save locally to offline queue first
    final List<dynamic> pendingRaw = box.get('offline_pending_progress_$childId') ?? [];
    final pending = List<Map<String, dynamic>>.from(pendingRaw.map((e) => Map<String, dynamic>.from(e)));
    
    final exists = pending.any((e) => e['lessonId'] == lessonId);
    if (!exists) {
      pending.add({
        'childId': childId,
        'lessonId': lessonId,
        'scorePercent': scorePercent,
        'timeSpentSeconds': timeSpentSeconds,
        'completedAt': DateTime.now().toIso8601String(),
      });
      await box.put('offline_pending_progress_$childId', pending);
    }

    try {
      final result = await _progressRepository.submitProgress(
        childId: childId,
        lessonId: lessonId,
        scorePercent: scorePercent,
        timeSpentSeconds: timeSpentSeconds,
      );
      
      // Successfully submitted to server! Remove from pending list
      final currentPending = box.get('offline_pending_progress_$childId') ?? [];
      final updated = List<Map<String, dynamic>>.from(currentPending.map((e) => Map<String, dynamic>.from(e)));
      updated.removeWhere((e) => e['lessonId'] == lessonId);
      await box.put('offline_pending_progress_$childId', updated);

      // Reload child progress from server
      await loadChildProgress(childId);
      return result;
    } catch (e) {
      debugPrint("Offline: failed to submit progress, keeping in queue: $e");
      
      // Load offline cached data and merge current queue for immediate UI satisfaction
      _loadOfflineFallback(childId);
      _mergeOfflineProgress(childId);
      notifyListeners();

      // Return a simulated LessonProgress representing the locally completed lesson
      return LessonProgress(
        id: 'local_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
        childId: childId,
        lessonId: lessonId,
        isCompleted: scorePercent >= 60,
        starsEarned: scorePercent >= 90 ? 3 : (scorePercent >= 70 ? 2 : (scorePercent >= 60 ? 1 : 0)),
        scorePercent: scorePercent,
        timeSpentSeconds: timeSpentSeconds,
        completedAt: DateTime.now(),
      );
    }
  }

  void _loadOfflineFallback(String childId) {
    final box = Hive.box('kidio_cache');
    
    // Load recent activities
    final recentRaw = box.get('cached_recent_activities_$childId');
    if (recentRaw != null) {
      _recentActivities = (recentRaw as List)
          .map((e) => LessonProgress.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      _recentActivities = [];
    }

    // Load achievements
    final achievementsRaw = box.get('cached_achievements_$childId');
    if (achievementsRaw != null) {
      _achievements = (achievementsRaw as List)
          .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      _achievements = [];
    }

    // Load active definitions
    final activeDefinitionsRaw = box.get('cached_active_definitions_$childId');
    if (activeDefinitionsRaw != null) {
      _activeDefinitions = (activeDefinitionsRaw as List)
          .map((e) => AchievementDefinition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      _activeDefinitions = [];
    }

    // Load summary
    final summaryRaw = box.get('cached_summary_$childId');
    if (summaryRaw != null) {
      _summary = ChildProgressSummary.fromJson(Map<String, dynamic>.from(summaryRaw));
    } else {
      _summary = null;
    }

    // Load completed lessons
    final completedRaw = box.get('cached_completed_lessons_$childId');
    if (completedRaw != null) {
      _completedLessons = (completedRaw as List)
          .map((e) => LessonProgress.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      _completedLessons = [];
    }
  }

  void _mergeOfflineProgress(String childId) {
    final box = Hive.box('kidio_cache');
    final List<dynamic>? pendingRaw = box.get('offline_pending_progress_$childId');
    if (pendingRaw == null || pendingRaw.isEmpty) return;

    final pending = pendingRaw.map((e) => Map<String, dynamic>.from(e)).toList();

    for (var item in pending) {
      final lessonId = item['lessonId'];
      final scorePercent = item['scorePercent'];
      final timeSpentSeconds = item['timeSpentSeconds'];
      final isCompleted = scorePercent >= 60;
      final starsEarned = scorePercent >= 90 ? 3 : (scorePercent >= 70 ? 2 : (scorePercent >= 60 ? 1 : 0));
      final completedAt = DateTime.parse(item['completedAt']);

      final alreadyCompleted = _completedLessons.any((l) => l.lessonId == lessonId);
      
      // 1. Add/Update in completedLessons
      if (isCompleted && !alreadyCompleted) {
        _completedLessons.insert(0, LessonProgress(
          id: 'local_${lessonId}_${completedAt.millisecondsSinceEpoch}',
          childId: childId,
          lessonId: lessonId,
          isCompleted: true,
          starsEarned: starsEarned,
          scorePercent: scorePercent,
          timeSpentSeconds: timeSpentSeconds,
          completedAt: completedAt,
        ));
      }

      // 2. Add/Update in recent activities
      final alreadyInRecent = _recentActivities.any((l) => l.lessonId == lessonId);
      if (!alreadyInRecent) {
        _recentActivities.insert(0, LessonProgress(
          id: 'local_${lessonId}_${completedAt.millisecondsSinceEpoch}',
          childId: childId,
          lessonId: lessonId,
          isCompleted: isCompleted,
          starsEarned: starsEarned,
          scorePercent: scorePercent,
          timeSpentSeconds: timeSpentSeconds,
          completedAt: completedAt,
        ));
      }

      // 3. Update child summary
      if (_summary != null) {
        int starsToAdd = 0;
        int completedLessonsIncrement = 0;

        if (isCompleted && !alreadyCompleted) {
          completedLessonsIncrement = 1;
          starsToAdd = starsEarned;
        }

        // Find topicId from cached lessons
        String? topicId;
        for (var key in box.keys) {
          if (key.toString().startsWith('lessons_topic_')) {
            final List<dynamic>? cachedLessons = box.get(key);
            if (cachedLessons != null) {
              final containsLesson = cachedLessons.any((l) => l['id'] == lessonId);
              if (containsLesson) {
                topicId = key.toString().replaceFirst('lessons_topic_', '');
                break;
              }
            }
          }
        }

        if (topicId == null) {
          for (var page = 1; page <= 5; page++) {
            final List<dynamic>? cachedTopics = box.get('topics_page_$page');
            if (cachedTopics != null) {
              for (var t in cachedTopics) {
                final lessons = t['lessons'] as List<dynamic>?;
                if (lessons != null && lessons.any((l) => l['id'] == lessonId)) {
                  topicId = t['id'];
                  break;
                }
              }
            }
            if (topicId != null) break;
          }
        }

        List<TopicProgressItem> updatedTopicProgresses = List.from(_summary!.topicProgresses);
        if (topicId != null) {
          final tpIdx = updatedTopicProgresses.indexWhere((tp) => tp.topicId == topicId);
          if (tpIdx != -1) {
            final currentItem = updatedTopicProgresses[tpIdx];
            final newCompleted = currentItem.completedLessons + completedLessonsIncrement;
            final newPercent = currentItem.totalLessons == 0 
                ? 0 
                : (newCompleted * 100 ~/ currentItem.totalLessons);
            
            updatedTopicProgresses[tpIdx] = TopicProgressItem(
              topicId: currentItem.topicId,
              topicName: currentItem.topicName,
              totalLessons: currentItem.totalLessons,
              completedLessons: newCompleted,
              progressPercent: newPercent > 100 ? 100 : newPercent,
            );
          }
        }

        _summary = ChildProgressSummary(
          childId: _summary!.childId,
          childName: _summary!.childName,
          totalLessonsCompleted: _summary!.totalLessonsCompleted + completedLessonsIncrement,
          totalStars: _summary!.totalStars + starsToAdd,
          currentStreakDays: _summary!.currentStreakDays,
          topicProgresses: updatedTopicProgresses,
        );
      }
    }
  }

  Future<LessonProgress?> checkLessonCompletion(String childId, String lessonId) async {
    // Check locally first
    final box = Hive.box('kidio_cache');
    final List<dynamic>? pendingRaw = box.get('offline_pending_progress_$childId');
    if (pendingRaw != null && pendingRaw.isNotEmpty) {
      final match = pendingRaw.firstWhere(
        (e) => e['lessonId'] == lessonId,
        orElse: () => null,
      );
      if (match != null) {
        final completedAt = DateTime.parse(match['completedAt']);
        final scorePercent = match['scorePercent'];
        final timeSpentSeconds = match['timeSpentSeconds'];
        return LessonProgress(
          id: 'local_${lessonId}_${completedAt.millisecondsSinceEpoch}',
          childId: childId,
          lessonId: lessonId,
          isCompleted: scorePercent >= 60,
          starsEarned: scorePercent >= 90 ? 3 : (scorePercent >= 70 ? 2 : (scorePercent >= 60 ? 1 : 0)),
          scorePercent: scorePercent,
          timeSpentSeconds: timeSpentSeconds,
          completedAt: completedAt,
        );
      }
    }
    
    // Default to API check
    return await _progressRepository.getLessonProgress(childId, lessonId);
  }
}
