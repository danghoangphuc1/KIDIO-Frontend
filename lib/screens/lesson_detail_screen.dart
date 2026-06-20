import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kidio_models.dart';
import '../repositories/topic_repository.dart';
import '../repositories/tts_repository.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../utils/content_parser.dart';
import '../local/cache_service.dart';

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
    final topicRepo = context.read<TopicRepository>();
    final progressProvider = context.read<ProgressProvider>();
    final childId = context.read<ChildProvider>().selectedChild?.id;

    try {
      final lesson = await topicRepo.fetchLessonById(widget.lessonId);
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
      final topicRepo = context.read<TopicRepository>();
      final ttsRepo = context.read<TtsRepository>();
      
      // Lấy Base URL để nối vào đường dẫn audio tương đối từ server
      final baseUrl = topicRepo.apiClient.dio.options.baseUrl.replaceAll('/api/', '');
      
      final response = await ttsRepo.synthesize(text);
      final fullUrl = response.audioUrl.startsWith('http') 
          ? response.audioUrl 
          : '$baseUrl${response.audioUrl}';
          
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi âm thanh: $e')));
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
          // Hiện thông báo nhận huy hiệu mới
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.blueAccent, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Giờ học đến rồi!', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('Ối! Không thể tải bài học.', style: TextStyle(fontSize: 18)),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () => setState(() { _lessonFuture = _fetchLessonAndStatus(); }),
                     child: const Text('Thử lại'),
                   )
                 ],
               ),
             );
          }

          final lesson = snapshot.data!;
          final plainTextContent = ContentParser.parseToPlainText(lesson.contentJson);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_stories, size: 60, color: Colors.orangeAccent),
                      const SizedBox(height: 16),
                      Text(lesson.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      if (lesson.description != null) ...[
                        const SizedBox(height: 8),
                        Text(lesson.description!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600)),
                      ],
                      if (_isCompleted)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Đã hoàn thành ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (plainTextContent.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(children: [Icon(Icons.lightbulb, color: Colors.amber), SizedBox(width: 8), Text('Nội dung', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                            IconButton(onPressed: () => _readAloud(plainTextContent), icon: Icon(_isPlaying ? Icons.stop_circle : Icons.volume_up, color: Colors.blueAccent)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.shade100, width: 2)),
                          child: Text(plainTextContent, style: const TextStyle(fontSize: 18, height: 1.5, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (lesson.vocabularies != null && lesson.vocabularies!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(children: [Icon(Icons.star, color: Colors.purpleAccent), SizedBox(width: 8), Text('Từ vựng mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lesson.vocabularies!.length,
                      itemBuilder: (context, index) {
                        final vocab = lesson.vocabularies![index];
                        final List<Color> colors = [Colors.green.shade50, Colors.orange.shade50, Colors.purple.shade50];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: colors[index % colors.length], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(vocab.word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                              Text(vocab.phoneticText ?? '', style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                              const Divider(),
                              Expanded(child: Center(child: Text(vocab.meaning, textAlign: TextAlign.center))),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(icon: const Icon(Icons.volume_up, color: Colors.blueAccent), onPressed: () => _readAloud(vocab.word)),
                                  IconButton(icon: const Icon(Icons.mic, color: Colors.redAccent), onPressed: () => _showPronunciationDialog(vocab)),
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
      floatingActionButton: _isSubmitting 
        ? const CircularProgressIndicator()
        : FloatingActionButton.extended(
            onPressed: _finishLesson,
            label: Text(_isCompleted ? 'Quay lại bài học' : 'Con đã học xong!'),
            icon: Icon(_isCompleted ? Icons.arrow_back : Icons.check_circle),
            backgroundColor: _isCompleted ? Colors.blueAccent : Colors.green,
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
      const SnackBar(content: Text('Tính năng ghi âm cần thư viện record. API chấm điểm đã sẵn sàng!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PronunciationProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      title: const Center(child: Text('Tập nói cùng AI')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.vocab.word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 20),
          if (provider.isScoring)
            const CircularProgressIndicator()
          else if (provider.lastScore != null)
            Column(
              children: [
                Text('Điểm số: ${provider.lastScore!.overallScore}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(provider.lastScore!.feedback, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Icon(
                  provider.lastScore!.isPassed ? Icons.check_circle : Icons.error,
                  color: provider.lastScore!.isPassed ? Colors.green : Colors.orange,
                  size: 50,
                ),
              ],
            )
          else
            const Text('Nhấn mic và đọc to từ trên nhé!'),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.blueAccent,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 40, color: Colors.white),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            provider.clearLastScore();
            Navigator.pop(context);
          },
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
