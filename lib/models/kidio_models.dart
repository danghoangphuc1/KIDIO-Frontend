import 'package:json_annotation/json_annotation.dart';

part 'kidio_models.g.dart';

@JsonSerializable(explicitToJson: true)
class Vocabulary {
  final String id;
  final String word;
  final String meaning;
  final String? phoneticText;
  final String? audioUrl;
  final String? imageUrl;
  final String? exampleSentence;
  final int orderIndex;

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    this.phoneticText,
    this.audioUrl,
    this.imageUrl,
    this.exampleSentence,
    required this.orderIndex,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) => _$VocabularyFromJson(json);
  Map<String, dynamic> toJson() => _$VocabularyToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Lesson {
  final String id;
  final String title;
  final String? description;
  final String? lessonType;
  final String? difficulty;
  final String? skillFocus;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final String? audioUrl;
  final int orderIndex;
  final bool isPublished;
  final String? contentJson;
  final List<Vocabulary>? vocabularies;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    this.lessonType,
    this.difficulty,
    this.skillFocus,
    this.durationSeconds,
    this.thumbnailUrl,
    this.audioUrl,
    required this.orderIndex,
    required this.isPublished,
    this.contentJson,
    this.vocabularies,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);
  Map<String, dynamic> toJson() => _$LessonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Topic {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int orderIndex;
  final bool? isActive;
  final List<Lesson>? lessons;
  final int? totalLessons;

  Topic({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.orderIndex,
    this.isActive,
    this.lessons,
    this.totalLessons,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}

class Child {
  final String id;
  final String name;
  final int age;
  final String? avatarUrl;
  final int totalStars;
  final int currentStreakDays;
  final DateTime? lastLessonAt;

  Child({
    required this.id,
    required this.name,
    required this.age,
    this.avatarUrl,
    this.totalStars = 0,
    this.currentStreakDays = 0,
    this.lastLessonAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    avatarUrl: json['avatarUrl'] as String?,
    totalStars: json['totalStars'] as int? ?? 0,
    currentStreakDays: json['currentStreakDays'] as int? ?? 0,
    lastLessonAt: json['lastLessonAt'] != null ? DateTime.parse(json['lastLessonAt'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'avatarUrl': avatarUrl,
    'totalStars': totalStars,
    'currentStreakDays': currentStreakDays,
    'lastLessonAt': lastLessonAt?.toIso8601String(),
  };
}

@JsonSerializable()
class LessonProgress {
  final String id;
  final String childId;
  final String lessonId;
  final bool isCompleted;
  final int starsEarned;
  final int scorePercent;
  final int timeSpentSeconds;
  final DateTime? completedAt;
  final List<Achievement>? newAchievements; // Huy hiệu mới nhận được

  LessonProgress({
    required this.id,
    required this.childId,
    required this.lessonId,
    required this.isCompleted,
    required this.starsEarned,
    required this.scorePercent,
    required this.timeSpentSeconds,
    this.completedAt,
    this.newAchievements,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) => _$LessonProgressFromJson(json);
  Map<String, dynamic> toJson() => _$LessonProgressToJson(this);
}

@JsonSerializable()
class Achievement {
  final String id;
  @JsonKey(name: 'name')
  final String title;
  final String? description;
  @JsonKey(name: 'badgeUrl')
  final String? iconUrl;
  final String? achievementType;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.title,
    this.description,
    this.iconUrl,
    this.achievementType,
    this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

@JsonSerializable()
class ChildProgressSummary {
  final String childId;
  final String childName;
  final int totalLessonsCompleted;
  final int totalStars;
  final int currentStreakDays;
  final List<TopicProgressItem> topicProgresses;

  ChildProgressSummary({
    required this.childId,
    required this.childName,
    required this.totalLessonsCompleted,
    required this.totalStars,
    required this.currentStreakDays,
    required this.topicProgresses,
  });

  factory ChildProgressSummary.fromJson(Map<String, dynamic> json) => _$ChildProgressSummaryFromJson(json);
}

@JsonSerializable()
class TopicProgressItem {
  final String topicId;
  final String topicName;
  final int totalLessons;
  final int completedLessons;
  final int progressPercent;

  TopicProgressItem({
    required this.topicId,
    required this.topicName,
    required this.totalLessons,
    required this.completedLessons,
    required this.progressPercent,
  });

  factory TopicProgressItem.fromJson(Map<String, dynamic> json) => _$TopicProgressItemFromJson(json);
}

@JsonSerializable()
class PronunciationScore {
  final String id;
  final String word;
  final int accuracyScore;
  final int fluencyScore;
  final int completenessScore;
  final int overallScore;
  final bool isPassed;
  final String feedback;
  final String audioStorageUrl;

  PronunciationScore({
    required this.id,
    required this.word,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.overallScore,
    required this.isPassed,
    required this.feedback,
    required this.audioStorageUrl,
  });

  factory PronunciationScore.fromJson(Map<String, dynamic> json) => _$PronunciationScoreFromJson(json);
  Map<String, dynamic> toJson() => _$PronunciationScoreToJson(this);
}

@JsonSerializable()
class TtsResponse {
  final String audioUrl;
  final String? fileName;
  final bool? isCached;

  TtsResponse({required this.audioUrl, this.fileName, this.isCached});

  factory TtsResponse.fromJson(Map<String, dynamic> json) => _$TtsResponseFromJson(json);
}

@JsonSerializable(genericArgumentFactories: true)
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  @JsonKey(name: 'pageNumber')
  final int page;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PagedResultFromJson(json, fromJsonT);
}

@JsonSerializable()
class ParentDashboardChildItemResponse {
  final String childId;
  final String childName;
  final int age;
  final String? avatarUrl;
  final int completedLessons;
  final int totalStars;
  final int currentStreakDays;
  final int timeSpentSeconds;
  final int completionPercent;
  final DateTime? lastLessonAt;

  ParentDashboardChildItemResponse({
    required this.childId,
    required this.childName,
    required this.age,
    this.avatarUrl,
    required this.completedLessons,
    required this.totalStars,
    required this.currentStreakDays,
    required this.timeSpentSeconds,
    required this.completionPercent,
    this.lastLessonAt,
  });

  factory ParentDashboardChildItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ParentDashboardChildItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ParentDashboardChildItemResponseToJson(this);
}

@JsonSerializable()
class WeeklyProgressResponse {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int completedLessons;
  final int timeSpentSeconds;
  final int activeChildrenCount;

  WeeklyProgressResponse({
    required this.weekStart,
    required this.weekEnd,
    required this.completedLessons,
    required this.timeSpentSeconds,
    required this.activeChildrenCount,
  });

  factory WeeklyProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$WeeklyProgressResponseFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyProgressResponseToJson(this);
}

@JsonSerializable()
class ChildComparisonResponse {
  final String childId;
  final String childName;
  final int completedLessons;
  final int totalStars;
  final int timeSpentSeconds;
  final int rank;

  ChildComparisonResponse({
    required this.childId,
    required this.childName,
    required this.completedLessons,
    required this.totalStars,
    required this.timeSpentSeconds,
    required this.rank,
  });

  factory ChildComparisonResponse.fromJson(Map<String, dynamic> json) =>
      _$ChildComparisonResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChildComparisonResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ParentDashboardOverviewResponse {
  final String parentId;
  final String parentName;
  final int totalChildren;
  final int totalPublishedLessons;
  final int totalLessonsCompleted;
  final int totalStars;
  final int totalTimeSpentSeconds;
  final DateTime generatedAt;
  final List<ParentDashboardChildItemResponse> children;
  final List<WeeklyProgressResponse> weeklyProgress;
  final List<ChildComparisonResponse> comparisons;

  ParentDashboardOverviewResponse({
    required this.parentId,
    required this.parentName,
    required this.totalChildren,
    required this.totalPublishedLessons,
    required this.totalLessonsCompleted,
    required this.totalStars,
    required this.totalTimeSpentSeconds,
    required this.generatedAt,
    required this.children,
    required this.weeklyProgress,
    required this.comparisons,
  });

  factory ParentDashboardOverviewResponse.fromJson(Map<String, dynamic> json) =>
      _$ParentDashboardOverviewResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ParentDashboardOverviewResponseToJson(this);
}

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final List<String>? roles;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.roles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String>? parsedRoles;
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) => e.toString()).toList();
    } else if (json['role'] is String) {
      parsedRoles = [json['role'] as String];
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'roles': roles,
      };
}

@JsonSerializable()
class TtsVoice {
  final String name;
  final String locale;
  final String gender;

  TtsVoice({
    required this.name,
    required this.locale,
    required this.gender,
  });

  factory TtsVoice.fromJson(Map<String, dynamic> json) => _$TtsVoiceFromJson(json);
  Map<String, dynamic> toJson() => _$TtsVoiceToJson(this);
}
