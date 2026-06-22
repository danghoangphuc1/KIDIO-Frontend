import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/progress_provider.dart';
import '../providers/child_provider.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    final totalStars = child?.totalStars ?? 0;
    final streak = child?.currentStreakDays ?? 0;
    final completedLessonsCount = progressProvider.completedLessons.length;

    // Define badges and check their unlocked state
    final badges = [
      BadgeItem(
        key: 'first_lesson',
        title: 'First Lesson',
        rewardText: '+10 stars',
        icon: Icons.book_rounded,
        emoji: '📖',
        activeColor: const Color(0xFFE0F2FE),
      ),
      BadgeItem(
        key: '10_lessons',
        title: '10 Lessons Done',
        rewardText: '+50 stars',
        icon: Icons.track_changes_rounded,
        emoji: '🎯',
        activeColor: const Color(0xFFFFE4E6),
      ),
      BadgeItem(
        key: '100_stars',
        title: '100 Stars Earned',
        rewardText: '+100 stars',
        icon: Icons.star_rounded,
        emoji: '⭐',
        activeColor: const Color(0xFFFEF9C3),
      ),
      BadgeItem(
        key: '7_streak',
        title: '7 Day Streak',
        rewardText: '+70 stars',
        icon: Icons.local_fire_department_rounded,
        emoji: '🔥',
        activeColor: const Color(0xFFFFEDD5),
      ),
      BadgeItem(
        key: 'pron_master',
        title: 'Pronunciation Master',
        rewardText: 'Keep playing to unlock!',
        icon: Icons.mic_rounded,
        emoji: '🎤',
        activeColor: const Color(0xFFF3E8FF),
      ),
      BadgeItem(
        key: 'quiz_champ',
        title: 'Quiz Champion',
        rewardText: 'Keep playing to unlock!',
        icon: Icons.emoji_events_rounded,
        emoji: '🏆',
        activeColor: const Color(0xFFFFF7ED),
      ),
      BadgeItem(
        key: 'explorer',
        title: 'Island Explorer',
        rewardText: 'Keep playing to unlock!',
        icon: Icons.map_rounded,
        emoji: '🗺️',
        activeColor: const Color(0xFFE0F2FE),
      ),
      BadgeItem(
        key: 'boss_slayer',
        title: 'Boss Slayer',
        rewardText: 'Keep playing to unlock!',
        icon: Icons.gavel_rounded,
        emoji: '⚔️',
        activeColor: const Color(0xFFFEE2E2),
      ),
    ];

    // Check unlock state based on statistics and earned achievements list
    bool isBadgeUnlocked(BadgeItem badge) {
      // 1. Check statistics
      if (badge.key == 'first_lesson' && completedLessonsCount > 0) return true;
      if (badge.key == '10_lessons' && completedLessonsCount >= 10) return true;
      if (badge.key == '100_stars' && totalStars >= 100) return true;
      if (badge.key == '7_streak' && streak >= 7) return true;

      // 2. Check achievement list from API
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
      backgroundColor: const Color(0xFFEEF2FD),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Top Purple Treasure Room Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E0854), Color(0xFF5B118F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Treasure Room',
                        style: TextStyle(
                          fontFamily: 'FredokaOne',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Large Coin Sack representation
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '💰',
                      style: TextStyle(fontSize: 72),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stars Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15), // Yellow star color
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF854D0E), size: 22),
                        const SizedBox(width: 6),
                        Text(
                          '$totalStars Total Stars',
                          style: const TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF854D0E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── My Badges Container ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Header Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🥇 My Badges',
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102D54),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$unlockedCount / ${badges.length} ✔',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid layout of badges
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        final isUnlocked = isBadgeUnlocked(badge);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isUnlocked
                                  ? badge.activeColor.withOpacity(0.8)
                                  : Colors.grey.shade100,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar badge circle
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? badge.activeColor
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
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
                                            size: 28,
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
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Title
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

                              // Reward or Description
                              Text(
                                isUnlocked ? badge.rewardText : 'Keep playing\nto unlock!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked
                                      ? const Color(0xFFEAB308)
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
            const SizedBox(height: 80), // bottom nav space
          ],
        ),
      ),
    );
  }
}
