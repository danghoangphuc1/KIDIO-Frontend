import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback onExit;
  const AdminSettingsScreen({super.key, required this.onExit});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _saved = false;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Platform',
      'items': [
        {'icon': '📱', 'label': 'App Name', 'value': 'KIDIO'},
        {'icon': '✉️', 'label': 'Support Email', 'value': 'support@kidio.app'},
        {'icon': '🎂', 'label': 'Max Child Age', 'value': '10 years'},
        {'icon': '🌍', 'label': 'Language', 'value': 'English'},
      ],
    },
    {
      'title': 'Stats',
      'items': [
        {'icon': '👥', 'label': 'Total Users', 'value': '4,940'},
        {'icon': '🟢', 'label': 'Active Today', 'value': '1,847'},
        {'icon': '⏱️', 'label': 'Avg. Session', 'value': '18.4 min'},
        {'icon': '🏆', 'label': 'Top Topic', 'value': 'Animals'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          width: double.infinity,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              SizedBox(height: 4),
              Text('Configure your KIDIO platform', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._sections.map((sec) => _buildSection(sec)),
              
              GestureDetector(
                onTap: () {
                  setState(() => _saved = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _saved = false);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _saved ? 'Saved!' : 'Save Settings',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: widget.onExit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Exit to KIDIO App',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(Map<String, dynamic> sec) {
    final items = sec['items'] as List<Map<String, String>>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              sec['title'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    border: index < items.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF9FAFB))) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(item['icon']!, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['label']!, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                            const SizedBox(height: 1),
                            Text(item['value']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 16),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
