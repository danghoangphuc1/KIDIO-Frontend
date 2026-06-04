import 'package:json_annotation/json_annotation.dart';

part 'kidio_models.g.dart';

@JsonSerializable(explicitToJson: true)
class Vocabulary {
  final String id;
  final String word;
  final String meaning;
  final String? phoneticText;
  final int orderIndex;

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    this.phoneticText,
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
  final String? type;
  final String? difficulty;
  final String? skillFocus;
  final int? durationSeconds;
  final int orderIndex;
  final bool isPublished;
  final String? contentJson;
  final List<Vocabulary>? vocabularies;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.difficulty,
    this.skillFocus,
    this.durationSeconds,
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
  final int orderIndex;
  final bool? isActive;
  final List<Lesson>? lessons;
  final String? iconUrl;
  final int? totalLessons;

  Topic({
    required this.id,
    required this.name,
    this.description,
    required this.orderIndex,
    this.isActive,
    this.lessons,
    this.iconUrl,
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

class LessonProgress {
  final String id;
  final String childId;
  final String lessonId;
  final bool isCompleted;
  final int starsEarned;
  final int scorePercent;
  final int timeSpentSeconds;
  final DateTime? completedAt;

  LessonProgress({
    required this.id,
    required this.childId,
    required this.lessonId,
    required this.isCompleted,
    required this.starsEarned,
    required this.scorePercent,
    required this.timeSpentSeconds,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
    id: json['id'] as String,
    childId: json['childId'] as String,
    lessonId: json['lessonId'] as String,
    isCompleted: json['isCompleted'] as bool,
    starsEarned: json['starsEarned'] as int,
    scorePercent: json['scorePercent'] as int,
    timeSpentSeconds: json['timeSpentSeconds'] as int,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'lessonId': lessonId,
    'isCompleted': isCompleted,
    'starsEarned': starsEarned,
    'scorePercent': scorePercent,
    'timeSpentSeconds': timeSpentSeconds,
    'completedAt': completedAt?.toIso8601String(),
  };
}

@JsonSerializable()
class Achievement {
  final String id;
  final String title;
  final String? description;
  final String? iconUrl;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    this.description,
    this.iconUrl,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
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
  final String? text;

  TtsResponse({required this.audioUrl, this.text});

  factory TtsResponse.fromJson(Map<String, dynamic> json) => _$TtsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TtsResponseToJson(this);
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
