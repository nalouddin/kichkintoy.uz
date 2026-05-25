import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class PuzzleGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const PuzzleGame({super.key, this.childId, this.lessonId});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  final List<Map<String, dynamic>> _puzzles = [
    {
      'sequence': ['🔴', '🔵', '🔴', '🔵', '?'],
      'answer': '🔴',
      'options': ['🔴', '🔵', '🟢'],
    },
    {
      'sequence': ['⭐', '🌙', '⭐', '🌙', '?'],
      'answer': '⭐',
      'options': ['☀️', '⭐', '🌈'],
    },
    {
      'sequence': ['🍎', '🍌', '🍎', '🍌', '?'],
      'answer': '🍎',
      'options': ['🍇', '🍎', '🍊'],
    },
    {
      'sequence': ['🐱', '🐶', '🐱', '🐶', '?'],
      'answer': '🐱',
      'options': ['🐱', '🐰', '🐻'],
    },
    {
      'sequence': ['🔺', '⭕', '🔺', '⭕', '?'],
      'answer': '🔺',
      'options': ['🟦', '🔺', '⭐'],
    },
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _answered = false;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  void _onAnswer(String selected) {
    if (_answered) return;
    final correct = _puzzles[_currentIndex]['answer'] as String;
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
        if (_currentIndex < _puzzles.length - 1) {
          setState(() {
            _currentIndex++;
            _answered = false;
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
          isCorrect ? 'Aqlli bola! 🎉' : 'Yana o\'yla 🤔',
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
    final earnedStars = (_correctAnswers / _puzzles.length * 3).round();

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
            Text('🧩', style: TextStyle(fontSize: 64)),
            Text('Aqlli bola!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hamma jumboqlarni yechding!', textAlign: TextAlign.center),
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
    final puzzle = _puzzles[_currentIndex];
    final sequence = puzzle['sequence'] as List<String>;
    final options = puzzle['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('${_currentIndex + 1} / ${_puzzles.length}'),
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
                      value: (_currentIndex + 1) / _puzzles.length,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(Colors.teal),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Keyin nima keladi?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: sequence.map((item) {
                          final isQuestion = item == '?';
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isQuestion
                                  ? Colors.teal.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isQuestion
                                  ? Border.all(color: Colors.teal, width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isQuestion ? '?' : item,
                              style: TextStyle(
                                fontSize: isQuestion ? 32 : 40,
                                fontWeight: isQuestion
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isQuestion ? Colors.teal : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Spacer(),
                    const Text('Tanlang:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: options
                          .map((opt) => _PuzzleOption(
                                emoji: opt,
                                onTap: () => _onAnswer(opt),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
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
                Colors.teal,
                AppTheme.accentColor,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleOption extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  const _PuzzleOption({required this.emoji, required this.onTap});

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
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
        ),
      ),
    );
  }
}
