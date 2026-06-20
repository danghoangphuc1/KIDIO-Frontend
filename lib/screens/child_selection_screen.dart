import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/child_provider.dart';
import '../providers/auth_provider.dart';
import '../models/kidio_models.dart';
import '../widgets/parent_pin_dialogs.dart';
import 'parent_dashboard_screen.dart';
import '../widgets/glassmorphic_widgets.dart';
import 'create_profile_screen.dart';


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
      body: PlayfulBackground(
        backgroundColors: const [
          Color(0xFFBAE6FD), // Sky blue
          Color(0xFFFEE2E2), // Soft pink
          Color(0xFFFEF9C3), // Soft yellow
        ],
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Title Header
                      const Text(
                        'Who is playing today? 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your profile to continue your adventure',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Profiles List in a nice Grid/Wrap Row
                      if (childProvider.isLoading && childProvider.children.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: childProvider.children.asMap().entries.map((entry) {
                            return _buildChildCard(context, entry.value, entry.key);
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 28),
                        // Create New Profile Card below the list
                        _buildAddChildCard(context),
                      ],
                      
                      const SizedBox(height: 32),
                      // Bottom Waving Panda Mascot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBottomPanda(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBottomSpeechBubble(
                              'Choose your profile and let\'s go! 🌟',
                            ),
                          ),
                        ],
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
          GestureDetector(
            onTap: () => _showParentVerification(context),
            child: GlassCard(
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              fillColor: Colors.white.withOpacity(0.35),
              borderColor: Colors.white.withOpacity(0.55),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0EA5E9), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'PARENTS',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          IconButton(
            icon: GlassCard(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(8),
              fillColor: Colors.red.shade50.withOpacity(0.4),
              borderColor: Colors.white.withOpacity(0.55),
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
      const Color(0xFFFF2E93), // Pink
      const Color(0xFF0EA5E9), // Sky blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
    ];
    final color = colors[index % colors.length];
    
    // Dynamic level based on totalStars
    final level = (child.totalStars / 30).floor() + 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => context.read<ChildProvider>().selectChild(child),
          borderRadius: BorderRadius.circular(28),
          child: GlassCard(
            width: 150,
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            fillColor: Colors.white.withOpacity(0.35),
            borderColor: Colors.white.withOpacity(0.55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Avatar circle matching Figma style
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4), width: 3.5),
                  ),
                  child: ClipOval(
                    child: child.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: child.avatarUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: color),
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.face_rounded, size: 50, color: color),
                          )
                        : Icon(Icons.face_rounded, size: 50, color: color),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  child.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Level badge capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Level $level',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Star points badge on top right of the whole card
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A), // Light yellow
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                const SizedBox(width: 2),
                Text(
                  '${child.totalStars}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF854D0E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddChildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 80,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFF38BDF8),
          strokeWidth: 2.5,
          gap: 5.0,
          dashLength: 8.0,
          borderRadius: 24.0,
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Plus icon in blue square
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create New Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add a child account to get started',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanda() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ears
          Positioned(
            left: 8,
            top: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 8,
            top: 2,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
            ),
          ),
          // Head
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E293B), width: 3),
            ),
          ),
          // Eyes
          Positioned(
            left: 18,
            top: 22,
            child: Container(
              width: 12,
              height: 18,
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
              child: Align(
                alignment: const Alignment(0, -0.4),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 22,
            child: Container(
              width: 12,
              height: 18,
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
              child: Align(
                alignment: const Alignment(0, -0.4),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          // Cheeks
          Positioned(
            left: 10,
            top: 38,
            child: Container(
              width: 8,
              height: 5,
              decoration: BoxDecoration(color: Colors.pink.withOpacity(0.4), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 10,
            top: 38,
            child: Container(
              width: 8,
              height: 5,
              decoration: BoxDecoration(color: Colors.pink.withOpacity(0.4), shape: BoxShape.circle),
            ),
          ),
          // Nose
          Positioned(
            top: 36,
            child: Container(
              width: 8,
              height: 5,
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
            ),
          ),
          // Mouth
          Positioned(
            top: 42,
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: const Color(0xFF1E293B).withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSpeechBubble(String text) {
    return GlassCard(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
        bottomLeft: Radius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: Colors.white.withOpacity(0.35),
      borderColor: Colors.white.withOpacity(0.55),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
          height: 1.3,
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

// Custom painter to draw beautiful dashed rounded borders
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    
    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
