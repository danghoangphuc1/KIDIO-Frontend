import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/topic_repository.dart';
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
  late Future<Lesson> _lessonFuture;

  @override
  void initState() {
    super.initState();
    _lessonFuture = _fetchLesson();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Details'),
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lesson = snapshot.data!;
          final plainTextContent = ContentParser.parseToPlainText(lesson.contentJson);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.description ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                if (plainTextContent.isNotEmpty) ...[
                  const Text('Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(plainTextContent),
                  ),
                  const SizedBox(height: 24),
                ],
                if (lesson.vocabularies != null && lesson.vocabularies!.isNotEmpty) ...[
                  const Text('Vocabularies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lesson.vocabularies!.length,
                    itemBuilder: (context, index) {
                      final vocab = lesson.vocabularies![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(vocab.word, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          subtitle: Text('${vocab.phoneticText ?? ""} • ${vocab.meaning}'),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
