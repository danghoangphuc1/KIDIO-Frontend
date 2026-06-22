import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../providers/child_provider.dart';
import '../widgets/glassmorphic_widgets.dart';

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
    final completedLessonsCount = progressProvider.completedLessons.length;

    // Define badges and check their unlocked state
    final badges = [
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
              title: const Text(
                '🏅 Thành Tích Của Bé',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF102D54),
                ),
              ),
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
            padding: EdgeInsets.fromLTRB(16, widget.isTab ? 16 : 12, 16, 100),
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
                
                // ── Badges Title Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🥇 Huy hiệu của bé',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102D54),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$unlockedCount / ${badges.length} Đã mở',
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
                
                // ── Badges Grid ──
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    final isUnlocked = isBadgeUnlocked(badge);

                    return GlassCard(
                      padding: const EdgeInsets.all(12),
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
                                width: 60,
                                height: 60,
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
                                        style: const TextStyle(fontSize: 32),
                                      )
                                    : const Icon(
                                        Icons.lock_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 26,
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
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            badge.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isUnlocked
                                  ? const Color(0xFF102D54)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUnlocked ? badge.rewardText : 'Học tập thêm để mở khóa!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
