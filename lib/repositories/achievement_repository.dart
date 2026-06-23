import '../models/kidio_models.dart';
import '../services/achievement_api.dart';

class AchievementRepository {
  final AchievementApi _api;

  AchievementRepository(this._api);

  Future<List<Achievement>> getByChild(String childId) => _api.getByChild(childId);

  Future<List<AchievementDefinition>> getActiveDefinitions() => _api.getActiveDefinitions();

  Future<List<Achievement>> getDefinitions() => _api.getDefinitions();

  Future<Achievement> getDefinitionById(String id) => _api.getDefinitionById(id);

  Future<Achievement> createDefinition({
    required String title,
    String? description,
    String? iconUrl,
    String? achievementType,
  }) => _api.createDefinition(
        title: title,
        description: description,
        iconUrl: iconUrl,
        achievementType: achievementType,
      );

  Future<Achievement> updateDefinition({
    required String id,
    required String title,
    String? description,
    String? iconUrl,
    String? achievementType,
  }) => _api.updateDefinition(
        id: id,
        title: title,
        description: description,
        iconUrl: iconUrl,
        achievementType: achievementType,
      );

  Future<void> deleteDefinition(String id) => _api.deleteDefinition(id);

  Future<void> restoreDefinition(String id) => _api.restoreDefinition(id);

  Future<void> hardDeleteDefinition(String id) => _api.hardDeleteDefinition(id);
}
