import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/kidio_models.dart';
import '../providers/topic_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import 'topic_detail_screen.dart';
import 'achievements_screen.dart';
import '../widgets/glassmorphic_widgets.dart';

class TopicsListScreen extends StatefulWidget {
  const TopicsListScreen({super.key});

  @override
  State<TopicsListScreen> createState() => _TopicsListScreenState();
}

class _TopicsListScreenState extends State<TopicsListScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopicProvider>().loadFirstPage();
      final childId = context.read<ChildProvider>().selectedChild?.id;
      if (childId != null) {
        context.read<ProgressProvider>().loadChildProgress(childId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<TopicProvider>().loadMore();
    }
  }

  void _showLogoutConfirm(BuildContext context) {
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
              context.read<AuthProvider>().logout();
            },
            child: const Text('CÓ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildTopicsGrid(),
      const AchievementsScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: _isSearching ? 80 : 70,
        backgroundColor: Colors.white.withOpacity(0.15),
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: _isSearching 
          ? _buildSearchField()
          : Consumer<ChildProvider>(
              builder: (context, childProvider, _) {
                final selectedChild = childProvider.selectedChild;
                final stars = selectedChild?.totalStars ?? 0;
                
                if (_currentIndex == 1) {
                  return Row(
                    children: [
                      const Text(
                        'Thành tích của con',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => _buildBadgeGuideSheet(),
                          );
                        },
                        child: const Icon(Icons.help_outline_rounded, color: Colors.blueAccent, size: 24),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    // Back/Avatar button on the left
                    GestureDetector(
                      onTap: () => childProvider.deselectChild(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: ClipOval(
                          child: selectedChild?.avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: selectedChild!.avatarUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Icon(Icons.face_rounded, color: Colors.blueAccent),
                                  errorWidget: (context, url, error) => const Icon(Icons.face_rounded, color: Colors.blueAccent),
                                )
                              : const Icon(Icons.face_rounded, color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Star Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF08A), // Light yellow
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '$stars',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF854D0E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Fire Streak Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5), // Light orange
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFB923C), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '${selectedChild?.currentStreakDays ?? 0}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // KIDIO Logo
                    const Text(
                      'KIDIO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
        actions: [
          if (!_isSearching && _currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.blueAccent),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() => _isSearching = false);
                _searchController.clear();
                context.read<TopicProvider>().search(null);
              },
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
              onPressed: () => _showLogoutConfirm(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: PlayfulBackground(
        backgroundColors: const [
          Color(0xFFE0F2FE), // Light sky blue
          Color(0xFFFEE2E2), // Light pink/red
          Color(0xFFFEF9C3), // Light yellow
        ],
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _isSearching = false;
                });
              },
              backgroundColor: Colors.white.withOpacity(0.15),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.blueGrey.shade300,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_rounded, size: 28),
                  activeIcon: Icon(Icons.auto_stories_rounded, size: 30),
                  label: 'BÀI HỌC',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.workspace_premium_rounded, size: 28),
                  activeIcon: Icon(Icons.workspace_premium_rounded, size: 30),
                  label: 'THÀNH TÍCH',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Tìm bài học...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          context.read<TopicProvider>().search(value);
        },
      ),
    );
  }

  Widget _buildTopicsGrid() {
    return Column(
      children: [
        Consumer<TopicProvider>(
          builder: (context, provider, _) => provider.isOffline
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orangeAccent,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Đang xem lại bài học (Ngoại tuyến)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Consumer2<TopicProvider, ProgressProvider>(
            builder: (context, topicProvider, progressProvider, child) {
              if (topicProvider.isLoading && topicProvider.topics.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!topicProvider.isLoading && topicProvider.topics.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        topicProvider.searchQuery != null 
                          ? 'Không tìm thấy bài học nào.'
                          : 'Chưa có bài học nào hôm nay.', 
                        style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await topicProvider.refresh();
                  final childId = context.read<ChildProvider>().selectedChild?.id;
                  if (childId != null) {
                    await progressProvider.loadChildProgress(childId);
                  }
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 120,
                    bottom: 24,
                    left: 20,
                    right: 20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: topicProvider.topics.length + 1 + (topicProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildDailyQuestCard(context);
                    }
                    
                    final topicIndex = index - 1;
                    if (topicIndex < topicProvider.topics.length) {
                      final topic = topicProvider.topics[topicIndex];
                      final progressItem = progressProvider.summary?.topicProgresses.firstWhere(
                        (tp) => tp.topicId == topic.id,
                        orElse: () => TopicProgressItem(topicId: topic.id, topicName: topic.name, totalLessons: 0, completedLessons: 0, progressPercent: 0),
                      );

                      final List<Color> colors = [
                        const Color(0xFF10B981), // Green (Animals)
                        const Color(0xFFF97316), // Orange (Food)
                        const Color(0xFFEC4899), // Pink (Family)
                        const Color(0xFF8B5CF6), // Purple
                        const Color(0xFF38BDF8), // Light Blue
                      ];
                      final baseColor = colors[topicIndex % colors.length];

                      return _buildStaggeredMapRow(context, topic, progressItem, baseColor, topicIndex);
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuestCard(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 24),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16),
      fillColor: Colors.amber.shade50.withOpacity(0.35),
      borderColor: Colors.amber.shade200.withOpacity(0.6),
      borderWidth: 2.5,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('🏆', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhiệm Vụ Hàng Ngày',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hoàn thành 1 bài học để nhận thêm 10 ⭐!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Color(0xFFFEF3C7),
                    color: Color(0xFFF59E0B),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredMapRow(BuildContext context, Topic topic, TopicProgressItem? progress, Color color, int index) {
    final bool isEven = index % 2 == 0;
    final progressPercent = progress?.progressPercent ?? 0;

    // Action button text and colors matching Figma specs
    final String buttonText = progressPercent >= 100
        ? 'Completed! 🎖️'
        : progressPercent > 0
            ? 'Continue! 🚀'
            : 'Start! 👉';

    final Color btnBaseColor = progressPercent >= 100
        ? const Color(0xFF10B981) // Green
        : progressPercent > 0
            ? const Color(0xFFF97316) // Orange
            : const Color(0xFFFF2E93); // Pink

    final Color btnShadowColor = progressPercent >= 100
        ? const Color(0xFF047857)
        : progressPercent > 0
            ? const Color(0xFFC2410C)
            : const Color(0xFFB8154E);

    // Build the topic island card
    final cardWidget = GlassCard(
      width: 155,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(12),
      fillColor: Colors.white.withOpacity(0.35),
      borderColor: color.withOpacity(0.5),
      borderWidth: 2.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getTopicEmoji(topic.name),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            topic.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 6),
          // Star ratings representing levels of progress (5 stars matching Figma)
          _buildStarRating(progressPercent),
          const SizedBox(height: 8),
          
          // Action button with Tap-shrinking scale
          _AnimatedMapButton(
            text: buttonText,
            baseColor: btnBaseColor,
            shadowColor: btnShadowColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicDetailScreen(
                    topicId: topic.id,
                    topicName: topic.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    // Stagger layout using Row with center divider
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center vertical dashed line
          Positioned(
            top: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(20, 210),
              painter: DashedLinePainter(isVertical: true, strokeWidth: 3.5, color: const Color(0xFF94A3B8)),
            ),
          ),

          // Horizontal connecting line
          Positioned(
            left: isEven ? 100 : null,
            right: !isEven ? 100 : null,
            child: Container(
              width: 80,
              height: 20,
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(80, 20),
                painter: DashedLinePainter(isVertical: false, strokeWidth: 2.5, color: color.withOpacity(0.5)),
              ),
            ),
          ),

          // Center pathway dot node
          Positioned(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),

          // Island Card placement
          Row(
            children: [
              Expanded(
                child: isEven
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: cardWidget,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 40), // Center gap for the path dot
              Expanded(
                child: !isEven
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: cardWidget,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTopicEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('animal') || lower.contains('động vật')) return '🦁';
    if (lower.contains('food') || lower.contains('fruit') || lower.contains('ăn') || lower.contains('quả')) return '🍎';
    if (lower.contains('family') || lower.contains('gia đình')) return '👪';
    if (lower.contains('school') || lower.contains('trường')) return '🎒';
    if (lower.contains('color') || lower.contains('màu')) return '🎨';
    if (lower.contains('number') || lower.contains('số')) return '🔢';
    if (lower.contains('toy') || lower.contains('chơi')) return '🧸';
    return '📚';
  }

  Widget _buildStarRating(int progressPercent) {
    int stars = 0;
    if (progressPercent >= 100) {
      stars = 5;
    } else if (progressPercent >= 80) {
      stars = 4;
    } else if (progressPercent >= 60) {
      stars = 3;
    } else if (progressPercent >= 40) {
      stars = 2;
    } else if (progressPercent >= 20) {
      stars = 1;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i < stars;
        return Icon(
          Icons.star_rounded,
          color: active ? const Color(0xFFFACC15) : const Color(0xFFCBD5E1),
          size: 18,
        );
      }),
    );
  }

  Widget _buildBadgeGuideSheet() {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 32),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Cách Nhận Huy Hiệu',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Để sưu tập huy hiệu siêu ngầu, con cần chăm chỉ học bài nhé! Học càng nhiều bài học mới, huy hiệu càng hiếm:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey, height: 1.4),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/1.png', 'Tân binh dũng cảm', 'Hoàn thành 1 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/2.png', 'Chiến binh thông thái', 'Hoàn thành 2 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/3.png', 'Ngôi sao chớp nhoáng', 'Hoàn thành 3 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/4.png', 'Sắc màu rực rỡ', 'Hoàn thành 4 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/5.png', 'Trái tim kiên cường', 'Hoàn thành 5 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/6.png', 'Bậc thầy kiên nhẫn', 'Hoàn thành 6 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/7.png', 'Ngọn lửa nhiệt huyết', 'Hoàn thành 7 bài học'),
                  _buildBadgeRuleItem('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/badges/8.png', 'Nhà vô địch Trái Đất', 'Hoàn thành 8 bài học'),
                ],
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
                child: const Text('Đã Rõ Cách Nhận!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
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
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.orange.shade800)),
                const SizedBox(height: 4),
                Text(range, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Staggered Map Animated Button
class _AnimatedMapButton extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color shadowColor;
  final VoidCallback onPressed;

  const _AnimatedMapButton({
    required this.text,
    required this.baseColor,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedMapButton> createState() => _AnimatedMapButtonState();
}

class _AnimatedMapButtonState extends State<_AnimatedMapButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isTapped ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: widget.shadowColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: _isTapped ? 1.5 : 3.5),
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final bool isVertical;

  DashedLinePainter({
    this.color = const Color(0xFF94A3B8),
    this.strokeWidth = 3,
    this.gap = 6,
    this.dashLength = 8,
    this.isVertical = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (isVertical) {
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashLength), paint);
        y += dashLength + gap;
      }
    } else {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, size.height / 2), Offset(x + dashLength, size.height / 2), paint);
        x += dashLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
