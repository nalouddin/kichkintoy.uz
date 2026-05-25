import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../auth/welcome_screen.dart';
import '../chat/chat_list_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import '../parent/recommendations_screen.dart';
import 'teacher_content_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const TeacherHomeScreen({super.key, required this.user});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _api = ApiClient();
  List<dynamic> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _api.getMyGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pedagog paneli'),
        backgroundColor: const Color(0xFF6C5CE7),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Kontent boshqaruvi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherContentScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Tavsiyalar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RecommendationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadGroups,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salom, ${widget.user['full_name']}!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Guruhlaringizni va bolalarni boshqaring",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Mening guruhlarim",
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildGroupsList()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          if (created == true) _loadGroups();
        },
        icon: const Icon(Icons.add),
        label: const Text("GURUH YARATISH"),
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 100, color: Color(0xFF6C5CE7)),
            const SizedBox(height: 16),
            const Text(
              "Hali guruh yaratilmagan",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pastdagi '+' tugmasi orqali yarating",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final group = _groups[i];
        return _GroupCard(
          group: group,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(group: group),
            ),
          ).then((_) => _loadGroups()),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.group,
                    color: Color(0xFF6C5CE7), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group['age_group']} yosh • ${group['children_count'] ?? 0} bola',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
