import 'package:hive_flutter/hive_flutter.dart';
import '../models/kidio_models.dart';

class CacheService {
  static const String _boxName = 'kidio_cache';

  Future<void> saveTopicsPage(int page, PagedResult<Topic> result) async {
    final box = Hive.box(_boxName);
    await box.put('topics_page_$page', result.items.map((e) => e.toJson()).toList());
    await box.put('topics_total_$page', result.totalCount);
  }

  List<Topic>? getTopicsPage(int page) {
    final box = Hive.box(_boxName);
    final data = box.get('topics_page_$page');
    if (data == null) return null;
    return (data as List).map((e) => Topic.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  int getTotalCountForPage(int page) {
    final box = Hive.box(_boxName);
    return box.get('topics_total_$page', defaultValue: 0);
  }

  Future<void> saveTopic(Topic topic) async {
    final box = Hive.box(_boxName);
    await box.put('topic_${topic.id}', topic.toJson());
  }

  Topic? getTopic(String id) {
    final box = Hive.box(_boxName);
    final data = box.get('topic_$id');
    return data != null ? Topic.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  Future<void> saveLessonsForTopic(String topicId, List<Lesson> lessons) async {
    final box = Hive.box(_boxName);
    await box.put('lessons_topic_$topicId', lessons.map((e) => e.toJson()).toList());
  }

  List<Lesson>? getLessonsForTopic(String topicId) {
    final box = Hive.box(_boxName);
    final data = box.get('lessons_topic_$topicId');
    if (data == null) return null;
    return (data as List).map((e) => Lesson.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveLesson(Lesson lesson) async {
    final box = Hive.box(_boxName);
    await box.put('lesson_${lesson.id}', lesson.toJson());
  }

  Lesson? getLesson(String id) {
    final box = Hive.box(_boxName);
    final data = box.get('lesson_$id');
    return data != null ? Lesson.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  Future<void> saveActivityStatus(String childId, String lessonId, String activityKey, bool isCompleted) async {
    final box = Hive.box(_boxName);
    await box.put('activity_status_${childId}_${lessonId}_$activityKey', isCompleted);
  }

  bool getActivityStatus(String childId, String lessonId, String activityKey) {
    final box = Hive.box(_boxName);
    return box.get('activity_status_${childId}_${lessonId}_$activityKey', defaultValue: false);
  }

  Future<void> clearActivityStatuses(String childId, String lessonId) async {
    final box = Hive.box(_boxName);
    await box.delete('activity_status_${childId}_${lessonId}_vocab');
    await box.delete('activity_status_${childId}_${lessonId}_listening');
    await box.delete('activity_status_${childId}_${lessonId}_pron');
    await box.delete('activity_status_${childId}_${lessonId}_quiz');
    await box.delete('activity_status_${childId}_${lessonId}_boss');
  }
}
