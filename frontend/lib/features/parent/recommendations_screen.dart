import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late TabController _tabController;

  List<dynamic> _parentTips = [];
  List<dynamic> _teacherTips = [];
  List<dynamic> _psychology = [];
  List<dynamic> _development = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getRecommendations(category: 'parent'),
        _api.getRecommendations(category: 'teacher'),
        _api.getRecommendations(category: 'psychology'),
        _api.getRecommendations(category: 'development'),
      ]);
      if (!mounted) return;
      setState(() {
        _parentTips = results[0];
        _teacherTips = results[1];
        _psychology = results[2];
        _development = results[3];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tavsiyalar va maslahatlar'),
        backgroundColor: const Color(0xFF00B894),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: '👨‍👩‍👧 Ota-ona'),
            Tab(text: '👩‍🏫 Pedagog'),
            Tab(text: '🧠 Psixolog'),
            Tab(text: '📈 Rivojlanish'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_parentTips, const Color(0xFF00B894)),
                _buildList(_teacherTips, const Color(0xFF6C5CE7)),
                _buildList(_psychology, const Color(0xFFE17055)),
                _buildList(_development, const Color(0xFF0984E3)),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> items, Color color) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💡', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Hali tavsiya yo\'q',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _RecommendationCard(rec: items[i], accentColor: color),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final Map<String, dynamic> rec;
  final Color accentColor;

  const _RecommendationCard({required this.rec, required this.accentColor});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.rec['content'] as String;
    final preview = content.length > 120 ? '${content.substring(0, 120)}...' : content;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.rec['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _expanded ? content : preview,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF2D3436),
                ),
              ),
              if (widget.rec['author'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.verified,
                        size: 14, color: widget.accentColor),
                    const SizedBox(width: 4),
                    Text(
                      widget.rec['author'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
