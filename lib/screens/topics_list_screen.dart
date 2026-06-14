import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/kidio_models.dart';
import '../providers/topic_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/progress_provider.dart';
import 'topic_detail_screen.dart';
import 'achievements_screen.dart';

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
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        toolbarHeight: _isSearching ? 80 : 70,
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching 
          ? _buildSearchField()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentIndex == 0 ? 'Chào con yêu! 👋' : 'Thành tích của con',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A237E),
                  ),
                ),
                if (_currentIndex == 0)
                  const Text(
                    'Hôm nay chúng mình học gì nào?',
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                  ),
              ],
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
            Consumer<ChildProvider>(
              builder: (context, childProvider, _) {
                final selectedChild = childProvider.selectedChild;
                return GestureDetector(
                  onTap: () => childProvider.deselectChild(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          selectedChild?.name ?? 'Bé',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent, width: 2),
                          ),
                          child: ClipOval(
                            child: selectedChild?.avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: selectedChild!.avatarUrl!,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Icon(Icons.face, color: Colors.blueAccent),
                                    errorWidget: (context, url, error) => const Icon(Icons.face, color: Colors.blueAccent),
                                  )
                                : const Icon(Icons.face, color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _isSearching = false;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey.shade400,
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
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Tăng chiều cao để tránh overflow
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: topicProvider.topics.length + (topicProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < topicProvider.topics.length) {
                      final topic = topicProvider.topics[index];
                      
                      final progressItem = progressProvider.summary?.topicProgresses.firstWhere(
                        (tp) => tp.topicId == topic.id,
                        orElse: () => TopicProgressItem(topicId: topic.id, topicName: topic.name, totalLessons: 0, completedLessons: 0, progressPercent: 0),
                      );

                      final List<Color> colors = [Colors.orange, Colors.green, Colors.purple, Colors.blue, Colors.pink];
                      final baseColor = colors[index % colors.length];

                      return _buildTopicCard(context, topic, progressItem, baseColor);
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

  Widget _buildTopicCard(BuildContext context, Topic topic, TopicProgressItem? progress, Color color) {
    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: topic.iconUrl != null
                            ? CachedNetworkImage(
                                imageUrl: topic.iconUrl!,
                                width: 35,
                                height: 35,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) => Icon(Icons.book_rounded, size: 30, color: color),
                              )
                            : Icon(Icons.book_rounded, size: 30, color: color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      topic.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (progress?.progressPercent ?? 0) / 100,
                            backgroundColor: Colors.grey.shade100,
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${progress?.progressPercent ?? 0}%',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
                              ),
                              Text(
                                ' XONG',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
