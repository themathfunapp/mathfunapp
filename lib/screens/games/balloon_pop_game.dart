import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';

class BalloonPopGame extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onBack;

  const BalloonPopGame({super.key, required this.game, required this.onBack});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame>
    with TickerProviderStateMixin {
  List<Balloon> _balloons = [];
  int _targetNumber = 1;
  int _score = 0;
  int _correctPops = 0;
  int _wrongPops = 0;
  int _level = 1;
  int _totalQuestions = 10;
  int _currentQuestion = 0;
  bool _isPlaying = false;
  bool _showConfetti = false;
  Timer? _gameTimer;
  Timer? _balloonTimer;
  
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _balloonTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _correctPops = 0;
      _wrongPops = 0;
      _currentQuestion = 0;
      _balloons = [];
    });
    _generateNewTarget();
    _startBalloonGeneration();
  }

  void _generateNewTarget() {
    final random = Random();
    setState(() {
      _targetNumber = random.nextInt(_level + 4) + 1; // 1 to level+4
      _currentQuestion++;
    });
  }

  void _startBalloonGeneration() {
    _balloonTimer?.cancel();
    _balloonTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _addNewBalloon();
    });

    // Initial balloons
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted && _isPlaying) _addNewBalloon();
      });
    }

    // Animation timer
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _updateBalloons();
    });
  }

  void _addNewBalloon() {
    if (_balloons.length >= 10) return;

    final random = Random();
    final colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#74B9FF', '#FF9FF3'];
    
    // Make sure target number appears
    int number;
    if (random.nextDouble() < 0.3) {
      number = _targetNumber;
    } else {
      number = random.nextInt(_level + 4) + 1;
    }

    setState(() {
      _balloons.add(Balloon(
        id: DateTime.now().millisecondsSinceEpoch + random.nextInt(1000),
        number: number,
        color: colors[random.nextInt(colors.length)],
        x: random.nextDouble() * 0.8 + 0.1,
        y: 1.1,
        speed: 0.003 + random.nextDouble() * 0.002,
        scale: 0.8 + random.nextDouble() * 0.4,
      ));
    });
  }

  void _updateBalloons() {
    setState(() {
      for (var balloon in _balloons) {
        if (!balloon.isPopped) {
          balloon.y -= balloon.speed;
        }
      }
      // Remove off-screen balloons
      _balloons.removeWhere((b) => b.y < -0.2 || b.isPopped);
    });
  }

  void _popBalloon(Balloon balloon) {
    if (balloon.isPopped) return;

    setState(() {
      balloon.isPopped = true;
    });

    if (balloon.number == _targetNumber) {
      // Correct!
      _correctPops++;
      _score += 10 * _level;
      _showSuccessEffect();
      
      if (_currentQuestion >= _totalQuestions) {
        _endGame();
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isPlaying) _generateNewTarget();
        });
      }
    } else {
      // Wrong
      _wrongPops++;
      _showWrongEffect();
    }
  }

  void _showSuccessEffect() {
    setState(() => _showConfetti = true);
    _confettiController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  void _showWrongEffect() {
    // Shake effect would go here
  }

  void _endGame() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _balloonTimer?.cancel();

    final miniGameService = Provider.of<MiniGameService>(context, listen: false);
    final stars = miniGameService.calculateStars(
      _correctPops,
      _totalQuestions,
      Duration.zero,
      GameDifficulty.easy,
    );
    final coinsEarned = stars * 10 + _correctPops * 2;

    // Save result
    miniGameService.saveGameResult(MiniGameResult(
      gameId: widget.game.id,
      score: _score,
      correctAnswers: _correctPops,
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
              Text(
                stars >= 2 ? '🎉 ${localizations.get('great_job')}!' : localizations.get('keep_trying'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text(
                '${localizations.get('score')}: $_score',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.get('correct')}: $_correctPops/$_totalQuestions',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '+$coinsEarned',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        localizations.get('back'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        localizations.get('play_again'),
                        style: const TextStyle(color: Colors.white),
                      ),
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
              const Color(0xFF87CEEB), // Sky blue
              Color(int.parse(widget.game.colors[0].replaceFirst('#', '0xFF'))),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Clouds background
              ..._buildClouds(),

              // Main content - RepaintBoundary prevents header/target from repainting on balloon updates
              Column(
                children: [
                  RepaintBoundary(
                    child: _buildHeader(localizations),
                  ),
                  RepaintBoundary(
                    child: _buildTargetSection(localizations),
                  ),
                  Expanded(
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: _balloons.map((balloon) {
                              return _buildBalloon(balloon, constraints.biggest);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Confetti
              if (_showConfetti) _buildConfetti(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildClouds() {
    return [
      Positioned(
        top: 50,
        left: 20,
        child: Opacity(opacity: 0.5, child: Text('☁️', style: TextStyle(fontSize: 60))),
      ),
      Positioned(
        top: 100,
        right: 30,
        child: Opacity(opacity: 0.4, child: Text('☁️', style: TextStyle(fontSize: 80))),
      ),
      Positioned(
        top: 200,
        left: 100,
        child: Opacity(opacity: 0.3, child: Text('☁️', style: TextStyle(fontSize: 50))),
      ),
    ];
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
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
                Text(
                  localizations.get(widget.game.nameKey),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${localizations.get('question')} $_currentQuestion/$_totalQuestions',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${localizations.get('pop_number')}: ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(15),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              ),
              child: Text(
                '$_targetNumber',
                key: ValueKey<int>(_targetNumber),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalloon(Balloon balloon, Size gameAreaSize) {
    if (balloon.isPopped) return const SizedBox.shrink();

    return Positioned(
      key: ValueKey(balloon.id),
      left: gameAreaSize.width * balloon.x - 40,
      bottom: gameAreaSize.height * balloon.y - 100,
      child: GestureDetector(
        onTap: () => _popBalloon(balloon),
        child: Transform.scale(
          scale: balloon.scale,
          child: Column(
            children: [
              Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(int.parse(balloon.color.replaceFirst('#', '0xFF'))).withOpacity(0.8),
                      Color(int.parse(balloon.color.replaceFirst('#', '0xFF'))),
                    ],
                    center: const Alignment(-0.3, -0.3),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${balloon.number}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Balloon tie
              Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(int.parse(balloon.color.replaceFirst('#', '0xFF'))),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
              // String
              Container(
                width: 2,
                height: 30,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return Opacity(
                opacity: 1 - _confettiController.value,
                child: Transform.scale(
                  scale: 1 + _confettiController.value,
                  child: const Text(
                    '🎉',
                    style: TextStyle(fontSize: 100),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

