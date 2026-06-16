import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/topic_repository.dart';

class AdminTopicFormScreen extends StatefulWidget {
  final Topic? topic; // If null, it's Create mode. Else, Edit mode.

  const AdminTopicFormScreen({super.key, this.topic});

  @override
  State<AdminTopicFormScreen> createState() => _AdminTopicFormScreenState();
}

class _AdminTopicFormScreenState extends State<AdminTopicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _iconUrlCtrl;
  late TextEditingController _orderIndexCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.topic?.name ?? '');
    _descCtrl = TextEditingController(text: widget.topic?.description ?? '');
    _iconUrlCtrl = TextEditingController(text: widget.topic?.iconUrl ?? '');
    _orderIndexCtrl = TextEditingController(text: widget.topic?.orderIndex.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _iconUrlCtrl.dispose();
    _orderIndexCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = context.read<TopicRepository>();
      if (widget.topic == null) {
        // Create
        await repo.createTopic(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          iconUrl: _iconUrlCtrl.text.trim(),
          orderIndex: int.tryParse(_orderIndexCtrl.text),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm chủ đề thành công!')),
        );
      } else {
        // Update
        await repo.updateTopic(
          topicId: widget.topic!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          iconUrl: _iconUrlCtrl.text.trim(),
          orderIndex: int.tryParse(_orderIndexCtrl.text),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật chủ đề thành công!')),
        );
      }
      Navigator.pop(context, true); // Return true to indicate success
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
    final isEdit = widget.topic != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa Chủ đề' : 'Thêm Chủ đề mới',
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.w900,
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
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên Chủ đề (*)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên chủ đề';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'URL Icon/Hình ảnh',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderIndexCtrl,
                decoration: InputDecoration(
                  labelText: 'Thứ tự hiển thị (Order Index)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Thứ tự phải là một số nguyên';
                  }
                  return null;
                },
              ),
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
                          isEdit ? 'CẬP NHẬT CHỦ ĐỀ' : 'TẠO CHỦ ĐỀ',
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
}
