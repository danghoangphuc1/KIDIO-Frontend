import 'package:flutter/material.dart';
import '../models/kidio_models.dart';
import '../repositories/child_repository.dart';

class ChildProvider extends ChangeNotifier {
  final ChildRepository _repository;

  List<Child> _children = [];
  Child? _selectedChild;
  bool _isLoading = false;
  String? _errorMessage;

  List<Child> get children => _children;
  Child? get selectedChild => _selectedChild;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChildProvider(this._repository);

  // ** Danh sách Pokemon linh vật cho bé chọn **
  final List<String> _availableAvatars = [
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png', // Pikachu
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png',  // Bulbasaur
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png',  // Charmander
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png',  // Squirtle
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/133.png', // Eevee
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/151.png', // Mew
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/150.png', // Mewtwo
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/39.png',  // Jigglypuff
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/54.png',  // Psyduck
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/143.png', // Snorlax
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/131.png', // Lapras
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/172.png', // Pichu
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/175.png', // Togepi
  ];

  List<String> get availableAvatars => _availableAvatars;

  Future<void> loadChildren() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _children = await _repository.getChildren();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectChild(Child child) {
    _selectedChild = child;
    notifyListeners();
  }

  void deselectChild() {
    _selectedChild = null;
    notifyListeners();
  }

  Future<void> refreshSelectedChild() async {
    if (_selectedChild == null) return;
    try {
      final updated = await _repository.getChildById(_selectedChild!.id);
      _selectedChild = updated;
      
      final index = _children.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _children[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing selected child: $e");
    }
  }

  Future<bool> createChild(String name, int age, {String? avatarUrl}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final child = await _repository.createChild(name: name, age: age, avatarUrl: avatarUrl);
      _children.add(child);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChild(String childId, String name, int age, {String? avatarUrl}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _repository.updateChild(
        childId: childId,
        name: name,
        age: age,
        avatarUrl: avatarUrl,
      );
      
      final index = _children.indexWhere((c) => c.id == childId);
      if (index != -1) {
        _children[index] = updated;
      }
      
      if (_selectedChild?.id == childId) {
        _selectedChild = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChild(String childId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteChild(childId);
      _children.removeWhere((c) => c.id == childId);
      if (_selectedChild?.id == childId) {
        _selectedChild = null;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addQuestStars({
    required String childId,
    required int stars,
    required String reason,
  }) async {
    try {
      final result = await _repository.addStars(
        childId: childId,
        stars: stars,
        reason: reason,
      );
      if (_selectedChild != null) {
        final newTotal = result['totalStars'] as int;
        _selectedChild = Child(
          id: _selectedChild!.id,
          name: _selectedChild!.name,
          age: _selectedChild!.age,
          avatarUrl: _selectedChild!.avatarUrl,
          totalStars: newTotal,
          currentStreakDays: _selectedChild!.currentStreakDays,
          lastLessonAt: _selectedChild!.lastLessonAt,
        );
        final index = _children.indexWhere((c) => c.id == _selectedChild!.id);
        if (index != -1) {
          _children[index] = _selectedChild!;
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error adding quest stars: $e');
      return false;
    }
  }
}
