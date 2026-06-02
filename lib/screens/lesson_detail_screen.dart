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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.blueAccent, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Learning Time!', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Oops! Failed to load lesson.', style: TextStyle(fontSize: 18)),
                  TextButton(onPressed: () => setState(() { _lessonFuture = _fetchLesson(); }), child: const Text('Try Again')),
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
                // Top Header with illustration-like space
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_stories, size: 60, color: Colors.orangeAccent),
                      const SizedBox(height: 16),
                      Text(
                        lesson.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      if (lesson.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          lesson.description!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Content Section
                if (plainTextContent.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Story Content', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.blue.shade100, width: 2),
                          ),
                          child: Text(
                            plainTextContent,
                            style: const TextStyle(fontSize: 18, height: 1.5, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Vocabularies Section
                if (lesson.vocabularies != null && lesson.vocabularies!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.purpleAccent),
                        SizedBox(width: 8),
                        Text('New Words', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lesson.vocabularies!.length,
                      itemBuilder: (context, index) {
                        final vocab = lesson.vocabularies![index];
                        final List<Color> cardColors = [
                          Colors.green.shade50,
                          Colors.orange.shade50,
                          Colors.purple.shade50,
                          Colors.pink.shade50,
                        ];
                        final List<Color> borderColors = [
                          Colors.green.shade200,
                          Colors.orange.shade200,
                          Colors.purple.shade200,
                          Colors.pink.shade200,
                        ];

                        return Container(
                          width: 160,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColors[index % cardColors.length],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColors[index % borderColors.length], width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                vocab.word,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vocab.phoneticText ?? '',
                                style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                              ),
                              const Divider(),
                              Text(
                                vocab.meaning,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Play audio or start quiz
        },
        label: const Text('Read for me'),
        icon: const Icon(Icons.play_arrow),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}
