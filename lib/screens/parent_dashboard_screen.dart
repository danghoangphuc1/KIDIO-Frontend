import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/dashboard_provider.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../models/kidio_models.dart';
import '../widgets/parent_pin_dialogs.dart' as import_parent_pin_dialogs;
import 'change_password_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Tăng lên 4 tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadData();
    });
  }

  void _reloadData() {
    context.read<DashboardProvider>().loadOverview();
    context.read<ChildProvider>().loadChildren();
    // Lấy hoạt động cho tất cả các bé hoặc bé đầu tiên để khởi tạo
    final children = context.read<ChildProvider>().children;
    if (children.isNotEmpty) {
      context.read<ProgressProvider>().loadChildProgress(children.first.id);
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
      backgroundColor: const Color(0xFFF3F8FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bảng điều khiển Phụ huynh',
          style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _reloadData,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Tổng Quan', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Nhật Ký Học', icon: Icon(Icons.history_edu_rounded)), // Tab mới kết nối API Progress
            Tab(text: 'Quản Lý Trẻ', icon: Icon(Icons.people_outline)),
            Tab(text: 'Xếp Hạng', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
      ),
      body: dashboardProvider.isLoading
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
    );
  }

  // --- TAB: NHẬT KÝ HỌC TẬP (Kết nối API GetRecentActivities) ---
  Widget _buildActivityLogTab(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final activities = progressProvider.recentActivities;

    if (activities.isEmpty) {
      return const Center(child: Text('Chưa có hoạt động học tập nào gần đây.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.book, color: Colors.white),
            ),
            title: Text('Hoàn thành bài học', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Đạt ${activity.scorePercent}% - Nhận ${activity.starsEarned} ⭐'),
            trailing: Text(
              activity.completedAt != null 
                ? '${activity.completedAt!.day}/${activity.completedAt!.month}' 
                : '',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 1: OVERVIEW STATISTICS ---
  Widget _buildOverviewTab(BuildContext context, ParentDashboardOverviewResponse? overview) {
    if (overview == null) return const Center(child: Text('Không có dữ liệu tổng quan.'));

    final formatDuration = (int totalSecs) {
      if (totalSecs < 60) return '$totalSecs giây';
      final mins = totalSecs ~/ 60;
      if (mins < 60) return '$mins phút';
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '$hrs giờ $remMins phút';
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào phụ huynh, ${overview.parentName}!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Cập nhật lúc: ${overview.generatedAt.toLocal().toString().split('.')[0]}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
              icon: const Icon(Icons.lock_open, size: 20),
              label: const Text('THAY ĐỔI MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                import_parent_pin_dialogs.ParentPinDialogs.showVerifyPinDialog(
                  context,
                  onSuccess: () {
                    // Sau khi nhập đúng PIN cũ, hiển thị dialog tạo PIN mới
                    import_parent_pin_dialogs.ParentPinDialogs.showCreatePinDialog(context);
                  },
                );
              },
              icon: const Icon(Icons.dialpad, size: 20),
              label: const Text('THAY ĐỔI MÃ PIN', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard('Số bé đang học', '${overview.totalChildren}', Icons.child_care, Colors.orangeAccent),
              _buildStatCard('Tổng bài đã học', '${overview.totalLessonsCompleted}', Icons.auto_stories, Colors.blueAccent),
              _buildStatCard('Ngôi sao thu hoạch', '${overview.totalStars}', Icons.star, Colors.amber),
              _buildStatCard('Thời gian học', formatDuration(overview.totalTimeSpentSeconds), Icons.timer, Colors.green),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly progress logs
          const Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.indigo),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hoạt động học tập hàng tuần',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          overview.weeklyProgress.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: Text('Chưa có hoạt động học tập nào trong các tuần qua.', style: TextStyle(color: Colors.grey)),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.date_range, color: Colors.blueAccent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tuần ($startFormatted - $endFormatted)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Đã học: ${week.completedLessons} bài | Thời gian: ${formatDuration(week.timeSpentSeconds)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                '${week.activeChildrenCount} Bé hoạt động',
                                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
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
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: childProvider.children.length,
      itemBuilder: (context, index) {
        final child = childProvider.children[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: child.avatarUrl != null ? CachedNetworkImageProvider(child.avatarUrl!) : null,
                  child: child.avatarUrl == null ? const Icon(Icons.face, size: 36) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 4),
                      Text('${child.age} tuổi', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${child.totalStars} Sao'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 4),
                              Text('${child.currentStreakDays} Ngày'),
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
                      onPressed: () => _showEditChildDialog(context, child),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteChild(context, child),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditChildDialog(BuildContext context, Child child) {
    final nameController = TextEditingController(text: child.name);
    final ageController = TextEditingController(text: '${child.age}');
    final formKey = GlobalKey<FormState>();
    String? selectedAvatar = child.avatarUrl;
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await childProvider.updateChild(
                    child.id,
                    nameController.text.trim(),
                    int.parse(ageController.text),
                    avatarUrl: selectedAvatar,
                  );
                  if (success && mounted) {
                    Navigator.pop(ctx);
                    context.read<DashboardProvider>().loadOverview(); // Reload stats to sync names
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
                    );
                  }
                }
              },
              child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa hồ sơ bé.')),
                );
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
    if (overview == null) return const Center(child: Text('Không có dữ liệu xếp hạng.'));
    
    if (overview.comparisons.isEmpty) {
      return const Center(child: Text('Chưa có thông tin so sánh các bé.', style: TextStyle(color: Colors.grey)));
    }

    final formatDuration = (int totalSecs) {
      final mins = totalSecs ~/ 60;
      return '$mins phút';
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bảng thành tích học tập các bé',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // Rank
                  1: FlexColumnWidth(3),   // Name
                  2: FlexColumnWidth(2),   // Lessons Completed
                  3: FlexColumnWidth(1.8), // Stars
                  4: FlexColumnWidth(2),   // Time Spent
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue.shade50),
                    children: const [
                      Padding(padding: EdgeInsets.all(12), child: Text('Hạng', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))),
                      Padding(padding: EdgeInsets.all(12), child: Text('Tên Bé', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))),
                      Padding(padding: EdgeInsets.all(12), child: Text('Đã học', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))),
                      Padding(padding: EdgeInsets.all(12), child: Text('Sao ⭐', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))),
                      Padding(padding: EdgeInsets.all(12), child: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))),
                    ],
                  ),
                  // Body
                  ...overview.comparisons.map((c) {
                    final isTop1 = c.rank == 1;
                    return TableRow(
                      decoration: const BoxDecoration(color: Colors.white),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              if (isTop1)
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 18)
                              else
                                Text('${c.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(c.childName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('${c.completedLessons} bài'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('${c.totalStars}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(formatDuration(c.timeSpentSeconds)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
