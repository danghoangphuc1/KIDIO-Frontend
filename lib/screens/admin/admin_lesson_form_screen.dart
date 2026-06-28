import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/lesson_repository.dart';
import '../../repositories/topic_repository.dart';

class AdminLessonFormScreen extends StatefulWidget {
  final String? topicId;
  final Lesson? lesson; // Null for create mode
  final int? nextOrderIndex;

  const AdminLessonFormScreen({super.key, this.topicId, this.lesson, this.nextOrderIndex});

  @override
  State<AdminLessonFormScreen> createState() => _AdminLessonFormScreenState();
}

class _AdminLessonFormScreenState extends State<AdminLessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _diffCtrl;
  late TextEditingController _focusCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _thumbCtrl;
  late TextEditingController _audioCtrl;
  late TextEditingController _orderIndexCtrl;
  late TextEditingController _contentJsonCtrl;

  bool _isFetching = false;
  String? _selectedTopicId;
  List<Topic> _topics = [];

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.topicId;
    final l = widget.lesson;
    _titleCtrl = TextEditingController(text: l?.title ?? '');
    _descCtrl = TextEditingController(text: l?.description ?? '');
    _typeCtrl = TextEditingController(text: l?.lessonType ?? 'Story');
    _diffCtrl = TextEditingController(text: l?.difficulty ?? 'Beginner');
    _focusCtrl = TextEditingController(text: l?.skillFocus ?? 'Listening');
    _durationCtrl = TextEditingController(text: l?.durationSeconds?.toString() ?? '180');
    _thumbCtrl = TextEditingController(text: l?.thumbnailUrl ?? '');
    _audioCtrl = TextEditingController(text: l?.audioUrl ?? '');
    
    String orderText = '';
    if (l != null) {
      orderText = l.orderIndex.toString();
    } else if (widget.nextOrderIndex != null) {
      orderText = widget.nextOrderIndex.toString();
    } else {
      orderText = '1';
    }
    _orderIndexCtrl = TextEditingController(text: orderText);
    
    _contentJsonCtrl = TextEditingController(text: l?.contentJson ?? '');

    _fetchTopics();

    if (l != null) {
      _fetchFullLesson(l.id);
    }
  }

  Future<void> _fetchTopics() async {
    try {
      final repo = context.read<TopicRepository>();
      final topicsResult = await repo.fetchTopics(pageSize: 1000);
      if (!mounted) return;
      setState(() {
        _topics = topicsResult.items;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _fetchFullLesson(String id) async {
    setState(() => _isFetching = true);
    try {
      final repo = context.read<LessonRepository>();
      final fullLesson = await repo.getLessonById(id);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = fullLesson.title;
        _descCtrl.text = fullLesson.description ?? '';
        _typeCtrl.text = fullLesson.lessonType ?? 'Story';
        _diffCtrl.text = fullLesson.difficulty ?? 'Beginner';
        _focusCtrl.text = fullLesson.skillFocus ?? 'Listening';
        _durationCtrl.text = fullLesson.durationSeconds?.toString() ?? '180';
        _thumbCtrl.text = fullLesson.thumbnailUrl ?? '';
        _audioCtrl.text = fullLesson.audioUrl ?? '';
        _orderIndexCtrl.text = fullLesson.orderIndex.toString();
        _contentJsonCtrl.text = fullLesson.contentJson ?? '';
        _isFetching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetching = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _typeCtrl.dispose();
    _diffCtrl.dispose();
    _focusCtrl.dispose();
    _durationCtrl.dispose();
    _thumbCtrl.dispose();
    _audioCtrl.dispose();
    _orderIndexCtrl.dispose();
    _contentJsonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTopicId == null) {
      CustomSnackBar.showError(context, 'Vui lòng chọn một Chủ đề (Topic)', prefix: '');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = context.read<LessonRepository>();
      
      final duration = int.tryParse(_durationCtrl.text);
      final order = int.tryParse(_orderIndexCtrl.text);

      if (widget.lesson == null) {
        // Create
        await repo.createLesson(
          title: _titleCtrl.text.trim(),
          topicId: _selectedTopicId!,
          description: _descCtrl.text.trim(),
          lessonType: _typeCtrl.text.trim(),
          difficulty: _diffCtrl.text.trim(),
          skillFocus: _focusCtrl.text.trim(),
          durationSeconds: duration,
          thumbnailUrl: _thumbCtrl.text.trim(),
          audioUrl: _audioCtrl.text.trim(),
          orderIndex: order,
          contentJson: _contentJsonCtrl.text.trim(),
        );
        CustomSnackBar.show(context, 'Thêm bài học thành công!');
      } else {
        // Update
        await repo.updateLesson(
          lessonId: widget.lesson!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          lessonType: _typeCtrl.text.trim(),
          difficulty: _diffCtrl.text.trim(),
          skillFocus: _focusCtrl.text.trim(),
          durationSeconds: duration,
          thumbnailUrl: _thumbCtrl.text.trim(),
          audioUrl: _audioCtrl.text.trim(),
          orderIndex: order,
          contentJson: _contentJsonCtrl.text.trim(),
          isPublished: widget.lesson!.isPublished,
        );
        CustomSnackBar.show(context, 'Cập nhật bài học thành công!');
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
    final isEdit = widget.lesson != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa Bài học' : 'Thêm Bài học mới',
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
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.lesson == null && widget.topicId == null) ...[
                DropdownButtonFormField<String>(
                  value: _selectedTopicId,
                  decoration: const InputDecoration(
                    labelText: 'Chủ đề (*)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: _topics.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTopicId = val;
                    });
                  },
                  validator: (val) => val == null ? 'Vui lòng chọn Chủ đề' : null,
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(_titleCtrl, 'Tên bài học (*)', true),
              const SizedBox(height: 16),
              _buildTextField(_descCtrl, 'Mô tả', false, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Loại bài học (*)',
                      value: _typeCtrl.text.isEmpty ? null : _typeCtrl.text,
                      items: const ['Story', 'Dialogue', 'VideoShort', 'PronunciationDrill'],
                      onChanged: (val) { if (val != null) _typeCtrl.text = val; },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Độ khó (*)',
                      value: _diffCtrl.text.isEmpty ? null : _diffCtrl.text,
                      items: const ['Beginner', 'Elementary', 'PreIntermediate'],
                      onChanged: (val) { if (val != null) _diffCtrl.text = val; },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Kỹ năng (*)',
                      value: _focusCtrl.text.isEmpty ? null : _focusCtrl.text,
                      items: const ['Listening', 'Speaking', 'Vocabulary', 'Pronunciation'],
                      onChanged: (val) { if (val != null) _focusCtrl.text = val; },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_durationCtrl, 'Thời lượng (giây)', false, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildUrlFieldWithDropdown(
                ctrl: _thumbCtrl,
                label: 'URL Ảnh Thumbnail',
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
                label: 'URL Video/Audio',
                sampleUrls: [
                  {'name': 'Audio Cat', 'url': 'https://dict.youdao.com/dictvoice?audio=cat&type=1'},
                  {'name': 'Audio Dog', 'url': 'https://dict.youdao.com/dictvoice?audio=dog&type=1'},
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_orderIndexCtrl, 'Thứ tự hiển thị (Order)', false, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_contentJsonCtrl, 'Nội dung (Content JSON)', false, maxLines: 5),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'CẬP NHẬT BÀI HỌC' : 'TẠO BÀI HỌC',
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = (value != null && items.contains(value)) ? value : items.first;
    if (validValue != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(validValue);
      });
    }

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true, // Fix overflow issue
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item, 
        child: Text(item, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Vui lòng chọn';
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

