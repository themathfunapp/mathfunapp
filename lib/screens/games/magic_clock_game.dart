import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/game_mechanics_service.dart';
import '../../services/mini_game_session_report.dart';
import '../../services/mini_game_service.dart';
import '../../models/mini_game.dart';
import '../../localization/app_localizations.dart';

class MagicClockGame extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onBack;

  const MagicClockGame({super.key, required this.game, required this.onBack});

  @override
  State<MagicClockGame> createState() => _MagicClockGameState();
}

class _MagicClockGameState extends State<MagicClockGame> {
  int _targetHour = 8;
  int _targetMinute = 0;
  int _selectedHour = 12;
  int _selectedMinute = 0;
  String _activityEmoji = '🍳';
  String _activityKey = 'breakfast';
  int _score = 0;
  int _currentQuestion = 0;
  int _totalQuestions = 8;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _runStreak = 0;
  int _bestStreak = 0;

  final List<Map<String, dynamic>> _activities = [
    {'key': 'wake_up', 'hour': 7, 'emoji': '⏰'},
    {'key': 'breakfast', 'hour': 8, 'emoji': '🍳'},
    {'key': 'school', 'hour': 9, 'emoji': '🏫'},
    {'key': 'lunch', 'hour': 12, 'emoji': '🍽️'},
    {'key': 'play', 'hour': 15, 'emoji': '⚽'},
    {'key': 'homework', 'hour': 17, 'emoji': '📚'},
    {'key': 'dinner', 'hour': 19, 'emoji': '🍕'},
    {'key': 'sleep', 'hour': 21, 'emoji': '😴'},
  ];

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final random = Random();
    final activity = _activities[random.nextInt(_activities.length)];

    setState(() {
      _targetHour = activity['hour'] as int;
      _targetMinute = [0, 30][random.nextInt(2)];
      _activityEmoji = activity['emoji'] as String;
      _activityKey = activity['key'] as String;
      _selectedHour = 12;
      _selectedMinute = 0;
      _currentQuestion++;
    });
  }

  void _checkAnswer() {
    final isCorrect = _selectedHour == _targetHour && _selectedMinute == _targetMinute;

    if (isCorrect) {
      _correctAnswers++;
      _runStreak++;
      if (_runStreak > _bestStreak) _bestStreak = _runStreak;
      _score += 15;
    } else {
      _wrongAnswers++;
      _runStreak = 0;
      final mechanics = Provider.of<GameMechanicsService>(context, listen: false);
      mechanics.onWrongAnswer();
      if (!mechanics.hasLives) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _endGame();
        });
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect ? '✅' : '❌',
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Doğru!' : 'Yanlış!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'Doğru cevap: ${_targetHour.toString().padLeft(2, '0')}:${_targetMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentQuestion >= _totalQuestions) {
                _endGame();
              } else {
                _generateQuestion();
              }
            },
            child: const Text('Devam'),
          ),
        ],
      ),
    );
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
              const Text('🕐', style: TextStyle(fontSize: 50)),
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
              _buildQuestion(localizations),
              const SizedBox(height: 30),
              _buildClock(),
              const SizedBox(height: 20),
              _buildTimeSelector(),
              const Spacer(),
              _buildCheckButton(localizations),
              const SizedBox(height: 20),
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

  Widget _buildQuestion(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(_activityEmoji, style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text(
            '${localizations.get('activity_$_activityKey')} ${localizations.get('time_at')}',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          Text(
            '${_targetHour.toString().padLeft(2, '0')}:${_targetMinute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ClockPainter(
          hour: _selectedHour,
          minute: _selectedMinute,
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hour selector
        Column(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedHour = (_selectedHour % 12) + 1),
              icon: const Icon(Icons.arrow_drop_up, size: 40, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedHour.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _selectedHour = _selectedHour == 1 ? 12 : _selectedHour - 1),
              icon: const Icon(Icons.arrow_drop_down, size: 40, color: Colors.white),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        // Minute selector
        Column(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedMinute = (_selectedMinute + 30) % 60),
              icon: const Icon(Icons.arrow_drop_up, size: 40, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _selectedMinute.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _selectedMinute = (_selectedMinute - 30 + 60) % 60),
              icon: const Icon(Icons.arrow_drop_down, size: 40, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckButton(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: _checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          localizations.get('check'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;

  _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw clock face
    final facePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - 5, facePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 5, borderPaint);

    // Draw hour markers
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final markerStart = Offset(
        center.dx + (radius - 20) * cos(angle),
        center.dy + (radius - 20) * sin(angle),
      );
      final markerEnd = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      canvas.drawLine(markerStart, markerEnd, borderPaint..strokeWidth = 2);
    }

    // Draw hour hand
    final hourAngle = ((hour % 12) * 30 + minute * 0.5 - 90) * pi / 180;
    final hourHandEnd = Offset(
      center.dx + (radius * 0.5) * cos(hourAngle),
      center.dy + (radius * 0.5) * sin(hourAngle),
    );
    canvas.drawLine(center, hourHandEnd, Paint()..color = Colors.black..strokeWidth = 6..strokeCap = StrokeCap.round);

    // Draw minute hand
    final minuteAngle = (minute * 6 - 90) * pi / 180;
    final minuteHandEnd = Offset(
      center.dx + (radius * 0.7) * cos(minuteAngle),
      center.dy + (radius * 0.7) * sin(minuteAngle),
    );
    canvas.drawLine(center, minuteHandEnd, Paint()..color = Colors.blue..strokeWidth = 4..strokeCap = StrokeCap.round);

    // Draw center dot
    canvas.drawCircle(center, 8, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

