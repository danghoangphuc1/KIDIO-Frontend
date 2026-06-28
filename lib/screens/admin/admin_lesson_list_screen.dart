import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/lesson_repository.dart';
import 'admin_lesson_form_screen.dart';
import 'admin_vocabulary_list_screen.dart';
import '../../utils/snackbar_utils.dart';

class AdminLessonListScreen extends StatefulWidget {
  final Topic? topic;
  final bool isEmbedded;

  const AdminLessonListScreen({super.key, this.topic, this.isEmbedded = false});

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
      List<Lesson> result;
      if (widget.topic != null) {
        result = await repo.getLessonsByTopic(widget.topic!.id);
      } else {
        final pagedResult = await repo.getAllLessons(pageSize: 100);
        result = pagedResult.items ?? [];
      }
      
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
        builder: (_) => AdminLessonFormScreen(topicId: widget.topic?.id, lesson: lesson, nextOrderIndex: nextOrderIndex),
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
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                widget.topic != null ? 'Bài học: ${widget.topic!.name}' : 'Quản lý Bài học',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.blue.shade700,
        label: const Text('Thêm mới', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
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
        final bool isPublished = lesson.isPublished;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminVocabularyListScreen(lesson: lesson),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon Box
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: lesson.thumbnailUrl != null && lesson.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                lesson.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(_getEmojiForLesson(lesson.lessonType, lesson.title), style: const TextStyle(fontSize: 24)),
                                ),
                              )
                            : Center(
                                child: Text(_getEmojiForLesson(lesson.lessonType, lesson.title), style: const TextStyle(fontSize: 24)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lesson.lessonType ?? 'General'} | Order: ${lesson.orderIndex}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trailing Actions (Badge and Icons)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPublished ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              color: isPublished ? const Color(0xFF059669) : const Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _togglePublish(lesson),
                              child: Icon(isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF9CA3AF), size: 20),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _navigateToForm(lesson),
                              child: const Icon(Icons.edit_rounded, color: Color(0xFF9CA3AF), size: 20),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _deleteLesson(lesson),
                              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getEmojiForLesson(String? type, String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('animal') || lowerTitle.contains('pet')) return '🦁';
    if (lowerTitle.contains('food') || lowerTitle.contains('drink') || lowerTitle.contains('fruit')) return '🍎';
    if (lowerTitle.contains('family')) return '👨‍👩‍👧‍👦';
    if (lowerTitle.contains('color')) return '🎨';
    if (lowerTitle.contains('number')) return '🔢';
    
    if (type == null) return '📖';
    final lower = type.toLowerCase();
    if (lower.contains('video')) return '🎥';
    if (lower.contains('audio') || lower.contains('pronunciation')) return '🎙️';
    if (lower.contains('quiz') || lower.contains('game')) return '🎮';
    if (lower.contains('story')) return '📘';
    return '📖';
  }
}
