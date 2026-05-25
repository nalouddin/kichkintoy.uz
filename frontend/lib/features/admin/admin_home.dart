import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../auth/welcome_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final _pages = const [
    _DashboardTab(),
    _UsersTab(),
    _LessonsTab(),
    _ContentTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin paneli'),
        backgroundColor: const Color(0xFF2D3436),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiClient().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF2D3436),
        indicatorColor: AppTheme.primaryColor,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.dashboard, color: Colors.white),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.people, color: Colors.white),
            label: 'Foydalanuvchilar',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.school, color: Colors.white),
            label: 'Darslar',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.auto_stories, color: Colors.white),
            label: 'Kontent',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD TAB
// ============================================================

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _api = ApiClient();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _api.getAdminStats();
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Ma\'lumotlarni yuklab bo\'lmadi'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Tizim statistikasi',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _StatsGrid(stats: _stats!),
                  ],
                ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Ota-onalar', '${stats['total_parents']}',
          Icons.family_restroom, AppTheme.primaryColor),
      _StatItem('Pedagoglar', '${stats['total_teachers']}',
          Icons.school, const Color(0xFF6C5CE7)),
      _StatItem('Bolalar', '${stats['total_children']}',
          Icons.child_care, AppTheme.secondaryColor),
      _StatItem('Guruhlar', '${stats['total_groups']}',
          Icons.groups, Colors.teal),
      _StatItem('Darslar', '${stats['total_lessons']}',
          Icons.menu_book, Colors.orange),
      _StatItem('Ertaklar', '${stats['total_stories']}',
          Icons.auto_stories, Colors.pink),
      _StatItem('Tavsiyalar', '${stats['total_recommendations']}',
          Icons.lightbulb, Colors.amber),
      _StatItem('Jami foydalanuvchi', '${stats['total_users']}',
          Icons.people, Colors.indigo),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _StatCard(item: items[i]),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: item.color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              Text(item.label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// USERS TAB
// ============================================================

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  List<dynamic> _users = [];
  bool _isLoading = true;
  late TabController _tabController;

  final _roles = ['parent', 'teacher', 'child'];
  final _roleLabels = ['Ota-onalar', 'Pedagoglar', 'Bolalar'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final role = _roles[_tabController.index];
      final users = await _api.getAdminUsers(role: role);
      if (mounted) setState(() { _users = users; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(Map user) async {
    try {
      final updated = await _api.toggleUserActive(user['id'] as String);
      if (!mounted) return;
      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) _users[idx] = updated;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xato yuz berdi'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(Map user) async {
    final ok = await _confirmDelete(context, user['full_name'] as String);
    if (!ok) return;
    try {
      await _api.adminDeleteUser(user['id'] as String);
      if (!mounted) return;
      setState(() => _users.removeWhere((u) => u['id'] == user['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O'chirildi"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('400')
            ? "Avval bog'liq ma'lumotlarni o'chiring"
            : "Xato yuz berdi";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _create() async {
    final role = _roles[_tabController.index];
    if (role == 'child') {
      await _showCreateChildDialog();
    } else {
      await _showCreateUserDialog(role);
    }
    _load();
  }

  Future<void> _showCreateUserDialog(String role) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(role == 'parent' ? 'Yangi ota-ona' : 'Yangi pedagog'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'F.I.Sh. *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefon (login) *',
                    hintText: '+998901234567',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email (ixtiyoriy)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Parol *'),
                  obscureText: true,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    phoneCtrl.text.trim().isEmpty ||
                    passwordCtrl.text.length < 4) {
                  setS(() => error = "F.I.Sh., telefon va parol (min 4 belgi) to'ldiring");
                  return;
                }
                try {
                  await _api.adminCreateUser(
                    fullName: nameCtrl.text.trim(),
                    role: role,
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    password: passwordCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (_) {
                  setS(() => error = "Xato: telefon band bo'lishi mumkin");
                }
              },
              child: const Text("Qo'shish"),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showCreateChildDialog() async {
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    DateTime? birthDate;
    String? selectedParentId;
    List<dynamic> parents = [];
    String? error;

    try {
      parents = await _api.getAdminUsers(role: 'parent');
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: const Text('Yangi bola'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Bola to'liq ismi *"),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime(2020),
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2023),
                    );
                    if (d != null) setS(() => birthDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Tug'ilgan sana *",
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      birthDate == null
                          ? 'Sanani tanlang'
                          : '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: birthDate == null ? Colors.grey : Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (parents.isEmpty)
                  const Text('Avval ota-ona yarating',
                      style: TextStyle(color: Colors.orange))
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedParentId,
                    decoration: const InputDecoration(labelText: 'Ota-ona *'),
                    items: parents
                        .map((p) => DropdownMenuItem<String>(
                              value: p['id'] as String,
                              child: Text(p['full_name'] as String),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => selectedParentId = v),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Parol *'),
                  obscureText: true,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    birthDate == null ||
                    selectedParentId == null ||
                    passwordCtrl.text.length < 4) {
                  setS(() => error = "Barcha maydonlarni to'ldiring");
                  return;
                }
                try {
                  final bd = birthDate!;
                  await _api.adminCreateChild(
                    fullName: nameCtrl.text.trim(),
                    birthDate:
                        '${bd.year}-${bd.month.toString().padLeft(2, '0')}-${bd.day.toString().padLeft(2, '0')}',
                    password: passwordCtrl.text,
                    parentId: selectedParentId!,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (_) {
                  setS(() => error = "Xato. Yoshni tekshiring (2-10 yosh bo'lsin)");
                }
              },
              child: const Text("Qo'shish"),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF2D3436),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: _roleLabels.map((l) => Tab(text: l)).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text("Yangi qo'shish"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(
                      child: Text('Foydalanuvchilar yo\'q',
                          style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          final isActive = u['is_active'] as bool;
                          final loginInfo = u['phone'] ?? u['email'] ?? '';
                          final passwordInfo = u['password_plain'] as String? ?? '••••';
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isActive
                                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                    : Colors.grey.shade200,
                                child: Text(
                                  (u['full_name'] as String).isNotEmpty
                                      ? (u['full_name'] as String)[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                ),
                              ),
                              title: Text(
                                u['full_name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Login: $loginInfo  •  Parol: $passwordInfo',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: isActive,
                                    activeThumbColor: AppTheme.primaryColor,
                                    onChanged: (_) => _toggleActive(u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () => _deleteUser(u),
                                    tooltip: "O'chirish",
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ============================================================
// LESSONS TAB
// ============================================================

class _LessonsTab extends StatefulWidget {
  const _LessonsTab();

  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  final _api = ApiClient();
  List<dynamic> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final lessons = await _api.getLessons();
      if (mounted) setState(() { _lessons = lessons; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("O'chirishni tasdiqlang"),
        content: Text("\"$title\" darsini o'chirmoqchimisiz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Bekor qilish")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteLesson(id);
      if (mounted) {
        setState(() => _lessons.removeWhere((l) => l['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Dars o'chirildi"),
              backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Xato yuz berdi"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _categoryEmoji(String cat) {
    const map = {
      'letters': '🔤', 'numbers': '🔢', 'colors': '🎨',
      'shapes': '⭐', 'memory': '🧠', 'puzzle': '🧩',
      'story': '📖', 'drawing': '✏️',
    };
    return map[cat] ?? '📚';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _lessons.isEmpty
                  ? const Center(child: Text('Darslar yo\'q'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final l = _lessons[i];
                        final emoji = _categoryEmoji(l['category'] as String);
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Text(emoji,
                                style: const TextStyle(fontSize: 28)),
                            title: Text(l['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "${l['age_group']} yosh • ${l['category']} • ${l['difficulty']}⭐"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  _delete(l['id'] as String, l['title'] as String),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ============================================================
// CONTENT TAB (Ertaklar + Tavsiyalar)
// ============================================================

class _ContentTab extends StatefulWidget {
  const _ContentTab();

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF2D3436),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Ertaklar'),
              Tab(text: 'Tavsiyalar'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _StoriesPanel(),
              _RecommendationsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Stories Panel ----

class _StoriesPanel extends StatefulWidget {
  const _StoriesPanel();

  @override
  State<_StoriesPanel> createState() => _StoriesPanelState();
}

class _StoriesPanelState extends State<_StoriesPanel> {
  final _api = ApiClient();
  List<dynamic> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final s = await _api.getStories();
      if (mounted) setState(() { _stories = s; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id, String title) async {
    final ok = await _confirmDelete(context, title);
    if (!ok) return;
    try {
      await _api.deleteStory(id);
      if (mounted) setState(() => _stories.removeWhere((s) => s['id'] == id));
    } catch (_) {}
  }

  Future<void> _showAddDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    String category = 'story';
    int ageGroup = 4;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: const Text("Yangi ertak qo'shish"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Sarlavha *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      const InputDecoration(labelText: 'Tur'),
                  items: const [
                    DropdownMenuItem(value: 'story', child: Text('Ertak')),
                    DropdownMenuItem(value: 'poem', child: Text("She'r")),
                    DropdownMenuItem(value: 'song', child: Text("Qo'shiq")),
                  ],
                  onChanged: (v) => setS(() => category = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: ageGroup,
                  decoration: const InputDecoration(labelText: 'Yosh guruhi'),
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(
                        value: i + 3, child: Text('${i + 3} yosh')),
                  ),
                  onChanged: (v) => setS(() => ageGroup = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Muallif'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'Matn *'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    contentCtrl.text.trim().isEmpty) { return; }
                Navigator.pop(ctx);
                try {
                  await _api.createStory(
                    title: titleCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    category: category,
                    ageGroup: ageGroup,
                    author: authorCtrl.text.trim().isEmpty
                        ? null
                        : authorCtrl.text.trim(),
                  );
                  _load();
                } catch (_) {}
              },
              child: const Text("Qo'shish"),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _stories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = _stories[i];
                  final catEmoji = s['category'] == 'story'
                      ? '📖'
                      : s['category'] == 'poem'
                          ? '📝'
                          : '🎵';
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Text(catEmoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(s['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "${s['age_group']} yosh • ${s['author'] ?? ''}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _delete(s['id'] as String, s['title'] as String),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ---- Recommendations Panel ----

class _RecommendationsPanel extends StatefulWidget {
  const _RecommendationsPanel();

  @override
  State<_RecommendationsPanel> createState() => _RecommendationsPanelState();
}

class _RecommendationsPanelState extends State<_RecommendationsPanel> {
  final _api = ApiClient();
  List<dynamic> _recs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final r = await _api.getRecommendations();
      if (mounted) setState(() { _recs = r; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id, String title) async {
    final ok = await _confirmDelete(context, title);
    if (!ok) return;
    try {
      await _api.deleteRecommendation(id);
      if (mounted) setState(() => _recs.removeWhere((r) => r['id'] == id));
    } catch (_) {}
  }

  Future<void> _showAddDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    String category = 'parent';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: const Text("Yangi tavsiya qo'shish"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Sarlavha *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategoriya'),
                  items: const [
                    DropdownMenuItem(
                        value: 'parent', child: Text('Ota-ona uchun')),
                    DropdownMenuItem(
                        value: 'teacher', child: Text('Pedagog uchun')),
                    DropdownMenuItem(
                        value: 'psychology', child: Text('Psixologiya')),
                    DropdownMenuItem(
                        value: 'development', child: Text('Rivojlanish')),
                  ],
                  onChanged: (v) => setS(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Muallif'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'Matn *'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    contentCtrl.text.trim().isEmpty) { return; }
                Navigator.pop(ctx);
                try {
                  await _api.createRecommendation(
                    title: titleCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    category: category,
                    author: authorCtrl.text.trim().isEmpty
                        ? null
                        : authorCtrl.text.trim(),
                  );
                  _load();
                } catch (_) {}
              },
              child: const Text("Qo'shish"),
            ),
          ],
        );
      }),
    );
  }

  String _catLabel(String cat) {
    const map = {
      'parent': 'Ota-ona',
      'teacher': 'Pedagog',
      'psychology': 'Psixologiya',
      'development': 'Rivojlanish',
    };
    return map[cat] ?? cat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _recs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = _recs[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb,
                          color: Colors.amber, size: 32),
                      title: Text(r['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "${_catLabel(r['category'] as String)} • ${r['author'] ?? ''}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _delete(r['id'] as String, r['title'] as String),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

Future<bool> _confirmDelete(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("O'chirishni tasdiqlang"),
      content: Text("\"$title\" ni o'chirmoqchimisiz?"),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("O'chirish",
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result == true;
}
