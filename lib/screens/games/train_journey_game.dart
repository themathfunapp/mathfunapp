import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/game_mechanics_service.dart';
import '../../services/mini_game_session_report.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';

class TrainJourneyGame extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onBack;

  const TrainJourneyGame({super.key, required this.game, required this.onBack});

  @override
  State<TrainJourneyGame> createState() => _TrainJourneyGameState();
}

class _TrainJourneyGameState extends State<TrainJourneyGame>
    with SingleTickerProviderStateMixin {
  int _startPassengers = 5;
  int _boarding = 3;
  int _alighting = 2;
  int _answer = 6;
  List<int> _options = [];
  int _score = 0;
  int _currentQuestion = 0;
  int _totalQuestions = 8;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  int _selectedAnswer = 0;

  late AnimationController _trainController;

  @override
  void initState() {
    super.initState();
    _trainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _trainController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = Random();
    
    _startPassengers = random.nextInt(8) + 2;
    _boarding = random.nextInt(5) + 1;
    _alighting = random.nextInt(min(5, _startPassengers)) + 1;
    _answer = _startPassengers + _boarding - _alighting;

    // Generate options
    _options = [_answer];
    while (_options.length < 4) {
      final wrong = _answer + random.nextInt(7) - 3;
      if (wrong >= 0 && wrong != _answer && !_options.contains(wrong)) {
        _options.add(wrong);
      }
    }
    _options.shuffle();

    setState(() {
      _currentQuestion++;
      _showResult = false;
    });

    _trainController.forward(from: 0);
  }

  void _selectAnswer(int selected) {
    if (_showResult) return;

    final isCorrect = selected == _answer;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      _selectedAnswer = selected;
      if (isCorrect) {
        _correctAnswers++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _score += 15;
      } else {
        _wrongAnswers++;
        _runStreak = 0;
      }
    });

    if (!isCorrect) {
      mechanics.onWrongAnswer();
      if (!mechanics.hasLives) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _endGame();
        });
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
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
      _correctAnswers, _totalQuestions, Duration.zero, GameDifficulty.medium,
    );
    final coinsEarned = stars * 12 + _correctAnswers * 3;

    miniGameService.saveGameResult(MiniGameResult(
      gameId: widget.game.id,
      score: _score,
      correctAnswers: _correctAnswers,
      totalQuestions: _totalQuestions,
      stars: stars,
      coinsEarned: coinsEarned,
      timeTaken: Duration.zero,
      difficulty: GameDifficulty.medium,
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
              const Text('🚂', style: TextStyle(fontSize: 50)),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF228B22)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(localizations),
              const SizedBox(height: 20),
              _buildStorySection(localizations),
              const SizedBox(height: 20),
              _buildTrainSection(),
              const SizedBox(height: 20),
              _buildQuestion(localizations),
              const SizedBox(height: 20),
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

  Widget _buildStorySection(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoBadge('👥', '$_startPassengers', localizations.get('starting')),
              _buildInfoBadge('➕', '$_boarding', localizations.get('boarding')),
              _buildInfoBadge('➖', '$_alighting', localizations.get('alighting')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String emoji, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildTrainSection() {
    return AnimatedBuilder(
      animation: _trainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            -200 + (_trainController.value * 400),
            0,
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Engine
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🚂', style: TextStyle(fontSize: 40)),
          ),
          // Wagons
          ...List.generate(3, (i) => Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🚃', style: TextStyle(fontSize: 30)),
          )),
        ],
      ),
    );
  }

  Widget _buildQuestion(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${localizations.get('how_many_passengers')}?',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _options.map((option) {
          final isCorrect = option == _answer;
          final isSelected = _showResult && option == _selectedAnswer;
          final showCorrect = _showResult && isCorrect;

          return GestureDetector(
            onTap: () => _selectAnswer(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: showCorrect
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : isSelected && !isCorrect
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: showCorrect
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$option',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

