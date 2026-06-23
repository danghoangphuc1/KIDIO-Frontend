import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/glassmorphic_widgets.dart';

class Quest {
  final int id;
  final String title;
  final String emoji;
  final int total;
  final int reward;
  final Color color;
  int progress;
  bool isClaimed;

  Quest({
    required this.id,
    required this.title,
    required this.emoji,
    required this.total,
    required this.reward,
    required this.color,
    this.progress = 0,
    this.isClaimed = false,
  });

  bool get isDone => progress >= total;
}

class QuestScreen extends StatefulWidget {
  final bool isTab;
  const QuestScreen({super.key, this.isTab = false});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  Future<void> _claimReward(Quest quest) async {
    if (!quest.isDone || quest.isClaimed) return;
    
    final childProvider = context.read<ChildProvider>();
    final child = childProvider.selectedChild;
    if (child == null) return;
    final childId = child.id;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final box = Hive.box('kidio_cache');
    
    // Save claim status locally
    await box.put('quest_${quest.id}_claimed_${childId}_$todayStr', true);

    // Update child's stars in Provider
    final updatedChild = Child(
      id: child.id,
      name: child.name,
      age: child.age,
      avatarUrl: child.avatarUrl,
      totalStars: child.totalStars + quest.reward,
      currentStreakDays: child.currentStreakDays,
      lastLessonAt: child.lastLessonAt,
    );
    childProvider.selectChild(updatedChild);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Nhận thành công ${quest.reward} ⭐! Tổng số sao: ${updatedChild.totalStars} ⭐'),
          backgroundColor: const Color(0xFF03A566),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final progressProvider = context.watch<ProgressProvider>();

    if (progressProvider.isLoading && progressProvider.completedLessons.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final child = childProvider.selectedChild;
    final childId = child?.id ?? 'default';
    final totalStars = child?.totalStars ?? 0;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);

    // Compute progress dynamically:
    // 1. Lessons completed today
    final completedToday = progressProvider.completedLessons.where((p) {
      if (p.completedAt == null) return false;
      final localDate = p.completedAt!.toLocal();
      return localDate.year == today.year && localDate.month == today.month && localDate.day == today.day;
    }).length;

    // 2. Daily pronunciations count in Hive
    final box = Hive.box('kidio_cache');
    final pronCount = box.get('daily_pron_count_${childId}_$todayStr', defaultValue: 0) as int;

    // 3. Stars earned today
    final starsToday = progressProvider.completedLessons.where((p) {
      if (p.completedAt == null) return false;
      final localDate = p.completedAt!.toLocal();
      return localDate.year == today.year && localDate.month == today.month && localDate.day == today.day;
    }).fold<int>(0, (sum, p) => sum + p.starsEarned);

    // 4. Minutes spent today
    final secondsToday = progressProvider.completedLessons.where((p) {
      if (p.completedAt == null) return false;
      final localDate = p.completedAt!.toLocal();
      return localDate.year == today.year && localDate.month == today.month && localDate.day == today.day;
    }).fold<int>(0, (sum, p) => sum + p.timeSpentSeconds);
    final minutesToday = secondsToday ~/ 60;

    final quests = [
      Quest(id: 1, title: "Hoàn thành 2 bài học", emoji: "📖", total: 2, reward: 10, color: const Color(0xFF03A566), progress: completedToday, isClaimed: box.get('quest_1_claimed_${childId}_$todayStr', defaultValue: false)),
      Quest(id: 2, title: "Luyện phát âm ×3 lần", emoji: "🎤", total: 3, reward: 20, color: const Color(0xFFFF5C9F), progress: pronCount, isClaimed: box.get('quest_2_claimed_${childId}_$todayStr', defaultValue: false)),
      Quest(id: 3, title: "Đạt được 5 Sao học tập", emoji: "⭐", total: 5, reward: 15, color: const Color(0xFFFACC15), progress: starsToday, isClaimed: box.get('quest_3_claimed_${childId}_$todayStr', defaultValue: false)),
      Quest(id: 4, title: "Học tập trong 15 phút", emoji: "⏱️", total: 15, reward: 25, color: const Color(0xFF0EA5E9), progress: minutesToday, isClaimed: box.get('quest_4_claimed_${childId}_$todayStr', defaultValue: false)),
    ];

    final completedCount = quests.filterDoneCount();
    final progressPct = quests.isEmpty ? 0.0 : completedCount / quests.length;

    return Scaffold(
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
                '⚡ Nhiệm Vụ Hàng Ngày',
                style: TextStyle(
                  fontFamily: 'FredokaOne',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF102D54),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF08A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$totalStars',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF854D0E),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
      extendBodyBehindAppBar: !widget.isTab,
      body: PlayfulBackground(
        backgroundColors: const [
          Color(0xFFFFF8E8), // Light cream
          Color(0xFFFFF3CC), // Soft orange
          Color(0xFFFFF9E8),
        ],
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: widget.isTab ? (70.0 + 12.0) : 12),
              
              // ── Progress Header Banner ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(28),
                  fillColor: Colors.white.withOpacity(0.9),
                  borderColor: const Color(0xFFFFD43F).withOpacity(0.5),
                  borderWidth: 2,
                  child: Column(
                    children: [
                      // Top Banner Gradient
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFDE047), Color(0xFFFFB700)],
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚡ Nhiệm vụ hôm nay',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 22,
                                color: Color(0xFF102D54),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hoàn thành tất cả nhiệm vụ để đạt được nhiều phần thưởng hơn!',
                              style: TextStyle(
                                color: const Color(0xFF102D54).withOpacity(0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Progress Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            const Text(
                              'Tiến độ ngày',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF102D54),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progressPct,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE0EAF4),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF03A566)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$completedCount / ${quests.length}',
                              style: const TextStyle(
                                fontFamily: 'FredokaOne',
                                color: Color(0xFF03A566),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ── Quest Items List ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    final quest = quests[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: quest.isDone 
                                ? quest.color.withOpacity(0.08) 
                                : Colors.black.withOpacity(0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: GlassCard(
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(16),
                        fillColor: Colors.white,
                        borderColor: quest.isDone
                            ? quest.color.withOpacity(0.35)
                            : Colors.transparent,
                        borderWidth: 2,
                        child: Row(
                          children: [
                            // Emoji circle
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: quest.isDone 
                                    ? quest.color.withOpacity(0.12)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                quest.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Quest details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quest.title,
                                    style: const TextStyle(
                                      fontFamily: 'FredokaOne',
                                      color: Color(0xFF102D54),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  
                                  // Quest Progress text + sub bar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: LinearProgressIndicator(
                                            value: quest.total == 0 ? 0.0 : (quest.progress / quest.total).clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            valueColor: AlwaysStoppedAnimation<Color>(quest.color),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${quest.progress} / ${quest.total}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: quest.color,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Claim Button / Status Action
                            _buildActionWidget(quest),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionWidget(Quest quest) {
    if (!quest.isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
            const SizedBox(width: 2),
            Text(
              '+${quest.reward}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFD97706),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (quest.isClaimed) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 22),
      );
    }

    // Done but unclaimed -> interactive button
    return GestureDetector(
      onTap: () => _claimReward(quest),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [quest.color, quest.color.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: quest.color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Text(
          'NHẬN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

extension _QuestListExtension on List<Quest> {
  int filterDoneCount() {
    int count = 0;
    for (var q in this) {
      if (q.isDone) count++;
    }
    return count;
  }
}
