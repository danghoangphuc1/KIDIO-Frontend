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
