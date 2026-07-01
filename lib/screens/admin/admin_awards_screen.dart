import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kidio_models.dart';
import '../../repositories/achievement_repository.dart';
import '../../utils/snackbar_utils.dart';

class AdminAwardsScreen extends StatefulWidget {
  const AdminAwardsScreen({super.key});

  @override
  State<AdminAwardsScreen> createState() => _AdminAwardsScreenState();
}

class _AdminAwardsScreenState extends State<AdminAwardsScreen> {
  List<AchievementDefinition> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<AchievementRepository>();
      final data = await repo.getDefinitions();
      setState(() {
        _achievements = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, 'Lỗi tải danh sách huy hiệu: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddOrEditModal({AchievementDefinition? existing}) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name);
    final descCtrl = TextEditingController(text: existing?.description);
    final badgeUrlCtrl = TextEditingController(text: existing?.badgeUrl);
    final thresholdCtrl = TextEditingController(text: existing?.threshold.toString());
    String selectedType = existing?.type ?? 'Stars';

    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEdit ? 'Chỉnh sửa Huy hiệu' : 'Thêm Huy hiệu mới', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên huy hiệu', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: badgeUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Emoji / Icon', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Loại điều kiện', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Stars', child: Text('Stars')),
                      DropdownMenuItem(value: 'Streak', child: Text('Streak')),
                      DropdownMenuItem(value: 'Lessons', child: Text('Lessons')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: thresholdCtrl,
                    decoration: const InputDecoration(labelText: 'Ngưỡng đạt được', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final threshold = int.tryParse(thresholdCtrl.text) ?? 0;
                        setModalState(() => isSubmitting = true);
                        try {
                          final repo = context.read<AchievementRepository>();
                          if (isEdit) {
                            await repo.updateDefinition(
                              id: existing.id,
                              name: nameCtrl.text,
                              description: descCtrl.text,
                              type: selectedType,
                              threshold: threshold,
                              badgeUrl: badgeUrlCtrl.text,
                              orderIndex: existing.orderIndex,
                              isActive: existing.isActive,
                            );
                            CustomSnackBar.show(ctx, 'Cập nhật thành công');
                          } else {
                            await repo.createDefinition(
                              name: nameCtrl.text,
                              description: descCtrl.text,
                              type: selectedType,
                              threshold: threshold,
                              badgeUrl: badgeUrlCtrl.text,
                              orderIndex: _achievements.length,
                            );
                            CustomSnackBar.show(ctx, 'Thêm mới thành công');
                          }
                          Navigator.pop(ctx, true);
                        } catch (e) {
                          CustomSnackBar.show(ctx, 'Lỗi: $e', isError: true);
                          setModalState(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Lưu' : 'Thêm', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    ).then((changed) {
      if (changed == true) {
        _fetchData();
      }
    });
  }

  Future<void> _deleteAchievement(AchievementDefinition item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa huy hiệu "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<AchievementRepository>().deleteDefinition(item.id);
        CustomSnackBar.show(context, 'Xóa thành công');
        _fetchData();
      } catch (e) {
        CustomSnackBar.show(context, 'Lỗi khi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Since we don't have total unlocks from API for definitions, we can just show active count
    int activeCount = _achievements.where((a) => a.isActive).length;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Achievements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTap: () => _showAddOrEditModal(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_achievements.length} badges • $activeCount active',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: _achievements.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu huy hiệu.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _achievements.length,
                  itemBuilder: (context, index) {
                    final a = _achievements[index];
                    return GestureDetector(
                      onTap: () => _showAddOrEditModal(existing: a),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                          border: !a.isActive ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1) : null,
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(a.badgeUrl?.isNotEmpty == true ? a.badgeUrl! : '🏆', style: const TextStyle(fontSize: 28)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF111827), decoration: !a.isActive ? TextDecoration.lineThrough : null)),
                                      const SizedBox(height: 2),
                                      Text(a.description ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          if (a.type.toLowerCase() == 'stars')
                                            _buildBadge('Stars: ${a.threshold}', const Color(0xFFD97706)),
                                          if (a.type.toLowerCase() == 'streak')
                                            _buildBadge('Streak: ${a.threshold}d', const Color(0xFFEF4444)),
                                          if (a.type.toLowerCase() == 'lessons')
                                            _buildBadge('Lessons: ${a.threshold}', const Color(0xFF059669)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _deleteAchievement(a),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
