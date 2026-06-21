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
import 'package:hive_flutter/hive_flutter.dart';
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
            _isCompleted = progress != null;
            // If already completed in the DB, unlock and mark everything completed
            if (_isCompleted) {
              _vocabCompleted = true;
              _listeningCompleted = true;
              _pronCompleted = true;
              _quizCompleted = true;
              _bossCompleted = true;
            } else {
              // Load from local Hive cache so progress isn't lost if they exit and return
              try {
                final box = Hive.box('kidio_cache');
                _vocabCompleted = box.get('lesson_${widget.lessonId}_vocab', defaultValue: false);
                _listeningCompleted = box.get('lesson_${widget.lessonId}_listening', defaultValue: false);
                _pronCompleted = box.get('lesson_${widget.lessonId}_pron', defaultValue: false);
                _quizCompleted = box.get('lesson_${widget.lessonId}_quiz', defaultValue: false);
                _bossCompleted = box.get('lesson_${widget.lessonId}_boss', defaultValue: false);
              } catch (e) {
                debugPrint("Error loading local progress: $e");
              }
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
    if (_isCompleted) {
      return;
    }

    final childId = context.read<ChildProvider>().selectedChild?.id;
    if (childId == null) return;

    final duration = DateTime.now().difference(_startTime).inSeconds;
    setState(() => _isSubmitting = true);

    try {
      final progress = await context.read<ProgressProvider>().submitProgress(
        childId: childId,
        lessonId: widget.lessonId,
        scorePercent: 100,
        timeSpentSeconds: duration > 0 ? duration : 1,
      );

      if (progress != null && mounted) {
        setState(() {
          _isCompleted = true;
        });
        if (progress.newAchievements != null && progress.newAchievements!.isNotEmpty) {
          await _showAchievementCelebration(progress.newAchievements!);
        } else {
          CustomSnackBar.show(context, 'Học giỏi quá! Con đã hoàn thành tất cả thử thách! 🏆');
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAchievementCelebration(List<Achievement> achievements) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.orangeAccent)
                .animate()
                .scale(duration: 500.ms)
                .shake(),
            const SizedBox(height: 16),
            const Text('CHÚC MỪNG CON!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            Text('Con vừa nhận được ${achievements.length} huy hiệu mới:', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ...achievements.map((a) => ListTile(
              leading: a.iconUrl != null ? Image.network(a.iconUrl!, width: 40) : const Icon(Icons.workspace_premium),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(a.description ?? ''),
            )),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lesson Adventure Hub',
          style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải bài học'));
          }

          final lesson = snapshot.data!;
          final plainTextContent = ContentParser.parseToPlainText(lesson.contentJson);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Welcoming Banner Box
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBAE6FD), Color(0xFFE0F2FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.5), width: 1.5),
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
                            Text(
                              lesson.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hoàn thành 5 thử thách để làm chủ bài học nhé!',
                              style: TextStyle(
                                fontSize: 13,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiến trình thử thách',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          Text(
                            '${_getCompletedCount()} / 5',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                          backgroundColor: Colors.blue.shade50,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Collapsible Story Book
                if (plainTextContent.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102D54),
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
                                    fontSize: 16,
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
                                      fontSize: 15,
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
                          if (res == true) {
                            setState(() => _vocabCompleted = true);
                            try { Hive.box('kidio_cache').put('lesson_${widget.lessonId}_vocab', true); } catch (_) {}
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
                          if (res == true) {
                            setState(() => _listeningCompleted = true);
                            try { Hive.box('kidio_cache').put('lesson_${widget.lessonId}_listening', true); } catch (_) {}
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
                          if (res == true) {
                            setState(() => _pronCompleted = true);
                            try { Hive.box('kidio_cache').put('lesson_${widget.lessonId}_pron', true); } catch (_) {}
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
                          if (res == true) {
                            setState(() => _quizCompleted = true);
                            try { Hive.box('kidio_cache').put('lesson_${widget.lessonId}_quiz', true); } catch (_) {}
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
                          if (res == true) {
                            setState(() => _bossCompleted = true);
                            try { Hive.box('kidio_cache').put('lesson_${widget.lessonId}_boss', true); } catch (_) {}
                            await _finishLesson();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
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
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDone
              ? Border.all(color: Colors.green.withOpacity(0.4), width: 2)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102D54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDone)
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            trailing: isUnlocked
                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.blueGrey)
                : const Icon(Icons.lock_outline_rounded, size: 20, color: Colors.grey),
            onTap: isUnlocked ? onTap : null,
          ),
        ),
      ),
    );
  }
}
