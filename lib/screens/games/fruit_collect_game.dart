import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../constants/fruit_collect_catalog.dart';
import '../../services/auth_service.dart';
import '../../services/game_mechanics_service.dart';
import '../../services/mini_game_session_report.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';
import '../../localization/fruit_collect_l10n.dart';
import '../../widgets/fruit_photo.dart';

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
  List<_FruitGoal> _goals = [];
  int _completedRounds = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongTaps = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
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
      _wrongTaps = 0;
      _runStreak = 0;
      _bestStreak = 0;
      _completedRounds = 0;
    });
    _generateNewQuestion();
  }

  /// Her 10 başarılı turda +1 meyve çeşidi (en fazla 10 çeşit, her birinden N adet).
  int get _fruitTypeCount {
    final tier = 1 + (_completedRounds ~/ 10);
    return tier.clamp(1, 10);
  }

  int get _requiredPerType => _fruitTypeCount;

  int get _totalRequired =>
      _goals.fold<int>(0, (sum, g) => sum + g.required);

  int get _totalCollected =>
      _goals.fold<int>(0, (sum, g) => sum + g.collected);

  bool get _allGoalsMet =>
      _goals.isNotEmpty && _goals.every((g) => g.collected >= g.required);

  List<double> _spawnPositions(Random random, int count) {
    final xs = <double>[];
    final ys = <double>[];
    const minDx = 0.14;
    const minDy = 0.16;

    for (var i = 0; i < count; i++) {
      for (var attempt = 0; attempt < 40; attempt++) {
        final x = 0.08 + random.nextDouble() * 0.74;
        final y = 0.06 + random.nextDouble() * 0.52;
        var ok = true;
        for (var j = 0; j < xs.length; j++) {
          if ((xs[j] - x).abs() < minDx && (ys[j] - y).abs() < minDy) {
            ok = false;
            break;
          }
        }
        if (ok) {
          xs.add(x);
          ys.add(y);
          break;
        }
      }
      if (xs.length <= i) {
        xs.add(0.1 + (i % 5) * 0.16);
        ys.add(0.08 + (i ~/ 5) * 0.18);
      }
    }
    return [...xs, ...ys];
  }

  void _generateNewQuestion() {
    final random = Random();
    final typeCount = _fruitTypeCount;
    final perType = _requiredPerType;
    final picked = pickDistinctFruitGoals(random, typeCount);

    final goals = picked
        .map(
          (e) => _FruitGoal(
            fruitId: e.id,
            required: perType,
          ),
        )
        .toList();
    final goalIds = goals.map((g) => g.fruitId).toSet();

    final fruits = <_FruitItem>[];
    var spawnTotal = 0;
    for (final goal in goals) {
      spawnTotal += goal.required + 1;
    }
    spawnTotal += random.nextInt(3) + 2;

    final positions = _spawnPositions(random, spawnTotal);
    var posIndex = 0;
    var id = 0;

    for (final goal in goals) {
      for (var i = 0; i < goal.required + 1; i++) {
        fruits.add(_FruitItem(
          id: id++,
          fruitId: goal.fruitId,
          x: positions[posIndex++],
          y: positions[posIndex++],
        ));
      }
    }

    while (posIndex < positions.length) {
      final other = randomDistractorFruit(random, goalIds);
      fruits.add(_FruitItem(
        id: id++,
        fruitId: other.id,
        x: positions[posIndex++],
        y: positions[posIndex++],
      ));
    }

    fruits.shuffle(random);

    setState(() {
      _goals = goals;
      _fruits = fruits;
    });
  }

  String _goalText(AppLocalizations localizations) {
    final lang = localizations.locale.languageCode;
    final parts = _goals
        .map((g) => (count: g.required, fruitId: g.fruitId))
        .toList();
    return fruitCollectMultiGoal(lang, parts);
  }

  void _collectFruit(_FruitItem fruit) {
    if (fruit.isCollected) return;

    final goalIndex = _goals.indexWhere((g) => g.fruitId == fruit.fruitId);
    if (goalIndex >= 0 && _goals[goalIndex].collected < _goals[goalIndex].required) {
      setState(() {
        fruit.isCollected = true;
        _goals[goalIndex].collected++;
      });
      _basketController.forward(from: 0);

      if (_allGoalsMet) {
        _score += 10 * _goals.length * _requiredPerType;
        _correctAnswers++;
        _completedRounds++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _showSuccessFeedback();
      }
    } else {
      _wrongTaps++;
      _runStreak = 0;
      final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
      mechanics.onWrongAnswer();
      _showWrongFeedback();
      if (!mechanics.hasLives) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _endGame();
        });
      }
    }
  }

  void _showSuccessFeedback() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || !_isPlaying) return;
      _generateNewQuestion();
    });
  }

  void _showWrongFeedback() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final loc = AppLocalizations(
      Locale(authService.currentUser?.selectedLanguage ?? 'tr'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('❌'),
            const SizedBox(width: 8),
            Text(loc.get('wrong_fruit')),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  Future<void> _endGame() async {
    setState(() => _isPlaying = false);

    await MiniGameSessionReport.submit(
      context,
      correctAnswers: _correctAnswers,
      wrongAnswers: _wrongTaps,
      score: _score,
      bestCorrectStreakInSession: _bestStreak,
    );

    final miniGameService = Provider.of<MiniGameService>(context, listen: false);
    final attempts = (_correctAnswers + _wrongTaps).clamp(1, 9999);
    final stars = miniGameService.calculateStars(
      _correctAnswers,
      attempts,
      Duration.zero,
      GameDifficulty.easy,
    );
    final previousCorrectTotal =
        miniGameService.progress?.gameStats[widget.game.id]?.totalCorrectAnswers ??
            0;
    final newCorrectTotal = previousCorrectTotal + _correctAnswers;
    final coinsEarned = _calculateThresholdCoins(
      previousCorrectTotal,
      newCorrectTotal,
    );

    miniGameService.saveGameResult(MiniGameResult(
      gameId: widget.game.id,
      score: _score,
      correctAnswers: _correctAnswers,
      totalQuestions: attempts,
      stars: stars,
      coinsEarned: coinsEarned,
      timeTaken: Duration.zero,
      difficulty: GameDifficulty.easy,
      playedAt: DateTime.now(),
    ));

    _showResultDialog(stars, coinsEarned);
  }

  int _calculateThresholdCoins(int previousTotalCorrect, int newTotalCorrect) {
    if (newTotalCorrect <= previousTotalCorrect) return 0;
    var reward = 0;

    // İlk 20 doğru cevap eşiği
    if (previousTotalCorrect < 20 && newTotalCorrect >= 20) {
      reward += 5;
    }

    // 20'den sonraki her +10 doğru cevap (30, 40, 50...) için +3
    final previousTier = previousTotalCorrect < 30
        ? 0
        : ((previousTotalCorrect - 20) ~/ 10);
    final newTier = newTotalCorrect < 30 ? 0 : ((newTotalCorrect - 20) ~/ 10);
    if (newTier > previousTier) {
      reward += (newTier - previousTier) * 3;
    }

    return reward;
  }

  void _showResultDialog(int stars, int coinsEarned) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'en';
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
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'en';
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  localizations.get(widget.game.nameKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: _goals
                .map((g) => FruitPhoto(fruitId: g.fruitId, size: 40))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _goalText(localizations),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '($_totalCollected/$_totalRequired)',
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
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
                  feedback: Material(
                    color: Colors.transparent,
                    child: FruitPhoto(fruitId: fruit.fruitId, size: 50),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: FruitPhoto(fruitId: fruit.fruitId, size: 40),
                  ),
                  child: GestureDetector(
                    onTap: () => _collectFruit(fruit),
                    child: FruitPhoto(fruitId: fruit.fruitId, size: 40),
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
                  '${localizations.get('basket')}: $_totalCollected/$_totalRequired',
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

class _FruitGoal {
  final String fruitId;
  final int required;
  int collected;

  _FruitGoal({
    required this.fruitId,
    required this.required,
    this.collected = 0,
  });
}

class _FruitItem {
  final int id;
  final String fruitId;
  final double x;
  final double y;
  bool isCollected;

  _FruitItem({
    required this.id,
    required this.fruitId,
    required this.x,
    required this.y,
    this.isCollected = false,
  });
}

