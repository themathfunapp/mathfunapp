import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/auth_service.dart';
import '../../services/game_mechanics_service.dart';
import '../../services/mini_game_session_report.dart';
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
  int _popStreak = 0;
  int _bestPopStreak = 0;
  int _level = 1;
  int _totalQuestions = 10;
  int _currentQuestion = 0;
  bool _isPlaying = false;
  bool _showConfetti = false;
  Timer? _gameTimer;
  Timer? _balloonTimer;
  
  late AnimationController _confettiController;
  /// Hedef sayı rozeti — hafif nabız (çocuk dostu)
  late AnimationController _targetPulseController;

  /// Yaklaşık yatay/dikey merkez mesafesi (normalize); çakışmayı azaltır.
  static const double _minCenterDistX = 0.20;
  static const double _minCenterDistY = 0.32;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _targetPulseController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _balloonTimer?.cancel();
    _confettiController.dispose();
    _targetPulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _correctPops = 0;
      _wrongPops = 0;
      _popStreak = 0;
      _bestPopStreak = 0;
      _currentQuestion = 0;
      _balloons = [];
    });
    _generateNewTarget();
    _startBalloonGeneration();
  }

  void _generateNewTarget() {
    final random = math.Random();
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

  bool _balloonOverlapsCandidate(double x, double y) {
    const margin = 1.15;
    final dxNeed = _minCenterDistX * margin;
    final dyNeed = _minCenterDistY * margin;
    for (final b in _balloons) {
      if (b.isPopped) continue;
      final dx = (b.x - x).abs();
      final dy = (b.y - y).abs();
      if (dx < dxNeed && dy < dyNeed) return true;
    }
    return false;
  }

  /// Yeni balon için x: mümkün olduğunca mevcut balonlarla üst üste binmeyen konum.
  double _pickSpawnX(math.Random random) {
    const spawnY = 1.1;
    for (int attempt = 0; attempt < 45; attempt++) {
      final candidate = 0.10 + random.nextDouble() * 0.80;
      if (!_balloonOverlapsCandidate(candidate, spawnY)) {
        return candidate;
      }
    }
    const lanes = [0.16, 0.28, 0.40, 0.52, 0.64, 0.76];
    double bestX = lanes[3];
    double bestMinDist = -1;
    for (final lx in lanes) {
      double minNeighbor = double.infinity;
      for (final b in _balloons) {
        if (b.isPopped) continue;
        if ((b.y - spawnY).abs() > 0.55) continue;
        final d = (b.x - lx).abs();
        if (d < minNeighbor) minNeighbor = d;
      }
      if (minNeighbor > bestMinDist) {
        bestMinDist = minNeighbor;
        bestX = lx;
      }
    }
    return bestX;
  }

  void _addNewBalloon() {
    if (_balloons.length >= 10) return;

    final random = math.Random();
    final colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#74B9FF', '#FF9FF3'];
    
    // Make sure target number appears
    int number;
    if (random.nextDouble() < 0.3) {
      number = _targetNumber;
    } else {
      number = random.nextInt(_level + 4) + 1;
    }

    final scale = 0.8 + random.nextDouble() * 0.35;

    setState(() {
      _balloons.add(Balloon(
        id: DateTime.now().millisecondsSinceEpoch + random.nextInt(1000),
        number: number,
        color: colors[random.nextInt(colors.length)],
        x: _pickSpawnX(random),
        y: 1.1,
        speed: 0.003 + random.nextDouble() * 0.002,
        scale: scale,
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
      _popStreak++;
      if (_popStreak > _bestPopStreak) _bestPopStreak = _popStreak;
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
      _popStreak = 0;
      final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
      mechanics.onWrongAnswer();
      _showWrongEffect();
      if (!mechanics.hasLives) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _endGame();
        });
      }
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

  Future<void> _endGame() async {
    _isPlaying = false;
    _gameTimer?.cancel();
    _balloonTimer?.cancel();

    await MiniGameSessionReport.submit(
      context,
      correctAnswers: _correctPops,
      wrongAnswers: _wrongPops,
      score: _score,
      bestCorrectStreakInSession: _bestPopStreak,
    );

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
    return AnimatedBuilder(
      animation: _targetPulseController,
      builder: (context, child) {
        final pulse = 1.0 + 0.08 * _targetPulseController.value;
        final bob = 4 * math.sin(_targetPulseController.value * math.pi * 2);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.97),
                const Color(0xFFFFF8E7).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withOpacity(0.35 + 0.15 * _targetPulseController.value),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.18 + 0.12 * _targetPulseController.value),
                blurRadius: 14 + 6 * _targetPulseController.value,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, bob),
                child: const Text('🎈', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${localizations.get('pop_number')}:',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Transform.scale(
                scale: pulse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF8E8E),
                        Color(0xFFFF5252),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5252).withOpacity(0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.elasticOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.6, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      '$_targetNumber',
                      key: ValueKey<int>(_targetNumber),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Transform.translate(
                offset: Offset(0, -bob * 0.6),
                child: const Text('✨', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
        );
      },
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

