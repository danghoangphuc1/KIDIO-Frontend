import '../models/kidio_models.dart';
import '../services/child_api.dart';

class ChildRepository {
  final ChildApi _childApi;

  ChildRepository(this._childApi);

  Future<List<Child>> getChildren() => _childApi.getChildren();

  Future<Child> createChild({required String name, required int age, String? avatarUrl}) =>
      _childApi.createChild(name: name, age: age, avatarUrl: avatarUrl);

  Future<void> deleteChild(String childId) => _childApi.deleteChild(childId);

  Future<Child> updateChild({
    required String childId,
    required String name,
    required int age,
    String? avatarUrl,
  }) =>
      _childApi.updateChild(childId: childId, name: name, age: age, avatarUrl: avatarUrl);
}
