import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/lesson_repository.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../local/cache_service.dart';
import 'lesson_detail_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  final String topicId;
  final String topicName;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late Future<List<Lesson>> _lessonsFuture;
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _fetchLessons();
  }

  Future<List<Lesson>> _fetchLessons() async {
    final repository = context.read<LessonRepository>();
    try {
      final lessons = await repository.getLessonsByTopic(widget.topicId);
      await _cacheService.saveLessonsForTopic(widget.topicId, lessons);
      return lessons;
    } catch (e) {
      final cached = _cacheService.getLessonsForTopic(widget.topicId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final childId = context.read<ChildProvider>().selectedChild?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.topicName,
          style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.blueAccent),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => _buildScoringGuideSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải bài học'));
          }

          final lessons = snapshot.data ?? [];
          if (lessons.isEmpty) {
            return const Center(child: Text('Chủ đề này chưa có bài học nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              
              // Kiểm tra xem bài học này đã xong chưa từ API Progress
              final lessonProgresses = progressProvider.completedLessons.where((p) => p.lessonId == lesson.id).toList();
              final isDone = lessonProgresses.isNotEmpty;
              final starsEarned = isDone ? lessonProgresses.first.starsEarned : 0;
              final starsText = List.filled(starsEarned > 0 ? starsEarned : 1, '⭐').join('');

              int completedGames = 0;
              if (!isDone) {
                try {
                  final cacheBox = Hive.box('kidio_cache');
                  if (cacheBox.get('${childId}_lesson_${lesson.id}_vocab', defaultValue: false)) completedGames++;
                  if (cacheBox.get('${childId}_lesson_${lesson.id}_listening', defaultValue: false)) completedGames++;
                  if (cacheBox.get('${childId}_lesson_${lesson.id}_pron', defaultValue: false)) completedGames++;
                  if (cacheBox.get('${childId}_lesson_${lesson.id}_quiz', defaultValue: false)) completedGames++;
                  if (cacheBox.get('${childId}_lesson_${lesson.id}_boss', defaultValue: false)) completedGames++;
                } catch (_) {}
              }

              String subtitleText;
              if (isDone) {
                subtitleText = starsEarned > 0 ? 'Đã nhận $starsEarned sao! $starsText' : 'Chưa đạt đủ điểm nhận sao';
              } else {
                subtitleText = completedGames > 0 ? 'Tiến độ: $completedGames/5 phần thi' : (lesson.description ?? 'Nhấn để bắt đầu học');
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: (isDone ? Colors.green : Colors.blue).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: isDone ? Border.all(color: Colors.green.withOpacity(0.2), width: 1) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (isDone ? Colors.green : Colors.blue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone 
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)
                        : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blueAccent)),
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 17, 
                      color: const Color(0xFF1A237E),
                      decoration: isDone ? TextDecoration.none : null,
                    ),
                  ),
                  subtitle: Text(
                    subtitleText,
                    style: TextStyle(
                      color: isDone 
                          ? (starsEarned > 0 ? Colors.green : Colors.orange) 
                          : (completedGames > 0 ? Colors.blueAccent : Colors.blueGrey), 
                      fontWeight: (isDone || completedGames > 0) ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LessonDetailScreen(lessonId: lesson.id)),
                    );
                    // Refresh progress when coming back
                    if (childId != null) progressProvider.loadChildProgress(childId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScoringGuideSheet() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Text('🌟', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cách Tính Điểm Thưởng',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Để nhận được sao, con chỉ cần hoàn thành đầy đủ tất cả 5 thử thách trong bài học! Rất đơn giản phải không nào?',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey, height: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildScoreRuleItem('⭐⭐⭐', 'Tuyệt Vời!', 'Hoàn thành 5/5 thử thách', Colors.amber),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Đã Rõ Luật Chơi!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRuleItem(String stars, String title, String range, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(stars, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(range, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
