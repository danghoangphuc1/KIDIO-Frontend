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
      final response = await apiClient.dio.get('/Topic', queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (q != null) 'q': q,
      });

      // Backend bọc kết quả trong field 'data'
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
      final response = await apiClient.dio.get('/Topic/$id');
      // Thường thì chi tiết cũng nằm trong field 'data'
      final data = response.data['success'] == true ? response.data['data'] : response.data;
      return Topic.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Lesson> fetchLessonById(String id) async {
    try {
      final response = await apiClient.dio.get('/Lesson/$id');
      final data = response.data['success'] == true ? response.data['data'] : response.data;
      return Lesson.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Lesson>> fetchLessonsByTopicId(String topicId) async {
    try {
      final response = await apiClient.dio.get('/Lesson/topic/$topicId');

      // Sửa ở đây: Truy cập vào data rồi đến items
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
