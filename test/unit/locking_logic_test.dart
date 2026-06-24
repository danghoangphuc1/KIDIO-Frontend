import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('kidio_cache');
  });

  tearDown(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  test('Calculate dynamic lesson percentage and unlocking rules', () async {
    const childId = 'child_123';
    const lessonId1 = 'lesson_1';

    // Helper function equivalent to _isLessonCompletedLocally
    bool isLessonCompletedLocally(String lessonId) {
      int completedGames = 0;
      if (box.get('${childId}_lesson_${lessonId}_vocab', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_listening', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_pron', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_quiz', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_boss', defaultValue: false) == true) completedGames++;
      return completedGames == 5;
    }

    // Helper function to calculate lesson percentage (each game counts 20%)
    double getLessonProgress(String lessonId) {
      int completedGames = 0;
      if (box.get('${childId}_lesson_${lessonId}_vocab', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_listening', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_pron', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_quiz', defaultValue: false) == true) completedGames++;
      if (box.get('${childId}_lesson_${lessonId}_boss', defaultValue: false) == true) completedGames++;
      return completedGames * 20.0;
    }

    // Initially lesson 1 is not completed
    expect(isLessonCompletedLocally(lessonId1), isFalse);
    expect(getLessonProgress(lessonId1), 0.0);

    // Complete 3 out of 5 games of lesson 1
    await box.put('${childId}_lesson_${lessonId1}_vocab', true);
    await box.put('${childId}_lesson_${lessonId1}_listening', true);
    await box.put('${childId}_lesson_${lessonId1}_pron', true);

    expect(isLessonCompletedLocally(lessonId1), isFalse);
    expect(getLessonProgress(lessonId1), 60.0);

    // Complete the remaining games of lesson 1
    await box.put('${childId}_lesson_${lessonId1}_quiz', true);
    await box.put('${childId}_lesson_${lessonId1}_boss', true);

    expect(isLessonCompletedLocally(lessonId1), isTrue);
    expect(getLessonProgress(lessonId1), 100.0);

    // Lesson 2 is unlocked if lesson 1 is completed
    bool isLesson2Unlocked = isLessonCompletedLocally(lessonId1);
    expect(isLesson2Unlocked, isTrue);
  });
}
