import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/vocabulary_repository.dart';
import 'admin_vocabulary_form_screen.dart';

class AdminVocabularyListScreen extends StatefulWidget {
  final Lesson? lesson;
  final bool isEmbedded;

  const AdminVocabularyListScreen({super.key, this.lesson, this.isEmbedded = false});

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
      backgroundColor: widget.isEmbedded ? Colors.transparent : const Color(0xFFF8FBFF),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.purple,
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
        final String emoji = _getEmojiForVocab(vocab.word);
        
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty
                          ? Image.network(
                              vocab.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                            )
                          : Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Word and Meaning
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              vocab.word,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '/${vocab.phoneticText}/',
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab.meaning,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trailing Actions (Icons)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToForm(vocab),
                        child: const Icon(Icons.edit_rounded, color: Color(0xFF9CA3AF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteVocabulary(vocab),
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getEmojiForVocab(String word) {
    final lower = word.toLowerCase();
    if (lower.contains('dog') || lower.contains('cat') || lower.contains('bird') || lower.contains('cow') || lower.contains('pig')) return '🐾';
    if (lower.contains('apple') || lower.contains('banana') || lower.contains('orange') || lower.contains('fruit') || lower.contains('milk')) return '🍎';
    if (lower.contains('sun') || lower.contains('moon') || lower.contains('star')) return '⭐';
    if (lower.contains('red') || lower.contains('blue') || lower.contains('green') || lower.contains('color')) return '🎨';
    if (lower.contains('one') || lower.contains('two') || lower.contains('three') || lower.contains('four')) return '🔢';
    if (lower.contains('father') || lower.contains('mother') || lower.contains('brother') || lower.contains('sister') || lower.contains('family')) return '👨‍👩‍👧‍👦';
    if (lower.contains('car') || lower.contains('bus') || lower.contains('train') || lower.contains('bike')) return '🚗';
    return '📝';
  }
}

