import 'package:dio/dio.dart';
import '../models/kidio_models.dart';

class TopicApi {
  final Dio _dio;

  TopicApi(this._dio);

  Future<PagedResult<Topic>> fetchTopics({
    int pageNumber = 1,
    int pageSize = 10,
    String? q,
  }) async {
    try {
      final response = await _dio.get('Topic', queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (q != null) 'q': q,
      });

      final data = response.data['data'];

      return PagedResult<Topic>.fromJson(
        data,
        (json) => Topic.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Topic> fetchTopicById(String id) async {
    try {
      final response = await _dio.get('Topic/$id');
      final data = response.data['data'] ?? response.data;
      return Topic.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Topic> createTopic({
    required String name,
    String? description,
    String? iconUrl,
    int? orderIndex,
  }) async {
    try {
      final response = await _dio.post('Topic', data: {
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'orderIndex': orderIndex,
      });
      return Topic.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Topic> updateTopic({
    required String topicId,
    required String name,
    String? description,
    String? iconUrl,
    int? orderIndex,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.put('Topic/$topicId', data: {
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'orderIndex': orderIndex,
        'isActive': isActive ?? true,
      });
      return Topic.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTopic(String topicId) async {
    try {
      await _dio.delete('Topic/$topicId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restoreTopic(String topicId) async {
    try {
      await _dio.patch('Topic/$topicId/restore');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> hardDeleteTopic(String topicId) async {
    try {
      await _dio.delete('Topic/$topicId/hard');
    } catch (e) {
      rethrow;
    }
  }
}
