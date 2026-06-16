import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kidio_models.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';

class VocabularyQuizScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final String lessonId;

  const VocabularyQuizScreen({
    super.key,
    required this.vocabularies,
    required this.lessonId,
  });

  @override
  State<VocabularyQuizScreen> createState() => _VocabularyQuizScreenState();
}

class QuizQuestion {
  final Vocabulary vocabulary;
  final bool hasImage;
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.vocabulary,
    required this.hasImage,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });
}

class _VocabularyQuizScreenState extends State<VocabularyQuizScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = Random();
    _questions = widget.vocabularies.map((vocab) {
      final hasImage = vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty;
      final questionText = hasImage ? "What is this?" : "Nghĩa của từ này là gì?";
      final correctAnswer = hasImage ? vocab.word : vocab.meaning;

      // Generate distractors
      List<String> options = [correctAnswer];
      final otherVocabs = widget.vocabularies.where((v) => v.id != vocab.id).toList();
      otherVocabs.shuffle(random);
      
      for (var v in otherVocabs) {
        if (options.length >= 3) break;
        options.add(hasImage ? v.word : v.meaning);
      }

      // If we don't have enough distractors (e.g., only 1-2 vocabularies in lesson),
      // we just use what we have, but ideally we want 3 options.
      options.shuffle(random);

      return QuizQuestion(
        vocabulary: vocab,
        hasImage: hasImage,
        questionText: questionText,
        options: options,
        correctAnswer: correctAnswer,
      );
    }).toList();
    _questions.shuffle(random); // Shuffle the overall questions
  }

  Future<void> _playTts(String text, {String? customAudioUrl, bool showLoading = true}) async {
    if (showLoading) {
      if (_isAudioPlaying) return;
      setState(() => _isAudioPlaying = true);
    }
    
    try {
      final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
      final baseUrl = dioBaseUrl.endsWith('/api/') ? dioBaseUrl.substring(0, dioBaseUrl.length - 5) : dioBaseUrl;
      
      String audioPath;
      if (customAudioUrl != null && customAudioUrl.isNotEmpty) {
        audioPath = customAudioUrl;
      } else {
        final ttsRepo = context.read<TtsRepository>();
        final response = await ttsRepo.synthesize(text);
        audioPath = response.audioUrl;
      }
      
      String fullUrl = audioPath.startsWith('http') ? audioPath : '$baseUrl${audioPath.startsWith('/') ? '' : '/'}$audioPath';
      if (fullUrl.contains('192.168.') || fullUrl.contains('10.')) {
        fullUrl = fullUrl.replaceFirst('https://', 'http://').replaceFirst(':7014', ':5109');
      }
      
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint('Audio Error: $e');
    } finally {
      if (showLoading && mounted) {
        setState(() => _isAudioPlaying = false);
      }
    }
  }

  void _onOptionSelected(String option) {
    if (_hasAnswered) return;

    final isCorrect = option == _questions[_currentIndex].correctAnswer;

    setState(() {
      _selectedAnswer = option;
      _hasAnswered = true;
    });

    if (isCorrect) {
      _playTts("Excellent!", customAudioUrl: 'https://dict.youdao.com/dictvoice?audio=excellent&type=1', showLoading: false);
    } else {
      _playTts("Oops, try again!", customAudioUrl: 'https://dict.youdao.com/dictvoice?audio=oops+try+again&type=1', showLoading: false);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _hasAnswered = true; // They already answered it
        // Note: we're losing the specific answer they selected for simplicity,
        // or we could store it in a map if we want to show their previous choice.
        // For now, we'll just require them to re-answer or skip.
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            const Text('Tuyệt vời!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.orange)),
            const SizedBox(height: 8),
            const Text('Con đã hoàn thành bài tập từ vựng!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to lesson
              },
              child: const Text('QUAY LẠI BÀI HỌC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài tập từ vựng')),
        body: const Center(child: Text('Không có từ vựng nào trong bài học này.')),
      );
    }

    final currentQ = _questions[_currentIndex];
    final progressPercent = ((_currentIndex + 1) / _questions.length);

    final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
    final baseUrl = dioBaseUrl.endsWith('/api/') ? dioBaseUrl.substring(0, dioBaseUrl.length - 5) : dioBaseUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KIDIO PLACEMENT QUIZ',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E88E5), letterSpacing: 1.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Question ${_currentIndex + 1} / ${_questions.length}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.purple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent == 0 ? 0.05 : progressPercent,
                  minHeight: 12,
                  backgroundColor: Colors.blue.shade50,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 24),

              // Main Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Image or Text area
                        SizedBox(
                          height: 180,
                          child: Center(
                            child: currentQ.hasImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      currentQ.vocabulary.imageUrl!.startsWith('http') 
                                        ? currentQ.vocabulary.imageUrl! 
                                        : '$baseUrl${currentQ.vocabulary.imageUrl!.startsWith('/') ? '' : '/'}${currentQ.vocabulary.imageUrl}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.psychology_alt_rounded, size: 60, color: Colors.orangeAccent),
                                      const SizedBox(height: 8),
                                      Text(
                                        currentQ.vocabulary.word,
                                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (currentQ.vocabulary.phoneticText != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          currentQ.vocabulary.phoneticText!,
                                          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),

                        // Question Text
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            currentQ.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                          ),
                        ),

                        // Audio Button
                        if (!_hasAnswered)
                          _isAudioPlaying
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
                              )
                            : IconButton(
                                icon: const Icon(Icons.volume_up_rounded, size: 36, color: Colors.blueAccent),
                                onPressed: () => _playTts(currentQ.vocabulary.word, customAudioUrl: currentQ.vocabulary.audioUrl),
                              ),
                        
                        const SizedBox(height: 16),

                        // Options
                        Row(
                          children: currentQ.options.map((option) {
                            final isSelected = _selectedAnswer == option;
                            Color btnColor = Colors.white;
                            Color borderColor = Colors.blue.shade100;
                            Color textColor = const Color(0xFF1A237E);

                            if (_hasAnswered) {
                              if (option == currentQ.correctAnswer) {
                                btnColor = Colors.green.shade50;
                                borderColor = Colors.green;
                                textColor = Colors.green.shade700;
                              } else if (isSelected) {
                                btnColor = Colors.red.shade50;
                                borderColor = Colors.red;
                                textColor = Colors.red.shade700;
                              }
                            } else if (isSelected) {
                              borderColor = Colors.blueAccent;
                            }

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => _onOptionSelected(option),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: btnColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor, width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),

                        // Nav Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _currentIndex > 0 ? _prevQuestion : () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.blueGrey),
                              label: Text(_currentIndex > 0 ? 'Back' : 'Thoát', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            ElevatedButton(
                              onPressed: _hasAnswered ? _nextQuestion : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE0E5EC),
                                foregroundColor: const Color(0xFF1A237E),
                                disabledBackgroundColor: const Color(0xFFE0E5EC).withOpacity(0.5),
                                disabledForegroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                elevation: 0,
                              ),
                              child: Row(
                                children: [
                                  Text(_currentIndex == _questions.length - 1 ? 'Hoàn thành' : 'Next', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                  if (_currentIndex < _questions.length - 1) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                  ]
                                ],
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
