import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/topic_repository.dart';
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
    final repository = context.read<TopicRepository>();
    try {
      final lessons = await repository.fetchLessonsByTopicId(widget.topicId);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
        elevation: 2,
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _lessonsFuture = _fetchLessons();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final lessons = snapshot.data ?? [];
          if (lessons.isEmpty) {
            return const Center(child: Text('No lessons found for this topic.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: lessons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${lesson.orderIndex}'),
                  ),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lesson.description ?? 'No description'),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.blue),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonDetailScreen(lessonId: lesson.id),
                      ),
                    );
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
