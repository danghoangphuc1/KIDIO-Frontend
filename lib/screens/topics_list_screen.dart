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
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản phụ huynh không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Có', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      _buildTopicsGrid(),
      const AchievementsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _currentIndex == 0 ? 'Hành trình học tập' : 'Thành tích của con',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
        ),
        elevation: 0,
        actions: [
          Consumer<ChildProvider>(
            builder: (context, childProvider, _) {
              final selectedChild = childProvider.selectedChild;
              return GestureDetector(
                onTap: () => childProvider.deselectChild(),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: ClipOval(
                      child: selectedChild?.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: selectedChild!.avatarUrl!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Icon(Icons.account_circle, color: Colors.blueAccent),
                              errorWidget: (context, url, error) => const Icon(Icons.account_circle, color: Colors.blueAccent),
                            )
                          : const Icon(Icons.account_circle, color: Colors.blueAccent),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => _showLogoutConfirm(context),
          ),
        ],
      ),
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bài học'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Thành tích'),
        ],
        selectedItemColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildTopicsGrid() {
    return Column(
      children: [
        Consumer<TopicProvider>(
          builder: (context, provider, _) => provider.isOffline
              ? Container(
                  color: Colors.orange.shade800,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Text(
                    'Chế độ ngoại tuyến - Đang hiển thị dữ liệu cũ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: topicProvider.topics.length + (topicProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < topicProvider.topics.length) {
                      final topic = topicProvider.topics[index];
                      
                      // Lấy % tiến độ từ summary
                      final progressItem = progressProvider.summary?.topicProgresses.firstWhere(
                        (tp) => tp.topicId == topic.id,
                        orElse: () => TopicProgressItem(topicId: topic.id, topicName: topic.name, totalLessons: 0, completedLessons: 0, progressPercent: 0),
                      );

                      final List<Color> colors = [Colors.orange, Colors.green, Colors.purple, Colors.blue, Colors.pink];
                      final baseColor = colors[index % colors.length];

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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: baseColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: baseColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: topic.iconUrl != null
                                    ? CachedNetworkImage(imageUrl: topic.iconUrl!, width: 50, height: 50)
                                    : Icon(Icons.school, size: 50, color: baseColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                topic.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E)),
                              ),
                              const SizedBox(height: 8),
                              // Thanh tiến độ
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: (progressItem?.progressPercent ?? 0) / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      color: baseColor,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${progressItem?.progressPercent ?? 0}% hoàn thành',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: baseColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
}
