import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class AchievementApi {
  final Dio _dio;

  AchievementApi(this._dio);

  Future<List<Achievement>> getByChild(String childId) async {
    try {
      final response = await _dio.get('Achievement/child/$childId');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AchievementDefinition>> getActiveDefinitions() async {
    try {
      final response = await _dio.get('Achievement/active-definitions');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((json) => AchievementDefinition.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Achievement>> getDefinitions() async {
    try {
      final response = await _dio.get('Achievement/definitions');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement> getDefinitionById(String id) async {
    try {
      final response = await _dio.get('Achievement/definitions/$id');
      return Achievement.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement> createDefinition({
    required String title,
    String? description,
    String? iconUrl,
    String? achievementType,
  }) async {
    try {
      final response = await _dio.post('Achievement/definitions', data: {
        'title': title,
        'description': description,
        'iconUrl': iconUrl,
        'achievementType': achievementType,
      });
      return Achievement.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Achievement> updateDefinition({
    required String id,
    required String title,
    String? description,
    String? iconUrl,
    String? achievementType,
  }) async {
    try {
      final response = await _dio.put('Achievement/definitions/$id', data: {
        'title': title,
        'description': description,
        'iconUrl': iconUrl,
        'achievementType': achievementType,
      });
      return Achievement.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDefinition(String id) async {
    try {
      await _dio.delete('Achievement/definitions/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreDefinition(String id) async {
    try {
      await _dio.patch('Achievement/definitions/$id/restore');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> hardDeleteDefinition(String id) async {
    try {
      await _dio.delete('Achievement/definitions/$id/hard');
    } catch (e) {
      rethrow;
    }
  }
}
