import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/progress_provider.dart';
import '../providers/child_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glassmorphic_widgets.dart';
import 'lesson_detail_screen.dart';

class BadgeItem {
  final String key;
  final String title;
  final String rewardText;
  final IconData icon;
  final String emoji;
  final Color activeColor;

  BadgeItem({
    required this.key,
    required this.title,
    required this.rewardText,
    required this.icon,
    required this.emoji,
    required this.activeColor,
  });
}

class AchievementsScreen extends StatefulWidget {
  final bool isTab;
  const AchievementsScreen({super.key, this.isTab = false});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _selectedTab = 0; // 0: Huy Hiệu, 1: Thành Tựu, 2: Bài Học Xong

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final childProvider = context.watch<ChildProvider>();
    final child = childProvider.selectedChild;

    if (progressProvider.isLoading && progressProvider.achievements.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalStars = child?.totalStars ?? 0;
    final streak = child?.currentStreakDays ?? 0;
    final completedLessonsCount = progressProvider.summary?.totalLessonsCompleted ?? progressProvider.completedLessons.length;

    // Define badges and check their unlocked state
    final List<BadgeItem> badges = progressProvider.activeDefinitions.isNotEmpty
        ? progressProvider.activeDefinitions.map((def) {
            IconData icon = Icons.emoji_events_rounded;
            String emoji = '🏆';
            Color activeColor = const Color(0xFFFFF7ED);
            String rewardText = '';

            if (def.badgeUrl == 'first_lesson') {
              icon = Icons.book_rounded;
              emoji = '📖';
              activeColor = const Color(0xFFE0F2FE);
              rewardText = '+10 sao';
            } else if (def.badgeUrl == '10_lessons') {
              icon = Icons.track_changes_rounded;
              emoji = '🎯';
              activeColor = const Color(0xFFFFE4E6);
              rewardText = '+50 sao';
            } else if (def.badgeUrl == '100_stars') {
              icon = Icons.star_rounded;
              emoji = '⭐';
              activeColor = const Color(0xFFFEF9C3);
              rewardText = '+100 sao';
            } else if (def.badgeUrl == '7_streak') {
              icon = Icons.local_fire_department_rounded;
              emoji = '🔥';
              activeColor = const Color(0xFFFFEDD5);
              rewardText = '+70 sao';
            } else if (def.badgeUrl == 'pron_master') {
              icon = Icons.mic_rounded;
              emoji = '🎤';
              activeColor = const Color(0xFFF3E8FF);
              rewardText = 'Cần đạt 90% phát âm';
            } else if (def.badgeUrl == 'quiz_champ') {
              icon = Icons.emoji_events_rounded;
              emoji = '🏆';
              activeColor = const Color(0xFFFFF7ED);
              rewardText = 'Hoàn thành 5 bài Quiz';
            } else if (def.badgeUrl == 'explorer') {
              icon = Icons.map_rounded;
              emoji = '🗺️';
              activeColor = const Color(0xFFE0F2FE);
              rewardText = 'Mở khóa tất cả chủ đề';
            } else if (def.badgeUrl == 'boss_slayer') {
              icon = Icons.gavel_rounded;
              emoji = '⚔️';
              activeColor = const Color(0xFFFEE2E2);
              rewardText = 'Vượt qua Boss Battle';
            } else {
              rewardText = def.description ?? '';
            }

            return BadgeItem(
              key: def.badgeUrl ?? def.type,
              title: def.name,
              rewardText: rewardText,
              icon: icon,
              emoji: emoji,
              activeColor: activeColor,
            );
          }).toList()
        : [
            BadgeItem(
              key: 'first_lesson',
              title: 'Bài Học Đầu Tiên',
              rewardText: '+10 sao',
              icon: Icons.book_rounded,
              emoji: '📖',
              activeColor: const Color(0xFFE0F2FE),
            ),
            BadgeItem(
              key: '10_lessons',
              title: 'Hoàn Thành 10 Bài',
              rewardText: '+50 sao',
              icon: Icons.track_changes_rounded,
              emoji: '🎯',
              activeColor: const Color(0xFFFFE4E6),
            ),
            BadgeItem(
              key: '100_stars',
              title: 'Đạt 100 Sao',
              rewardText: '+100 sao',
              icon: Icons.star_rounded,
              emoji: '⭐',
              activeColor: const Color(0xFFFEF9C3),
            ),
            BadgeItem(
              key: '7_streak',
              title: 'Chăm Chỉ 7 Ngày',
              rewardText: '+70 sao',
              icon: Icons.local_fire_department_rounded,
              emoji: '🔥',
              activeColor: const Color(0xFFFFEDD5),
            ),
            BadgeItem(
              key: 'pron_master',
              title: 'Bậc Thầy Phát Âm',
              rewardText: 'Cần đạt 90% phát âm',
              icon: Icons.mic_rounded,
              emoji: '🎤',
              activeColor: const Color(0xFFF3E8FF),
            ),
            BadgeItem(
              key: 'quiz_champ',
              title: 'Nhà Vô Địch Quiz',
              rewardText: 'Hoàn thành 5 bài Quiz',
              icon: Icons.emoji_events_rounded,
              emoji: '🏆',
              activeColor: const Color(0xFFFFF7ED),
            ),
            BadgeItem(
              key: 'explorer',
              title: 'Nhà Thám Hiểm',
              rewardText: 'Mở khóa tất cả chủ đề',
              icon: Icons.map_rounded,
              emoji: '🗺️',
              activeColor: const Color(0xFFE0F2FE),
            ),
            BadgeItem(
              key: 'boss_slayer',
              title: 'Dũng Sĩ Diệt Boss',
              rewardText: 'Vượt qua Boss Battle',
              icon: Icons.gavel_rounded,
              emoji: '⚔️',
              activeColor: const Color(0xFFFEE2E2),
            ),
          ];

    bool isBadgeUnlocked(BadgeItem badge) {
      if (badge.key == 'first_lesson' && completedLessonsCount > 0) return true;
      if (badge.key == '10_lessons' && completedLessonsCount >= 10) return true;
      if (badge.key == '100_stars' && totalStars >= 100) return true;
      if (badge.key == '7_streak' && streak >= 7) return true;

      // Check achievement list from API
      final searchKey = badge.title.toLowerCase();
      final keyMatch = badge.key.toLowerCase();
      for (var ach in progressProvider.achievements) {
        final title = ach.title.toLowerCase();
        final type = ach.achievementType?.toLowerCase() ?? '';
        if (title.contains(searchKey) || type.contains(keyMatch)) {
          return true;
        }
      }
      return false;
    }

    int unlockedCount = 0;
    for (var b in badges) {
      if (isBadgeUnlocked(b)) unlockedCount++;
    }

    return Scaffold(
      extendBodyBehindAppBar: !widget.isTab,
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF102D54)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Thành tích của con',
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102D54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => _buildBadgeGuideSheet(context),
                      );
                    },
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.w900)),
                        content: const Text('Bạn có muốn thoát tài khoản không?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('KHÔNG')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<ProgressProvider>().clearProgress();
                              context.read<ChildProvider>().deselectChild();
                              context.read<AuthProvider>().logout();
                            },
                            child: const Text('CÓ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: PlayfulBackground(
        backgroundColors: const [
          Color(0xFFEEF2FD),
          Color(0xFFE0E7FF),
          Color(0xFFF5F3FF),
        ],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, widget.isTab ? (70.0 + 16.0) : (56.0 + 12.0), 16, 100),
            child: Column(
              children: [
                // ── Top Glassmorphic Treasure Banner ──
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(28),
                  fillColor: const Color(0xB3312E81), // Dark indigo opacity
                  borderColor: const Color(0x33FFFFFF),
                  borderWidth: 1.5,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4F46E5).withOpacity(0.85),
                              const Color(0xFF7C3AED).withOpacity(0.85),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                                border: Border.all(color: Colors.white30, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '💰',
                                style: TextStyle(fontSize: 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Phòng Kho Báu',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nơi trưng bày các huy hiệu quý giá của bé!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFACC15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFF854D0E), size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$totalStars Sao tích lũy',
                                    style: const TextStyle(
                                      fontFamily: 'FredokaOne',
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF854D0E),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // ── Segment Selector for 3 Tabs ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(0, '🏅 Huy hiệu'),
                        _buildTabButton(1, '🏆 Thành tựu'),
                        _buildTabButton(2, '📖 Bài học xong'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (_selectedTab == 0) ...[
                  // ── Pokemon Badges View ──
                  const SizedBox(height: 8),
                  _buildPokemonBadgesList(completedLessonsCount),
                ] else if (_selectedTab == 1) ...[
                  // ── Achievements Title Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '🏆 Thành tựu của bé',
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102D54),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$unlockedCount/${badges.length} Mở',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ── Achievements Grid ──
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9, // Adjust ratio to prevent bottom overflow
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      final isUnlocked = isBadgeUnlocked(badge);

                      return GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        borderRadius: BorderRadius.circular(24),
                        fillColor: isUnlocked 
                            ? Colors.white.withOpacity(0.9) 
                            : Colors.white.withOpacity(0.55),
                        borderColor: isUnlocked
                            ? badge.activeColor.withOpacity(0.9)
                            : Colors.white.withOpacity(0.3),
                        borderWidth: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? badge.activeColor
                                        : const Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isUnlocked ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isUnlocked
                                      ? Text(
                                          badge.emoji,
                                          style: const TextStyle(fontSize: 26),
                                        )
                                      : const Icon(
                                          Icons.lock_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 22,
                                        ),
                                ),
                                if (isUnlocked)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                badge.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'FredokaOne',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isUnlocked
                                      ? const Color(0xFF102D54)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Text(
                              isUnlocked ? badge.rewardText : 'Học thêm để mở!',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else if (_selectedTab == 2) ...[
                  // ── Completed Lessons List View ──
                  if (progressProvider.completedLessons.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Chưa xong bài nào.',
                              style: TextStyle(fontFamily: 'FredokaOne', fontSize: 18, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            const Text('Bắt đầu bài học đầu tiên ngay thôi!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: progressProvider.completedLessons.length,
                      itemBuilder: (context, index) {
                        final progress = progressProvider.completedLessons[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(20),
                            fillColor: Colors.white.withOpacity(0.85),
                            borderColor: Colors.white.withOpacity(0.9),
                            borderWidth: 1.5,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.check_circle_rounded, color: Colors.green),
                              ),
                              title: Text(
                                progress.lessonTitle?.isNotEmpty == true ? progress.lessonTitle! : 'Bài học #${index + 1}',
                                style: const TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF102D54)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Đã nhận ${progress.starsEarned} ⭐',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LessonDetailScreen(lessonId: progress.lessonId)),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: 13,
            color: isSelected ? Colors.white : const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonBadgesList(int completedLessonsCount) {
    return Column(
      children: [
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/1.png', 'Tân binh dũng cảm', 'Cần: 1 bài học', completedLessonsCount >= 1),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/2.png', 'Chiến binh thông thái', 'Cần: 2 bài học', completedLessonsCount >= 2),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/3.png', 'Ngôi sao chớp nhoáng', 'Cần: 3 bài học', completedLessonsCount >= 3),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/4.png', 'Sắc màu rực rỡ', 'Cần: 4 bài học', completedLessonsCount >= 4),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/5.png', 'Trái tim kiên cường', 'Cần: 5 bài học', completedLessonsCount >= 5),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/6.png', 'Bậc thầy kiên nhẫn', 'Cần: 6 bài học', completedLessonsCount >= 6),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/7.png', 'Ngọn lửa nhiệt huyết', 'Cần: 7 bài học', completedLessonsCount >= 7),
        _buildPokemonBadgeItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/8.png', 'Nhà vô địch Trái Đất', 'Cần: 8 bài học', completedLessonsCount >= 8),
      ],
    );
  }

  Widget _buildPokemonBadgeItem(String imgUrl, String title, String requirement, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFFFFBEB) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? const Color(0xFFFDE68A) : Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.3,
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              width: 44,
              height: 44,
              errorWidget: (context, url, error) => Icon(Icons.stars, color: isUnlocked ? Colors.orange : Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnlocked ? title : '???',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isUnlocked ? const Color(0xFFD97706) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requirement,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle_rounded, color: Colors.green)
          else
            const Icon(Icons.lock_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBadgeGuideSheet(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  'Cách Nhận Huy Hiệu',
                  style: TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Để sưu tập huy hiệu siêu ngầu, con cần chăm chỉ học bài nhé! Học càng nhiều bài học mới, huy hiệu càng hiếm:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildBadgeRuleItem(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/1.png',
                      'Tân binh dũng cảm',
                      'Hoàn thành 1 bài học',
                    ),
                    _buildBadgeRuleItem(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/2.png',
                      'Chiến binh thông thái',
                      'Hoàn thành 2 bài học',
                    ),
                    _buildBadgeRuleItem(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/3.png',
                      'Ngôi sao chớp nhoáng',
                      'Hoàn thành 3 bài học',
                    ),
                    _buildBadgeRuleItem(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/4.png',
                      'Sắc màu rực rỡ',
                      'Hoàn thành 4 bài học',
                    ),
                    _buildBadgeRuleItem(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/5.png',
                      'Trái tim kiên cường',
                      'Hoàn thành 5 bài học',
                    ),
                    _buildBadgeRuleItem(
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/6.png',
                      'Bậc thầy kiên nhẫn',
                      'Hoàn thành 6 bài học',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  'Đã Rõ Cách Nhận!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeRuleItem(String imgUrl, String title, String range) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: imgUrl,
            width: 40,
            height: 40,
            errorWidget: (context, url, error) => const Icon(Icons.stars, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
