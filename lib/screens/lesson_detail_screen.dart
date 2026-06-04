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
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _lessonFuture = _fetchLesson();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Lesson> _fetchLesson() async {
    final repository = context.read<TopicRepository>();
    try {
      final lesson = await repository.fetchLessonById(widget.lessonId);
      await _cacheService.saveLesson(lesson);
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
      final response = await ttsRepo.synthesize(text);
      await _audioPlayer.play(UrlSource(response.audioUrl));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
    final childId = context.read<ChildProvider>().selectedChild?.id;
    if (childId == null) return;
    final duration = DateTime.now().difference(_startTime).inSeconds;
    setState(() => _isSubmitting = true);
    try {
      final success = await context.read<ProgressProvider>().submitProgress(
        childId: childId,
        lessonId: widget.lessonId,
        scorePercent: 100,
        timeSpentSeconds: duration > 0 ? duration : 1,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Học giỏi quá! Đã lưu kết quả.')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          if (snapshot.hasError) return const Center(child: Text('Ối! Không thể tải bài học.'));

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
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _isSubmitting 
        ? const CircularProgressIndicator()
        : FloatingActionButton.extended(
            onPressed: _finishLesson,
            label: const Text('Con đã học xong!'),
            icon: const Icon(Icons.check_circle),
            backgroundColor: Colors.green,
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
      // Giả lập ghi âm trong 2 giây vì không có thư viện record trong pubspec
      // Trong thực tế, bạn sẽ dùng thư viện 'record' để lưu file WAV
      await Future.delayed(const Duration(seconds: 2));
      _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    setState(() => _isRecording = false);
    
    // Lưu ý: Đây là phần mockup file vì hiện tại môi trường chưa cài thư viện ghi âm
    // Nhưng API đã sẵn sàng để gửi file.
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
