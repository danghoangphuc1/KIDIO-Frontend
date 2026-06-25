import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/kidio_models.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';
import '../providers/child_provider.dart';
import '../local/cache_service.dart';

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
  int _originalQuestionCount = 0;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  final Set<String> _wrongAnswers = {};
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
    List<QuizQuestion> questions = [];

    // Each vocabulary is turned into a question
    for (var vocab in widget.vocabularies) {
      final hasImage = vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty;
      final qText = hasImage
          ? 'What does this picture show? 🔍'
          : 'Từ này có nghĩa là gì? 🤔';

      List<String> options = [vocab.meaning];
      List<Vocabulary> distractors =
          widget.vocabularies.where((v) => v.id != vocab.id).toList();
      distractors.shuffle(random);

      for (var d in distractors) {
        if (options.length >= 4) break;
        options.add(d.meaning);
      }

      while (options.length < 4 && widget.vocabularies.isNotEmpty) {
        options.add(widget.vocabularies[random.nextInt(widget.vocabularies.length)].meaning);
      }

      options.shuffle(random);

      questions.add(QuizQuestion(
        vocabulary: vocab,
        hasImage: hasImage,
        questionText: qText,
        options: options,
        correctAnswer: vocab.meaning,
      ));
    }

    questions.shuffle(random);
    setState(() {
      _questions = questions;
      _originalQuestionCount = questions.length;
      _currentIndex = 0;
    });
  }

  Future<void> _playTts(String text, {String? customAudioUrl}) async {
    if (_isAudioPlaying) return;
    setState(() => _isAudioPlaying = true);

    try {
      final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
      final baseUrl = dioBaseUrl.endsWith('/api/')
          ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
          : dioBaseUrl;

      String audioPath;
      if (customAudioUrl != null && customAudioUrl.isNotEmpty) {
        audioPath = customAudioUrl;
      } else {
        final ttsRepo = context.read<TtsRepository>();
        final response = await ttsRepo.synthesize(text).timeout(const Duration(seconds: 5));
        audioPath = response.audioUrl;
      }

      String fullUrl = audioPath.startsWith('http')
          ? audioPath
          : '$baseUrl${audioPath.startsWith('/') ? '' : '/'}$audioPath';
      if (fullUrl.contains('192.168.') || fullUrl.contains('10.')) {
        fullUrl = fullUrl.replaceFirst('https://', 'http://').replaceFirst(':7014', ':5109');
      }

      await _audioPlayer.play(UrlSource(fullUrl)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Audio Quiz Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAudioPlaying = false);
      }
    }
  }

  void _onOptionSelected(String option) {
    if (_hasAnswered) return;

    final currentQ = _questions[_currentIndex];
    final isCorrect = option == currentQ.correctAnswer;

    setState(() {
      _selectedAnswer = option;
      _hasAnswered = true;
    });

    if (isCorrect) {
      _playSystemSound(true);
      Future.delayed(const Duration(milliseconds: 1600), _nextQuestion);
    } else {
      _playSystemSound(false);
      setState(() {
        _wrongAnswers.add(option);
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _selectedAnswer = null;
            _hasAnswered = false;
          });
        }
      });
    }
  }

  Future<void> _playSystemSound(bool isCorrect) async {
    try {
      final soundPath = isCorrect
          ? 'https://assets.mixkit.co/active_storage/sfx/2019/2019-84.wav'
          : 'https://assets.mixkit.co/active_storage/sfx/2017/2017-84.wav';
      await _audioPlayer.play(UrlSource(soundPath));
    } catch (e) {
      debugPrint('System Sound Error: $e');
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _wrongAnswers.clear();
      });
    } else {
      _showCompletionScreen();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedAnswer = null;
        _hasAnswered = false;
        _wrongAnswers.clear();
      });
    }
  }

  void _showCompletionScreen() {
    try {
      final childId = Provider.of<ChildProvider>(context, listen: false).selectedChild?.id;
      if (childId != null) {
        CacheService().saveActivityStatus(childId, widget.lessonId, 'quiz', true);
      }
    } catch (e) {
      debugPrint('Error caching quiz status: $e');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🏆 QUIZ COMPLETED! 🏆',
                        style: TextStyle(
                          fontFamily: 'FredokaOne',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'Con đã xuất sắc hoàn thành Quiz!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                            ],
                          ),
                          child: const Text(
                            'QUAY LẠI HOẠT ĐỘNG',
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102D54),
                            ),
                          ),
                        ),
                      ).animate().slideY(begin: 0.2, delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
    double progressPercent = ((_currentIndex + 1) / _originalQuestionCount);
    if (progressPercent > 1.0) progressPercent = 1.0;

    final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
    final baseUrl = dioBaseUrl.endsWith('/api/')
        ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
        : dioBaseUrl;

    // Speech bubble text
    String mascotText = "Find the correct matching animal for the question! 🐼";
    if (_hasAnswered) {
      final isCorrect = _selectedAnswer == currentQ.correctAnswer;
      mascotText = isCorrect ? "Fantastic! That's correct! 🎉" : "Oops! Let's try again! 🌟";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF102D54), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Question ${_currentIndex + 1} / $_originalQuestionCount',
                    style: const TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102D54),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFCBD5E1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2E93)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Purple Gradient Question Card ──
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // White rounded card for image/emoji
                      Container(
                        width: 140,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: currentQ.hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  currentQ.vocabulary.imageUrl!.startsWith('http')
                                      ? currentQ.vocabulary.imageUrl!
                                      : '$baseUrl${currentQ.vocabulary.imageUrl!.startsWith('/') ? '' : '/'}${currentQ.vocabulary.imageUrl}',
                                  headers: const {'User-Agent': 'KidioApp/1.0'},
                                  height: 90,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Text(
                                    '🦁',
                                    style: TextStyle(fontSize: 60),
                                  ),
                                ),
                              )
                            : const Text(
                                '🦁',
                                style: TextStyle(fontSize: 60),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Question text
                      Text(
                        currentQ.questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'FredokaOne',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 2x2 grid of options ──
              Expanded(
                flex: 4,
                child: GridView.builder(
                  itemCount: currentQ.options.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, idx) {
                    final option = currentQ.options[idx];
                    final isSelected = _selectedAnswer == option;
                    final isWrong = _wrongAnswers.contains(option);

                    Color cardBorderColor = const Color(0xFFE2E8F0);
                    Color cardColor = Colors.white;
                    Color textColor = const Color(0xFF102D54);

                    if (_hasAnswered && option == currentQ.correctAnswer) {
                      cardColor = const Color(0xFFD1FAE5);
                      cardBorderColor = const Color(0xFF10B981);
                      textColor = const Color(0xFF065F46);
                    } else if (isWrong) {
                      cardColor = const Color(0xFFFFE4E6);
                      cardBorderColor = const Color(0xFFF43F5E);
                      textColor = const Color(0xFF9F1239);
                    } else if (isSelected) {
                      cardBorderColor = const Color(0xFF3B82F6);
                    }

                    // A, B, C, D label
                    final String prefix = String.fromCharCode(65 + idx) + ". ";

                    Widget optionCard = GestureDetector(
                      onTap: () => _onOptionSelected(option),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorderColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            prefix + option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );

                    if (isWrong) {
                      optionCard = optionCard.animate().shake(duration: 500.ms, hz: 6);
                    }

                    return optionCard;
                  },
                ),
              ),

              // ── Mascot Section ──
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  children: [
                    const Text(
                      '🐼',
                      style: TextStyle(fontSize: 48),
                    ).animate().shake(hz: 2, duration: 2.seconds),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black12.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Text(
                          mascotText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102D54),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _currentIndex > 0 ? _prevQuestion : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.blueGrey),
                    label: Text(
                      _currentIndex > 0 ? 'Back' : 'Thoát',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _hasAnswered ? _nextQuestion : null,
                    child: Opacity(
                      opacity: _hasAnswered ? 1.0 : 0.45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2E93),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2E93).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentIndex == _questions.length - 1 ? 'Hoàn thành' : 'Next',
                              style: const TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            if (_currentIndex < _questions.length - 1) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
