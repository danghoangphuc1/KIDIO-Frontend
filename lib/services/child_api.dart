import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class ChildApi {
  final Dio _dio;

  ChildApi(this._dio);

  Future<List<Child>> getChildren() async {
    try {
      final response = await _dio.get('Child');
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List)
            .map((json) => Child.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Child> createChild({required String name, required int age, String? avatarUrl}) async {
    try {
      final response = await _dio.post('Child', data: {
        'name': name,
        'age': age,
        'avatarUrl': avatarUrl,
      });
      return Child.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteChild(String childId) async {
    try {
      await _dio.delete('Child/$childId');
    } catch (e) {
      rethrow;
    }
  }

  Future<Child> updateChild({
    required String childId,
    required String name,
    required int age,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.put('Child/$childId', data: {
        'name': name,
        'age': age,
        'avatarUrl': avatarUrl,
      });
      return Child.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Child> getChildById(String childId) async {
    try {
      final response = await _dio.get('Child/$childId');
      return Child.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreChild(String childId) async {
    try {
      await _dio.patch('Child/$childId/restore');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> hardDeleteChild(String childId) async {
    try {
      await _dio.delete('Child/$childId/hard');
    } catch (e) {
      rethrow;
    }
  }
}
