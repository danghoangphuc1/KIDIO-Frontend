import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/lesson_repository.dart';
import 'admin_lesson_form_screen.dart';
import 'admin_vocabulary_list_screen.dart';
import '../../utils/snackbar_utils.dart';

class AdminLessonListScreen extends StatefulWidget {
  final Topic topic;

  const AdminLessonListScreen({super.key, required this.topic});

  @override
  State<AdminLessonListScreen> createState() => _AdminLessonListScreenState();
}

class _AdminLessonListScreenState extends State<AdminLessonListScreen> {
  bool _isLoading = true;
  List<Lesson> _lessons = [];
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = context.read<LessonRepository>();
      final result = await repo.getLessonsByTopic(widget.topic.id);
      setState(() {
        _lessons = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải danh sách bài học: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá bài học "${lesson.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = context.read<LessonRepository>();
      await repo.deleteLesson(lesson.id);
      CustomSnackBar.show(context, 'Xoá bài học thành công!');
      _fetchLessons();
    } catch (e) {
      CustomSnackBar.show(context, 'Lỗi khi xoá: $e', isError: true);
    }
  }

  Future<void> _togglePublish(Lesson lesson) async {
    try {
      final repo = context.read<LessonRepository>();
      if (lesson.isPublished) {
        await repo.unpublishLesson(lesson.id);
      } else {
        await repo.publishLesson(lesson.id);
      }
      _fetchLessons(); // Reload after toggle
    } catch (e) {
      CustomSnackBar.show(context, 'Lỗi: $e', isError: true);
    }
  }

  void _navigateToForm([Lesson? lesson]) async {
    int? nextOrderIndex;
    if (lesson == null) {
      nextOrderIndex = _lessons.isEmpty 
          ? 1 
          : (_lessons.map((l) => l.orderIndex).reduce((a, b) => a > b ? a : b) + 1);
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLessonFormScreen(topicId: widget.topic.id, lesson: lesson, nextOrderIndex: nextOrderIndex),
      ),
    );
    if (result == true) {
      _fetchLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text(
          'Bài học: ${widget.topic.name}',
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bài học...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.toLowerCase());
            },
          ),
        ),
        Expanded(
          child: _buildList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLessons,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final filtered = _lessons.where((l) => 
      l.title.toLowerCase().contains(_searchQuery)
    ).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Chủ đề này chưa có bài học nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final lesson = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            shape: const Border(), // Removes top/bottom border when expanded
            tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            leading: lesson.thumbnailUrl != null && lesson.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    lesson.thumbnailUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.play_circle_filled, size: 48, color: Colors.blueAccent),
                  )
                : const Icon(Icons.play_circle_filled, size: 48, color: Colors.blueAccent),
            title: Text(
              lesson.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${lesson.lessonType ?? 'General'} | Order: ${lesson.orderIndex}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: lesson.isPublished ? Colors.green.shade100 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: lesson.isPublished ? Colors.green.shade800 : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.spellcheck_rounded, color: Colors.purple, size: 20),
                      label: const Text('Từ vựng', style: TextStyle(color: Colors.purple)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminVocabularyListScreen(lesson: lesson),
                          ),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: Icon(
                        lesson.isPublished ? Icons.visibility_off : Icons.visibility,
                        color: lesson.isPublished ? Colors.grey : Colors.green,
                        size: 20,
                      ),
                      label: Text(lesson.isPublished ? 'Ẩn' : 'Hiện', style: TextStyle(color: lesson.isPublished ? Colors.grey : Colors.green)),
                      onPressed: () => _togglePublish(lesson),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                      label: const Text('Sửa', style: TextStyle(color: Colors.orange)),
                      onPressed: () => _navigateToForm(lesson),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      label: const Text('Xoá', style: TextStyle(color: Colors.red)),
                      onPressed: () => _deleteLesson(lesson),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
