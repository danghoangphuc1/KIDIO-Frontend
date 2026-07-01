import '../models/kidio_models.dart';
import '../services/achievement_api.dart';

class AchievementRepository {
  final AchievementApi _api;

  AchievementRepository(this._api);

  Future<List<Achievement>> getByChild(String childId) => _api.getByChild(childId);

  Future<List<AchievementDefinition>> getActiveDefinitions() => _api.getActiveDefinitions();

  Future<List<AchievementDefinition>> getDefinitions() => _api.getDefinitions();

  Future<AchievementDefinition> getDefinitionById(String id) => _api.getDefinitionById(id);

  Future<AchievementDefinition> createDefinition({
    required String type,
    required int threshold,
    required String name,
    String? description,
    String? badgeUrl,
    int orderIndex = 0,
  }) => _api.createDefinition(
        type: type,
        threshold: threshold,
        name: name,
        description: description,
        badgeUrl: badgeUrl,
        orderIndex: orderIndex,
      );

  Future<AchievementDefinition> updateDefinition({
    required String id,
    required String type,
    required int threshold,
    required String name,
    String? description,
    String? badgeUrl,
    required int orderIndex,
    required bool isActive,
  }) => _api.updateDefinition(
        id: id,
        type: type,
        threshold: threshold,
        name: name,
        description: description,
        badgeUrl: badgeUrl,
        orderIndex: orderIndex,
        isActive: isActive,
      );

  Future<void> deleteDefinition(String id) => _api.deleteDefinition(id);

  Future<void> restoreDefinition(String id) => _api.restoreDefinition(id);

  Future<void> hardDeleteDefinition(String id) => _api.hardDeleteDefinition(id);
}
