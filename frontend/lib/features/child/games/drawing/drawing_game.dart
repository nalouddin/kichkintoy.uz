import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class DrawingGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const DrawingGame({super.key, this.childId, this.lessonId});

  @override
  State<DrawingGame> createState() => _DrawingGameState();
}

class _DrawingGameState extends State<DrawingGame> {
  final List<Map<String, String>> _letters = [
    {'letter': 'A', 'emoji': '🍎', 'word': 'Anor'},
    {'letter': 'B', 'emoji': '🐟', 'word': 'Baliq'},
    {'letter': 'D', 'emoji': '🌳', 'word': 'Daraxt'},
    {'letter': 'G', 'emoji': '🌸', 'word': 'Gul'},
    {'letter': 'K', 'emoji': '📚', 'word': 'Kitob'},
    {'letter': 'M', 'emoji': '🐱', 'word': 'Mushuk'},
    {'letter': 'O', 'emoji': '🍏', 'word': 'Olma'},
    {'letter': 'S', 'emoji': '🌙', 'word': 'Oy'},
  ];

  int _currentIndex = 0;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  void _onPanStart(DragStartDetails d) {
    setState(() => _currentStroke = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_currentStroke));
        _currentStroke = [];
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  void _next() {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Avval harfni chiz!",
              style: TextStyle(fontSize: 18)),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
      return;
    }
    _confettiController.play();
    setState(() => _completedCount++);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_currentIndex < _letters.length - 1) {
        setState(() {
          _currentIndex++;
          _strokes.clear();
          _currentStroke = [];
        });
      } else {
        _showComplete();
      }
    });
  }

  Future<void> _showComplete() async {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    if (widget.childId != null && widget.lessonId != null) {
      try {
        await ApiClient().submitProgress(
          childId: widget.childId!,
          lessonId: widget.lessonId!,
          score: _completedCount * 10,
          timeSpentSeconds: timeSpent,
          stars: 3,
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
          Text('✍️', style: TextStyle(fontSize: 64)),
          SizedBox(height: 8),
          Text('Ajoyib yozding!', textAlign: TextAlign.center),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Barcha harflarni chizding!',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (_) => const Icon(Icons.star, size: 48, color: Colors.amber),
              ),
            ),
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
                  AppTheme.letterColor.withValues(alpha: 0.2),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${current['emoji']} ${current['word']} — '
                      '${current['letter']} harfini chiz',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Barmoqingiz bilan katta harfni trat qiling',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.letterColor.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              painter: _DrawingPainter(
                                strokes: _strokes,
                                currentStroke: _currentStroke,
                                guideLetter: current['letter']!,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clear,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tozala'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              side: const BorderSide(
                                  color: AppTheme.letterColor, width: 2),
                              foregroundColor: AppTheme.letterColor,
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _next,
                            icon: const Icon(Icons.check),
                            label: const Text('Keyingi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.letterColor,
                              minimumSize: const Size(0, 56),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
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

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final String guideLetter;

  const _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.guideLetter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guide letter in background
    final textPainter = TextPainter(
      text: TextSpan(
        text: guideLetter,
        style: TextStyle(
          fontSize: size.height * 0.65,
          fontWeight: FontWeight.bold,
          color: AppTheme.letterColor.withValues(alpha: 0.10),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    final paint = Paint()
      ..color = AppTheme.letterColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    _drawStroke(canvas, currentStroke, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.length < 2) return;
    final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
    for (int i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
