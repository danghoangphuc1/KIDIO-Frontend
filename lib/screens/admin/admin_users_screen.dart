import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _tab = 'parents'; // 'parents' or 'children'
  String _search = '';
  
  // Mock Data
  final List<Map<String, dynamic>> _parents = [
    {
      'id': 'p1',
      'name': 'Sarah Wilson',
      'email': 'sarah.w@example.com',
      'status': 'Active',
      'childrenCount': 2,
      'registered': '2025-10-12',
    },
    {
      'id': 'p2',
      'name': 'Michael Chen',
      'email': 'm.chen88@example.com',
      'status': 'Inactive',
      'childrenCount': 1,
      'registered': '2025-11-05',
    },
  ];

  final List<Map<String, dynamic>> _children = [
    {
      'id': 'c1',
      'parentId': 'p1',
      'name': 'Emma',
      'age': 6,
      'avatar': '👧',
      'stars': 120,
      'streak': 15,
      'level': 4,
      'pronScore': 85,
    },
    {
      'id': 'c2',
      'parentId': 'p1',
      'name': 'Lucas',
      'age': 8,
      'avatar': '👦',
      'stars': 340,
      'streak': 30,
      'level': 8,
      'pronScore': 92,
    },
    {
      'id': 'c3',
      'parentId': 'p2',
      'name': 'Mia',
      'age': 5,
      'avatar': '👧',
      'stars': 45,
      'streak': 2,
      'level': 1,
      'pronScore': 60,
    },
  ];

  Map<String, dynamic>? _selectedParent;
  Map<String, dynamic>? _selectedChild;

  @override
  Widget build(BuildContext context) {
    if (_selectedChild != null) {
      return _buildChildDetail(_selectedChild!);
    }
    if (_selectedParent != null) {
      return _buildParentDetail(_selectedParent!);
    }

    final filteredParents = _parents.where((p) => 
        p['name'].toString().toLowerCase().contains(_search.toLowerCase()) || 
        p['email'].toString().toLowerCase().contains(_search.toLowerCase())).toList();
    
    final filteredChildren = _children.where((c) => 
        c['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Users', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 14),
              // Search
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search by name or email...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Tabs
              Row(
                children: [
                  _buildTabBtn('Parents', _tab == 'parents', () => setState(() => _tab = 'parents')),
                  const SizedBox(width: 8),
                  _buildTabBtn('Children', _tab == 'children', () => setState(() => _tab = 'children')),
                ],
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tab == 'parents' ? filteredParents.length : filteredChildren.length,
            itemBuilder: (context, index) {
              if (_tab == 'parents') {
                final p = filteredParents[index];
                return _buildParentCard(p);
              } else {
                final c = filteredChildren[index];
                return _buildChildCard(c);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBtn(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () => setState(() => _selectedParent = p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                p['name'].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(p['email'], style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p['status'] == 'Active' ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: p['status'] == 'Active' ? const Color(0xFF059669) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${p['childrenCount']} children', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> c) {
    return GestureDetector(
      onTap: () => setState(() => _selectedChild = c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Text(c['avatar'], style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                      const SizedBox(width: 6),
                      Text('Age ${c['age']}', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('⭐ ${c['stars']}', style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text('🔥 ${c['streak']}d', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text('Lv ${c['level']}', style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  Widget _buildParentDetail(Map<String, dynamic> p) {
    final kids = _children.where((c) => c['parentId'] == p['id']).toList();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedParent = null),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p['name'].toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(p['email'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
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
                    _buildDetailRow('Status', p['status']),
                    const Divider(height: 16),
                    _buildDetailRow('Registered', p['registered']),
                    const Divider(height: 16),
                    _buildDetailRow('Children', p['childrenCount'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Children (${kids.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 12),
              ...kids.map((c) => _buildChildCard(c)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildDetail(Map<String, dynamic> c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedChild = null),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(c['avatar'], style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Age ${c['age']} • Level ${c['level']}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _buildStatCard('⭐ Stars', c['stars'].toString(), const Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  _buildStatCard('🔥 Streak', '${c['streak']}d', const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatCard('📚 Lessons', '24', const Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  _buildStatCard('🎯 Score', '${c['pronScore']}%', const Color(0xFF7C3AED)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Achievement Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                    const SizedBox(height: 12),
                    _buildAchievementRow('First Lesson', '🎯', true),
                    const Divider(height: 16),
                    _buildAchievementRow('3 Day Streak', '🔥', true),
                    const Divider(height: 16),
                    _buildAchievementRow('100 Stars', '⭐', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementRow(String name, String emoji, bool unlocked) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: unlocked ? const Color(0xFF7C3AED).withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: unlocked ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
        Icon(unlocked ? Icons.check_circle : Icons.lock, color: unlocked ? const Color(0xFF059669) : const Color(0xFFD1D5DB), size: 18),
      ],
    );
  }
}
