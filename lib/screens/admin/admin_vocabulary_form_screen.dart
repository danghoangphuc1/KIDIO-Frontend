import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/vocabulary_repository.dart';
import '../../repositories/lesson_repository.dart';

class AdminVocabularyFormScreen extends StatefulWidget {
  final Vocabulary? vocabulary; // Null for create mode
  final Lesson? lesson;
  final int? nextOrderIndex;

  const AdminVocabularyFormScreen({super.key, this.vocabulary, this.lesson, this.nextOrderIndex});

  @override
  State<AdminVocabularyFormScreen> createState() => _AdminVocabularyFormScreenState();
}

class _AdminVocabularyFormScreenState extends State<AdminVocabularyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetchingLessons = false;

  List<Lesson> _lessons = [];
  String? _selectedLessonId;

  late TextEditingController _wordCtrl;
  late TextEditingController _meaningCtrl;
  late TextEditingController _phoneticCtrl;
  late TextEditingController _audioCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _orderIndexCtrl;
  late TextEditingController _exampleSentenceCtrl;

  @override
  void initState() {
    super.initState();
    final v = widget.vocabulary;
    _wordCtrl = TextEditingController(text: v?.word ?? '');
    _meaningCtrl = TextEditingController(text: v?.meaning ?? '');
    _phoneticCtrl = TextEditingController(text: v?.phoneticText ?? '');
    _audioCtrl = TextEditingController(text: v?.audioUrl ?? '');
    _imageCtrl = TextEditingController(text: v?.imageUrl ?? '');
    
    String orderText = '';
    if (v != null) {
      orderText = v.orderIndex?.toString() ?? '0';
    } else if (widget.nextOrderIndex != null) {
      orderText = widget.nextOrderIndex.toString();
    } else {
      orderText = '1';
    }
    _orderIndexCtrl = TextEditingController(text: orderText);
    
    _exampleSentenceCtrl = TextEditingController(text: v?.exampleSentence ?? '');

    if (widget.lesson == null && widget.vocabulary == null) {
      _fetchLessons();
    }
  }

  Future<void> _fetchLessons() async {
    setState(() => _isFetchingLessons = true);
    try {
      final repo = context.read<LessonRepository>();
      final result = await repo.getAllLessons(pageSize: 1000);
      setState(() {
        _lessons = result.items;
        if (_lessons.isNotEmpty) {
          _selectedLessonId = _lessons.first.id;
        }
      });
    } catch (e) {
      debugPrint('Error fetching lessons: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingLessons = false);
      }
    }
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _meaningCtrl.dispose();
    _phoneticCtrl.dispose();
    _audioCtrl.dispose();
    _imageCtrl.dispose();
    _orderIndexCtrl.dispose();
    _exampleSentenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = context.read<VocabularyRepository>();
      
      final order = int.tryParse(_orderIndexCtrl.text);

      if (widget.vocabulary == null) {
        // Create
        await repo.createVocabulary(
          word: _wordCtrl.text.trim(),
          meaning: _meaningCtrl.text.trim(),
          lessonId: widget.lesson?.id ?? _selectedLessonId!,
          phoneticText: _phoneticCtrl.text.trim(),
          audioUrl: _audioCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          orderIndex: order,
          exampleSentence: _exampleSentenceCtrl.text.trim(),
        );
        CustomSnackBar.show(context, 'Thêm từ vựng thành công!');
      } else {
        // Update
        await repo.updateVocabulary(
          vocabId: widget.vocabulary!.id,
          word: _wordCtrl.text.trim(),
          meaning: _meaningCtrl.text.trim(),
          phoneticText: _phoneticCtrl.text.trim(),
          audioUrl: _audioCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          orderIndex: order,
          exampleSentence: _exampleSentenceCtrl.text.trim(),
        );
        CustomSnackBar.show(context, 'Cập nhật từ vựng thành công!');
      }
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CustomSnackBar.showError(context, e, prefix: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vocabulary != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa Từ vựng' : 'Thêm Từ vựng mới',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.lesson == null && !isEdit) ...[
                if (_isFetchingLessons) 
                  const Center(child: CircularProgressIndicator())
                else 
                  DropdownButtonFormField<String>(
                    value: _selectedLessonId,
                    decoration: InputDecoration(
                      labelText: 'Chọn Bài học (*)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _lessons.map((l) => DropdownMenuItem(
                      value: l.id, 
                      child: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) {
                      setState(() { _selectedLessonId = val; });
                    },
                    validator: (val) => val == null ? 'Vui lòng chọn bài học' : null,
                  ),
                const SizedBox(height: 16),
              ],
              _buildTextField(_wordCtrl, 'Từ vựng (Tiếng Anh) (*)', true),
              const SizedBox(height: 16),
              _buildTextField(_meaningCtrl, 'Nghĩa (Tiếng Việt) (*)', true),
              const SizedBox(height: 16),
              _buildTextField(_phoneticCtrl, 'Phiên âm (VD: /\u0027æp.əl/)', false),
              const SizedBox(height: 16),
              _buildUrlFieldWithDropdown(
                ctrl: _imageCtrl,
                label: 'URL Hình ảnh minh họa',
                sampleUrls: [
                  {'name': 'Ảnh Koala (gấu túi)', 'url': 'https://cdn-icons-png.flaticon.com/512/3069/3069172.png'},
                  {'name': 'Ảnh Cua', 'url': 'https://cdn-icons-png.flaticon.com/512/3069/3069168.png'},
                  {'name': 'Ảnh Bò', 'url': 'https://img.icons8.com/color/512/cow.png'},
                  {'name': 'Khỉ (Monkey)', 'url': 'https://cdn-icons-png.flaticon.com/512/3468/3468081.png'},
                  {'name': 'Màu Đỏ (Red)', 'url': 'https://placehold.co/512x512/red/red.png'},
                  {'name': 'Màu Xanh lá (Green)', 'url': 'https://placehold.co/512x512/green/green.png'},
                  {'name': 'Màu Xanh dương (Blue)', 'url': 'https://placehold.co/512x512/blue/blue.png'},
                ],
              ),
              const SizedBox(height: 16),
              _buildUrlFieldWithDropdown(
                ctrl: _audioCtrl,
                label: 'URL File phát âm (Audio)',
                sampleUrls: [
                  {'name': 'Audio Cat', 'url': 'https://dict.youdao.com/dictvoice?audio=cat&type=1'},
                  {'name': 'Audio Dog', 'url': 'https://dict.youdao.com/dictvoice?audio=dog&type=1'},
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_orderIndexCtrl, 'Thứ tự hiển thị (Order)', false, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_exampleSentenceCtrl, 'Câu ví dụ (Example Sentence)', false, maxLines: 2),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'CẬP NHẬT TỪ VỰNG' : 'TẠO TỪ VỰNG',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, bool isRequired, {int maxLines = 1, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return 'Không được để trống';
        }
        if (isNumber && val != null && val.isNotEmpty && int.tryParse(val) == null) {
          return 'Phải là số nguyên';
        }
        return null;
      },
    );
  }

  Widget _buildUrlFieldWithDropdown({
    required TextEditingController ctrl,
    required String label,
    required List<Map<String, String>> sampleUrls,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Mẫu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                items: [
                  ...sampleUrls.map((sample) => DropdownMenuItem(
                        value: sample['url'],
                        child: Text(sample['name']!, overflow: TextOverflow.ellipsis),
                      )),
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Trống (Clear)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ctrl.text = val;
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

