import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/child_provider.dart';
import '../providers/auth_provider.dart';
import '../models/kidio_models.dart';
import '../widgets/parent_pin_dialogs.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<ChildProvider>().loadChildren();
    });
  }

  bool _pinChecked = false;

  void _checkPinIfNeeded() {
    if (_pinChecked) return;
    
    // Chỉ kiểm tra khi màn hình này đang là màn hình hiển thị trên cùng (không bị VerifyEmail đè lên)
    if (ModalRoute.of(context)?.isCurrent == true) {
      _pinChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final authProvider = context.read<AuthProvider>();
        final hasPin = await authProvider.hasParentPin();
        if (!hasPin && mounted) {
          await ParentPinDialogs.showCreatePinDialog(context, dismissible: false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkPinIfNeeded();
    final childProvider = context.watch<ChildProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Màu nền nhẹ nhàng, hiện đại
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              const Color(0xFFF8FBFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Hình minh họa vui nhộn
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            size: 60,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Hôm nay ai học nhỉ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A237E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Chọn hồ sơ của bé để bắt đầu nhé!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      if (childProvider.isLoading && childProvider.children.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 30,
                            alignment: WrapAlignment.center,
                            children: [
                              ...childProvider.children.asMap().entries.map((entry) {
                                return _buildChildCard(context, entry.value, entry.key);
                              }),
                              _buildAddChildCard(context),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Phụ huynh được thiết kế lại đẹp hơn
          GestureDetector(
            onTap: () => _showParentVerification(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: Colors.indigoAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'PHỤ HUYNH',
                    style: TextStyle(
                      color: Colors.indigoAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Nút Đăng xuất
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            ),
            onPressed: () => _showLogoutConfirm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, Child child, int index) {
    final List<Color> colors = [
      Colors.orangeAccent,
      Colors.blueAccent,
      Colors.greenAccent.shade700,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: () => context.read<ChildProvider>().selectChild(child),
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Hiệu ứng đổ bóng màu sắc
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                // Avatar chính
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 4),
                  ),
                  child: ClipOval(
                    child: child.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: child.avatarUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: color),
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.face_rounded, size: 60, color: color),
                          )
                        : Icon(Icons.face_rounded, size: 60, color: color),
                  ),
                ),
                // Huy hiệu nhỏ góc dưới
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              child.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${child.age} TUỔI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
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
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.3),
                  width: 3,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 50, color: Colors.blueAccent),
            ),
            const SizedBox(height: 14),
            const Text(
              'Thêm bé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.blueAccent,
              ),
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
            child: Text(
              'Tạo hồ sơ cho bé',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn linh vật đồng hành:',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 15),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.orange.shade50 : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Colors.orange : Colors.grey.shade200,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 8)]
                                    : null,
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
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: _buildInputDecor('Tên gọi của bé', Icons.face_rounded),
                      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ageController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: _buildInputDecor('Tuổi của bé (4 - 10)', Icons.cake_rounded),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập tuổi';
                        final age = int.tryParse(v);
                        if (age == null || age < 4 || age > 10) return 'Bé từ 4 đến 10 tuổi';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('HỦY', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
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
              child: const Text('TẠO HỒ SƠ', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _showParentVerification(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final hasPin = await authProvider.hasParentPin();
    
    if (mounted) {
      if (!hasPin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        );
      } else {
        ParentPinDialogs.showVerifyPinDialog(context);
      }
    }
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('KHÔNG', style: TextStyle(fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('CÓ, ĐĂNG XUẤT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
