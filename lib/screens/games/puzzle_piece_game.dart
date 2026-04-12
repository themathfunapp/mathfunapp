import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/game_mechanics_service.dart';
import '../../services/mini_game_session_report.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';

class PuzzlePieceGame extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onBack;

  const PuzzlePieceGame({super.key, required this.game, required this.onBack});

  @override
  State<PuzzlePieceGame> createState() => _PuzzlePieceGameState();
}

class _PuzzlePieceGameState extends State<PuzzlePieceGame>
    with TickerProviderStateMixin {
  String _targetShape = '⭕';
  String _targetShapeName = 'circle';
  List<String> _options = [];
  int _score = 0;
  int _currentQuestion = 0;
  int _totalQuestions = 10;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
  bool _showResult = false;
  bool _isCorrect = false;

  late AnimationController _rotateController;

  final List<Map<String, String>> _shapes = [
    {'emoji': '⭕', 'name': 'circle'},
    {'emoji': '⬜', 'name': 'square'},
    {'emoji': '🔺', 'name': 'triangle'},
    {'emoji': '⬛', 'name': 'rectangle'},
    {'emoji': '⭐', 'name': 'star'},
    {'emoji': '💎', 'name': 'diamond'},
    {'emoji': '❤️', 'name': 'heart'},
    {'emoji': '🔷', 'name': 'rhombus'},
  ];

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = Random();
    final targetIndex = random.nextInt(_shapes.length);
    final target = _shapes[targetIndex];

    // Generate options
    final options = <String>[target['emoji']!];
    while (options.length < 4) {
      final optionIndex = random.nextInt(_shapes.length);
      final option = _shapes[optionIndex]['emoji']!;
      if (!options.contains(option)) {
        options.add(option);
      }
    }
    options.shuffle();

    setState(() {
      _targetShape = target['emoji']!;
      _targetShapeName = target['name']!;
      _options = options;
      _currentQuestion++;
      _showResult = false;
    });
  }

  void _selectOption(String option) {
    if (_showResult) return;

    final isCorrect = option == _targetShape;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _correctAnswers++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _score += 10;
      } else {
        _wrongAnswers++;
        _runStreak = 0;
      }
    });

    if (isCorrect) {
      _rotateController.forward(from: 0);
    } else {
      mechanics.onWrongAnswer();
      if (!mechanics.hasLives) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _endGame();
        });
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQuestion >= _totalQuestions) {
        _endGame();
      } else {
        _generateQuestion();
      }
    });
  }

  Future<void> _endGame() async {
    await MiniGameSessionReport.submit(
      context,
      correctAnswers: _correctAnswers,
      wrongAnswers: _wrongAnswers,
      score: _score,
      bestCorrectStreakInSession: _bestStreak,
    );

    final miniGameService = Provider.of<MiniGameService>(context, listen: false);
    final stars = miniGameService.calculateStars(
      _correctAnswers, _totalQuestions, Duration.zero, GameDifficulty.easy,
    );
    final coinsEarned = stars * 10 + _correctAnswers * 2;

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
    final localizations = AppLocalizations(Locale(authService.currentUser?.selectedLanguage ?? 'tr'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(int.parse(widget.game.colors[0].replaceFirst('#', '0xFF'))),
              const Color(0xFF1a1a2e),
            ]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧩', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 16),
              Text(
                stars >= 2 ? '${localizations.get('great_job')}!' : localizations.get('keep_trying'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 36,
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
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _score = 0;
                          _correctAnswers = 0;
                          _wrongAnswers = 0;
                          _runStreak = 0;
                          _bestStreak = 0;
                          _currentQuestion = 0;
                        });
                        _generateQuestion();
                      },
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
    final localizations = AppLocalizations(Locale(authService.currentUser?.selectedLanguage ?? 'tr'));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(int.parse(widget.game.colors[0].replaceFirst('#', '0xFF'))),
              const Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(localizations),
              const SizedBox(height: 20),
              _buildPuzzleArea(localizations),
              const SizedBox(height: 30),
              _buildOptions(),
              const Spacer(),
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
                color: Colors.white.withOpacity(0.2),
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

  Widget _buildPuzzleArea(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            localizations.get('find_shape'),
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          // Puzzle with missing piece
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 3, style: BorderStyle.solid),
            ),
            child: _showResult && _isCorrect
                ? RotationTransition(
                    turns: _rotateController,
                    child: Center(
                      child: Text(_targetShape, style: const TextStyle(fontSize: 80)),
                    ),
                  )
                : Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 60,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.get('shape_$_targetShapeName'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _options.map((option) {
          final isSelected = _showResult && option == _targetShape;
          final isWrong = _showResult && !_isCorrect && option != _targetShape;

          return GestureDetector(
            onTap: () => _selectOption(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.withOpacity(0.3)
                    : isWrong
                        ? Colors.red.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.green : (isWrong ? Colors.red : Colors.white.withOpacity(0.5)),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(option, style: const TextStyle(fontSize: 40)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

