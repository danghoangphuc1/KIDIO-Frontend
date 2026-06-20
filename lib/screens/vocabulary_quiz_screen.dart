import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/kidio_models.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';
import '../providers/pronunciation_provider.dart';

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

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng cấp quyền Micro để sử dụng tính năng này.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecordingAndSubmit(String vocabularyId) async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null && mounted) {
        final file = File(path);
        if (await file.exists()) {
          _showScoringDialog();

          await context.read<PronunciationProvider>().submitPronunciation(
                vocabularyId: vocabularyId,
                audioFile: file,
                lessonId: widget.lessonId,
              );

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            final score = context.read<PronunciationProvider>().lastScore;
            if (score != null) {
              _showScoreResultDialog(score);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Không thể chấm điểm: ${context.read<PronunciationProvider>().errorMessage}',
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() => _isRecording = false);
    }
  }

  void _showScoringDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.purpleAccent),
            const SizedBox(height: 20),
            const Text(
              'AI đang nghe và chấm điểm...',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF102D54)),
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreResultDialog(PronunciationScore score) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Center(
          child: Text(
            'Kết quả phát âm 🎤',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.purple),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score.overallScore >= 80
                  ? 'Tuyệt vời! 🌟'
                  : (score.overallScore >= 50 ? 'Khá tốt! 👍' : 'Cần cố gắng thêm! 💪'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: score.overallScore >= 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tổng điểm: ${score.overallScore.toInt()}/100',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF102D54)),
            ),
            const SizedBox(height: 12),
            _buildScoreProgressRow('Độ chính xác', score.accuracyScore),
            _buildScoreProgressRow('Độ lưu loát', score.fluencyScore),
            _buildScoreProgressRow('Độ hoàn thiện', score.completenessScore),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text(
                'Đóng',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScoreProgressRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: score >= 60 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
          ),
        ],
      ),
    );
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

      options.shuffle(random);

      return QuizQuestion(
        vocabulary: vocab,
        hasImage: hasImage,
        questionText: questionText,
        options: options,
        correctAnswer: correctAnswer,
      );
    }).toList();
    _originalQuestionCount = _questions.length;
    _questions.shuffle(random);
  }

  Future<void> _playTts(String text, {String? customAudioUrl, bool showLoading = true}) async {
    if (showLoading) {
      if (_isAudioPlaying) return;
      setState(() => _isAudioPlaying = true);
    }

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
      debugPrint('Audio Error: $e');
    } finally {
      if (showLoading && mounted) {
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
      if (!isCorrect) {
        _wrongAnswers.add(option);
      }
    });

    if (isCorrect) {
      _playTts(
        "Excellent!",
        customAudioUrl: 'https://dict.youdao.com/dictvoice?audio=excellent&type=1',
        showLoading: false,
      );
    } else {
      _playTts(
        "Oops, try again!",
        customAudioUrl: 'https://dict.youdao.com/dictvoice?audio=oops+try+again&type=1',
        showLoading: false,
      );
      // Add the wrong question to the end of the list so they have to do it again
      _questions.add(currentQ);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _selectedAnswer = null;
        _wrongAnswers.clear();
      });
    } else {
      _showCompletionDialog();
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

  void _showCompletionDialog() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SUPER QUIZ MASTER! 📝',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'Con đã hoàn thành thử thách trắc nghiệm!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Floating star rewards
                      const Text('🏆', style: TextStyle(fontSize: 80))
                          .animate()
                          .scale(duration: 500.ms)
                          .shake(),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context, true); // Return true to mark completed
                        },
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

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FD),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FD), Color(0xFFE0E7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                      'Question ${_currentIndex < _originalQuestionCount ? _currentIndex + 1 : "Retry"} / $_originalQuestionCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102D54),
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
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 10,
                    backgroundColor: Colors.blue.shade50,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 24),

                // Question Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Image / Text Display
                          Container(
                            constraints: const BoxConstraints(minHeight: 180),
                            alignment: Alignment.center,
                            child: currentQ.hasImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(
                                      currentQ.vocabulary.imageUrl!.startsWith('http')
                                          ? currentQ.vocabulary.imageUrl!
                                          : '$baseUrl${currentQ.vocabulary.imageUrl!.startsWith('/') ? '' : '/'}${currentQ.vocabulary.imageUrl}',
                                      headers: const {'User-Agent': 'KidioApp/1.0'},
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => const Icon(
                                        Icons.emoji_events_rounded,
                                        size: 100,
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.psychology_alt_rounded,
                                          size: 60, color: Colors.orangeAccent),
                                      const SizedBox(height: 8),
                                      Text(
                                        currentQ.vocabulary.word,
                                        style: const TextStyle(
                                          fontFamily: 'Fredoka One',
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF102D54),
                                        ),
                                        textAlign: TextAlign.center,
                                      ).animate(key: ValueKey(currentQ.vocabulary.id)).shake(duration: 600.ms),
                                      if (currentQ.vocabulary.phoneticText != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          currentQ.vocabulary.phoneticText!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Question text
                          Text(
                            currentQ.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102D54),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Audio and Mic row
                          if (!_hasAnswered)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isAudioPlaying
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.blueAccent),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.volume_up_rounded,
                                            size: 36, color: Colors.blueAccent),
                                        onPressed: () => _playTts(
                                          currentQ.vocabulary.word,
                                          customAudioUrl: currentQ.vocabulary.audioUrl,
                                        ),
                                      ),
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: () {
                                    if (_isRecording) {
                                      _stopRecordingAndSubmit(currentQ.vocabulary.id);
                                    } else {
                                      _startRecording();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRecording ? Colors.red.shade100 : Colors.purple.shade50,
                                      boxShadow: _isRecording
                                          ? [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                      size: 36,
                                      color: _isRecording ? Colors.red : Colors.purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),

                          // Option buttons list
                          Column(
                            children: currentQ.options.map((option) {
                              final isSelected = _selectedAnswer == option;
                              final isWrong = _wrongAnswers.contains(option);
                              Color btnColor = Colors.grey.shade50;
                              Color borderColor = Colors.grey.shade200;
                              Color textColor = const Color(0xFF102D54);

                              if (_hasAnswered && option == currentQ.correctAnswer) {
                                btnColor = Colors.green.shade50;
                                borderColor = Colors.green;
                                textColor = Colors.green.shade800;
                              } else if (isWrong) {
                                btnColor = Colors.red.shade50;
                                borderColor = Colors.red;
                                textColor = Colors.red.shade800;
                              } else if (isSelected) {
                                borderColor = Colors.blueAccent;
                              }

                              Widget optionCard = Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => _onOptionSelected(option),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: btnColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: borderColor, width: 2.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
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
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Next/Back control buttons
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
                                    fontSize: 16,
                                  ),
                                ),
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
                                    Text(
                                      _currentIndex == _questions.length - 1 ? 'Hoàn thành' : 'Next',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                    ),
                                    if (_currentIndex < _questions.length - 1) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
