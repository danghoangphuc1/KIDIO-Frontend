import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/topic_repository.dart';
import 'admin_topic_form_screen.dart';
import 'admin_lesson_list_screen.dart';

class AdminTopicListScreen extends StatefulWidget {
  final bool isEmbedded;
  const AdminTopicListScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminTopicListScreen> createState() => _AdminTopicListScreenState();
}

class _AdminTopicListScreenState extends State<AdminTopicListScreen> {
  bool _isLoading = true;
  List<Topic> _topics = [];
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = context.read<TopicRepository>();
      final result = await repo.fetchTopics(pageSize: 100);
      setState(() {
        _topics = result.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải danh sách chủ đề: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTopic(Topic topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá chủ đề "${topic.name}" không?'),
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
      final repo = context.read<TopicRepository>();
      await repo.deleteTopic(topic.id);
      CustomSnackBar.show(context, 'Xoá chủ đề thành công!');
      _fetchTopics();
    } catch (e) {
      CustomSnackBar.show(context, 'Lỗi khi xoá: $e', isError: true);
    }
  }

  void _navigateToForm([Topic? topic]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminTopicFormScreen(topic: topic),
      ),
    );
    if (result == true) {
      _fetchTopics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : const Color(0xFFF8FBFF),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Quản lý Chủ đề',
                style: TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w900,
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
              hintText: 'Tìm kiếm chủ đề...',
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
              onPressed: _fetchTopics,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final filtered = _topics.where((t) => 
      t.name.toLowerCase().contains(_searchQuery)
    ).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy chủ đề nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final topic = filtered[index];
        final bool isPublished = topic.isActive ?? true;
        final String emoji = _getEmojiForTopic(topic.name);
        final Color bgColor = _getColorForTopic(topic.name);

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
                    builder: (_) => AdminLessonListScreen(topic: topic),
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
                        color: bgColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: topic.iconUrl != null && topic.iconUrl!.isNotEmpty
                            ? Image.network(
                                topic.iconUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                              )
                            : Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${topic.totalLessons ?? 0} lessons',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trailing Actions (Badge and Trash)
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
                              onTap: () => _navigateToForm(topic),
                              child: const Icon(Icons.edit_rounded, color: Color(0xFF9CA3AF), size: 20),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _deleteTopic(topic),
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

  String _getEmojiForTopic(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('animal')) return '🦁';
    if (lower.contains('food') || lower.contains('drink') || lower.contains('fruit')) return '🍎';
    if (lower.contains('family')) return '👨‍👩‍👧‍👦';
    if (lower.contains('school') || lower.contains('class')) return '🎒';
    if (lower.contains('color')) return '🎨';
    if (lower.contains('number')) return '🔢';
    if (lower.contains('body')) return '👤';
    if (lower.contains('letter') || lower.contains('alphabet')) return '🅰️';
    if (lower.contains('weather') || lower.contains('season')) return '🌤️';
    if (lower.contains('vehicle') || lower.contains('transport')) return '🚗';
    if (lower.contains('toy') || lower.contains('game')) return '🧸';
    if (lower.contains('clothes')) return '👕';
    return '📚';
  }

  Color _getColorForTopic(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('animal')) return const Color(0xFFF59E0B);
    if (lower.contains('food')) return const Color(0xFFEF4444);
    if (lower.contains('family')) return const Color(0xFF3B82F6);
    if (lower.contains('school')) return const Color(0xFF10B981);
    if (lower.contains('space')) return const Color(0xFF7C3AED);
    return const Color(0xFF6366F1);
  }
}

