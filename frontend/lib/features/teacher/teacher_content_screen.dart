import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

/// Pedagog uchun kontent boshqaruvi: ertaklar va tavsiyalar.
class TeacherContentScreen extends StatefulWidget {
  const TeacherContentScreen({super.key});

  @override
  State<TeacherContentScreen> createState() => _TeacherContentScreenState();
}

class _TeacherContentScreenState extends State<TeacherContentScreen>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontent boshqaruvi'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories), text: 'Ertaklar'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Tavsiyalar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StoriesPanel(),
          _RecommendationsPanel(),
        ],
      ),
    );
  }
}

// ============================================================
// ERTAKLAR PANELI
// ============================================================

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
    final ok = await _confirm(context, title);
    if (!ok) return;
    try {
      await _api.deleteStory(id);
      if (mounted) setState(() => _stories.removeWhere((s) => s['id'] == id));
    } catch (_) {}
  }

  Future<void> _showStoryDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl = TextEditingController(text: existing?['content'] ?? '');
    final authorCtrl = TextEditingController(text: existing?['author'] ?? '');
    String category = existing?['category'] ?? 'story';
    int ageGroup = existing?['age_group'] ?? 4;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(isEdit ? "Ertakni tahrirlash" : "Yangi ertak / she'r / qo'shiq"),
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
                  decoration: const InputDecoration(labelText: 'Tur'),
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
                    (i) => DropdownMenuItem(value: i + 3, child: Text('${i + 3} yosh')),
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
                  maxLines: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (isEdit) {
                    await _api.updateStory(
                      existing['id'] as String,
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      category: category,
                      ageGroup: ageGroup,
                      author: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                    );
                  } else {
                    await _api.createStory(
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      category: category,
                      ageGroup: ageGroup,
                      author: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                    );
                  }
                  _load();
                } catch (_) {}
              },
              child: Text(isEdit ? "Saqlash" : "Qo'shish"),
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
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        onPressed: () => _showStoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _stories.isEmpty
                  ? const Center(child: Text("Hozircha ertaklar yo'q"))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _stories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = _stories[i];
                        final emoji = s['category'] == 'story'
                            ? '📖'
                            : s['category'] == 'poem'
                                ? '📝'
                                : '🎵';
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Text(emoji,
                                style: const TextStyle(fontSize: 28)),
                            title: Text(s['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "${s['age_group']} yosh • ${s['author'] ?? ''}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Color(0xFF6C5CE7)),
                                  onPressed: () => _showStoryDialog(existing: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _delete(s['id'] as String, s['title'] as String),
                                ),
                              ],
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
// TAVSIYALAR PANELI
// ============================================================

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
    final ok = await _confirm(context, title);
    if (!ok) return;
    try {
      await _api.deleteRecommendation(id);
      if (mounted) setState(() => _recs.removeWhere((r) => r['id'] == id));
    } catch (_) {}
  }

  Future<void> _showRecDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final contentCtrl = TextEditingController(text: existing?['content'] ?? '');
    final authorCtrl = TextEditingController(text: existing?['author'] ?? '');
    String category = existing?['category'] ?? 'parent';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(isEdit ? 'Tavsiyani tahrirlash' : 'Yangi psixologik tavsiya'),
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
                    DropdownMenuItem(value: 'parent', child: Text('Ota-ona uchun')),
                    DropdownMenuItem(value: 'teacher', child: Text('Pedagog uchun')),
                    DropdownMenuItem(value: 'psychology', child: Text('Psixologiya')),
                    DropdownMenuItem(value: 'development', child: Text('Rivojlanish')),
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
                  maxLines: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (isEdit) {
                    await _api.updateRecommendation(
                      existing['id'] as String,
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      category: category,
                      author: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                    );
                  } else {
                    await _api.createRecommendation(
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      category: category,
                      author: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                    );
                  }
                  _load();
                } catch (_) {}
              },
              child: Text(isEdit ? 'Saqlash' : "Qo'shish"),
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
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        onPressed: () => _showRecDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _recs.isEmpty
                  ? const Center(child: Text("Hozircha tavsiyalar yo'q"))
                  : ListView.separated(
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
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "${_catLabel(r['category'] as String)} • ${r['author'] ?? ''}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Color(0xFF6C5CE7)),
                                  onPressed: () => _showRecDialog(existing: r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _delete(r['id'] as String, r['title'] as String),
                                ),
                              ],
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
// HELPER
// ============================================================

Future<bool> _confirm(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("O'chirishni tasdiqlang"),
      content: Text('"$title" ni o\'chirmoqchimisiz?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("O'chirish", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result == true;
}
