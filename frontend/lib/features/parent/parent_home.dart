import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import 'add_child_screen.dart';
import 'child_stats_screen.dart';
import '../chat/chat_list_screen.dart';
import '../auth/welcome_screen.dart';
import 'recommendations_screen.dart';
import 'screen_time_screen.dart';

/// Ota-ona uchun asosiy ekran - bolalar ro'yxati.
class ParentHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ParentHomeScreen({super.key, required this.user});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final _api = ApiClient();
  List<dynamic> _children = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final children = await _api.getMyChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Bolalarni yuklab bo\'lmadi';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAssignGroupDialog(Map<String, dynamic> child) async {
    List<dynamic> groups = [];
    try {
      groups = await _api.getAllGroups();
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Guruhga biriktirish"),
        content: SizedBox(
          width: double.maxFinite,
          child: groups.isEmpty
              ? const Text("Hozircha guruhlar mavjud emas")
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final g = groups[i];
                    final isCurrent = child['group_id'] == g['id'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrent
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        child: Text(
                          '${g['age_group']}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(g['name'] ?? ''),
                      subtitle: Text("${g['age_group']} yosh"),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.primaryColor)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await _api.assignChildToGroup(
                            child['id'] as String,
                            g['id'] as String,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "${child['full_name']} guruhga biriktirildi"),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                            _loadChildren();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().contains('403')
                                    ? "Bu bola sizniki emas"
                                    : "Xato yuz berdi. Qayta urinib ko'ring"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
        ],
      ),
    );
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
        title: const Text('Ota-ona paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: 'Ekran vaqti',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScreenTimeScreen()),
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Chiqish',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: _loadChildren,
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
                      "Bolalaringizning rivojlanishini kuzating",
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddChildScreen()),
          );
          if (added == true) {
            _loadChildren();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('BOLA QO\'SHISH'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChildren,
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }
    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care,
                size: 100, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              "Hali bola qo'shilmagan",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pastdagi '+' tugmasini bosing",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final child = _children[i];
        return _ChildCard(
          child: child,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildStatsScreen(child: child),
            ),
          ),
          onAssignGroup: () => _showAssignGroupDialog(child),
        );
      },
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;
  final VoidCallback onAssignGroup;

  const _ChildCard({
    required this.child,
    required this.onTap,
    required this.onAssignGroup,
  });

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      (child['full_name'] as String).isNotEmpty
                          ? (child['full_name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['full_name'] ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${child['age_group']} yosh',
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                        if (child['login'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Login: ${child['login']}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${child['total_stars'] ?? 0}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    child['group_id'] != null
                        ? Icons.groups
                        : Icons.group_add_outlined,
                    size: 16,
                    color: child['group_id'] != null
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    child['group_id'] != null
                        ? "Guruhga biriktirilgan"
                        : "Guruhga biriktirilmagan",
                    style: TextStyle(
                      fontSize: 12,
                      color: child['group_id'] != null
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onAssignGroup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit,
                              size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            "Guruhni o'zgartirish",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
