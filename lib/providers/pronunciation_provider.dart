import 'dart:io';
import 'package:flutter/material.dart';
import '../models/kidio_models.dart';
import '../repositories/pronunciation_repository.dart';

class PronunciationProvider extends ChangeNotifier {
  final PronunciationRepository _repository;

  PronunciationProvider(this._repository);

  PronunciationScore? _lastScore;
  bool _isScoring = false;
  String? _errorMessage;

  PronunciationScore? get lastScore => _lastScore;
  bool get isScoring => _isScoring;
  String? get errorMessage => _errorMessage;

  Future<void> submitPronunciation({
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
        vocabularyId: vocabularyId,
        audioFile: audioFile,
        lessonId: lessonId,
      );
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
