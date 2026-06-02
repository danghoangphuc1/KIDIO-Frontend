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
      orderIndex: (json['orderIndex'] as num).toInt(),
    );

Map<String, dynamic> _$VocabularyToJson(Vocabulary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'word': instance.word,
      'meaning': instance.meaning,
      'phoneticText': instance.phoneticText,
      'orderIndex': instance.orderIndex,
    };

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String?,
      difficulty: json['difficulty'] as String?,
      skillFocus: json['skillFocus'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
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
      'type': instance.type,
      'difficulty': instance.difficulty,
      'skillFocus': instance.skillFocus,
      'durationSeconds': instance.durationSeconds,
      'orderIndex': instance.orderIndex,
      'isPublished': instance.isPublished,
      'contentJson': instance.contentJson,
      'vocabularies': instance.vocabularies?.map((e) => e.toJson()).toList(),
    };

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
      isActive: json['isActive'] as bool?,
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      iconUrl: json['iconUrl'] as String?,
      totalLessons: (json['totalLessons'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'orderIndex': instance.orderIndex,
      'isActive': instance.isActive,
      'lessons': instance.lessons?.map((e) => e.toJson()).toList(),
      'iconUrl': instance.iconUrl,
      'totalLessons': instance.totalLessons,
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
