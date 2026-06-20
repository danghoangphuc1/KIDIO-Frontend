import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/progress_provider.dart';
import '../providers/child_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final childProvider = context.watch<ChildProvider>();
    final child = childProvider.selectedChild;

    if (progressProvider.isLoading && progressProvider.achievements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header Summary
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orangeAccent, width: 3),
                ),
                child: ClipOval(
                  child: child?.avatarUrl != null
                      ? CachedNetworkImage(imageUrl: child!.avatarUrl!, fit: BoxFit.contain)
                      : const Icon(Icons.face_rounded, size: 40, color: Colors.orangeAccent),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child?.name ?? 'Bé',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMiniStat(Icons.star_rounded, '${child?.totalStars ?? 0}', Colors.orangeAccent),
                          const SizedBox(width: 12),
                          _buildMiniStat(Icons.local_fire_department_rounded, '${child?.currentStreakDays ?? 0}', Colors.redAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.blueAccent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            tabs: const [
              Tab(text: 'HUY HIỆU'),
              Tab(text: 'BÀI HỌC XONG'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAchievementsGrid(progressProvider),
              _buildCompletedLessonsList(progressProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(ProgressProvider provider) {
    if (provider.achievements.isEmpty) {
      return _buildEmptyState(Icons.emoji_events_rounded, 'Chưa có huy hiệu nào.', 'Hãy học thật chăm chỉ để nhận quà nhé!');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: provider.achievements.length,
      itemBuilder: (context, index) {
        final achievement = provider.achievements[index];
        return Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.orange.shade50, width: 2),
                ),
                child: achievement.iconUrl != null
                    ? CachedNetworkImage(
                        imageUrl: achievement.iconUrl!,
                        placeholder: (context, url) => const Icon(Icons.stars, color: Colors.orangeAccent, size: 30),
                      )
                    : const Icon(Icons.stars, size: 40, color: Colors.orangeAccent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1A237E)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedLessonsList(ProgressProvider provider) {
    if (provider.completedLessons.isEmpty) {
      return _buildEmptyState(Icons.menu_book_rounded, 'Chưa xong bài nào.', 'Bắt đầu bài học đầu tiên ngay thôi!');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: provider.completedLessons.length,
      itemBuilder: (context, index) {
        final progress = provider.completedLessons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green),
            ),
            title: Text(
              'Bài học #${index + 1}', // Ở đây nếu có tên Lesson từ BE thì tốt, hiện tại data LessonProgress có lessonId
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
            ),
            subtitle: Text('Đã nhận ${progress.starsEarned} ⭐ | Hoàn thành tốt'),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
