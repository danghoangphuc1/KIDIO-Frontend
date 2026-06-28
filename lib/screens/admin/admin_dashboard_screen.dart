import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_topic_list_screen.dart';
import 'admin_lesson_list_screen.dart';
import 'admin_vocabulary_list_screen.dart';
import 'admin_topic_form_screen.dart';
import 'admin_vocabulary_form_screen.dart';
import 'admin_lesson_form_screen.dart';
import '../../utils/snackbar_utils.dart';
import '../../models/kidio_models.dart';
import '../../repositories/admin_dashboard_repository.dart';
import 'admin_users_screen.dart';
import 'admin_awards_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      bottomNavigationBar: _buildBottomNav(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _HomeScreen(onNavigate: _onTabTapped);
      case 1:
        return const _ContentScreen();
      case 2:
        return const AdminUsersScreen();
      case 3:
        return const AdminAwardsScreen();
      case 4:
        return AdminSettingsScreen(onExit: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Xác nhận thoát'),
              content: const Text('Bạn có chắc chắn muốn thoát khỏi chế độ quản trị?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<AuthProvider>().logout();
                  },
                  child: const Text('Thoát', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        });
      default:
        return _HomeScreen(onNavigate: _onTabTapped);
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF7C3AED),
            unselectedItemColor: const Color(0xFF9CA3AF),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Content'),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Users'),
              BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Awards'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const _HomeScreen({required this.onNavigate});

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AdminDashboardOverviewResponse? _dashboardData;
  int _visibleRecentActivitiesCount = 5;
  Future<AdminDashboardDetailResponse>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() {
    final repo = context.read<AdminDashboardRepository>();
    setState(() {
      _dashboardFuture = repo.getDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.currentUser;

    return FutureBuilder<AdminDashboardDetailResponse>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi khi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadDashboard, child: const Text('Thử lại')),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Glassmorphism Elements
              Container(
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: Center(
                            child: Text(userProfile?.displayName.isNotEmpty == true ? userProfile!.displayName[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                              Text(
                                '${userProfile?.displayName ?? 'Admin'} 👋',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xác nhận đăng xuất'),
                                content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      authProvider.logout();
                                    },
                                    child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Glassmorphism Search Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search users, topics, lessons...',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ),
              const SizedBox(height: 16),
              
              // Stats Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildStatCard('Parents', '${data.overview.totalParents}', Icons.family_restroom, const Color(0xFF7C3AED), const Color(0xFF6D28D9)),
                    _buildStatCard('Children', '${data.overview.totalChildren}', Icons.child_care, const Color(0xFF3B82F6), const Color(0xFF1D4ED8)),
                    _buildStatCard('Lessons', '${data.overview.totalLessons}', Icons.book_rounded, const Color(0xFF10B981), const Color(0xFF059669)),
                    _buildStatCard('Completed', '${data.overview.totalLessonCompletions}', Icons.check_circle_outline, const Color(0xFF0EA5E9), const Color(0xFF0284C7)),
                    _buildStatCard('Achievements', '${data.overview.totalAchievementsEarned}', Icons.emoji_events, const Color(0xFF8B5CF6), const Color(0xFF7C3AED)),
                    _buildStatCard('Topics', '${data.overview.totalTopics}', Icons.topic_rounded, const Color(0xFFF59E0B), const Color(0xFFD97706)),
                    _buildStatCard('Vocabs', '${data.overview.totalVocabularies}', Icons.sort_by_alpha, const Color(0xFFEC4899), const Color(0xFFBE185D)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Activities (From API)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: data.recentActivities.isEmpty 
                    ? const Text('Chưa có hoạt động nào.', style: TextStyle(color: Colors.grey))
                    : Column(
                        children: [
                          ...data.recentActivities.take(_visibleRecentActivitiesCount).map((act) {
                            Color c = const Color(0xFF7C3AED);
                            if (act.activityType.toLowerCase().contains('lesson')) c = const Color(0xFF3B82F6);
                            if (act.activityType.toLowerCase().contains('achievement')) c = const Color(0xFF10B981);
                            return _buildRecentActivity(act.childName, act.description, act.activityType.replaceAll('Lesson', '').replaceAll('Earned', '').trim(), _formatTimeAgo(act.timestamp), c);
                          }),
                          if (data.recentActivities.length > _visibleRecentActivitiesCount)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _visibleRecentActivitiesCount += 5;
                                });
                              },
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent),
                              label: const Text('Xem thêm', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions (Glassmorphism Cards)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95, // Increased height to prevent text overflow
                  children: [
                    _buildQuickAction(context, 'Add Topic', '🗂️', const Color(0xFF7C3AED), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTopicFormScreen()));
                    }),
                    _buildQuickAction(context, 'Add Vocab', '✏️', const Color(0xFF10B981), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVocabularyFormScreen()));
                    }),
                    _buildQuickAction(context, 'Manage Users', '👥', const Color(0xFFF59E0B), () {
                      widget.onNavigate(2);
                    }),
                    _buildQuickAction(context, 'System Settings', '⚙️', const Color(0xFFEC4899), () {
                      widget.onNavigate(4);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color c1, Color c2) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c1.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(String name, String action, String badge, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(action, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, String emoji, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 12),
                FittedBox(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)))),
                const SizedBox(height: 2),
                FittedBox(child: Text('Tap to open', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentScreen extends StatefulWidget {
  const _ContentScreen();

  @override
  State<_ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<_ContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Content Management',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () {
                      if (_tabController.index == 0) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTopicFormScreen()));
                      } else if (_tabController.index == 2) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVocabularyFormScreen()));
                      } else {
                        // Lesson tab
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLessonFormScreen()));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Glassmorphism TabBar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      labelColor: const Color(0xFF3B82F6),
                      unselectedLabelColor: Colors.white,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Topics'),
                        Tab(text: 'Lessons'),
                        Tab(text: 'Vocabulary'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AdminTopicListScreen(isEmbedded: true),
              AdminLessonListScreen(topic: null, isEmbedded: true),
              AdminVocabularyListScreen(isEmbedded: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Coming Soon', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const Text('This feature is under development.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
