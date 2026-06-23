import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/kidio_models.dart';
import '../repositories/lesson_repository.dart';
import '../repositories/tts_repository.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../utils/content_parser.dart';
import '../local/cache_service.dart';
import '../api/api_client.dart';
import '../repositories/vocabulary_repository.dart';
import 'vocabulary_quiz_screen.dart';
import 'vocab_learn_screen.dart';
import 'listening_game_screen.dart';
import 'pronunciation_challenge_screen.dart';
import 'boss_battle_screen.dart';
import '../utils/snackbar_utils.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final CacheService _cacheService = CacheService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late Future<Lesson> _lessonFuture;
  List<Vocabulary> _vocabularies = [];
  bool _isSubmitting = false;
  bool _isPlaying = false;
  bool _isSynthesizingLesson = false;
  bool _isCompleted = false;
  bool _isTranslating = false;
  String? _translatedText;
  late DateTime _startTime;

  // Local activity progress
  bool _vocabCompleted = false;
  bool _listeningCompleted = false;
  bool _pronCompleted = false;
  bool _quizCompleted = false;
  bool _bossCompleted = false;

  bool _isStoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _lessonFuture = _fetchLessonAndStatus();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Lesson> _fetchLessonAndStatus() async {
    final lessonRepo = context.read<LessonRepository>();
    final progressProvider = context.read<ProgressProvider>();
    final childId = context.read<ChildProvider>().selectedChild?.id;

    try {
      final lesson = await lessonRepo.getLessonById(widget.lessonId);
      await _cacheService.saveLesson(lesson);

      if (!mounted) return lesson;

      try {
        final vocabRepo = context.read<VocabularyRepository>();
        final vocabs = await vocabRepo.getByLesson(widget.lessonId);
        if (mounted) setState(() => _vocabularies = vocabs);
      } catch (e) {
        debugPrint("Error fetching vocabularies: $e");
      }

      if (childId != null) {
        final progress = await progressProvider.checkLessonCompletion(childId, widget.lessonId);
        if (mounted) {
          setState(() {
            _isCompleted = progress != null && progress.isCompleted;
            if (_isCompleted) {
              _vocabCompleted = true;
              _listeningCompleted = true;
              _pronCompleted = true;
              _quizCompleted = true;
              _bossCompleted = true;
            } else {
              _vocabCompleted = _cacheService.getActivityStatus(childId, widget.lessonId, 'vocab');
              _listeningCompleted = _cacheService.getActivityStatus(childId, widget.lessonId, 'listening');
              _pronCompleted = _cacheService.getActivityStatus(childId, widget.lessonId, 'pron');
              _quizCompleted = _cacheService.getActivityStatus(childId, widget.lessonId, 'quiz');
              _bossCompleted = _cacheService.getActivityStatus(childId, widget.lessonId, 'boss');
            }
          });
        }
      }

      return lesson;
    } catch (e) {
      final cached = _cacheService.getLesson(widget.lessonId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _readWholeLesson(Lesson lesson, String text) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      return;
    }
    setState(() => _isSynthesizingLesson = true);
    try {
      final fullUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=${Uri.encodeComponent(text)}';
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint("Lỗi TTS: $e");
      if (mounted) CustomSnackBar.show(context, 'Lỗi tải bài đọc: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSynthesizingLesson = false);
    }
  }

  Future<void> _translateContent(String text) async {
    setState(() => _isTranslating = true);
    try {
      final extDio = Dio();
      final response = await extDio.get('https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=${Uri.encodeComponent(text)}');
      if (response.data != null && response.data is List && response.data.isNotEmpty) {
        final List translations = response.data[0];
        String result = '';
        for (var i = 0; i < translations.length; i++) {
          result += translations[i][0];
        }
        if (mounted) {
          setState(() => _translatedText = result);
        }
      }
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, 'Lỗi dịch thuật. Vui lòng thử lại!', isError: true);
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _finishLesson() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final progressProvider = context.read<ProgressProvider>();
    final childId = context.read<ChildProvider>().selectedChild?.id;

    if (childId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final totalTimeSpent = DateTime.now().difference(_startTime).inSeconds;

    try {
      await progressProvider.submitProgress(
        childId: childId,
        lessonId: widget.lessonId,
        scorePercent: 100,
        timeSpentSeconds: totalTimeSpent,
      );

      if (mounted) {
        // Immediately mark as completed in local state so UI updates
        // without waiting for the async reload from the server.
        setState(() {
          _isCompleted = true;
          _vocabCompleted = true;
          _listeningCompleted = true;
          _pronCompleted = true;
          _quizCompleted = true;
          _bossCompleted = true;
        });
        await _cacheService.clearActivityStatuses(childId, widget.lessonId);
        await context.read<ChildProvider>().refreshSelectedChild();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, 'Lỗi cập nhật tiến trình bài học: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          '🎉 Hoàn thành bài học!',
          style: TextStyle(fontFamily: 'FredokaOne', color: Color(0xFF1E3A8A)),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Con đã chinh phục tất cả thử thách xuất sắc! Nhận ngay +10 Stars 🌟',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return completed status to list
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2E93),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Tuyệt vời!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  int _getCompletedCount() {
    int count = 0;
    if (_vocabCompleted) count++;
    if (_listeningCompleted) count++;
    if (_pronCompleted) count++;
    if (_quizCompleted) count++;
    if (_bossCompleted) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getCompletedCount() / 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FD),
      body: SafeArea(
        child: FutureBuilder<Lesson>(
          future: _lessonFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF2E93)));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Lỗi tải bài học', style: TextStyle(color: Color(0xFF1E3A8A))));
            }

            final lesson = snapshot.data!;
            final plainTextContent = ContentParser.parseToPlainText(lesson.contentJson);

            return Column(
              children: [
                // ── Custom Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E3A8A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Welcoming Banner Box
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '🐼',
                                style: TextStyle(fontSize: 48),
                              ).animate().shake(hz: 2, duration: 2.seconds),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lesson Adventure Hub',
                                      style: TextStyle(
                                        fontFamily: 'FredokaOne',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Chinh phục 5 thử thách để làm chủ bài học nhé!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lesson Progress Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tiến trình thử thách',
                                    style: TextStyle(
                                      fontFamily: 'FredokaOne',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  Text(
                                    '${_getCompletedCount()} / 5',
                                    style: const TextStyle(
                                      fontFamily: 'FredokaOne',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF2E93),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFCBD5E1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2E93)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Collapsible Story Book
                        if (plainTextContent.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ExpansionTile(
                                shape: const Border(),
                                initiallyExpanded: _isStoryExpanded,
                                onExpansionChanged: (val) => setState(() => _isStoryExpanded = val),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                                  child: const Icon(Icons.auto_stories_rounded, color: Colors.amberAccent, size: 24),
                                ),
                                title: const Text(
                                  'Truyện Đọc Bài Học 📖',
                                  style: TextStyle(
                                    fontFamily: 'FredokaOne',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (_isTranslating)
                                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                            else
                                              TextButton.icon(
                                                onPressed: () => _translateContent(plainTextContent),
                                                icon: const Icon(Icons.g_translate, color: Colors.teal, size: 16),
                                                label: const Text('Dịch', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 13)),
                                              ),
                                            const SizedBox(width: 12),
                                            if (_isSynthesizingLesson)
                                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                            else
                                              IconButton(
                                                icon: Icon(_isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded, color: Colors.blueAccent, size: 24),
                                                onPressed: () => _readWholeLesson(lesson, plainTextContent),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          plainTextContent,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_translatedText != null) ...[
                                          const Divider(height: 24),
                                          Text(
                                            _translatedText!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.6,
                                              color: Colors.teal,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Challenge Activities List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Challenge 1: Learn Vocabulary
                              _buildActivityCard(
                                index: 1,
                                icon: '📖',
                                title: 'Learn Vocabulary',
                                desc: 'Swipe and learn words and sounds!',
                                colors: [const Color(0xFFFF5C9F), const Color(0xFFFF8C00)],
                                isUnlocked: true,
                                isDone: _vocabCompleted,
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VocabLearnScreen(
                                        vocabularies: _vocabularies,
                                        lessonId: widget.lessonId,
                                      ),
                                    ),
                                  );
                                  final childId = context.read<ChildProvider>().selectedChild?.id;
                                  final isDone = res == true || (childId != null && _cacheService.getActivityStatus(childId, widget.lessonId, 'vocab'));
                                  if (isDone) {
                                    setState(() => _vocabCompleted = true);
                                    if (childId != null) {
                                      await _cacheService.saveActivityStatus(childId, widget.lessonId, 'vocab', true);
                                    }
                                  }
                                },
                              ),

                              // Challenge 2: Listening Game
                              _buildActivityCard(
                                index: 2,
                                icon: '🎧',
                                title: 'Listening Quest',
                                desc: 'Listen and choose the matching cards!',
                                colors: [const Color(0xFF3EA5FF), const Color(0xFF03A566)],
                                isUnlocked: _vocabCompleted,
                                isDone: _listeningCompleted,
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ListeningGameScreen(
                                        vocabularies: _vocabularies,
                                        lessonId: widget.lessonId,
                                      ),
                                    ),
                                  );
                                  final childId = context.read<ChildProvider>().selectedChild?.id;
                                  final isDone = res == true || (childId != null && _cacheService.getActivityStatus(childId, widget.lessonId, 'listening'));
                                  if (isDone) {
                                    setState(() => _listeningCompleted = true);
                                    if (childId != null) {
                                      await _cacheService.saveActivityStatus(childId, widget.lessonId, 'listening', true);
                                    }
                                  }
                                },
                              ),

                              // Challenge 3: Speak Up
                              _buildActivityCard(
                                index: 3,
                                icon: '🎤',
                                title: 'AI Pronunciation',
                                desc: 'Say the words and get AI feedback!',
                                colors: [const Color(0xFFFF4B2B), const Color(0xFFFF416C)],
                                isUnlocked: _listeningCompleted,
                                isDone: _pronCompleted,
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PronunciationChallengeScreen(
                                        vocabularies: _vocabularies,
                                        lessonId: widget.lessonId,
                                      ),
                                    ),
                                  );
                                  final childId = context.read<ChildProvider>().selectedChild?.id;
                                  final isDone = res == true || (childId != null && _cacheService.getActivityStatus(childId, widget.lessonId, 'pron'));
                                  if (isDone) {
                                    setState(() => _pronCompleted = true);
                                    if (childId != null) {
                                      await _cacheService.saveActivityStatus(childId, widget.lessonId, 'pron', true);
                                    }
                                  }
                                },
                              ),

                              // Challenge 4: Super Quiz
                              _buildActivityCard(
                                index: 4,
                                icon: '📝',
                                title: 'Placement Quiz',
                                desc: 'Test your vocabulary spelling!',
                                colors: [const Color(0xFF8A2387), const Color(0xFFE94057)],
                                isUnlocked: _pronCompleted,
                                isDone: _quizCompleted,
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VocabularyQuizScreen(
                                        vocabularies: _vocabularies,
                                        lessonId: widget.lessonId,
                                      ),
                                    ),
                                  );
                                  final childId = context.read<ChildProvider>().selectedChild?.id;
                                  final isDone = res == true || (childId != null && _cacheService.getActivityStatus(childId, widget.lessonId, 'quiz'));
                                  if (isDone) {
                                    setState(() => _quizCompleted = true);
                                    if (childId != null) {
                                      await _cacheService.saveActivityStatus(childId, widget.lessonId, 'quiz', true);
                                    }
                                  }
                                },
                              ),

                              // Challenge 5: Boss Battle
                              _buildActivityCard(
                                index: 5,
                                icon: '👾',
                                title: 'Boss Battle',
                                desc: 'Defeat the monster using word powers!',
                                colors: [const Color(0xFF1F1C2C), const Color(0xFF928DAB)],
                                isUnlocked: _quizCompleted,
                                isDone: _bossCompleted,
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BossBattleScreen(
                                        vocabularies: _vocabularies,
                                        lessonId: widget.lessonId,
                                      ),
                                    ),
                                  );
                                  final childId = context.read<ChildProvider>().selectedChild?.id;
                                  final isDone = res == true || (childId != null && _cacheService.getActivityStatus(childId, widget.lessonId, 'boss'));
                                  if (isDone) {
                                    setState(() => _bossCompleted = true);
                                    if (childId != null) {
                                      await _cacheService.saveActivityStatus(childId, widget.lessonId, 'boss', true);
                                    }
                                    await _finishLesson();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required int index,
    required String icon,
    required String title,
    required String desc,
    required List<Color> colors,
    required bool isUnlocked,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    final List<Color> activeGradient = isUnlocked
        ? colors
        : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)];

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.65,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: activeGradient.first.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: activeGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isUnlocked ? onTap : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      // Emoji Pill left
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Trailing icon
                      if (!isUnlocked)
                        const Icon(Icons.lock_rounded, color: Colors.white, size: 24)
                      else if (isDone)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.green, size: 16),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
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
}
