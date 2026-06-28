import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/lesson_repository.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import '../local/cache_service.dart';
import 'lesson_detail_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  final String topicId;
  final String topicName;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late Future<List<Lesson>> _lessonsFuture;
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _fetchLessons();
  }

  Future<List<Lesson>> _fetchLessons() async {
    final repository = context.read<LessonRepository>();
    try {
      final lessons = await repository.getLessonsByTopic(widget.topicId);
      await _cacheService.saveLessonsForTopic(widget.topicId, lessons);
      return lessons;
    } catch (e) {
      final cached = _cacheService.getLessonsForTopic(widget.topicId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  String _getTopicEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('animal')) return '🦁';
    if (n.contains('food')) return '🍔';
    if (n.contains('job') || n.contains('career')) return '💼';
    if (n.contains('number')) return '🔢';
    return '📚';
  }

  String _getLessonEmoji(String topicName, String lessonTitle, int index) {
    final tName = topicName.toLowerCase();
    final lTitle = lessonTitle.toLowerCase();

    if (lTitle.contains('fruit') || lTitle.contains('trái cây') || lTitle.contains('quả')) {
      return '🍎';
    }
    if (lTitle.contains('veggie') || lTitle.contains('vegetable') || lTitle.contains('rau')) {
      return '🥕';
    }
    if (lTitle.contains('color') || lTitle.contains('màu')) {
      return '🎨';
    }
    if (lTitle.contains('number') || lTitle.contains('count') || lTitle.contains('số')) {
      return '🔢';
    }
    if (lTitle.contains('shape') || lTitle.contains('hình')) {
      return '📐';
    }
    if (lTitle.contains('transport') || lTitle.contains('vehicle') || lTitle.contains('xe') || lTitle.contains('vận chuyển')) {
      return '🚗';
    }
    if (lTitle.contains('family') || lTitle.contains('gia đình')) {
      return '👪';
    }

    if (tName.contains('animal') || tName.contains('động vật')) {
      if (lTitle.contains('farm') || lTitle.contains('nông trại')) {
        return '🐮';
      }
      if (lTitle.contains('jungle') || lTitle.contains('rừng')) {
        return '🐯';
      }
      if (lTitle.contains('ocean') || lTitle.contains('biển')) {
        return '🐟';
      }
      if (lTitle.contains('bird') || lTitle.contains('chim')) {
        return '🐦';
      }
      switch (index % 4) {
        case 0: return '🦁';
        case 1: return '🐘';
        case 2: return '🦒';
        case 3: return '🐼';
      }
    }

    switch (index % 5) {
      case 0:
        return '📚';
      case 1:
        return '✏️';
      case 2:
        return '🧠';
      case 3:
        return '✨';
      case 4:
        return '🌟';
    }
    return '📚';
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final childId = context.read<ChildProvider>().selectedChild?.id;

    final topicEmoji = _getTopicEmoji(widget.topicName);

    return Scaffold(
      backgroundColor: const Color(0xFF8CD4FF), // Figma soft sky blue background
      body: SafeArea(
        child: FutureBuilder<List<Lesson>>(
          future: _lessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Lỗi tải bài học', style: TextStyle(color: Colors.white)));
            }

            final lessons = snapshot.data ?? [];
            if (lessons.isEmpty) {
              return const Center(
                child: Text('Chủ đề này chưa có bài học nào.', style: TextStyle(color: Colors.white)),
              );
            }

            bool isLessonCompleted(String lessonId) {
              if (progressProvider.completedLessons.any((p) => p.lessonId == lessonId)) {
                return true;
              }
              if (childId == null) return false;
              try {
                if (_cacheService.isLessonCompleted(childId, lessonId)) {
                  return true;
                }
                final cacheBox = Hive.box('kidio_cache');
                final vocab = cacheBox.get('activity_status_${childId}_${lessonId}_vocab', defaultValue: false);
                final listening = cacheBox.get('activity_status_${childId}_${lessonId}_listening', defaultValue: false);
                final pron = cacheBox.get('activity_status_${childId}_${lessonId}_pron', defaultValue: false);
                final quiz = cacheBox.get('activity_status_${childId}_${lessonId}_quiz', defaultValue: false);
                final boss = cacheBox.get('activity_status_${childId}_${lessonId}_boss', defaultValue: false);
                return vocab && listening && pron && quiz && boss;
              } catch (_) {
                return false;
              }
            }

            int getLessonStars(String lessonId) {
              final prog = progressProvider.completedLessons.firstWhere(
                (p) => p.lessonId == lessonId,
                orElse: () => LessonProgress(
                  id: '',
                  childId: '',
                  lessonId: '',
                  isCompleted: false,
                  starsEarned: 0,
                  scorePercent: 0,
                  timeSpentSeconds: 0,
                ),
              );
              if (prog.starsEarned > 0) return prog.starsEarned;
              return isLessonCompleted(lessonId) ? 3 : 0;
            }

            // Calculate completed lessons count
            int completedCount = 0;
            for (var lesson in lessons) {
              if (isLessonCompleted(lesson.id)) {
                completedCount++;
              }
            }

            // Calculate total stars earned in this topic
            int totalTopicStars = 0;
            for (var lesson in lessons) {
              totalTopicStars += getLessonStars(lesson.id);
            }

            return Column(
              children: [
                // ── Beautiful Header Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Circular White Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Subtitle column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  topicEmoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.topicName,
                                    style: const TextStyle(
                                      fontFamily: 'FredokaOne',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E3A8A), // Dark blue
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$completedCount of ${lessons.length} lessons completed',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Golden Stars Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF08A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$totalTopicStars/${lessons.length * 3}',
                              style: const TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF854D0E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // "?" Info/Help Button
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => _buildScoringGuideSheet(),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── "Choose a Lesson" Divider ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Colors.white54, thickness: 1.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: const [
                            Text('📖 ', style: TextStyle(fontSize: 14)),
                            Text(
                              'Chọn bài học',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Colors.white54, thickness: 1.5),
                      ),
                    ],
                  ),
                ),

                // ── Main Lesson List Grid ──
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];

                      final isDone = isLessonCompleted(lesson.id);
                      final isPreviousDone = index == 0 || isLessonCompleted(lessons[index - 1].id);
                      final isUnlocked = index == 0 || isPreviousDone;

                      final int starsEarned = getLessonStars(lesson.id);

                      // Card styling properties based on order and unlock state
                      Color headerBgColor;
                      String avatarEmoji = _getLessonEmoji(widget.topicName, lesson.title, index);

                      if (!isUnlocked) {
                        headerBgColor = const Color(0xFFCBD5E1); // Locked Grey
                      } else {
                        // Alternate theme colors matching Figma (orange, green, blue)
                        final themeIdx = index % 3;
                        if (themeIdx == 0) {
                          headerBgColor = const Color(0xFFF09A37); // Orange
                        } else if (themeIdx == 1) {
                          headerBgColor = const Color(0xFF10A36D); // Green
                        } else {
                          headerBgColor = const Color(0xFF1D87F3); // Blue
                        }
                      }

                      final String difficulty = lesson.difficulty ?? 'Beginner';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isUnlocked ? headerBgColor.withValues(alpha: 0.4) : const Color(0xFFCBD5E1),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Upper Color Header Block
                              Container(
                                color: headerBgColor,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Circular L-badge with Emoji
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'L${index + 1}',
                                            style: const TextStyle(
                                              fontFamily: 'FredokaOne',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        isUnlocked
                                            ? Text(
                                                avatarEmoji,
                                                style: const TextStyle(fontSize: 34),
                                              )
                                            : const Icon(
                                                Icons.lock_outline_rounded,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                      ],
                                    ),

                                    // Right badge (Difficulty) & Decor Star / Check
                                    Row(
                                      children: [
                                        // Small Decorative Star
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),

                                        // Difficulty Label Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white54, width: 1),
                                          ),
                                          child: Text(
                                            difficulty,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Completed green circle check or NOW badge
                                        if (isUnlocked && isDone)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFEF08A), // Yellow circle check
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Color(0xFF854D0E),
                                            ),
                                          )
                                        else if (isUnlocked && !isDone && index == completedCount)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF08A),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.play_arrow_rounded, size: 10, color: Color(0xFF854D0E)),
                                                Text(
                                                  'NOW',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF854D0E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Lower White Info Block
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    // Left Info Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          Text(
                                            lesson.title,
                                            style: const TextStyle(
                                              fontFamily: 'FredokaOne',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          // Stars or Locked Subtext
                                          if (isUnlocked) ...[
                                            Builder(
                                              builder: (context) {
                                                int completedGames = 0;
                                                if (childId != null && !isDone) {
                                                  try {
                                                    final cacheBox = Hive.box('kidio_cache');
                                                    if (cacheBox.get('activity_status_${childId}_${lesson.id}_vocab', defaultValue: false)) completedGames++;
                                                    if (cacheBox.get('activity_status_${childId}_${lesson.id}_listening', defaultValue: false)) completedGames++;
                                                    if (cacheBox.get('activity_status_${childId}_${lesson.id}_pron', defaultValue: false)) completedGames++;
                                                    if (cacheBox.get('activity_status_${childId}_${lesson.id}_quiz', defaultValue: false)) completedGames++;
                                                    if (cacheBox.get('activity_status_${childId}_${lesson.id}_boss', defaultValue: false)) completedGames++;
                                                  } catch (_) {}
                                                }

                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        // 3 Star Representation
                                                        Row(
                                                          children: List.generate(3, (starIdx) {
                                                            // Map completed stars (e.g. up to 3)
                                                            final active = isDone && (starIdx < (starsEarned >= 3 ? 3 : starsEarned));
                                                            return Icon(
                                                              Icons.star_rounded,
                                                              color: active ? const Color(0xFFFACC15) : const Color(0xFFCBD5E1),
                                                              size: 16,
                                                            );
                                                          }),
                                                        ),
                                                        const SizedBox(width: 8),

                                                        // Status Text: Complete! / progress %
                                                        Text(
                                                          isDone
                                                              ? 'Hoàn thành! ✓'
                                                              : (completedGames > 0 ? '${completedGames * 20}%' : '0%'),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w900,
                                                            color: isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    // Progress bar for all unlocked, incomplete lessons
                                                    if (!isDone) ...[
                                                      const SizedBox(height: 6),
                                                      SizedBox(
                                                        width: 100,
                                                        height: 4,
                                                        child: LayoutBuilder(
                                                          builder: (ctx, constraints) {
                                                            final targetProgress = isDone ? 1.0 : (completedGames / 5.0);
                                                            return TweenAnimationBuilder<double>(
                                                              tween: Tween<double>(begin: 0, end: targetProgress.clamp(0.0, 1.0)),
                                                              duration: const Duration(milliseconds: 700),
                                                              curve: Curves.easeOutBack,
                                                              builder: (ctx, val, _) => Stack(
                                                                children: [
                                                                  Container(
                                                                    height: 4,
                                                                    width: constraints.maxWidth,
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFFF1F5F9),
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    height: 4,
                                                                    width: (constraints.maxWidth * val).clamp(0, constraints.maxWidth),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFF10B981),
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              }
                                            ),
                                          ] else ...[
                                            // Locked description
                                            Row(
                                              children: const [
                                                Icon(Icons.lock, color: Color(0xFFF97316), size: 10),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Hoàn thành bài trước để mở khóa',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFF97316),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Right Button Column
                                    if (isUnlocked)
                                      _build3DButton(
                                        text: isDone ? 'Ôn lại!' : (index == completedCount ? 'Tiếp tục' : 'Bắt đầu →'),
                                        baseColor: isDone
                                            ? const Color(0xFFFBBF24) // Yellow Ôn lại!
                                            : (index == completedCount
                                                ? const Color(0xFF10B981) // Green Tiếp tục
                                                : const Color(0xFF3B82F6)), // Blue Bắt đầu
                                        shadowColor: isDone
                                            ? const Color(0xFFD97706)
                                            : (index == completedCount
                                                ? const Color(0xFF047857)
                                                : const Color(0xFF1D4ED8)),
                                        onPressed: () async {
                                          final res = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LessonDetailScreen(lessonId: lesson.id),
                                            ),
                                          );
                                          if (mounted) {
                                            if (res == true) {
                                              final childId = context.read<ChildProvider>().selectedChild?.id;
                                              if (childId != null) {
                                                context.read<ProgressProvider>().loadChildProgress(childId);
                                              }
                                            }
                                            setState(() {});
                                          }
                                        },
                                      )
                                    else
                                      // Locked Lock Circle
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 16,
                                        ),
                                      ),
                                  ],
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
            );
          },
        ),
      ),
    );
  }

  Widget _build3DButton({
    required String text,
    required Color baseColor,
    required Color shadowColor,
    required VoidCallback onPressed,
  }) {
    return _Animated3DButton(
      text: text,
      baseColor: baseColor,
      shadowColor: shadowColor,
      onPressed: onPressed,
    );
  }

  Widget _buildScoringGuideSheet() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Text('🌟', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cách Tính Điểm Thưởng',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Để nhận được sao, con chỉ cần hoàn thành đầy đủ tất cả 5 thử thách trong bài học! Rất đơn giản phải không nào?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // 3 Stars Reward Card matching screenshot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8), // Light yellow background
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFEF08A), width: 1.5),
                ),
                child: Row(
                  children: [
                    // 3 Star Icons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 24),
                        Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 24),
                        Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 24),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Text labels
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tuyệt Vời!',
                            style: TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEAB308), // Yellow-orange
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hoàn thành 5/5 thử thách',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                    'Đã Rõ Luật Chơi!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Animated3DButton extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color shadowColor;
  final VoidCallback onPressed;

  const _Animated3DButton({
    required this.text,
    required this.baseColor,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  State<_Animated3DButton> createState() => _Animated3DButtonState();
}

class _Animated3DButtonState extends State<_Animated3DButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: widget.shadowColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: _isTapped ? 1.0 : 3.0),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.text,
              style: const TextStyle(
                fontFamily: 'FredokaOne',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
