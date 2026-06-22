import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/kidio_models.dart';
import '../repositories/pronunciation_repository.dart';

class PronunciationProvider extends ChangeNotifier {
  final PronunciationRepository _repository;

  PronunciationProvider(this._repository);

  PronunciationScore? _lastScore;
  List<PronunciationScore> _history = [];
  bool _isScoring = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  PronunciationScore? get lastScore => _lastScore;
  List<PronunciationScore> get history => _history;
  bool get isScoring => _isScoring;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;

  Future<void> loadVocabularyHistory(String vocabularyId) async {
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _repository.getVocabularyHistory(vocabularyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> submitPronunciation({
    required String childId,
    required String vocabularyId,
    required File audioFile,
    String? lessonId,
  }) async {
    _isScoring = true;
    _errorMessage = null;
    _lastScore = null;
    notifyListeners();

    try {
      _lastScore = await _repository.submitPronunciation(
        childId: childId,
        vocabularyId: vocabularyId,
        audioFile: audioFile,
        lessonId: lessonId,
      );
      
      // Increment daily pronunciation counter on successful submission
      try {
        final box = Hive.box('kidio_cache');
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final key = 'daily_pron_count_${childId}_$todayStr';
        final currentCount = box.get(key, defaultValue: 0);
        await box.put(key, currentCount + 1);
      } catch (hiveError) {
        debugPrint("Error updating daily pronunciation count in Hive: $hiveError");
      }

      // Reload history after submit
      await loadVocabularyHistory(vocabularyId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isScoring = false;
      notifyListeners();
    }
  }

  void clearLastScore() {
    _lastScore = null;
    notifyListeners();
  }
}
