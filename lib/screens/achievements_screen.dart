import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/progress_provider.dart';
import '../providers/child_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final childProvider = context.watch<ChildProvider>();
    final child = childProvider.selectedChild;

    if (progressProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (progressProvider.achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '${child?.name ?? 'Bé'} chưa có huy hiệu nào.',
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
            const Text('Hãy hoàn thành các bài học để nhận quà nhé!'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Child Summary Header
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orangeAccent, width: 2),
                ),
                child: ClipOval(
                  child: child?.avatarUrl != null
                      ? CachedNetworkImage(imageUrl: child!.avatarUrl!)
                      : const Icon(Icons.face),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child?.name ?? 'Bé',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 4),
                        Text('${child?.totalStars ?? 0} Ngôi sao'),
                        const SizedBox(width: 16),
                        const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 4),
                        Text('${child?.currentStreakDays ?? 0} Ngày liên tiếp'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                'Bộ sưu tập huy hiệu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: progressProvider.achievements.length,
            itemBuilder: (context, index) {
              final achievement = progressProvider.achievements[index];
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                        ],
                      ),
                      child: achievement.iconUrl != null
                          ? CachedNetworkImage(
                              imageUrl: achievement.iconUrl!,
                              placeholder: (context, url) => const Icon(Icons.stars, color: Colors.orangeAccent),
                            )
                          : const Icon(Icons.stars, size: 50, color: Colors.orangeAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
