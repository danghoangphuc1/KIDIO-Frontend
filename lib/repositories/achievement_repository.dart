import '../models/kidio_models.dart';
import '../services/achievement_api.dart';

class AchievementRepository {
  final AchievementApi _api;

  AchievementRepository(this._api);

  Future<List<Achievement>> getByChild(String childId) => _api.getByChild(childId);
}
