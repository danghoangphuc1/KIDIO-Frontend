import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../providers/dashboard_provider.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/auth_provider.dart';
import '../models/kidio_models.dart';
import '../widgets/parent_pin_dialogs.dart' as import_parent_pin_dialogs;
import '../widgets/glassmorphic_widgets.dart';
import 'change_password_screen.dart';
import '../utils/snackbar_utils.dart';
import 'create_profile_screen.dart';


class ParentDashboardScreen extends StatefulWidget {
  final bool isTab;
  const ParentDashboardScreen({super.key, this.isTab = false});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedChildIdForLog;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Tăng lên 4 tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadData();
    });
  }

  Future<void> _reloadData() async {
    context.read<DashboardProvider>().loadOverview();
    await context.read<ChildProvider>().loadChildren();
    
    if (!mounted) return;
    
    final children = context.read<ChildProvider>().children;
    if (children.isNotEmpty) {
      _selectedChildIdForLog ??= children.first.id;
      context.read<ProgressProvider>().loadChildProgress(_selectedChildIdForLog!);
    }

    if (mounted) {
      final hasPin = await context.read<AuthProvider>().hasParentPin();
      if (mounted) {
        setState(() {
          _hasPin = hasPin;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.4),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A)),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Bảng điều khiển Phụ huynh',
          style: TextStyle(
            fontFamily: 'FredokaOne',
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
            onPressed: _reloadData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF3B82F6)),
            tooltip: 'Cài đặt Phụ huynh',
            onSelected: (value) async {
              if (value == 'change_pin') {
                 final created = await import_parent_pin_dialogs.ParentPinDialogs.showCreatePinDialog(context);
                 if (created == true && mounted) {
                   CustomSnackBar.show(context, 'Đổi mã PIN thành công');
                   _reloadData();
                 }
              } else if (value == 'change_password') {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                 );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'change_pin', child: Text('Thay đổi mã PIN')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'change_password', child: Text('Đổi mật khẩu')),
            ],
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: const Color(0x991E3A8A),
          indicatorColor: const Color(0xFF3B82F6),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: 'Tổng Quan', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Nhật Ký Học', icon: Icon(Icons.history_edu_rounded)), // Tab mới kết nối API Progress
            Tab(text: 'Quản Lý Trẻ', icon: Icon(Icons.people_outline)),
            Tab(text: 'Xếp Hạng', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
      ),
      body: PlayfulBackground(
        child: SafeArea(
          top: false,
          child: dashboardProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(context, dashboardProvider.overview),
                        _buildActivityLogTab(context), // Tab mới
                        _buildChildrenTab(context),
                        _buildComparisonTab(context, dashboardProvider.overview),
                      ],
                    ),
        ),
      ),
    );
  }

  // --- TAB: NHẬT KÝ HỌC TẬP (Kết nối API GetRecentActivities) ---
  Widget _buildActivityLogTab(BuildContext context) {
    final children = context.watch<ChildProvider>().children;
    final progressProvider = context.watch<ProgressProvider>();
    final activities = progressProvider.recentActivities;

    if (children.isEmpty) {
      return const Center(child: Text('Chưa có thông tin trẻ.'));
    }

    final selectedId = _selectedChildIdForLog ?? children.first.id;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 72.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            borderRadius: BorderRadius.circular(20),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Chọn trẻ để xem nhật ký',
                  labelStyle: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                ),
                dropdownColor: const Color(0xFFEFF6FF),
                value: selectedId,
                items: children.map((child) => DropdownMenuItem(
                  value: child.id,
                  child: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                )).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedChildIdForLog) {
                    setState(() => _selectedChildIdForLog = val);
                    context.read<ProgressProvider>().loadChildProgress(val);
                  }
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: progressProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : activities.isEmpty
              ? const Center(child: Text('Chưa có hoạt động học tập nào gần đây.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(16),
                      fillColor: Colors.white.withOpacity(0.4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.book_rounded, color: Color(0xFF0284C7)),
                        ),
                        title: Text(
                          activity.lessonTitle?.isNotEmpty == true
                              ? activity.lessonTitle!
                              : 'Bài học #${index + 1}',
                          style: const TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                        ),
                        subtitle: Text(
                          'Đạt ${activity.scorePercent}% - Nhận ${activity.starsEarned} ⭐',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                        trailing: Text(
                          activity.completedAt != null 
                            ? '${activity.completedAt!.day}/${activity.completedAt!.month}' 
                            : '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0x991E3A8A)),
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

  // --- TAB 1: OVERVIEW STATISTICS ---
  Widget _buildOverviewTab(BuildContext context, ParentDashboardOverviewResponse? overview) {
    if (overview == null) return const Center(child: Text('Không có dữ liệu tổng quan.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))));

    final formatDuration = (int totalSecs) {
      if (totalSecs < 60) return '$totalSecs giây';
      final mins = totalSecs ~/ 60;
      if (mins < 60) return '$mins phút';
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '$hrs giờ $remMins phút';
    };

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 72.0 + 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            fillColor: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào phụ huynh, ${overview.parentName}!',
                  style: const TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Cập nhật lúc: ${overview.generatedAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(20),
                  fillColor: Colors.indigo.withOpacity(0.1),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, size: 18, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 8),
                          Text(
                            'ĐỔI MẬT KHẨU',
                            style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(20),
                  fillColor: Colors.indigo.withOpacity(0.1),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      import_parent_pin_dialogs.ParentPinDialogs.showVerifyPinDialog(
                        context,
                        onSuccess: () {
                          import_parent_pin_dialogs.ParentPinDialogs.showCreatePinDialog(context);
                        },
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.dialpad_rounded, size: 18, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 8),
                          Text(
                            'ĐỔI MÃ PIN',
                            style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard('Số bé đang học', '${overview.totalChildren}', Icons.child_care_rounded, Colors.orangeAccent),
              _buildStatCard('Tổng bài đã học', '${overview.totalLessonsCompleted}', Icons.auto_stories_rounded, Colors.blueAccent),
              _buildStatCard('Ngôi sao đã nhận', '${overview.totalStars}', Icons.star_rounded, Colors.amber),
              _buildStatCard('Thời gian học', formatDuration(overview.totalTimeSpentSeconds), Icons.timer_rounded, Colors.green),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly progress logs
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hoạt động học tập hàng tuần',
                  style: TextStyle(fontFamily: 'FredokaOne', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          overview.weeklyProgress.isEmpty
              ? GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(20),
                  child: const Center(
                    child: Text('Chưa có hoạt động học tập nào trong các tuần qua.', style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: overview.weeklyProgress.length,
                  itemBuilder: (context, index) {
                    final week = overview.weeklyProgress[index];
                    final startFormatted = '${week.weekStart.day}/${week.weekStart.month}';
                    final endFormatted = '${week.weekEnd.day}/${week.weekEnd.month}';
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(16),
                      fillColor: Colors.white.withOpacity(0.4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                            child: const Icon(Icons.date_range_rounded, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tuần ($startFormatted - $endFormatted)',
                                  style: const TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Đã học: ${week.completedLessons} bài | ${formatDuration(week.timeSpentSeconds)}',
                                  style: const TextStyle(color: Color(0xFF0369A1), fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${week.activeChildrenCount} Bé',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFC2410C), fontWeight: FontWeight.w900, fontFamily: 'FredokaOne'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      fillColor: Colors.white.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'FredokaOne', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CHILDREN PROFILE MANAGEMENT ---
  Widget _buildChildrenTab(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 72.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassButton(
            borderRadius: 20,
            baseColor: const Color(0xFF3B82F6).withOpacity(0.8),
            highlightColor: const Color(0xFF2563EB).withOpacity(0.9),
            height: 52,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'THÊM BÉ MỚI',
                  style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: childProvider.children.length,
            itemBuilder: (context, index) {
              final child = childProvider.children[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 16),
                borderRadius: BorderRadius.circular(24),
                fillColor: Colors.white.withOpacity(0.4),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFEFF6FF),
                        backgroundImage: child.avatarUrl != null ? CachedNetworkImageProvider(child.avatarUrl!) : null,
                        child: child.avatarUrl == null ? const Icon(Icons.face_rounded, size: 36, color: Color(0xFF1E3A8A)) : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(fontFamily: 'FredokaOne', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${child.age} tuổi',
                            style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${child.totalStars} Sao',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${child.currentStreakDays} Ngày',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateProfileScreen(childToEdit: child),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDeleteChild(context, child),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
          ),
        ),
      ],
    ),
  );
}

  void _showCreateChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    String? selectedAvatar = childProvider.availableAvatars.first;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Center(
            child: Text(
              'Thêm hồ sơ bé',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
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
                      decoration: InputDecoration(
                        labelText: 'Tên của bé',
                        prefixIcon: const Icon(Icons.face, color: Colors.blueAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ageController,
                      decoration: InputDecoration(
                        labelText: 'Tuổi của bé',
                        prefixIcon: const Icon(Icons.cake, color: Colors.blueAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập tuổi';
                        final age = int.tryParse(v);
                        if (age == null || age < 4 || age > 10) return 'Tuổi từ 4 đến 10 là tốt nhất';
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
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: isSubmitting ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSubmitting = true);
                  final success = await childProvider.createChild(
                    nameController.text.trim(),
                    int.parse(ageController.text),
                    avatarUrl: selectedAvatar,
                  );
                  if (!ctx.mounted) return;
                  
                  if (success) {
                    Navigator.of(ctx).pop(); // Đóng dialog an toàn
                      if (context.mounted) {
                        context.read<DashboardProvider>().loadOverview(); // Cập nhật thống kê
                        CustomSnackBar.show(context, 'Tạo hồ sơ thành công!');
                      }
                  } else {
                    setDialogState(() => isSubmitting = false);
                    CustomSnackBar.show(ctx, childProvider.errorMessage ?? 'Có lỗi xảy ra', isError: true);
                  }
                }
              },
              child: isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Tạo mới', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChildDialog(BuildContext context, Child child) {
    final nameController = TextEditingController(text: child.name);
    final ageController = TextEditingController(text: '${child.age}');
    final formKey = GlobalKey<FormState>();
    String? selectedAvatar = child.avatarUrl;
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Center(
            child: Text(
              'Sửa hồ sơ: ${child.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
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
                      decoration: InputDecoration(
                        labelText: 'Tên của bé',
                        prefixIcon: const Icon(Icons.face, color: Colors.blueAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ageController,
                      decoration: InputDecoration(
                        labelText: 'Tuổi của bé',
                        prefixIcon: const Icon(Icons.cake, color: Colors.blueAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập tuổi';
                        final age = int.tryParse(v);
                        if (age == null || age < 4 || age > 10) return 'Tuổi từ 4 đến 10 là tốt nhất';
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
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: isSubmitting ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSubmitting = true);
                  final success = await childProvider.updateChild(
                    child.id,
                    nameController.text.trim(),
                    int.parse(ageController.text),
                    avatarUrl: selectedAvatar,
                  );
                  if (!ctx.mounted) return;
                  
                  if (success) {
                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      context.read<DashboardProvider>().loadOverview(); // Reload stats to sync names
                      CustomSnackBar.show(context, 'Cập nhật hồ sơ thành công!');
                    }
                  } else {
                    setDialogState(() => isSubmitting = false);
                    CustomSnackBar.show(ctx, childProvider.errorMessage ?? 'Có lỗi xảy ra', isError: true);
                  }
                }
              },
              child: isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChild(BuildContext context, Child child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa hồ sơ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ của bé "${child.name}" không? Tất cả điểm số và tiến trình sẽ bị mất.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ChildProvider>().deleteChild(child.id);
              if (success && mounted) {
                context.read<DashboardProvider>().loadOverview(); // Reload overview statistics
                CustomSnackBar.show(context, 'Đã xóa hồ sơ bé.');
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: LEADERBOARD & COMPARISONS ---
  Widget _buildComparisonTab(BuildContext context, ParentDashboardOverviewResponse? overview) {
    if (overview == null) return const Center(child: Text('Không có dữ liệu xếp hạng.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))));
    
    if (overview.comparisons.isEmpty) {
      return const Center(child: Text('Chưa có thông tin so sánh các bé.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))));
    }

    final formatDuration = (int totalSecs) {
      if (totalSecs < 60) return '$totalSecs giây';
      final mins = totalSecs ~/ 60;
      if (mins < 60) return '$mins phút';
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '$hrs giờ $remMins phút';
    };

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 72.0 + 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bảng thành tích học tập các bé',
                  style: TextStyle(fontFamily: 'FredokaOne', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(24),
            fillColor: Colors.white.withOpacity(0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.5), // Rank
                    1: FlexColumnWidth(2.5), // Name
                    2: FlexColumnWidth(2.2), // Lessons Completed
                    3: FlexColumnWidth(1.5), // Stars
                    4: FlexColumnWidth(2.3), // Time Spent
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.1), width: 1),
                  ),
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF).withOpacity(0.6)),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Text('Hạng', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Text('Tên Bé', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Text('Đã học', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Text('Sao ⭐', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4), child: Text('Thời gian', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 13))),
                      ],
                    ),
                    // Body
                    ...overview.comparisons.map((c) {
                      final isTop1 = c.rank == 1;
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Align(
                              alignment: Alignment.center,
                              child: isTop1
                                  ? const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20)
                                  : Text('${c.rank}', style: const TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text(c.childName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text('${c.completedLessons} bài', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text('${c.totalStars}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text(formatDuration(c.timeSpentSeconds), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
