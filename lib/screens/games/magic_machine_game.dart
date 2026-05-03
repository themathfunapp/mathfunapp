import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/game_mechanics_service.dart';
import '../../services/mini_game_session_report.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';

class MagicMachineGame extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onBack;

  const MagicMachineGame({super.key, required this.game, required this.onBack});

  @override
  State<MagicMachineGame> createState() => _MagicMachineGameState();
}

class _MagicMachineGameState extends State<MagicMachineGame>
    with SingleTickerProviderStateMixin {
  int _num1 = 2;
  int _num2 = 3;
  String _operation = '+';
  int _answer = 5;
  int _missingValue = 3; // The value to find
  String _missingPosition = 'num2'; // num1, num2, or answer
  List<int> _options = [];
  int _score = 0;
  int _currentQuestion = 0;
  int _totalQuestions = 10;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
  bool _showResult = false;
  bool _isCorrect = false;

  late AnimationController _machineController;

  @override
  void initState() {
    super.initState();
    _machineController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _generateQuestion();
  }

  @override
  void dispose() {
    _machineController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    final random = Random();
    
    // Generate numbers
    _num1 = random.nextInt(9) + 1;
    _num2 = random.nextInt(9) + 1;
    _operation = random.nextBool() ? '+' : '-';
    
    if (_operation == '-' && _num1 < _num2) {
      final temp = _num1;
      _num1 = _num2;
      _num2 = temp;
    }
    
    _answer = _operation == '+' ? _num1 + _num2 : _num1 - _num2;
    
    // Decide what's missing
    final positions = ['num1', 'num2', 'answer'];
    _missingPosition = positions[random.nextInt(positions.length)];
    
    switch (_missingPosition) {
      case 'num1':
        _missingValue = _num1;
        break;
      case 'num2':
        _missingValue = _num2;
        break;
      case 'answer':
        _missingValue = _answer;
        break;
    }
    
    // Generate options
    _options = [_missingValue];
    while (_options.length < 4) {
      final wrong = _missingValue + random.nextInt(7) - 3;
      if (wrong > 0 && wrong != _missingValue && !_options.contains(wrong)) {
        _options.add(wrong);
      }
    }
    _options.shuffle();

    setState(() {
      _currentQuestion++;
      _showResult = false;
    });
  }

  void _selectAnswer(int selected) {
    if (_showResult) return;

    final isCorrect = selected == _missingValue;
    final mechanics = Provider.of<GameMechanicsService>(context, listen: false);

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _correctAnswers++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _score += 12;
      } else {
        _wrongAnswers++;
        _runStreak = 0;
      }
    });

    if (isCorrect) {
      _machineController.forward(from: 0);
    } else {
      mechanics.onWrongAnswer();
      if (!mechanics.hasLives) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _endGame();
        });
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
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
              const Text('🎰', style: TextStyle(fontSize: 50)),
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
              const Color(0xFF2C3E50),
              Color(int.parse(widget.game.colors[0].replaceFirst('#', '0xFF'))),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(localizations),
              const Spacer(),
              _buildMachine(localizations),
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
                Text(
                  localizations.get(widget.game.nameKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '$_currentQuestion/$_totalQuestions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
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

  Widget _buildMachine(AppLocalizations localizations) {
    return AnimatedBuilder(
      animation: _machineController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_machineController.value * 0.05),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade700, Colors.grey.shade900],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Machine top lights
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _showResult && _isCorrect
                      ? [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple][i]
                      : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: _showResult && _isCorrect
                      ? [BoxShadow(color: [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple][i], blurRadius: 8)]
                      : null,
                ),
              )),
            ),
            const SizedBox(height: 20),
            
            // Equation display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade700, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNumberDisplay(_missingPosition == 'num1' ? '?' : _num1.toString()),
                  _buildOperatorDisplay(_operation),
                  _buildNumberDisplay(_missingPosition == 'num2' ? '?' : _num2.toString()),
                  _buildOperatorDisplay('='),
                  _buildNumberDisplay(_missingPosition == 'answer' ? '?' : _answer.toString()),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Machine label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations.get('find_missing_number'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberDisplay(String text) {
    final isMissing = text == '?';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isMissing ? Colors.amber.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isMissing ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: isMissing ? Colors.amber : Colors.green,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildOperatorDisplay(String op) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        op,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _options.map((option) {
          final isCorrect = option == _missingValue;
          final showCorrect = _showResult && isCorrect;
          final showWrong = _showResult && !isCorrect;

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
                      : showWrong
                          ? [Colors.grey.shade600, Colors.grey.shade800]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: showCorrect
                        ? Colors.green.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.3),
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

