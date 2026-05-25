import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class SequenceGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const SequenceGame({super.key, this.childId, this.lessonId});

  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  static const _gameColor = Color(0xFF00B894);

  // sequence: ko'rsatiladi, answer: to'g'ri javob, options: tanlovlar
  final List<Map<String, dynamic>> _questions = [
    {
      'sequence': ['1️⃣', '2️⃣', '3️⃣', '?'],
      'answer': '4️⃣',
      'options': ['4️⃣', '5️⃣', '6️⃣'],
      'hint': '1, 2, 3 dan keyin 4 keladi',
    },
    {
      'sequence': ['🍎', '🍊', '🍎', '?'],
      'answer': '🍊',
      'options': ['🍋', '🍊', '🍎'],
      'hint': 'Naqsh: Olma, Apelsin takrorlanadi',
    },
    {
      'sequence': ['🔴', '🔵', '🔴', '?'],
      'answer': '🔵',
      'options': ['🟡', '🔴', '🔵'],
      'hint': 'Qizil, Ko\'k, Qizil — keyin Ko\'k',
    },
    {
      'sequence': ['2️⃣', '4️⃣', '6️⃣', '?'],
      'answer': '8️⃣',
      'options': ['7️⃣', '8️⃣', '9️⃣'],
      'hint': 'Juft sonlar: 2, 4, 6, 8...',
    },
    {
      'sequence': ['🐶', '🐱', '🐶', '?'],
      'answer': '🐱',
      'options': ['🐰', '🐶', '🐱'],
      'hint': 'It, Mushuk, It — keyin Mushuk',
    },
    {
      'sequence': ['⭐', '⭐⭐', '⭐⭐⭐', '?'],
      'answer': '⭐⭐⭐⭐',
      'options': ['⭐⭐', '⭐⭐⭐⭐', '⭐⭐⭐⭐⭐'],
      'hint': 'Har safar bitta yulduz ko\'payadi',
    },
    {
      'sequence': ['🌑', '🌒', '🌓', '?'],
      'answer': '🌔',
      'options': ['🌕', '🌔', '🌑'],
      'hint': 'Oy to\'lib boradi',
    },
    {
      'sequence': ['🔺', '🔺🔺', '🔺🔺🔺', '?'],
      'answer': '🔺🔺🔺🔺',
      'options': ['🔺🔺🔺', '🔺🔺🔺🔺', '🔺🔺🔺🔺🔺'],
      'hint': 'Har safar bitta uchburchak ko\'payadi',
    },
  ];

  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  String? _selectedAnswer;
  bool _answered = false;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  void _onOptionTap(String option) {
    if (_answered) return;
    final q = _questions[_currentIndex];
    final isCorrect = option == q['answer'];

    setState(() {
      _selectedAnswer = option;
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
          _selectedAnswer = null;
          _answered = false;
        });
      } else {
        _showComplete();
      }
    });
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final q = _questions[_currentIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCorrect ? 'Zo\'r! 🎉' : q['hint'] as String,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
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
          Text('🧩', style: TextStyle(fontSize: 64)),
          SizedBox(height: 8),
          Text('Ketma-ketlik ustasi!', textAlign: TextAlign.center),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_correctAnswers / ${_questions.length} to\'g\'ri',
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
    final sequence = q['sequence'] as List<String>;
    final options = q['options'] as List<String>;
    final correctAnswer = q['answer'] as String;

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
                      'Davom ettir! 🔗',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Qaysi rasm keyingi bo\'ladi?',
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    // Ketma-ketlik ko'rgazmasi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: sequence.map((item) {
                          final isBlank = item == '?';
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isBlank
                                  ? _gameColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isBlank
                                  ? Border.all(
                                      color: _gameColor, width: 2.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                isBlank ? '?' : item,
                                style: TextStyle(
                                  fontSize: isBlank ? 32 : 36,
                                  fontWeight: isBlank
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isBlank ? _gameColor : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Javobni tanla:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: options.map((opt) {
                        Color borderColor = Colors.transparent;
                        Color bgColor = Colors.white;
                        double elevation = 4;

                        if (_answered) {
                          if (opt == correctAnswer) {
                            borderColor = AppTheme.successColor;
                            bgColor =
                                AppTheme.successColor.withValues(alpha: 0.15);
                          } else if (opt == _selectedAnswer) {
                            borderColor = AppTheme.secondaryColor;
                            bgColor = AppTheme.secondaryColor
                                .withValues(alpha: 0.15);
                          }
                          elevation = 1;
                        }

                        return GestureDetector(
                          onTap: () => _onOptionTap(opt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: borderColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.08),
                                  blurRadius: elevation * 3,
                                  offset: Offset(0, elevation),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                opt,
                                style: const TextStyle(fontSize: 36),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
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
                          const Icon(Icons.star,
                              color: Colors.amber, size: 24),
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
                _gameColor,
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
