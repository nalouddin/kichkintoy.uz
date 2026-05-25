import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class LettersGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const LettersGame({super.key, this.childId, this.lessonId});

  @override
  State<LettersGame> createState() => _LettersGameState();
}

class _LettersGameState extends State<LettersGame> {
  final List<Map<String, String>> _letters = [
    {'letter': 'A', 'word': 'Anor', 'emoji': '🍎'},
    {'letter': 'B', 'word': 'Baliq', 'emoji': '🐟'},
    {'letter': 'D', 'word': 'Daraxt', 'emoji': '🌳'},
    {'letter': 'G', 'word': 'Gul', 'emoji': '🌸'},
    {'letter': 'I', 'word': 'It', 'emoji': '🐕'},
    {'letter': 'K', 'word': 'Kitob', 'emoji': '📚'},
    {'letter': 'L', 'word': 'Limon', 'emoji': '🍋'},
    {'letter': 'M', 'word': 'Mushuk', 'emoji': '🐱'},
    {'letter': 'O', 'word': 'Olma', 'emoji': '🍏'},
    {'letter': 'Q', 'word': 'Quyon', 'emoji': '🐰'},
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _answered = false;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();
  List<Map<String, String>> _options = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _generateOptions();
  }

  void _generateOptions() {
    final correct = _letters[_currentIndex];
    final wrongOptions = _letters
        .where((l) => l['letter'] != correct['letter'])
        .toList()
      ..shuffle();
    _options = [correct, wrongOptions[0], wrongOptions[1]]..shuffle();
  }

  void _onAnswerTap(Map<String, String> selected) {
    if (_answered) return;
    final isCorrect = selected['letter'] == _letters[_currentIndex]['letter'];
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
        if (_currentIndex < _letters.length - 1) {
          setState(() {
            _currentIndex++;
            _answered = false;
            _generateOptions();
          });
        } else {
          _showGameComplete();
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
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Text(
              isCorrect ? 'Ofarin! 🎉' : "Yana urinib ko'r 💪",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor:
            isCorrect ? AppTheme.successColor : AppTheme.secondaryColor,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _showGameComplete() async {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final earnedStars = (_correctAnswers / _letters.length * 3).round();

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
            SizedBox(height: 8),
            Text('Ajoyib!', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sen barcha harflarni topding!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(
                i < earnedStars ? Icons.star : Icons.star_border,
                size: 48,
                color: Colors.amber,
              )),
            ),
            const SizedBox(height: 12),
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
    final current = _letters[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.letterColor,
        title: Text('${_currentIndex + 1} / ${_letters.length}'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.letterColor.withOpacity(0.3),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _letters.length,
                      backgroundColor: Colors.white,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.letterColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 32),
                    const Text('Bu qaysi harf?',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.letterColor.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(current['emoji']!,
                                  style: const TextStyle(fontSize: 80)),
                              const SizedBox(height: 8),
                              Text(current['word']!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.letterColor,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _options
                          .map((opt) => _AnswerButton(
                                letter: opt['letter']!,
                                onTap: () => _onAnswerTap(opt),
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
                AppTheme.secondaryColor,
                AppTheme.accentColor,
                AppTheme.successColor,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;
  const _AnswerButton({required this.letter, required this.onTap});

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
          child: Text(letter,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.letterColor,
              )),
        ),
      ),
    );
  }
}
