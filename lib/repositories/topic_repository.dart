import '../models/kidio_models.dart';
import '../services/topic_api.dart';

class TopicRepository {
  final TopicApi _topicApi;

  TopicRepository(this._topicApi);

  Future<PagedResult<Topic>> fetchTopics({
    int pageNumber = 1,
    int pageSize = 10,
    String? q,
  }) => _topicApi.fetchTopics(pageNumber: pageNumber, pageSize: pageSize, q: q);

  Future<Topic> fetchTopicById(String id) => _topicApi.fetchTopicById(id);

  Future<Topic> createTopic({
    required String name,
    String? description,
    String? iconUrl,
    int? orderIndex,
  }) => _topicApi.createTopic(
      name: name,
      description: description,
      iconUrl: iconUrl,
      orderIndex: orderIndex,
    );

  Future<Topic> updateTopic({
    required String topicId,
    required String name,
    String? description,
    String? iconUrl,
    int? orderIndex,
  }) => _topicApi.updateTopic(
      topicId: topicId,
      name: name,
      description: description,
      iconUrl: iconUrl,
      orderIndex: orderIndex,
    );

  Future<void> deleteTopic(String topicId) => _topicApi.deleteTopic(topicId);

  Future<void> restoreTopic(String topicId) => _topicApi.restoreTopic(topicId);

  Future<void> hardDeleteTopic(String topicId) => _topicApi.hardDeleteTopic(topicId);
}
