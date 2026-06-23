// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kidio_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vocabulary _$VocabularyFromJson(Map<String, dynamic> json) => Vocabulary(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      phoneticText: json['phoneticText'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
    );

Map<String, dynamic> _$VocabularyToJson(Vocabulary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'word': instance.word,
      'meaning': instance.meaning,
      'phoneticText': instance.phoneticText,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'exampleSentence': instance.exampleSentence,
      'orderIndex': instance.orderIndex,
    };

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lessonType: json['lessonType'] as String?,
      difficulty: json['difficulty'] as String?,
      skillFocus: json['skillFocus'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
      isPublished: json['isPublished'] as bool,
      contentJson: json['contentJson'] as String?,
      vocabularies: (json['vocabularies'] as List<dynamic>?)
          ?.map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'lessonType': instance.lessonType,
      'difficulty': instance.difficulty,
      'skillFocus': instance.skillFocus,
      'durationSeconds': instance.durationSeconds,
      'thumbnailUrl': instance.thumbnailUrl,
      'audioUrl': instance.audioUrl,
      'orderIndex': instance.orderIndex,
      'isPublished': instance.isPublished,
      'contentJson': instance.contentJson,
      'vocabularies': instance.vocabularies?.map((e) => e.toJson()).toList(),
    };

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
      isActive: json['isActive'] as bool?,
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalLessons: (json['totalLessons'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'orderIndex': instance.orderIndex,
      'isActive': instance.isActive,
      'lessons': instance.lessons?.map((e) => e.toJson()).toList(),
      'totalLessons': instance.totalLessons,
    };

LessonProgress _$LessonProgressFromJson(Map<String, dynamic> json) =>
    LessonProgress(
      id: json['id'] as String,
      childId: json['childId'] as String,
      lessonId: json['lessonId'] as String,
      lessonTitle: json['lessonTitle'] as String?,
      isCompleted: json['isCompleted'] as bool,
      starsEarned: (json['starsEarned'] as num).toInt(),
      scorePercent: (json['scorePercent'] as num).toInt(),
      timeSpentSeconds: (json['timeSpentSeconds'] as num).toInt(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      newAchievements: (json['newAchievements'] as List<dynamic>?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LessonProgressToJson(LessonProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'childId': instance.childId,
      'lessonId': instance.lessonId,
      'lessonTitle': instance.lessonTitle,
      'isCompleted': instance.isCompleted,
      'starsEarned': instance.starsEarned,
      'scorePercent': instance.scorePercent,
      'timeSpentSeconds': instance.timeSpentSeconds,
      'completedAt': instance.completedAt?.toIso8601String(),
      'newAchievements': instance.newAchievements,
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      title: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['badgeUrl'] as String?,
      achievementType: json['type'] as String?,
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.title,
      'description': instance.description,
      'badgeUrl': instance.iconUrl,
      'type': instance.achievementType,
      'earnedAt': instance.earnedAt?.toIso8601String(),
    };

ChildProgressSummary _$ChildProgressSummaryFromJson(
        Map<String, dynamic> json) =>
    ChildProgressSummary(
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      totalLessonsCompleted: (json['totalLessonsCompleted'] as num).toInt(),
      totalStars: (json['totalStars'] as num).toInt(),
      currentStreakDays: (json['currentStreakDays'] as num).toInt(),
      topicProgresses: (json['topicProgresses'] as List<dynamic>)
          .map((e) => TopicProgressItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChildProgressSummaryToJson(
        ChildProgressSummary instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'childName': instance.childName,
      'totalLessonsCompleted': instance.totalLessonsCompleted,
      'totalStars': instance.totalStars,
      'currentStreakDays': instance.currentStreakDays,
      'topicProgresses': instance.topicProgresses,
    };

TopicProgressItem _$TopicProgressItemFromJson(Map<String, dynamic> json) =>
    TopicProgressItem(
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      totalLessons: (json['totalLessons'] as num).toInt(),
      completedLessons: (json['completedLessons'] as num).toInt(),
      progressPercent: (json['progressPercent'] as num).toInt(),
    );

Map<String, dynamic> _$TopicProgressItemToJson(TopicProgressItem instance) =>
    <String, dynamic>{
      'topicId': instance.topicId,
      'topicName': instance.topicName,
      'totalLessons': instance.totalLessons,
      'completedLessons': instance.completedLessons,
      'progressPercent': instance.progressPercent,
    };

PronunciationScore _$PronunciationScoreFromJson(Map<String, dynamic> json) =>
    PronunciationScore(
      id: json['id'] as String,
      word: json['word'] as String,
      accuracyScore: (json['accuracyScore'] as num).toInt(),
      fluencyScore: (json['fluencyScore'] as num).toInt(),
      completenessScore: (json['completenessScore'] as num).toInt(),
      overallScore: (json['overallScore'] as num).toInt(),
      isPassed: json['isPassed'] as bool,
      feedback: json['feedback'] as String,
      audioStorageUrl: json['audioStorageUrl'] as String,
    );

Map<String, dynamic> _$PronunciationScoreToJson(PronunciationScore instance) =>
    <String, dynamic>{
      'id': instance.id,
      'word': instance.word,
      'accuracyScore': instance.accuracyScore,
      'fluencyScore': instance.fluencyScore,
      'completenessScore': instance.completenessScore,
      'overallScore': instance.overallScore,
      'isPassed': instance.isPassed,
      'feedback': instance.feedback,
      'audioStorageUrl': instance.audioStorageUrl,
    };

TtsResponse _$TtsResponseFromJson(Map<String, dynamic> json) => TtsResponse(
      audioUrl: json['audioUrl'] as String,
      fileName: json['fileName'] as String?,
      isCached: json['isCached'] as bool?,
    );

Map<String, dynamic> _$TtsResponseToJson(TtsResponse instance) =>
    <String, dynamic>{
      'audioUrl': instance.audioUrl,
      'fileName': instance.fileName,
      'isCached': instance.isCached,
    };

PagedResult<T> _$PagedResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PagedResult<T>(
      items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
      totalCount: (json['totalCount'] as num).toInt(),
      page: (json['pageNumber'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
    );

Map<String, dynamic> _$PagedResultToJson<T>(
  PagedResult<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'items': instance.items.map(toJsonT).toList(),
      'totalCount': instance.totalCount,
      'pageNumber': instance.page,
      'pageSize': instance.pageSize,
    };

ParentDashboardChildItemResponse _$ParentDashboardChildItemResponseFromJson(
        Map<String, dynamic> json) =>
    ParentDashboardChildItemResponse(
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      age: (json['age'] as num).toInt(),
      avatarUrl: json['avatarUrl'] as String?,
      completedLessons: (json['completedLessons'] as num).toInt(),
      totalStars: (json['totalStars'] as num).toInt(),
      currentStreakDays: (json['currentStreakDays'] as num).toInt(),
      timeSpentSeconds: (json['timeSpentSeconds'] as num).toInt(),
      completionPercent: (json['completionPercent'] as num).toInt(),
      lastLessonAt: json['lastLessonAt'] == null
          ? null
          : DateTime.parse(json['lastLessonAt'] as String),
    );

Map<String, dynamic> _$ParentDashboardChildItemResponseToJson(
        ParentDashboardChildItemResponse instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'childName': instance.childName,
      'age': instance.age,
      'avatarUrl': instance.avatarUrl,
      'completedLessons': instance.completedLessons,
      'totalStars': instance.totalStars,
      'currentStreakDays': instance.currentStreakDays,
      'timeSpentSeconds': instance.timeSpentSeconds,
      'completionPercent': instance.completionPercent,
      'lastLessonAt': instance.lastLessonAt?.toIso8601String(),
    };

WeeklyProgressResponse _$WeeklyProgressResponseFromJson(
        Map<String, dynamic> json) =>
    WeeklyProgressResponse(
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      completedLessons: (json['completedLessons'] as num).toInt(),
      timeSpentSeconds: (json['timeSpentSeconds'] as num).toInt(),
      activeChildrenCount: (json['activeChildrenCount'] as num).toInt(),
    );

Map<String, dynamic> _$WeeklyProgressResponseToJson(
        WeeklyProgressResponse instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart.toIso8601String(),
      'weekEnd': instance.weekEnd.toIso8601String(),
      'completedLessons': instance.completedLessons,
      'timeSpentSeconds': instance.timeSpentSeconds,
      'activeChildrenCount': instance.activeChildrenCount,
    };

ChildComparisonResponse _$ChildComparisonResponseFromJson(
        Map<String, dynamic> json) =>
    ChildComparisonResponse(
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      completedLessons: (json['completedLessons'] as num).toInt(),
      totalStars: (json['totalStars'] as num).toInt(),
      timeSpentSeconds: (json['timeSpentSeconds'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
    );

Map<String, dynamic> _$ChildComparisonResponseToJson(
        ChildComparisonResponse instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'childName': instance.childName,
      'completedLessons': instance.completedLessons,
      'totalStars': instance.totalStars,
      'timeSpentSeconds': instance.timeSpentSeconds,
      'rank': instance.rank,
    };

ParentDashboardOverviewResponse _$ParentDashboardOverviewResponseFromJson(
        Map<String, dynamic> json) =>
    ParentDashboardOverviewResponse(
      parentId: json['parentId'] as String,
      parentName: json['parentName'] as String,
      totalChildren: (json['totalChildren'] as num).toInt(),
      totalPublishedLessons: (json['totalPublishedLessons'] as num).toInt(),
      totalLessonsCompleted: (json['totalLessonsCompleted'] as num).toInt(),
      totalStars: (json['totalStars'] as num).toInt(),
      totalTimeSpentSeconds: (json['totalTimeSpentSeconds'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      children: (json['children'] as List<dynamic>)
          .map((e) => ParentDashboardChildItemResponse.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      weeklyProgress: (json['weeklyProgress'] as List<dynamic>)
          .map(
              (e) => WeeklyProgressResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      comparisons: (json['comparisons'] as List<dynamic>)
          .map((e) =>
              ChildComparisonResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ParentDashboardOverviewResponseToJson(
        ParentDashboardOverviewResponse instance) =>
    <String, dynamic>{
      'parentId': instance.parentId,
      'parentName': instance.parentName,
      'totalChildren': instance.totalChildren,
      'totalPublishedLessons': instance.totalPublishedLessons,
      'totalLessonsCompleted': instance.totalLessonsCompleted,
      'totalStars': instance.totalStars,
      'totalTimeSpentSeconds': instance.totalTimeSpentSeconds,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'children': instance.children.map((e) => e.toJson()).toList(),
      'weeklyProgress': instance.weeklyProgress.map((e) => e.toJson()).toList(),
      'comparisons': instance.comparisons.map((e) => e.toJson()).toList(),
    };

TtsVoice _$TtsVoiceFromJson(Map<String, dynamic> json) => TtsVoice(
      name: json['name'] as String,
      locale: json['locale'] as String,
      gender: json['gender'] as String,
    );

Map<String, dynamic> _$TtsVoiceToJson(TtsVoice instance) => <String, dynamic>{
      'name': instance.name,
      'locale': instance.locale,
      'gender': instance.gender,
    };

AchievementDefinition _$AchievementDefinitionFromJson(
        Map<String, dynamic> json) =>
    AchievementDefinition(
      id: json['id'] as String,
      type: json['type'] as String,
      threshold: (json['threshold'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      badgeUrl: json['badgeUrl'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$AchievementDefinitionToJson(
        AchievementDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'threshold': instance.threshold,
      'name': instance.name,
      'description': instance.description,
      'badgeUrl': instance.badgeUrl,
      'orderIndex': instance.orderIndex,
      'isActive': instance.isActive,
    };
