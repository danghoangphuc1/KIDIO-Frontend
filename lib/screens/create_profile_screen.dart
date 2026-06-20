import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/child_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/kidio_models.dart';
import '../widgets/glassmorphic_widgets.dart';
import '../utils/snackbar_utils.dart';

class CreateProfileScreen extends StatefulWidget {
  final Child? childToEdit; // If not null, we are editing this profile!

  const CreateProfileScreen({super.key, this.childToEdit});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _selectedAge;
  String? _selectedAvatarUrl;

  late AnimationController _avatarScaleController;
  late Animation<double> _avatarScaleAnimation;

  final List<Color> _agePalette = [
    const Color(0xFFFF5C9F),
    const Color(0xFFFF8C00),
    const Color(0xFFD4890A),
    const Color(0xFF03A566),
    const Color(0xFF0EA5E9),
    const Color(0xFF8B5CF6),
    const Color(0xFFFF5C9F),
  ];

  @override
  void initState() {
    super.initState();
    
    // Set initial values if editing
    if (widget.childToEdit != null) {
      _nameController.text = widget.childToEdit!.name;
      _selectedAge = widget.childToEdit!.age;
      _selectedAvatarUrl = widget.childToEdit!.avatarUrl;
    }

    _avatarScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _avatarScaleAnimation = CurvedAnimation(
      parent: _avatarScaleController,
      curve: Curves.elasticOut,
    );
    _avatarScaleController.forward();

    // Trigger animation when controller text changes so preview card feels alive
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarScaleController.dispose();
    super.dispose();
  }

  void _onAvatarSelected(String url) {
    if (_selectedAvatarUrl == url) return;
    setState(() {
      _selectedAvatarUrl = url;
    });
    _avatarScaleController.reset();
    _avatarScaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final isEditing = widget.childToEdit != null;

    // Default to first avatar if none selected
    if (_selectedAvatarUrl == null && childProvider.availableAvatars.isNotEmpty) {
      _selectedAvatarUrl = childProvider.availableAvatars.first;
    }

    final currentMeta = getPokemonMetadata(_selectedAvatarUrl ?? '');
    final bool canSave = _nameController.text.trim().isNotEmpty && _selectedAge != null;

    return Scaffold(
      body: PlayfulBackground(
        backgroundColors: const [
          Color(0xFFBAE6FD), // Sky blue
          Color(0xFFFEE2E2), // Soft pink
          Color(0xFFFEF9C3), // Soft yellow
        ],
        child: Column(
          children: [
            // Custom Header / App Bar matching React's design
            _buildAppBar(context, isEditing),
            
            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 1. Choose Your Avatar Section
                      _buildAvatarSection(childProvider),
                      const SizedBox(height: 16),

                      // 2. What's your name Input Section
                      _buildNameInputSection(),
                      const SizedBox(height: 16),

                      // 3. How old are you? Age Chips Section
                      _buildAgeChipsSection(),
                      const SizedBox(height: 16),

                      // 4. Live Profile Preview Section
                      _buildLivePreviewCard(currentMeta),
                      const SizedBox(height: 20),

                      // 5. Kiki Panda mascot speech bubble
                      _buildMascotSpeechBubble(),
                      const SizedBox(height: 100), // padding to ensure scroll is clear of bottom button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Fixed Bottom Action Button matching Figma/React
      bottomSheet: _buildFixedBottomButton(context, canSave, isEditing, childProvider),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isEditing) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF1E3A8A),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Chỉnh Sửa Hồ Sơ! 🌟' : 'Tạo Bạn Đồng Hành! 🌟',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditing 
                      ? 'Cập nhật thông tin bé để tiếp tục hành trình học tập'
                      : 'Thiết lập tài khoản cho bé để bắt đầu học tiếng Anh',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A).withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(ChildProvider childProvider) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      fillColor: Colors.white.withOpacity(0.65),
      borderColor: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎭', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Chọn bạn đồng hành Pokemon',
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: childProvider.availableAvatars.length,
              itemBuilder: (context, index) {
                final url = childProvider.availableAvatars[index];
                final isSelected = _selectedAvatarUrl == url;
                final meta = getPokemonMetadata(url);

                return GestureDetector(
                  onTap: () => _onAvatarSelected(url),
                  child: Container(
                    width: 78,
                    margin: const EdgeInsets.only(right: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? meta.bgColor : const Color(0xFFF4F9FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? meta.color : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: meta.color.withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const SizedBox(),
                                  errorWidget: (context, url, error) => const Icon(Icons.face_rounded),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                meta.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? meta.color : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: meta.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: meta.color.withOpacity(0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInputSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      fillColor: Colors.white.withOpacity(0.65),
      borderColor: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✍️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Tên của bé là gì?',
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _nameController,
            hintText: 'Nhập tên của bé',
            validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên của bé' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeChipsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      fillColor: Colors.white.withOpacity(0.65),
      borderColor: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎂', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Bé bao nhiêu tuổi rồi?',
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final age = 4 + index;
              final color = _agePalette[index % _agePalette.length];
              final isSelected = _selectedAge == age;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAge = age;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color : const Color(0xFFF4F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFDDE8F0),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$age',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(PokemonMetadata meta) {
    final displayName = _nameController.text.trim().isEmpty ? 'Tên của bé' : _nameController.text.trim();
    final displayAge = _selectedAge == null ? 'Tuổi ?' : '$_selectedAge Tuổi';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      fillColor: Colors.white.withOpacity(0.65),
      borderColor: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Xem trước hồ sơ',
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Live preview card widget matching React card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  meta.bgColor,
                  meta.bgColor.withOpacity(0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: meta.color.withOpacity(0.2),
                width: 2.0,
              ),
            ),
            child: Row(
              children: [
                // Animated avatar container with scaling spring effect
                ScaleTransition(
                  scale: _avatarScaleAnimation,
                  child: Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: meta.color.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedAvatarUrl != null
                        ? CachedNetworkImage(imageUrl: _selectedAvatarUrl!, fit: BoxFit.contain)
                        : const Icon(Icons.face_rounded),
                  ),
                ),
                const SizedBox(width: 14),

                // Info section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayAge,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Level 1 Starter tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: meta.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text(
                              'Cấp độ 1 · Bắt đầu',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating decorative elements
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FloatingEmoji(emoji: '⭐', delayMs: 0),
                    SizedBox(height: 4),
                    _FloatingEmoji(emoji: '🌟', delayMs: 400),
                    SizedBox(height: 4),
                    _FloatingEmoji(emoji: '✨', delayMs: 800),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotSpeechBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Simple built-in Panda representation matching selection screen
        SizedBox(
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
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white.withOpacity(0.65),
            borderColor: Colors.white.withOpacity(0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lựa chọn tuyệt vời! 🎉',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF2E93),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hãy cùng tớ bước vào thế giới phiêu lưu học tiếng Anh đầy thú vị nhé!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedBottomButton(
    BuildContext context, 
    bool canSave, 
    bool isEditing,
    ChildProvider childProvider,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF1E3A8A).withOpacity(0.07),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: 24, // Safe area padding
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: canSave ? () => _submit(context, childProvider, isEditing) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: canSave
                    ? const LinearGradient(
                        colors: [Color(0xFFFF5C9F), Color(0xFFFF1F6E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFC8D8E8), Color(0xFFCAE0F5)],
                      ),
                boxShadow: canSave
                    ? [
                        const BoxShadow(
                          color: Color(0xFFB8154E),
                          offset: Offset(0, 5),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF1F6E).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: childProvider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      isEditing ? '✨ Lưu Thay Đổi!' : '✨ Tạo Hồ Sơ Ngay!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          if (!canSave) ...[
            const SizedBox(height: 8),
            Text(
              _nameController.text.trim().isEmpty && _selectedAge == null
                  ? 'Chọn mascot Pokemon, nhập tên & tuổi để tiếp tục!'
                  : _nameController.text.trim().isEmpty
                      ? 'Vui lòng nhập tên của bé!'
                      : 'Hãy chọn tuổi của bé nhé!',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, ChildProvider childProvider, bool isEditing) async {
    if (_formKey.currentState!.validate()) {
      bool success;
      if (isEditing) {
        success = await childProvider.updateChild(
          widget.childToEdit!.id,
          _nameController.text.trim(),
          _selectedAge!,
          avatarUrl: _selectedAvatarUrl,
        );
      } else {
        success = await childProvider.createChild(
          _nameController.text.trim(),
          _selectedAge!,
          avatarUrl: _selectedAvatarUrl,
        );
      }

      if (mounted) {
        if (success) {
          // Reload dashboard stats just in case
          context.read<DashboardProvider>().loadOverview();
          CustomSnackBar.show(
            context,
            isEditing ? 'Cập nhật hồ sơ thành công!' : 'Tạo hồ sơ thành công!',
          );
          Navigator.pop(context);
        } else {
          CustomSnackBar.show(
            context,
            childProvider.errorMessage ?? 'Có lỗi xảy ra',
            isError: true,
          );
        }
      }
    }
  }

  PokemonMetadata getPokemonMetadata(String url) {
    if (url.contains('/25.png')) return const PokemonMetadata(name: "Pikachu", color: Color(0xFFEAB308), bgColor: Color(0xFFFEF08A));
    if (url.contains('/1.png')) return const PokemonMetadata(name: "Bulbasaur", color: Color(0xFF10B981), bgColor: Color(0xFFD1FAE5));
    if (url.contains('/4.png')) return const PokemonMetadata(name: "Charmander", color: Color(0xFFF97316), bgColor: Color(0xFFFFEDD5));
    if (url.contains('/7.png')) return const PokemonMetadata(name: "Squirtle", color: Color(0xFF0EA5E9), bgColor: Color(0xFFE0F2FE));
    if (url.contains('/133.png')) return const PokemonMetadata(name: "Eevee", color: Color(0xFFB45309), bgColor: Color(0xFFFEF3C7));
    if (url.contains('/151.png')) return const PokemonMetadata(name: "Mew", color: Color(0xFFEC4899), bgColor: Color(0xFFFCE7F3));
    if (url.contains('/150.png')) return const PokemonMetadata(name: "Mewtwo", color: Color(0xFF8B5CF6), bgColor: Color(0xFFEDE9FE));
    if (url.contains('/39.png')) return const PokemonMetadata(name: "Jigglypuff", color: Color(0xFFF472B6), bgColor: Color(0xFFFFE4E6));
    if (url.contains('/54.png')) return const PokemonMetadata(name: "Psyduck", color: Color(0xFFEAB308), bgColor: Color(0xFFFEF9C3));
    if (url.contains('/143.png')) return const PokemonMetadata(name: "Snorlax", color: Color(0xFF475569), bgColor: Color(0xFFF1F5F9));
    if (url.contains('/131.png')) return const PokemonMetadata(name: "Lapras", color: Color(0xFF06B6D4), bgColor: Color(0xFFECFEFF));
    if (url.contains('/172.png')) return const PokemonMetadata(name: "Pichu", color: Color(0xFFD97706), bgColor: Color(0xFFFEF3C7));
    if (url.contains('/175.png')) return const PokemonMetadata(name: "Togepi", color: Color(0xFFF43F5E), bgColor: Color(0xFFFFF1F2));
    
    return const PokemonMetadata(name: "Đồng hành", color: Color(0xFF0EA5E9), bgColor: Color(0xFFE0F2FE));
  }
}

class PokemonMetadata {
  final String name;
  final Color color;
  final Color bgColor;

  const PokemonMetadata({
    required this.name,
    required this.color,
    required this.bgColor,
  });
}

class _FloatingEmoji extends StatefulWidget {
  final String emoji;
  final int delayMs;

  const _FloatingEmoji({required this.emoji, required this.delayMs});

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double scale = 0.95 + (_controller.value * 0.15);
        final double angle = (_controller.value - 0.5) * 0.25;
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle,
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}
