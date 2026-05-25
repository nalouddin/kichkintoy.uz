import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class OddOneOutGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const OddOneOutGame({super.key, this.childId, this.lessonId});

  @override
  State<OddOneOutGame> createState() => _OddOneOutGameState();
}

class _OddOneOutGameState extends State<OddOneOutGame> {
  static const _gameColor = Color(0xFFE84393);

  final List<Map<String, dynamic>> _questions = [
    {
      'items': ['🐶', '🐱', '🚗', '🐰'],
      'odd': 2,
      'hint': 'Mashina hayvon emas',
    },
    {
      'items': ['🍎', '🍊', '🍋', '✈️'],
      'odd': 3,
      'hint': 'Samolyot meva emas',
    },
    {
      'items': ['🚗', '🚌', '🚲', '🌸'],
      'odd': 3,
      'hint': 'Gul transport emas',
    },
    {
      'items': ['🌳', '🌸', '🌻', '🐟'],
      'odd': 3,
      'hint': 'Baliq o\'simlik emas',
    },
    {
      'items': ['📚', '✏️', '🖊️', '🍎'],
      'odd': 3,
      'hint': 'Olma maktab jihozi emas',
    },
    {
      'items': ['🔴', '🔵', '🟡', '🐶'],
      'odd': 3,
      'hint': 'It rang emas',
    },
    {
      'items': ['1️⃣', '2️⃣', '🍋', '3️⃣'],
      'odd': 2,
      'hint': 'Limon son emas',
    },
    {
      'items': ['🎵', '🎸', '🥁', '🌙'],
      'odd': 3,
      'hint': 'Oy musiqa asbobi emas',
    },
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int? _selectedIndex;
  bool _answered = false;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  void _onTap(int index) {
    if (_answered) return;
    final isCorrect = index == _questions[_currentIndex]['odd'];

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (isCorrect) {
        _score += 10;
        _correctAnswers++;
      }
    });

    if (isCorrect) _confettiController.play();

    _showFeedback(isCorrect);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedIndex = null;
          _answered = false;
        });
      } else {
        _showComplete();
      }
    });
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCorrect
                    ? 'To\'g\'ri! 🎉'
                    : _questions[_currentIndex]['hint'] as String,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor:
            isCorrect ? AppTheme.successColor : AppTheme.secondaryColor,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _showComplete() async {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final stars = (_correctAnswers / _questions.length * 3).round();

    if (widget.childId != null && widget.lessonId != null) {
      try {
        await ApiClient().submitProgress(
          childId: widget.childId!,
          lessonId: widget.lessonId!,
          score: _score,
          timeSpentSeconds: timeSpent,
          stars: stars,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(children: [
          Text('🔍', style: TextStyle(fontSize: 64)),
          SizedBox(height: 8),
          Text('Aqlli ekansan!', textAlign: TextAlign.center),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_correctAnswers / ${_questions.length} to\'g\'ri javob',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Ball: $_score',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
    final q = _questions[_currentIndex];
    final items = q['items'] as List<String>;
    final oddIndex = q['odd'] as int;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _gameColor,
        title: Text('${_currentIndex + 1} / ${_questions.length}'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _gameColor.withValues(alpha: 0.2),
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
                      value: (_currentIndex + 1) / _questions.length,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(_gameColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Ortiqchasini top! 🔍',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Qaysi biri boshqalarga o\'xshamaydi?',
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(items.length, (i) {
                          Color borderColor = Colors.transparent;
                          Color bgColor = Colors.white;
                          if (_answered && _selectedIndex == i) {
                            if (i == oddIndex) {
                              borderColor = AppTheme.successColor;
                              bgColor = AppTheme.successColor
                                  .withValues(alpha: 0.15);
                            } else {
                              borderColor = AppTheme.secondaryColor;
                              bgColor = AppTheme.secondaryColor
                                  .withValues(alpha: 0.15);
                            }
                          } else if (_answered && i == oddIndex) {
                            borderColor = AppTheme.successColor;
                            bgColor = AppTheme.successColor
                                .withValues(alpha: 0.10);
                          }

                          return GestureDetector(
                            onTap: () => _onTap(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: borderColor, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  items[i],
                                  style: const TextStyle(fontSize: 72),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            'Ball: $_score',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
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
