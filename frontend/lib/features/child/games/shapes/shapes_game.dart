import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class ShapesGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const ShapesGame({super.key, this.childId, this.lessonId});

  @override
  State<ShapesGame> createState() => _ShapesGameState();
}

class _ShapesGameState extends State<ShapesGame> {
  final List<Map<String, dynamic>> _shapes = [
    {'name': 'Doira', 'shape': 'circle'},
    {'name': 'Kvadrat', 'shape': 'square'},
    {'name': 'Uchburchak', 'shape': 'triangle'},
    {'name': "To'rtburchak", 'shape': 'rectangle'},
    {'name': 'Yulduz', 'shape': 'star'},
    {'name': 'Yurak', 'shape': 'heart'},
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
    final correct = _shapes[_currentIndex];
    final wrongs = _shapes.where((s) => s['name'] != correct['name']).toList()
      ..shuffle();
    _options = [correct, wrongs[0], wrongs[1]]..shuffle();
  }

  void _onAnswer(Map<String, dynamic> selected) {
    if (_answered) return;
    final isCorrect = selected['name'] == _shapes[_currentIndex]['name'];
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
        if (_currentIndex < _shapes.length - 1) {
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
    final earnedStars = (_correctAnswers / _shapes.length * 3).round();

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
            Text('⭐', style: TextStyle(fontSize: 64)),
            Text('Shakl ustasi!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Barcha shakllarni topding!', textAlign: TextAlign.center),
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
    final current = _shapes[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.shapeColor,
        title: Text('${_currentIndex + 1} / ${_shapes.length}'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.shapeColor.withValues(alpha: 0.2),
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
                      value: (_currentIndex + 1) / _shapes.length,
                      backgroundColor: Colors.white,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.shapeColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Qaysi biri "${current['name']}"?',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: _options
                            .map((opt) => _ShapeOption(
                                  shape: opt['shape'] as String,
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
                AppTheme.shapeColor,
                AppTheme.accentColor,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeOption extends StatelessWidget {
  final String shape;
  final VoidCallback onTap;
  const _ShapeOption({required this.shape, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: CustomPaint(
            size: const Size(80, 80),
            painter: _ShapePainter(shape: shape, color: AppTheme.shapeColor),
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final String shape;
  final Color color;
  _ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    switch (shape) {
      case 'circle':
        canvas.drawCircle(center, w / 2 - 4, paint);
      case 'square':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w - 8, height: h - 8),
            const Radius.circular(8),
          ),
          paint,
        );
      case 'rectangle':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: w - 8, height: h / 1.5),
            const Radius.circular(8),
          ),
          paint,
        );
      case 'triangle':
        final path = Path()
          ..moveTo(w / 2, 4)
          ..lineTo(w - 4, h - 4)
          ..lineTo(4, h - 4)
          ..close();
        canvas.drawPath(path, paint);
      case 'star':
        _drawStar(canvas, paint, center, w / 2 - 4);
      case 'heart':
        _drawHeart(canvas, paint, center, w / 2 - 4);
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius : radius / 2.3;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.4);
    path.cubicTo(
      center.dx - size * 1.2, center.dy - size * 0.2,
      center.dx - size * 0.6, center.dy - size,
      center.dx, center.dy - size * 0.3,
    );
    path.cubicTo(
      center.dx + size * 0.6, center.dy - size,
      center.dx + size * 1.2, center.dy - size * 0.2,
      center.dx, center.dy + size * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
