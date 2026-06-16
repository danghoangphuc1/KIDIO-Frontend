import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kidio_models.dart';
import '../repositories/topic_repository.dart';
import '../repositories/lesson_repository.dart';
import '../repositories/tts_repository.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../utils/content_parser.dart';
import '../local/cache_service.dart';
import '../api/api_client.dart';

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

  Future<void> _readAloud(String text) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      return;
    }
    try {
      final ttsRepo = context.read<TtsRepository>();
      
      final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
      final response = await ttsRepo.synthesize(text);
      
      // Chuyển đổi sang HTTP nếu là IP local để tránh lỗi SSL trên MediaPlayer của Android
      String fullUrl = response.audioUrl.startsWith('http') ? response.audioUrl : '${dioBaseUrl.replaceAll('/api/', '')}${response.audioUrl}';
      if (fullUrl.contains('192.168.') || fullUrl.contains('10.')) {
        fullUrl = fullUrl.replaceFirst('https://', 'http://').replaceFirst(':7014', ':5109');
      }
          
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi âm thanh: $e')));
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

  void _showPronunciationDialog(Vocabulary vocab) {
    showDialog(
      context: context,
      builder: (context) => PronunciationPracticeDialog(
        vocab: vocab,
        lessonId: widget.lessonId,
      ),
    );
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

                // Vocabulary Section
                if (lesson.vocabularies != null && lesson.vocabularies!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [Icon(Icons.star_rounded, color: Colors.purpleAccent, size: 22), SizedBox(width: 8), Text('TỪ VỰNG QUAN TRỌNG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey))]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: lesson.vocabularies!.length,
                      itemBuilder: (context, index) {
                        final vocab = lesson.vocabularies![index];
                        final List<Color> colors = [Colors.green, Colors.orange, Colors.purple, Colors.blue, Colors.pink];
                        final color = colors[index % colors.length];
                        
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16, bottom: 10, left: 4),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                            border: Border.all(color: color.withOpacity(0.2), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(vocab.word, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
                              if (vocab.phoneticText != null)
                                Text(vocab.phoneticText!, style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 10),
                              Expanded(child: Center(child: Text(vocab.meaning, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildVocabAction(Icons.volume_up_rounded, color, () => _readAloud(vocab.word)),
                                  _buildVocabAction(Icons.mic_rounded, Colors.redAccent, () => _showPronunciationDialog(vocab)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
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

  Widget _buildVocabAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class PronunciationPracticeDialog extends StatefulWidget {
  final Vocabulary vocab;
  final String lessonId;

  const PronunciationPracticeDialog({super.key, required this.vocab, required this.lessonId});

  @override
  State<PronunciationPracticeDialog> createState() => _PronunciationPracticeDialogState();
}

class _PronunciationPracticeDialogState extends State<PronunciationPracticeDialog> {
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PronunciationProvider>().loadVocabularyHistory(widget.vocab.id);
    });
  }
  
  void _toggleRecording() async {
    if (!_isRecording) {
      setState(() => _isRecording = true);
      // Mockup recording for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    setState(() => _isRecording = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng ghi âm thật đang được chuẩn bị. Kết nối AI BE đã sẵn sàng!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PronunciationProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: const Center(child: Text('Tập nói cùng AI', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E)))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.vocab.word, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          const SizedBox(height: 20),
          if (provider.isScoring)
            const CircularProgressIndicator()
          else if (provider.lastScore != null)
            _buildScoreView(provider.lastScore!)
          else
            const Text('Nhấn mic và đọc to từ trên nhé!', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 30),
          
          // Record Button
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.blueAccent,
                boxShadow: [BoxShadow(color: (_isRecording ? Colors.red : Colors.blueAccent).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
              ),
              child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, size: 48, color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('LỊCH SỬ LUYỆN TẬP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
          const SizedBox(height: 16),
          
          // History List
          SizedBox(
            height: 80,
            child: provider.isLoadingHistory 
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : provider.history.isEmpty
                ? const Center(child: Text('Chưa có lịch sử', style: TextStyle(fontSize: 13, color: Colors.grey)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.history.length,
                    itemBuilder: (context, index) {
                      final h = provider.history[index];
                      final isGood = h.overallScore >= 80;
                      return Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isGood ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isGood ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${h.overallScore}', style: TextStyle(fontWeight: FontWeight.w900, color: isGood ? Colors.green : Colors.orange, fontSize: 18)),
                            const SizedBox(height: 4),
                            Icon(isGood ? Icons.check_circle_rounded : Icons.stars_rounded, size: 18, color: isGood ? Colors.green : Colors.orange),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () {
              provider.clearLastScore();
              Navigator.pop(context);
            },
            child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreView(PronunciationScore score) {
    return Column(
      children: [
        Text('Điểm số: ${score.overallScore}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.indigo)),
        const SizedBox(height: 4),
        Text(score.feedback, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        Icon(
          score.isPassed ? Icons.check_circle_rounded : Icons.stars_rounded,
          color: score.isPassed ? Colors.green : Colors.orange,
          size: 60,
        ),
      ],
    );
  }
}
