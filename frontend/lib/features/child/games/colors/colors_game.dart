import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class ColorsGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const ColorsGame({super.key, this.childId, this.lessonId});

  @override
  State<ColorsGame> createState() => _ColorsGameState();
}

class _ColorsGameState extends State<ColorsGame> {
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Qizil', 'color': const Color(0xFFFF6B6B), 'emoji': '🍎'},
    {'name': "Ko'k", 'color': const Color(0xFF4ECDC4), 'emoji': '🌊'},
    {'name': 'Sariq', 'color': const Color(0xFFFFE66D), 'emoji': '☀️'},
    {'name': 'Yashil', 'color': const Color(0xFF95E1A3), 'emoji': '🌳'},
    {'name': "To'q sariq", 'color': const Color(0xFFFFA502), 'emoji': '🥕'},
    {'name': 'Binafsha', 'color': const Color(0xFFA29BFE), 'emoji': '🍇'},
    {'name': 'Pushti', 'color': const Color(0xFFFF6B9D), 'emoji': '🌸'},
    {'name': 'Qora', 'color': const Color(0xFF2D3436), 'emoji': '🐱'},
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _answered = false;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();
  List<Map<String, dynamic>> _options = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _generateOptions();
  }

  void _generateOptions() {
    final correct = _colors[_currentIndex];
    final wrongs = _colors.where((c) => c['name'] != correct['name']).toList()
      ..shuffle();
    _options = [correct, wrongs[0], wrongs[1]]..shuffle();
  }

  void _onAnswer(Map<String, dynamic> selected) {
    if (_answered) return;
    final isCorrect = selected['name'] == _colors[_currentIndex]['name'];
    if (isCorrect) {
      setState(() {
        _answered = true;
        _score += 10;
        _correctAnswers++;
      });
      _confettiController.play();
      _showFeedback(true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (_currentIndex < _colors.length - 1) {
          setState(() {
            _currentIndex++;
            _answered = false;
            _generateOptions();
          });
        } else {
          _showComplete();
        }
      });
    } else {
      _showFeedback(false);
    }
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? 'Ofarin! 🎉' : "Yana urinib ko'r 💪",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor:
            isCorrect ? AppTheme.successColor : AppTheme.secondaryColor,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _showComplete() async {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final earnedStars = (_correctAnswers / _colors.length * 3).round();

    if (widget.childId != null && widget.lessonId != null) {
      try {
        await ApiClient().submitProgress(
          childId: widget.childId!,
          lessonId: widget.lessonId!,
          score: _score,
          timeSpentSeconds: timeSpent,
          stars: earnedStars,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Text('🎨', style: TextStyle(fontSize: 64)),
            Text('Rang ustasi!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Barcha ranglarni topding!', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < earnedStars ? Icons.star : Icons.star_border,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Ball: $_score',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Vaqt: ${timeSpent}s'),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('CHIQISH'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _colors[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.colorGameColor,
        title: Text('${_currentIndex + 1} / ${_colors.length}'),
      ),
      body: Stack(
        children: [
          Container(
            color: AppTheme.backgroundColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _colors.length,
                      backgroundColor: Colors.white,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.colorGameColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Qaysi biri "${current['name']}" rang?',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(current['emoji'] as String,
                        style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 1,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3,
                        children: _options
                            .map((opt) => _ColorOption(
                                  color: opt['color'] as Color,
                                  onTap: () => _onAnswer(opt),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [
                AppTheme.primaryColor,
                AppTheme.colorGameColor,
                AppTheme.accentColor,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _ColorOption({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Text(
            'Bu rang',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
