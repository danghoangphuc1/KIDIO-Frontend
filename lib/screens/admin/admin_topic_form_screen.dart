import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/topic_repository.dart';

class AdminTopicFormScreen extends StatefulWidget {
  final Topic? topic; // If null, it's Create mode. Else, Edit mode.
  final int? nextOrderIndex;

  const AdminTopicFormScreen({super.key, this.topic, this.nextOrderIndex});

  @override
  State<AdminTopicFormScreen> createState() => _AdminTopicFormScreenState();
}

class _AdminTopicFormScreenState extends State<AdminTopicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = false;

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
    
    String orderText = '';
    if (widget.topic != null) {
      orderText = widget.topic!.orderIndex?.toString() ?? '0';
    } else if (widget.nextOrderIndex != null) {
      orderText = widget.nextOrderIndex.toString();
    } else {
      orderText = '1';
    }
    _orderIndexCtrl = TextEditingController(text: orderText);

    if (widget.topic != null) {
      _fetchFullTopic(widget.topic!.id);
    }
  }

  Future<void> _fetchFullTopic(String id) async {
    setState(() => _isFetching = true);
    try {
      final repo = context.read<TopicRepository>();
      final fullTopic = await repo.fetchTopicById(id);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = fullTopic.name;
        _descCtrl.text = fullTopic.description ?? '';
        _iconUrlCtrl.text = fullTopic.iconUrl ?? '';
        _orderIndexCtrl.text = fullTopic.orderIndex.toString();
        _isFetching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetching = false);
    }
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
        CustomSnackBar.show(context, 'Thêm chủ đề thành công!');
      } else {
        // Update
        await repo.updateTopic(
          topicId: widget.topic!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          iconUrl: _iconUrlCtrl.text.trim(),
          orderIndex: int.tryParse(_orderIndexCtrl.text),
          isActive: widget.topic!.isActive ?? true,
        );
        CustomSnackBar.show(context, 'Cập nhật chủ đề thành công!');
      }
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CustomSnackBar.showError(context, e, prefix: '');
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
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
              _buildUrlFieldWithDropdown(
                ctrl: _iconUrlCtrl,
                label: 'URL Icon/Hình ảnh',
                sampleUrls: [
                  {'name': 'Động vật (Animals)', 'url': 'https://cdn-icons-png.flaticon.com/512/3069/3069172.png'},
                  {'name': 'Gia đình (Family)', 'url': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'},
                  {'name': 'Đồ ăn (Food)', 'url': 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png'},
                  {'name': 'Màu sắc (Colors)', 'url': 'https://cdn-icons-png.flaticon.com/512/2970/2970785.png'},
                  {'name': 'Trường học (School)', 'url': 'https://cdn-icons-png.flaticon.com/512/167/167707.png'},
                  {'name': 'Cơ thể (Body)', 'url': 'https://cdn-icons-png.flaticon.com/512/3048/3048122.png'},
                ],
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

