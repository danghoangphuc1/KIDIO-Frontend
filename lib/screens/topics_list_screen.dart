import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/topic_provider.dart';
import '../providers/auth_provider.dart';
import 'topic_detail_screen.dart';

class TopicsListScreen extends StatefulWidget {
  const TopicsListScreen({super.key});

  @override
  State<TopicsListScreen> createState() => _TopicsListScreenState();
}

class _TopicsListScreenState extends State<TopicsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopicProvider>().loadFirstPage();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Learning Adventures',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.blueAccent, size: 30),
            onPressed: () {
              // Show profile or settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline persistent banner
          Consumer<TopicProvider>(
            builder: (context, provider, _) => provider.isOffline
                ? Container(
                    color: Colors.orange.shade800,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Offline Mode - Showing Cached Data',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Consumer<TopicProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.topics.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.topics.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: provider.refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.topics.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < provider.topics.length) {
                        final topic = provider.topics[index];
                        // Assign a color based on index
                        final List<Color> colors = [
                          Colors.orange.shade100,
                          Colors.green.shade100,
                          Colors.purple.shade100,
                          Colors.blue.shade100,
                          Colors.pink.shade100,
                          Colors.yellow.shade100,
                        ];
                        final cardColor = colors[index % colors.length];
                        final iconColor = Colors.primaries[index % Colors.primaries.length];

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
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: topic.iconUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: topic.iconUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) => Icon(Icons.school, size: 40, color: iconColor),
                                          errorWidget: (context, url, error) => Icon(Icons.book, size: 40, color: iconColor),
                                        )
                                      : Icon(Icons.school, size: 60, color: iconColor),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  topic.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${topic.totalLessons ?? 0} lessons',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blueGrey.shade700,
                                    fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
