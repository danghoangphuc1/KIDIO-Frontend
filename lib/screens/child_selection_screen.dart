import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/child_provider.dart';
import '../providers/auth_provider.dart';
import '../models/kidio_models.dart';
import 'parent_dashboard_screen.dart';

class ChildSelectionScreen extends StatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildProvider>().loadChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF), // Nhạt và tươi sáng hơn
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => _showParentVerification(context),
          icon: const Icon(Icons.security, color: Colors.indigoAccent),
          label: const Text('Phụ huynh', style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
        ),
        leadingWidth: 140,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 28),
            onPressed: () => _showLogoutConfirm(context),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Logo hoặc Icon vui nhộn ở trên cùng
            const Icon(Icons.auto_stories, size: 50, color: Colors.orangeAccent),
            const SizedBox(height: 10),
            const Text(
              'Hôm nay ai sẽ học nhỉ?',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
                fontFamily: 'ShortStack', // Giả sử có font chữ bo tròn
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Chọn một hồ sơ để bắt đầu hành trình',
                style: TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: childProvider.isLoading && childProvider.children.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 30,
                        mainAxisSpacing: 30,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: childProvider.children.length + 1,
                      itemBuilder: (context, index) {
                        if (index < childProvider.children.length) {
                          return _buildChildCard(context, childProvider.children[index], index);
                        } else {
                          return _buildAddChildCard(context);
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, Child child, int index) {
    // Màu sắc khác nhau cho từng bé
    final List<Color> colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.pink];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: () {
        context.read<ChildProvider>().selectChild(child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 4),
              ),
              child: ClipOval(
                child: child.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: child.avatarUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.face, size: 50, color: color),
                      )
                    : Icon(Icons.face, size: 50, color: color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              child.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${child.age} tuổi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddChildCard(BuildContext context) {
    return InkWell(
      onTap: () => _showAddChildDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 60, color: Colors.blueAccent),
            SizedBox(height: 10),
            Text(
              'Thêm bé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedAvatar;
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Center(
            child: Text('Tạo hồ sơ cho bé', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chọn linh vật Pokemon:', style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: childProvider.availableAvatars.length,
                        itemBuilder: (context, index) {
                          final avatarUrl = childProvider.availableAvatars[index];
                          final isSelected = selectedAvatar == avatarUrl;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedAvatar = avatarUrl),
                            child: Container(
                              margin: const EdgeInsets.only(right: 15),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.orange.shade50 : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Colors.orange : Colors.grey.shade200,
                                  width: 3,
                                ),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: avatarUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: nameController,
                      decoration: _buildInputDecor('Tên của bé', Icons.face),
                      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ageController,
                      decoration: _buildInputDecor('Tuổi của bé', Icons.cake),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập tuổi';
                        final age = int.tryParse(v);
                        if (age == null || age < 2 || age > 10) return 'Tuổi từ 2 đến 10 là tốt nhất';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await childProvider.createChild(
                        nameController.text.trim(),
                        int.parse(ageController.text),
                        avatarUrl: selectedAvatar,
                      );
                  if (success && mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Tạo ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  void _showParentVerification(BuildContext context) {
    // Generate a random math equation
    final num1 = (10 + (20 - 10) * (DateTime.now().millisecond / 1000)).floor();
    final num2 = (2 + (9 - 2) * (DateTime.now().microsecond / 1000000)).floor();
    final result = num1 * num2;
    
    final answerController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.indigoAccent),
            SizedBox(width: 8),
            Text('Khu vực Phụ huynh', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng giải phép tính dưới đây để xác nhận bạn là phụ huynh:'),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '$num1 x $num2 = ?',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
            onPressed: () {
              final val = int.tryParse(answerController.text.trim());
              if (val == result) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xác nhận thất bại. Câu trả lời không đúng.')),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản phụ huynh không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Có', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
