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
      appBar: AppBar(
        title: const Text('KIDIO Topics'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.topics.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(provider.errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: provider.refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.topics.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < provider.topics.length) {
                        final topic = provider.topics[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: topic.iconUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: topic.iconUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Icon(Icons.image),
                                      errorWidget: (context, url, error) => const Icon(Icons.folder),
                                    )
                                  : const Icon(Icons.folder, size: 40),
                            ),
                            title: Text(topic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${topic.totalLessons ?? 0} lessons'),
                            trailing: const Icon(Icons.chevron_right),
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
                          ),
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
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
