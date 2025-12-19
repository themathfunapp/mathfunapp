import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';

class FruitCollectGame extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onBack;

  const FruitCollectGame({super.key, required this.game, required this.onBack});

  @override
  State<FruitCollectGame> createState() => _FruitCollectGameState();
}

class _FruitCollectGameState extends State<FruitCollectGame>
    with TickerProviderStateMixin {
  List<_FruitItem> _fruits = [];
  String _targetFruit = '🍎';
  String _targetName = 'apple';
  int _targetCount = 3;
  int _collectedCount = 0;
  int _score = 0;
  int _currentQuestion = 0;
  int _totalQuestions = 8;
  int _correctAnswers = 0;
  bool _isPlaying = false;

  late AnimationController _basketController;
  late Animation<double> _basketAnimation;

  @override
  void initState() {
    super.initState();
    _basketController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _basketAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _basketController, curve: Curves.elasticOut),
    );
    _startGame();
  }

  @override
  void dispose() {
    _basketController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _correctAnswers = 0;
      _currentQuestion = 0;
    });
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    final random = Random();
    final fruitTypes = [
      {'emoji': '🍎', 'name': 'apple'},
      {'emoji': '🍊', 'name': 'orange'},
      {'emoji': '🍋', 'name': 'lemon'},
      {'emoji': '🍇', 'name': 'grape'},
      {'emoji': '🍓', 'name': 'strawberry'},
      {'emoji': '🍌', 'name': 'banana'},
    ];

    final selectedFruit = fruitTypes[random.nextInt(fruitTypes.length)];
    final count = random.nextInt(5) + 2; // 2-6

    // Generate fruits
    final fruits = <_FruitItem>[];
    
    // Add target fruits
    for (int i = 0; i < count + random.nextInt(3); i++) {
      fruits.add(_FruitItem(
        id: i,
        emoji: selectedFruit['emoji']!,
        name: selectedFruit['name']!,
        x: random.nextDouble() * 0.7 + 0.1,
        y: random.nextDouble() * 0.4 + 0.1,
      ));
    }

    // Add some other fruits
    for (int i = 0; i < random.nextInt(4) + 2; i++) {
      final otherFruit = fruitTypes[random.nextInt(fruitTypes.length)];
      if (otherFruit['emoji'] != selectedFruit['emoji']) {
        fruits.add(_FruitItem(
          id: fruits.length,
          emoji: otherFruit['emoji']!,
          name: otherFruit['name']!,
          x: random.nextDouble() * 0.7 + 0.1,
          y: random.nextDouble() * 0.4 + 0.1,
        ));
      }
    }

    fruits.shuffle();

    setState(() {
      _fruits = fruits;
      _targetFruit = selectedFruit['emoji']!;
      _targetName = selectedFruit['name']!;
      _targetCount = count;
      _collectedCount = 0;
      _currentQuestion++;
    });
  }

  void _collectFruit(_FruitItem fruit) {
    if (fruit.isCollected) return;

    if (fruit.emoji == _targetFruit) {
      setState(() {
        fruit.isCollected = true;
        _collectedCount++;
      });
      _basketController.forward(from: 0);

      if (_collectedCount == _targetCount) {
        _score += 15;
        _correctAnswers++;
        _showSuccessFeedback();
      }
    } else {
      _showWrongFeedback();
    }
  }

  void _showSuccessFeedback() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_currentQuestion >= _totalQuestions) {
        _endGame();
      } else {
        _generateNewQuestion();
      }
    });
  }

  void _showWrongFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('❌'),
            const SizedBox(width: 8),
            Text(AppLocalizations(Locale('tr')).get('wrong_fruit')),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _endGame() {
    setState(() => _isPlaying = false);

    final miniGameService = Provider.of<MiniGameService>(context, listen: false);
    final stars = miniGameService.calculateStars(
      _correctAnswers,
      _totalQuestions,
      Duration.zero,
      GameDifficulty.easy,
    );
    final coinsEarned = stars * 10 + _correctAnswers * 3;

    miniGameService.saveGameResult(MiniGameResult(
      gameId: widget.game.id,
      score: _score,
      correctAnswers: _correctAnswers,
      totalQuestions: _totalQuestions,
      stars: stars,
      coinsEarned: coinsEarned,
      timeTaken: Duration.zero,
      difficulty: GameDifficulty.easy,
      playedAt: DateTime.now(),
    ));

    _showResultDialog(stars, coinsEarned);
  }

  void _showResultDialog(int stars, int coinsEarned) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(int.parse(widget.game.colors[0].replaceFirst('#', '0xFF'))),
                const Color(0xFF1a1a2e),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍎🍊🍋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                stars >= 2 ? '${localizations.get('great_job')}!' : localizations.get('keep_trying'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                )),
              ),
              const SizedBox(height: 16),
              Text('${localizations.get('score')}: $_score', style: const TextStyle(fontSize: 18, color: Colors.white)),
              Text('💰 +$coinsEarned', style: const TextStyle(fontSize: 16, color: Colors.amber)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () { Navigator.pop(context); widget.onBack(); },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                      child: Text(localizations.get('back'), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(context); _startGame(); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text(localizations.get('play_again'), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF87CEEB),
              Color(int.parse(widget.game.colors[0].replaceFirst('#', '0xFF'))),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(localizations),
              _buildTargetSection(localizations),
              Expanded(child: _buildFruitArea()),
              _buildBasket(localizations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(localizations.get(widget.game.nameKey),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('$_currentQuestion/$_totalQuestions',
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
            child: Text('⭐ $_score', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${localizations.get('collect')}: ', style: const TextStyle(fontSize: 18)),
          Text('$_targetCount ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          Text(_targetFruit, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Text('($_collectedCount/$_targetCount)', style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFruitArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Tree
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: constraints.maxHeight * 0.3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xFF228B22)],
                  ),
                ),
              ),
            ),
            // Tree trunk
            Positioned(
              bottom: 0,
              left: constraints.maxWidth * 0.45,
              child: Container(
                width: 40,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.brown.shade700,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
            ),
            // Fruits
            ..._fruits.where((f) => !f.isCollected).map((fruit) {
              return Positioned(
                left: constraints.maxWidth * fruit.x,
                top: constraints.maxHeight * fruit.y,
                child: Draggable<_FruitItem>(
                  data: fruit,
                  feedback: Text(fruit.emoji, style: const TextStyle(fontSize: 50)),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: Text(fruit.emoji, style: const TextStyle(fontSize: 40)),
                  ),
                  child: GestureDetector(
                    onTap: () => _collectFruit(fruit),
                    child: Text(fruit.emoji, style: const TextStyle(fontSize: 40)),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBasket(AppLocalizations localizations) {
    return DragTarget<_FruitItem>(
      onAcceptWithDetails: (details) => _collectFruit(details.data),
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _basketAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_basketAnimation.value * 0.1),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? Colors.green.shade200 : Colors.brown.shade300,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.brown.shade600, width: 3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧺', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Text(
                  '${localizations.get('basket')}: $_collectedCount/$_targetCount',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FruitItem {
  final int id;
  final String emoji;
  final String name;
  final double x;
  final double y;
  bool isCollected;

  _FruitItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.x,
    required this.y,
    this.isCollected = false,
  });
}

