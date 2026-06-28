import 'package:flutter/material.dart';

class AdminAwardsScreen extends StatefulWidget {
  const AdminAwardsScreen({super.key});

  @override
  State<AdminAwardsScreen> createState() => _AdminAwardsScreenState();
}

class _AdminAwardsScreenState extends State<AdminAwardsScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _achievements = [
    {
      'id': 'a1',
      'name': 'First Steps',
      'desc': 'Complete your first lesson',
      'emoji': '🎯',
      'reqStars': 0,
      'reqStreak': 0,
      'unlocks': 1250,
    },
    {
      'id': 'a2',
      'name': 'Consistency is Key',
      'desc': 'Maintain a 3-day learning streak',
      'emoji': '🔥',
      'reqStars': 0,
      'reqStreak': 3,
      'unlocks': 840,
    },
    {
      'id': 'a3',
      'name': 'Star Collector',
      'desc': 'Collect 50 stars from exercises',
      'emoji': '⭐',
      'reqStars': 50,
      'reqStreak': 0,
      'unlocks': 420,
    },
    {
      'id': 'a4',
      'name': 'Pronunciation Pro',
      'desc': 'Get 100% on 5 pronunciation drills',
      'emoji': '🗣️',
      'reqStars': 0,
      'reqStreak': 0,
      'unlocks': 150,
    },
    {
      'id': 'a5',
      'name': 'Week Champion',
      'desc': 'Maintain a 7-day streak',
      'emoji': '👑',
      'reqStars': 0,
      'reqStreak': 7,
      'unlocks': 85,
    },
  ];

  @override
  Widget build(BuildContext context) {
    int totalUnlocks = _achievements.fold(0, (sum, item) => sum + (item['unlocks'] as int));

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Achievements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTap: () {
                      // Show Add Modal
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_achievements.length} badges • $totalUnlocks total unlocks',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final a = _achievements[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(a['emoji'], style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text(a['desc'], style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (a['reqStars'] > 0)
                                    _buildBadge('Stars: ${a['reqStars']}', const Color(0xFFD97706)),
                                  if (a['reqStreak'] > 0)
                                    _buildBadge('Streak: ${a['reqStreak']}d', const Color(0xFFEF4444)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Delete
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFF9FAFB))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Unlocked by', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                          Text('${a['unlocks']} children', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
