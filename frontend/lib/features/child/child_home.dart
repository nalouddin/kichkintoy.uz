import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../auth/welcome_screen.dart';
import 'games/letters/letters_game.dart';
import 'games/numbers/numbers_game.dart';
import 'games/colors/colors_game.dart';
import 'games/shapes/shapes_game.dart';
import 'games/memory/memory_game.dart';
import 'games/puzzle/puzzle_game.dart';
import 'games/drawing/drawing_game.dart';
import 'games/odd_one_out/odd_one_out_game.dart';
import 'games/sequence/sequence_game.dart';
import 'stories/stories_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ChildHomeScreen({super.key, required this.user});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final _api = ApiClient();
  String? _childId;
  int _totalStars = 0;
  Map<String, String?> _lessonIds = {};
  Map<String, String> _lessonCategories = {};
  List<dynamic> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        _api.getMyChildProfile(),
        _api.getLessons(),
        _api.getMyAssignments(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final lessons = results[1] as List<dynamic>;
      final assignments = results[2] as List<dynamic>;

      final Map<String, String?> ids = {
        'letters': null,
        'numbers': null,
        'colors': null,
        'shapes': null,
        'memory': null,
        'puzzle': null,
        'drawing': null,
        'odd_one_out': null,
        'sequence': null,
      };
      final Map<String, String> lessonCategories = {};

      for (final l in lessons) {
        final cat = (l['category'] as String).toLowerCase();
        lessonCategories[l['id'] as String] = cat;
        if (ids.containsKey(cat) && ids[cat] == null) {
          ids[cat] = l['id'] as String;
        }
      }

      if (!mounted) return;
      setState(() {
        _childId = profile['id'] as String;
        _totalStars = (profile['total_stars'] as num?)?.toInt() ?? 0;
        _lessonIds = ids;
        _lessonCategories = lessonCategories;
        _assignments = assignments;
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

  void _openGame(Widget game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => game),
    ).then((_) => _loadProfile());
  }

  void _openAssignmentGame(Map<String, dynamic> assignment) {
    final lessonId = assignment['lesson_id'] as String;
    final category = _lessonCategories[lessonId];
    Widget? game;
    switch (category) {
      case 'letters':
        game = LettersGame(childId: _childId, lessonId: lessonId);
      case 'numbers':
        game = NumbersGame(childId: _childId, lessonId: lessonId);
      case 'colors':
        game = ColorsGame(childId: _childId, lessonId: lessonId);
      case 'shapes':
        game = ShapesGame(childId: _childId, lessonId: lessonId);
      case 'memory':
        game = MemoryGame(childId: _childId, lessonId: lessonId);
      case 'puzzle':
        game = PuzzleGame(childId: _childId, lessonId: lessonId);
      case 'drawing':
        game = DrawingGame(childId: _childId, lessonId: lessonId);
      case 'odd_one_out':
        game = OddOneOutGame(childId: _childId, lessonId: lessonId);
      case 'sequence':
        game = SequenceGame(childId: _childId, lessonId: lessonId);
      default:
        return;
    }
    _openGame(game);
  }

  String _categoryEmoji(String? category) {
    switch (category) {
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
      case 'drawing':
        return '✍️';
      case 'odd_one_out':
        return '🔍';
      case 'sequence':
        return '🔗';
      default:
        return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.primaryColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              (widget.user['full_name'] as String).isNotEmpty
                  ? (widget.user['full_name'] as String)[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Salom,',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                Text(
                  widget.user['full_name'] ?? 'Bola',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(
                  '$_totalStars',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Chiqish',
            onPressed: _logout,
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final games = [
      _GameDef(
        title: 'Harflar',
        emoji: '🔤',
        color: AppTheme.letterColor,
        game: () => LettersGame(
          childId: _childId,
          lessonId: _lessonIds['letters'],
        ),
      ),
      _GameDef(
        title: 'Sonlar',
        emoji: '🔢',
        color: AppTheme.numberColor,
        game: () => NumbersGame(
          childId: _childId,
          lessonId: _lessonIds['numbers'],
        ),
      ),
      _GameDef(
        title: 'Ranglar',
        emoji: '🎨',
        color: AppTheme.colorGameColor,
        game: () => ColorsGame(
          childId: _childId,
          lessonId: _lessonIds['colors'],
        ),
      ),
      _GameDef(
        title: 'Shakllar',
        emoji: '⭐',
        color: AppTheme.shapeColor,
        game: () => ShapesGame(
          childId: _childId,
          lessonId: _lessonIds['shapes'],
        ),
      ),
      _GameDef(
        title: 'Xotira',
        emoji: '🧠',
        color: const Color(0xFF6C5CE7),
        game: () => MemoryGame(
          childId: _childId,
          lessonId: _lessonIds['memory'],
        ),
      ),
      _GameDef(
        title: 'Jumboq',
        emoji: '🧩',
        color: Colors.teal,
        game: () => PuzzleGame(
          childId: _childId,
          lessonId: _lessonIds['puzzle'],
        ),
      ),
      _GameDef(
        title: 'Chizish',
        emoji: '✍️',
        color: AppTheme.letterColor,
        game: () => DrawingGame(
          childId: _childId,
          lessonId: _lessonIds['drawing'],
        ),
      ),
      _GameDef(
        title: 'Ortiqchasi',
        emoji: '🔍',
        color: const Color(0xFFE84393),
        game: () => OddOneOutGame(
          childId: _childId,
          lessonId: _lessonIds['odd_one_out'],
        ),
      ),
      _GameDef(
        title: 'Ketma-ket',
        emoji: '🔗',
        color: const Color(0xFF00B894),
        game: () => SequenceGame(
          childId: _childId,
          lessonId: _lessonIds['sequence'],
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossCount = w > 900 ? 5 : w > 600 ? 3 : 2;
        final hPad = w > 600 ? 40.0 : 20.0;
        return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_assignments.isNotEmpty) ...[
            _AssignmentsBanner(
              assignments: _assignments,
              lessonCategories: _lessonCategories,
              categoryEmoji: _categoryEmoji,
              onTap: _openAssignmentGame,
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            "Keling, o'ynaymiz! 🎮",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: games
                .map((def) => _GameCard(
                      title: def.title,
                      emoji: def.emoji,
                      color: def.color,
                      onTap: () => _openGame(def.game()),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          // Ertaklar va she'rlar
          Material(
            color: const Color(0xFFE17055),
            borderRadius: BorderRadius.circular(20),
            elevation: 4,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoriesScreen()),
              ),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('📖', style: TextStyle(fontSize: 40)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ertaklar va she\'rlar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'O\'qi, tingla, zavqlан',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
          ),
        ),
      ),
        );
      },
    );
  }
}

class _GameDef {
  final String title;
  final String emoji;
  final Color color;
  final Widget Function() game;

  const _GameDef({
    required this.title,
    required this.emoji,
    required this.color,
    required this.game,
  });
}

class _AssignmentsBanner extends StatelessWidget {
  final List<dynamic> assignments;
  final Map<String, String> lessonCategories;
  final String Function(String?) categoryEmoji;
  final void Function(Map<String, dynamic>) onTap;

  const _AssignmentsBanner({
    required this.assignments,
    required this.lessonCategories,
    required this.categoryEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Topshiriqlarim (${assignments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF856404),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...assignments.map((a) {
            final lessonId = a['lesson_id'] as String;
            final category = lessonCategories[lessonId];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 2,
                child: InkWell(
                  onTap: () => onTap(a as Map<String, dynamic>),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          categoryEmoji(category),
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['title'] ?? '',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (a['instructions'] != null &&
                                  (a['instructions'] as String).isNotEmpty)
                                Text(
                                  a['instructions'] as String,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => onTap(a as Map<String, dynamic>),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            minimumSize: const Size(76, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "O'ynash",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
