import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  List<dynamic> _children = [];
  List<dynamic> _assignments = [];
  List<dynamic> _lessons = [];
  bool _isLoadingChildren = true;
  bool _isLoadingAssignments = true;
  bool _isLoadingLessons = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadChildren();
    _loadAssignments();
    _loadLessons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoadingChildren = true);
    try {
      final children =
          await _api.getGroupChildren(widget.group['id'] as String);
      if (!mounted) return;
      setState(() {
        _children = children;
        _isLoadingChildren = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoadingAssignments = true);
    try {
      final assignments =
          await _api.getGroupAssignments(widget.group['id'] as String);
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _isLoadingAssignments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAssignments = false);
    }
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await _api.getLessons();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _isLoadingLessons = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLessons = false);
    }
  }

  Future<void> _showCreateAssignmentDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    String? selectedLessonId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_task,
                        color: Color(0xFF6C5CE7), size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Topshiriq berish',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topshiriq nomi *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Majburiy maydon' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedLessonId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Dars tanlash *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: _lessons.map((l) {
                    final cat = l['category'] as String;
                    final emoji = _categoryEmoji(cat);
                    return DropdownMenuItem<String>(
                      value: l['id'] as String,
                      child: Text(
                        '$emoji ${l['title']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => selectedLessonId = v,
                  validator: (v) =>
                      v == null ? 'Dars tanlang' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: instructionsCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ko'rsatma (ixtiyoriy)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'TOPSHIRIQ BERISH',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx);
                      try {
                        await _api.createAssignment(
                          groupId: widget.group['id'] as String,
                          lessonId: selectedLessonId!,
                          title: titleCtrl.text.trim(),
                          instructions:
                              instructionsCtrl.text.trim().isEmpty
                                  ? null
                                  : instructionsCtrl.text.trim(),
                        );
                        _loadAssignments();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Topshiriq muvaffaqiyatli berildi!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Xatolik yuz berdi'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'letters':
        return '🔤';
      case 'numbers':
        return '🔢';
      case 'colors':
        return '🎨';
      case 'shapes':
        return '⭐';
      case 'memory':
        return '🧠';
      case 'puzzle':
        return '🧩';
      case 'story':
        return '📖';
      case 'drawing':
        return '✏️';
      default:
        return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.group['name'] ?? ''),
        backgroundColor: const Color(0xFF6C5CE7),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Bolalar (${_children.length})'),
            Tab(text: 'Topshiriqlar (${_assignments.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChildrenTab(),
          _buildAssignmentsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              backgroundColor: _isLoadingLessons
                  ? Colors.grey
                  : const Color(0xFF6C5CE7),
              onPressed: _isLoadingLessons ? null : _showCreateAssignmentDialog,
              icon: _isLoadingLessons
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task),
              label: Text(
                  _isLoadingLessons ? 'Yuklanmoqda...' : 'TOPSHIRIQ BERISH'),
            )
          : null,
    );
  }

  Widget _buildChildrenTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _GroupStat(
                  icon: Icons.child_care,
                  label: 'Bolalar',
                  value: '${_children.length}',
                ),
                const SizedBox(width: 24),
                _GroupStat(
                  icon: Icons.cake,
                  label: 'Yosh',
                  value: '${widget.group['age_group']}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Bolalar va natijalari",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildChildrenList()),
        ],
      ),
    );
  }

  Widget _buildChildrenList() {
    if (_isLoadingChildren) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_children.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 80, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text("Guruhda hali bola yo'q",
                style:
                    TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            SizedBox(height: 8),
            Text(
              "Ota-ona o'z bolasini guruhga qo'shishi kerak",
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _children[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                  child: Text(
                    (c['full_name'] as String).isNotEmpty
                        ? (c['full_name'] as String)[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['full_name'] ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${c['lessons_completed']} dars • o'rtacha ${c['avg_score']}",
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${c['total_stars']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 80, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              "Hali topshiriq berilmagan",
              style:
                  TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              "Pastdagi '+' tugmasi orqali topshiriq bering",
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = _assignments[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment,
                      color: Color(0xFF6C5CE7), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (a['instructions'] != null &&
                          (a['instructions'] as String).isNotEmpty)
                        Text(
                          a['instructions'] as String,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (a['due_date'] != null)
                        Text(
                          "Muddat: ${_formatDate(a['due_date'] as String)}",
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _GroupStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GroupStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C5CE7), size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }
}
