import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/vocabulary_repository.dart';
import 'admin_vocabulary_form_screen.dart';

class AdminVocabularyListScreen extends StatefulWidget {
  final Lesson? lesson;

  const AdminVocabularyListScreen({super.key, this.lesson});

  @override
  State<AdminVocabularyListScreen> createState() => _AdminVocabularyListScreenState();
}

class _AdminVocabularyListScreenState extends State<AdminVocabularyListScreen> {
  bool _isLoading = true;
  List<Vocabulary> _vocabularies = [];
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchVocabularies();
  }

  Future<void> _fetchVocabularies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = context.read<VocabularyRepository>();
      final result = await repo.getPaged(pageNumber: 1, pageSize: 100, lessonId: widget.lesson?.id);
      setState(() {
        _vocabularies = result.items ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải danh sách từ vựng: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVocabulary(Vocabulary vocab) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá từ "${vocab.word}" không?'),
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
      final repo = context.read<VocabularyRepository>();
      await repo.deleteVocabulary(vocab.id);
      CustomSnackBar.show(context, 'Xoá từ vựng thành công!');
      _fetchVocabularies();
    } catch (e) {
      CustomSnackBar.show(context, 'Lỗi khi xoá: $e', isError: true);
    }
  }

  void _navigateToForm([Vocabulary? vocab]) async {
    int? nextOrderIndex;
    if (vocab == null) {
      nextOrderIndex = _vocabularies.isEmpty 
          ? 1 
          : (_vocabularies.map((v) => v.orderIndex ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminVocabularyFormScreen(vocabulary: vocab, lesson: widget.lesson, nextOrderIndex: nextOrderIndex),
      ),
    );
    if (result == true) {
      _fetchVocabularies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text(
          widget.lesson != null ? 'Từ vựng: ${widget.lesson!.title}' : 'Quản lý Từ vựng',
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
        backgroundColor: Colors.purple,
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
              hintText: 'Tìm kiếm từ vựng...',
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
              onPressed: _fetchVocabularies,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final filtered = _vocabularies.where((v) => 
      v.word.toLowerCase().contains(_searchQuery) ||
      v.meaning.toLowerCase().contains(_searchQuery)
    ).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy từ vựng nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final vocab = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty
                ? Image.network(
                    vocab.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, size: 48, color: Colors.purple),
                  )
                : const Icon(Icons.spellcheck_rounded, size: 48, color: Colors.purple),
            title: Text(
              vocab.word,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty)
                  Text(
                    '/${vocab.phoneticText}/',
                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 4),
                Text(
                  vocab.meaning,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _navigateToForm(vocab),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteVocabulary(vocab),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

