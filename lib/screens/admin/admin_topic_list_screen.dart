import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/topic_repository.dart';
import 'admin_topic_form_screen.dart';
import 'admin_lesson_list_screen.dart';

class AdminTopicListScreen extends StatefulWidget {
  const AdminTopicListScreen({super.key});

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
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: topic.iconUrl != null && topic.iconUrl!.isNotEmpty
                ? Image.network(
                    topic.iconUrl!,
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  )
                : const Icon(Icons.topic, size: 48, color: Colors.blueAccent),
            title: Text(
              topic.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Lessons: ${topic.totalLessons ?? 0} | Order: ${topic.orderIndex}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _navigateToForm(topic),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTopic(topic),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminLessonListScreen(topic: topic),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

