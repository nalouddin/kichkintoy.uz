import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class NumbersGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const NumbersGame({super.key, this.childId, this.lessonId});

  @override
  State<NumbersGame> createState() => _NumbersGameState();
}

class _NumbersGameState extends State<NumbersGame> {
  final List<Map<String, dynamic>> _items = [
    {'number': 1, 'word': 'Bir', 'object': '🍎'},
    {'number': 2, 'word': 'Ikki', 'object': '🍎'},
    {'number': 3, 'word': 'Uch', 'object': '🍎'},
    {'number': 4, 'word': "To'rt", 'object': '🐟'},
    {'number': 5, 'word': 'Besh', 'object': '🌸'},
    {'number': 6, 'word': 'Olti', 'object': '⭐'},
    {'number': 7, 'word': 'Yetti', 'object': '🎈'},
    {'number': 8, 'word': 'Sakkiz', 'object': '🍇'},
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _answered = false;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();
  List<int> _options = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _generateOptions();
  }

  void _generateOptions() {
    final correct = _items[_currentIndex]['number'] as int;
    final rng = Random();
    final candidates = List.generate(10, (i) => i + 1)
        .where((n) => n != correct)
        .toList()
      ..shuffle(rng);
    _options = [correct, candidates[0], candidates[1]]..shuffle(rng);
  }

  void _onAnswer(int selected) {
    if (_answered) return;
    final correct = _items[_currentIndex]['number'] as int;
    final isCorrect = selected == correct;
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
        if (_currentIndex < _items.length - 1) {
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
    final earnedStars = (_correctAnswers / _items.length * 3).round();

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
            Text('🎉', style: TextStyle(fontSize: 64)),
            Text('Ajoyib!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sonlarni juda yaxshi sanading!',
                textAlign: TextAlign.center),
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
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
    final current = _items[_currentIndex];
    final count = current['number'] as int;
    final emoji = current['object'] as String;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.numberColor,
        title: Text('${_currentIndex + 1} / ${_items.length}'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.numberColor.withValues(alpha: 0.3),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _items.length,
                      backgroundColor: Colors.white,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.numberColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 24),
                    const Text('Nechta?',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.numberColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              count,
                              (i) => Text(emoji,
                                  style: const TextStyle(fontSize: 48)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _options
                          .map((num) => _NumberButton(
                                number: num,
                                onTap: () => _onAnswer(num),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
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
                AppTheme.numberColor,
                AppTheme.accentColor,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final VoidCallback onTap;
  const _NumberButton({required this.number, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.numberColor,
            ),
          ),
        ),
      ),
    );
  }
}
