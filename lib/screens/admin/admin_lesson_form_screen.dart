import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/lesson_repository.dart';

class AdminLessonFormScreen extends StatefulWidget {
  final String topicId;
  final Lesson? lesson; // Null for create mode

  const AdminLessonFormScreen({super.key, required this.topicId, this.lesson});

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

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _titleCtrl = TextEditingController(text: l?.title ?? '');
    _descCtrl = TextEditingController(text: l?.description ?? '');
    _typeCtrl = TextEditingController(text: l?.lessonType ?? 'Video');
    _diffCtrl = TextEditingController(text: l?.difficulty ?? 'Easy');
    _focusCtrl = TextEditingController(text: l?.skillFocus ?? 'Listening');
    _durationCtrl = TextEditingController(text: l?.durationSeconds?.toString() ?? '180');
    _thumbCtrl = TextEditingController(text: l?.thumbnailUrl ?? '');
    _audioCtrl = TextEditingController(text: l?.audioUrl ?? '');
    _orderIndexCtrl = TextEditingController(text: l?.orderIndex.toString() ?? '0');
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
          topicId: widget.topicId,
          description: _descCtrl.text.trim(),
          lessonType: _typeCtrl.text.trim(),
          difficulty: _diffCtrl.text.trim(),
          skillFocus: _focusCtrl.text.trim(),
          durationSeconds: duration,
          thumbnailUrl: _thumbCtrl.text.trim(),
          audioUrl: _audioCtrl.text.trim(),
          orderIndex: order,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm bài học thành công!')),
        );
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
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật bài học thành công!')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_titleCtrl, 'Tên bài học (*)', true),
              const SizedBox(height: 16),
              _buildTextField(_descCtrl, 'Mô tả', false, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_typeCtrl, 'Loại (VD: Video, Quiz)', false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_diffCtrl, 'Độ khó (Easy, Medium)', false)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_focusCtrl, 'Kỹ năng (Listening)', false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_durationCtrl, 'Thời lượng (giây)', false, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_thumbCtrl, 'URL Ảnh Thumbnail', false),
              const SizedBox(height: 16),
              _buildTextField(_audioCtrl, 'URL Video/Audio', false),
              const SizedBox(height: 16),
              _buildTextField(_orderIndexCtrl, 'Thứ tự hiển thị (Order)', false, isNumber: true),
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
}
