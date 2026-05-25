import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme.dart';
import '../../../../core/api_client.dart';

class MemoryGame extends StatefulWidget {
  final String? childId;
  final String? lessonId;
  const MemoryGame({super.key, this.childId, this.lessonId});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final List<String> _pairs = ['🐶', '🐱', '🐰', '🐼', '🦁', '🐸'];

  late List<_Card> _cards;
  int? _firstSelected;
  bool _isProcessing = false;
  int _matchedPairs = 0;
  int _moves = 0;
  late ConfettiController _confettiController;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initCards();
  }

  void _initCards() {
    final allEmojis = [..._pairs, ..._pairs]..shuffle();
    _cards = allEmojis
        .asMap()
        .entries
        .map((e) => _Card(id: e.key, emoji: e.value))
        .toList();
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;
    if (_cards[index].isMatched) return;
    if (_cards[index].isFlipped) return;

    setState(() => _cards[index].isFlipped = true);

    if (_firstSelected == null) {
      _firstSelected = index;
    } else {
      _moves++;
      _isProcessing = true;

      if (_cards[_firstSelected!].emoji == _cards[index].emoji) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _cards[_firstSelected!].isMatched = true;
            _cards[index].isMatched = true;
            _matchedPairs++;
            _firstSelected = null;
            _isProcessing = false;
          });
          if (_matchedPairs == _pairs.length) {
            _confettiController.play();
            Future.delayed(const Duration(milliseconds: 600), _showComplete);
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() {
            _cards[_firstSelected!].isFlipped = false;
            _cards[index].isFlipped = false;
            _firstSelected = null;
            _isProcessing = false;
          });
        });
      }
    }
  }

  Future<void> _showComplete() async {
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    int earnedStars;
    if (_moves <= _pairs.length + 2) {
      earnedStars = 3;
    } else if (_moves <= _pairs.length + 6) {
      earnedStars = 2;
    } else {
      earnedStars = 1;
    }

    if (widget.childId != null && widget.lessonId != null) {
      try {
        final score = earnedStars == 3 ? 100 : earnedStars == 2 ? 80 : 60;
        await ApiClient().submitProgress(
          childId: widget.childId!,
          lessonId: widget.lessonId!,
          score: score,
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
            Text('🧠', style: TextStyle(fontSize: 64)),
            Text('Aql ustasi!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Barcha juftlikni topding!', textAlign: TextAlign.center),
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
            Text('Harakatlar: $_moves',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C5CE7),
        title: Text("Xotira o'yini  •  $_moves"),
      ),
      body: Stack(
        children: [
          Container(
            color: AppTheme.backgroundColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _matchedPairs / _pairs.length,
                      backgroundColor: Colors.white,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF6C5CE7)),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bir xil kartalarni juft qil!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _cards.length,
                        itemBuilder: (context, index) => _MemoryCard(
                          card: _cards[index],
                          onTap: () => _onCardTap(index),
                        ),
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
              numberOfParticles: 50,
              colors: const [
                AppTheme.primaryColor,
                Color(0xFF6C5CE7),
                AppTheme.accentColor,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  _Card({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class _MemoryCard extends StatelessWidget {
  final _Card card;
  final VoidCallback onTap;
  const _MemoryCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showFront = card.isFlipped || card.isMatched;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: showFront
              ? (card.isMatched
                  ? AppTheme.successColor.withValues(alpha: 0.3)
                  : Colors.white)
              : const Color(0xFF6C5CE7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: showFront
              ? Text(card.emoji, style: const TextStyle(fontSize: 48))
              : const Icon(Icons.question_mark, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}
