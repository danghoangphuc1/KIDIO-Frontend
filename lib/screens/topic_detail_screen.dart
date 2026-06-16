import 'package:flutter/material.dart';
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
              final isDone = progressProvider.completedLessons.any((p) => p.lessonId == lesson.id);

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
                    isDone ? 'Đã hoàn thành xuất sắc! ✨' : (lesson.description ?? 'Nhấn để bắt đầu học'),
                    style: TextStyle(color: isDone ? Colors.green : Colors.blueGrey, fontWeight: isDone ? FontWeight.bold : FontWeight.normal),
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
}
