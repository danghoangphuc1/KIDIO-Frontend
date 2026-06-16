import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
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
  late DateTime _startTime;

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
        if (mounted) setState(() => _isCompleted = progress != null);
      }

      return lesson;
    } catch (e) {
      final cached = _cacheService.getLesson(widget.lessonId);
      if (cached != null) return cached;
      rethrow;
    }
  }



  Future<void> _readWholeLesson() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      return;
    }
    setState(() => _isSynthesizingLesson = true);
    try {
      final ttsRepo = context.read<TtsRepository>();
      final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;

      debugPrint("Đang gọi API tổng hợp cả bài học...");
      final response = await ttsRepo.synthesizeLesson(widget.lessonId);
      debugPrint("API trả về: ${response.audioUrl}");
      
      String fullUrl = response.audioUrl.startsWith('http') ? response.audioUrl : '${dioBaseUrl.replaceAll('/api/', '')}${response.audioUrl}';
      
      // Khắc phục lỗi SSL trên thiết bị Android khi dùng IP local
      if (fullUrl.contains('192.168.') || fullUrl.contains('10.')) {
        fullUrl = fullUrl.replaceFirst('https://', 'http://').replaceFirst(':7014', ':5109');
      }
      
      debugPrint("Bắt đầu phát âm thanh: $fullUrl");
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint("Lỗi TTS: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải bài đọc: $e')));
    } finally {
      if (mounted) setState(() => _isSynthesizingLesson = false);
    }
  }



  Future<void> _finishLesson() async {
    if (_isCompleted) {
      Navigator.pop(context);
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
        if (progress.newAchievements != null && progress.newAchievements!.isNotEmpty) {
          await _showAchievementCelebration(progress.newAchievements!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Học giỏi quá! Đã lưu kết quả.')));
        }
        Navigator.pop(context);
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
            const Icon(Icons.stars, size: 80, color: Colors.orangeAccent),
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
              child: const Text('Tuyệt vời!'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.blueAccent, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bắt đầu bài học', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w900)),
        actions: [
          if (_isSynthesizingLesson)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(
              icon: Icon(_isPlaying ? Icons.stop_circle_rounded : Icons.campaign_rounded, color: Colors.blueAccent, size: 28),
              onPressed: _readWholeLesson,
              tooltip: 'Nghe giáo viên đọc cả bài',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Lỗi tải bài học'));

          final lesson = snapshot.data!;
          final plainTextContent = ContentParser.parseToPlainText(lesson.contentJson);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'lesson_${lesson.id}',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.auto_stories_rounded, size: 50, color: Colors.orangeAccent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(lesson.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
                      if (lesson.description != null) ...[
                        const SizedBox(height: 8),
                        Text(lesson.description!, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w600)),
                      ],
                      if (_isCompleted)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('ĐÃ HOÀN THÀNH', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Content Section
                if (plainTextContent.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 22), SizedBox(width: 8), Text('NỘI DUNG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey))]),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.blue.shade100, width: 2),
                          ),
                          child: Text(plainTextContent, style: const TextStyle(fontSize: 19, height: 1.6, color: Colors.black87, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                const SizedBox(height: 32),

                // Vocabulary Quiz Button Section
                if (_vocabularies.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.star_rounded, color: Colors.purpleAccent, size: 22), SizedBox(width: 8), Text('TỪ VỰNG QUAN TRỌNG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey))]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 80,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VocabularyQuizScreen(
                                    vocabularies: _vocabularies,
                                    lessonId: widget.lessonId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade50,
                              foregroundColor: Colors.purple,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: Colors.purple.shade200, width: 2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Bắt đầu Trắc nghiệm Từ vựng!',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _isSubmitting 
          ? const CircularProgressIndicator()
          : SizedBox(
              width: double.infinity,
              height: 60,
              child: FloatingActionButton.extended(
                onPressed: _finishLesson,
                elevation: 4,
                backgroundColor: _isCompleted ? Colors.blueAccent : Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                label: Text(
                  _isCompleted ? 'QUAY LẠI' : 'CON ĐÃ HỌC XONG!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                icon: Icon(_isCompleted ? Icons.arrow_back_rounded : Icons.check_circle_rounded, size: 28),
              ),
            ),
      ),
    );
  }

}
