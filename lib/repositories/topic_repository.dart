import '../api/api_client.dart';
import '../models/kidio_models.dart';

class TopicRepository {
  final ApiClient apiClient;

  TopicRepository(this.apiClient);

  Future<PagedResult<Topic>> fetchTopics({
    int pageNumber = 1,
    int pageSize = 10,
    String? q,
  }) async {
    try {
      // Backend route is api/Topic
      final response = await apiClient.dio.get('Topic', queryParameters: {
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
      // Backend route is api/Topic/{id}
      final response = await apiClient.dio.get('Topic/$id');
      final data = response.data['data'] ?? response.data;
      return Topic.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Lesson> fetchLessonById(String id) async {
    try {
      // Backend route is api/Lesson/{id}
      final response = await apiClient.dio.get('Lesson/$id');
      final data = response.data['data'] ?? response.data;
      return Lesson.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Lesson>> fetchLessonsByTopicId(String topicId) async {
    try {
      // Backend route is api/Lesson/topic/{topicId}
      final response = await apiClient.dio.get('Lesson/topic/$topicId');

      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        final List items = data['items'];
        return items.map((json) => Lesson.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
