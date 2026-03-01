import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../models/game_mechanics.dart';
import '../models/game_mechanics.dart' as GameMechanics;
import '../models/daily_reward.dart';
import '../services/badge_service.dart';
import '../services/daily_reward_service.dart';
import 'game_start_screen.dart';

class SpecializedGameScreen extends StatefulWidget {
  final TopicGameSettings topicSettings;
  final AgeGroupSelection ageGroup;
  final String difficulty;
  final VoidCallback onBack;

  const SpecializedGameScreen({
    super.key,
    required this.topicSettings,
    required this.ageGroup,
    required this.difficulty,
    required this.onBack,
  });

  @override
  State<SpecializedGameScreen> createState() => _SpecializedGameScreenState();
}

class _SpecializedGameScreenState extends State<SpecializedGameScreen>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _lives = 3;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalAnswerTimeSeconds = 0;
  int _fastAnswersCount = 0;
  int _superFastAnswersCount = 0;
  bool _hasReportedCompletion = false;
  bool _isAnswered = false;
  dynamic _selectedAnswer;
  bool _isCorrect = false;
  Timer? _timer;
  int _timeLeft = 30;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  // REKLAM SİSTEMİ
  int _remainingAds = 3; // Kalan reklam hakkı
  int _totalAdsWatched = 0; // İzlenen reklam sayısı
  bool _isGameOver = false; // Oyun bitti mi?
  bool _gamePaused = false; // Oyun duraklatıldı mı?
  late AnimationController _adController; // Reklam butonu animasyonu
  late Animation<double> _adAnimation;

  @override
  void initState() {
    super.initState();
    _questions = [];
    _generateQuestions();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );

    // Reklam animasyonu
    _adController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _adAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _adController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _heartController.dispose();
    _adController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = math.Random();
    _questions.clear();
    int questionCount = _getQuestionCount();

    for (int i = 0; i < questionCount; i++) {
      final question = GameMechanics.TopicGameManager.generateTopicQuestion(
        widget.topicSettings.topicType,
        widget.ageGroup,
        random,
      );
      _questions.add(Map<String, dynamic>.from(question));
    }
  }

  int _getQuestionCount() {
    switch (widget.difficulty) {
      case 'Kolay': return 5;
      case 'Orta': return 10;
      case 'Zor': return 15;
      default: return 10;
    }
  }

  void _startTimer() {
    if (_isGameOver || _gamePaused) return;

    _timer?.cancel();
    _timeLeft = _getTimeLimit();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isGameOver && !_gamePaused) {
        setState(() => _timeLeft--);
      } else if (_timeLeft == 0 && !_isGameOver && !_gamePaused) {
        _handleTimeout();
      }
    });
  }

  int _getTimeLimit() {
    switch (widget.difficulty) {
      case 'Kolay': return 45;
      case 'Orta': return 30;
      case 'Zor': return 20;
      default: return 30;
    }
  }

  void _handleTimeout() {
    _timer?.cancel();
    _loseLife();
  }

  void _checkAnswer(dynamic answer) {
    if (_isAnswered || _isGameOver || _gamePaused) return;

    _timer?.cancel();
    final currentQuestion = _questions[_currentQuestionIndex];
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == currentQuestion['correctAnswer'];
    });

    final timeUsed = _getTimeLimit() - _timeLeft;
    _totalAnswerTimeSeconds += timeUsed;
    if (timeUsed <= 5) _superFastAnswersCount++;
    else if (timeUsed <= 10) _fastAnswersCount++;

    if (_isCorrect) {
      _score += _calculateScore();
      _correctAnswers++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
      _animationController.forward(from: 0);

      // Biraz bekle ve sonraki soruya geç
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _isGameOver) return;
        _nextQuestion();
      });
    } else {
      _wrongAnswers++;
      _currentStreak = 0;
      _loseLife();
    }
  }

  void _loseLife() {
    _heartController.forward().then((_) => _heartController.reset());

    setState(() {
      _lives--;
    });

    if (_lives <= 0) {
      _gameOver();
    } else {
      _gamePaused = true;

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted || _isGameOver) return;
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
          _gamePaused = false;
        });
        _startTimer();
      });
    }
  }

  int _calculateScore() {
    return 10; // Her doğru cevap için 10 puan
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  // REKLAM İZLEYEREK CAN KAZANMA
  void _reviveWithAd() {
    // TODO: Gerçek reklam entegrasyonu buraya eklenecek

    setState(() {
      _lives = 1; // 1 CAN KAZANIR
      _remainingAds--; // Kalan reklam hakkı azalır
      _totalAdsWatched++; // İzlenen reklam sayısı artar
      _isGameOver = false;
      _gamePaused = false;
      _isAnswered = false;
      _selectedAnswer = null;
    });

    // Kullanıcıya bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.play_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎬 Reklam izlendi!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '+1 can kazandın! (Kalan: $_remainingAds)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // Yeni soruya geç ve devam et
    _startTimer();
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _gamePaused = true;
    });
    _timer?.cancel();
    _reportGameCompletion();
    _showGameOverDialog();
  }

  /// Oyun sonuçlarını BadgeService ve DailyRewardService'e bildir
  void _reportGameCompletion() {
    if (!mounted || _hasReportedCompletion) return;
    _hasReportedCompletion = true;
    try {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      final rewardService = Provider.of<DailyRewardService>(context, listen: false);

      final questionsAnswered = _currentQuestionIndex + 1;
      final avgTime = questionsAnswered > 0
          ? _totalAnswerTimeSeconds / questionsAnswered
          : 0.0;

      badgeService.onGameCompleted(
        questionsAnswered: questionsAnswered,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        score: _score,
        averageTime: avgTime,
        fastAnswersCount: _fastAnswersCount,
        superFastAnswersCount: _superFastAnswersCount,
        streak: _bestStreak,
      );

      rewardService.updateTaskProgress(TaskType.playGames, 1);
      rewardService.updateTaskProgress(TaskType.solveQuestions, _correctAnswers);
      rewardService.updateTaskProgress(TaskType.correctStreak, _bestStreak);
      if (_wrongAnswers == 0 && _correctAnswers > 0) {
        rewardService.updateTaskProgress(TaskType.perfectGame, 1);
      }
      rewardService.updateTaskProgress(TaskType.fastAnswers, _fastAnswersCount + _superFastAnswersCount);
    } catch (e) {
      debugPrint('Report game completion error: $e');
    }
  }

  void _showGameOverDialog() {
    final bool showAdOption = _remainingAds > 0; // Reklam hakkı varsa göster

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
                widget.topicSettings.color.withOpacity(0.8),
                widget.topicSettings.color,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💔 CANLAR BİTTİ 💔',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.topicSettings.emoji} ${widget.topicSettings.title}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Doğru Cevaplar', '$_correctAnswers / ${_currentQuestionIndex + 1}'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('Skor', '$_score'),
                    if (_totalAdsWatched > 0) ...[
                      const Divider(color: Colors.white24),
                      _buildStatRow('İzlenen Reklam', '$_totalAdsWatched'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // REKLAM İZLE BUTONU - Kalan hak varsa göster
              if (showAdOption) ...[
                AnimatedBuilder(
                  animation: _adAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _adAnimation.value,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _reviveWithAd();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle, size: 28),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'REKLAM İZLE +1 CAN KAZAN',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Kalan hak: $_remainingAds/3',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              // TEKRAR DENE
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'TEKRAR DENE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // ANA MENÜ
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onBack();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'ANA MENÜ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (!_isGameOver) {
        setState(() {
          _gamePaused = false;
        });
      }
    });
  }

  Widget _buildGeometryQuestion(Map<String, dynamic> question) {
    final type = question['type'] as String? ?? '';
    final correctAnswer = question['correctAnswer'];
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];

    switch (type) {
      case 'identify_shapes':
        final shapeToShow = question['shapeToShow'] as String? ??
            (correctAnswer is String ? correctAnswer : '');
        return Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _getShapeEmoji(shapeToShow),
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((option) {
                return _buildShapeOption(option.toString());
              }).toList(),
            ),
          ],
        );

      case 'count_sides':
        final shapeName = question['shapeToShow'] as String? ??
            (correctAnswer is int && correctAnswer == 3 ? 'üçgen' :
            correctAnswer is int && correctAnswer == 4 ? 'kare' : 'beşgen');
        final optionsList = options.map((o) => o as int).toList();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getShapeEmoji(shapeName),
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (optionsList.length > 1)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[0])),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[1])),
                      ],
                    ),
                  if (optionsList.length > 2) const SizedBox(height: 8),
                  if (optionsList.length > 2)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[2])),
                        if (optionsList.length > 3) const SizedBox(width: 8),
                        if (optionsList.length > 3)
                          Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );

      case 'find_area':
        final optionsList = options.map((o) => o as int).toList();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '⬛',
                  style: const TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (optionsList.length > 1)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[0])),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[1])),
                      ],
                    ),
                  if (optionsList.length > 2) const SizedBox(height: 8),
                  if (optionsList.length > 2)
                    Row(
                      children: [
                        Expanded(child: _buildCompactNumberOption(optionsList[2])),
                        if (optionsList.length > 3) const SizedBox(width: 8),
                        if (optionsList.length > 3)
                          Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );

      default:
        return Center(
          child: Text(
            questionText,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }

  Widget _buildFractionQuestion(Map<String, dynamic> question) {
    final type = question['type'] as String? ?? '';
    final correctAnswer = question['correctAnswer'];
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];

    return Column(
      children: [
        if (type == 'identify_fraction')
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: correctAnswer is String
                  ? _buildFractionVisual(correctAnswer)
                  : const Text('?', style: TextStyle(fontSize: 40, color: Colors.white)),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return _buildFractionOption(option.toString());
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeQuestion(Map<String, dynamic> question) {
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final correctAnswer = question['correctAnswer'];

    // Eğer soru daha önce karıştırılmamışsa, karıştır ve soruya ekle
    if (!question.containsKey('shuffledOptions')) {
      final shuffled = List<dynamic>.from(options)..shuffle(math.Random());
      question['shuffledOptions'] = shuffled;
    }

    // Karıştırılmış seçenekleri kullan
    final displayOptions = question['shuffledOptions'] as List<dynamic>;

    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildAnalogClock(correctAnswer.toString()),
        ),
        const SizedBox(height: 20),
        Text(
          questionText,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: displayOptions.map((option) {
            return _buildTimeOption(option.toString());
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildAnalogClock(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return const Icon(Icons.access_time, size: 80);

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      return CustomPaint(
        painter: _ClockPainter(hour: hour, minute: minute),
        child: Container(),
      );
    } catch (e) {
      return const Icon(Icons.access_time, size: 80);
    }
  }

  Widget _buildShapeOption(String shape) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = shape == correctAnswer;
    final isSelected = _selectedAnswer == shape;

    return GestureDetector(
      onTap: () => _checkAnswer(shape),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(_getShapeEmoji(shape), style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              _getShapeName(shape),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberOption(int number) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = number == correctAnswer;
    final isSelected = _selectedAnswer == number;

    return GestureDetector(
      onTap: () => _checkAnswer(number),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFractionOption(String fraction) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = fraction == correctAnswer;
    final isSelected = _selectedAnswer == fraction;

    return GestureDetector(
      onTap: () => _checkAnswer(fraction),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            fraction,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = time == correctAnswer;
    final isSelected = _selectedAnswer == time;

    return GestureDetector(
      onTap: () => _checkAnswer(time),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnswered
              ? (isCorrectAnswer
              ? Colors.green
              : (isSelected ? Colors.red : Colors.white24))
              : Colors.white24,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFractionVisual(String fraction) {
    try {
      final parts = fraction.split('/');
      if (parts.length != 2) {
        return const Icon(Icons.pie_chart, size: 80, color: Colors.white);
      }

      final numerator = int.tryParse(parts[0]) ?? 1;
      final denominator = int.tryParse(parts[1]) ?? 2;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: List.generate(denominator, (index) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: index < numerator ? Colors.orange : Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            }),
          ),
        ],
      );
    } catch (e) {
      return const Icon(Icons.pie_chart, size: 80, color: Colors.white);
    }
  }

  String _getShapeEmoji(String shape) {
    switch (shape.toLowerCase()) {
      case 'daire': return '🔴';
      case 'kare': return '⬛';
      case 'üçgen': return '🔺';
      case 'dikdörtgen': return '▭';
      case 'beşgen': return '⬟';
      case 'circle': return '🔴';
      case 'square': return '⬛';
      case 'triangle': return '🔺';
      case 'rectangle': return '▭';
      case 'pentagon': return '⬟';
      default: return '🔶';
    }
  }

  String _getShapeName(String shape) {
    switch (shape.toLowerCase()) {
      case 'daire': return 'Daire';
      case 'kare': return 'Kare';
      case 'üçgen': return 'Üçgen';
      case 'dikdörtgen': return 'Dikdörtgen';
      case 'beşgen': return 'Beşgen';
      case 'circle': return 'Daire';
      case 'square': return 'Kare';
      case 'triangle': return 'Üçgen';
      case 'rectangle': return 'Dikdörtgen';
      case 'pentagon': return 'Beşgen';
      default: return shape;
    }
  }

  Widget _buildQuestionContent(Map<String, dynamic> question) {
    final topicType = widget.topicSettings.topicType;

    switch (topicType) {
      case GameMechanics.TopicType.counting:
        return _buildCountingQuestion(question);
      case GameMechanics.TopicType.geometry:
        return _buildGeometryQuestion(question);
      case GameMechanics.TopicType.fractions:
        return _buildFractionQuestion(question);
      case GameMechanics.TopicType.time:
        return _buildTimeQuestion(question);
      case GameMechanics.TopicType.addition:
      case GameMechanics.TopicType.subtraction:
      case GameMechanics.TopicType.multiplication:
      case GameMechanics.TopicType.division:
        return _buildBasicMathQuestion(question);
      case GameMechanics.TopicType.decimals:
        return _buildDecimalsQuestion(question);
      case GameMechanics.TopicType.algebra:
        return _buildAlgebraQuestion(question);
      default:
        return _buildBasicMathQuestion(question);
    }
  }

  Widget _buildCountingQuestion(Map<String, dynamic> question) {
    final type = question['type'] as String;
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final optionsList = options.whereType<int>().toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔢', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isAnswered) ...[
                const SizedBox(width: 10),
                Text(
                  _isCorrect ? '✅' : '❌',
                  style: const TextStyle(fontSize: 22),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),

        if (type == 'count_objects') ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                question['count'] as int,
                    (index) => Text(
                  question['emoji'] as String,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ] else if (type == 'find_missing' || type == 'whats_next') ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              question['sequence'] as String,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildCompactNumberOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactNumberOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildCompactNumberOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDecimalsQuestion(Map<String, dynamic> question) {
    final type = question['type'] as String? ?? '';
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];

    List<dynamic> optionsList = [];
    if (type == 'decimal_compare') {
      optionsList = options.whereType<String>().toList();
    } else if (type == 'decimal_round') {
      optionsList = options.whereType<int>().toList();
    } else {
      optionsList = options.whereType<String>().toList();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔢', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isAnswered) ...[
                const SizedBox(width: 10),
                Text(
                  _isCorrect ? '✅' : '❌',
                  style: const TextStyle(fontSize: 22),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildDecimalOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildDecimalOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildDecimalOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildDecimalOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDecimalOption(dynamic value) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final valueStr = value.toString();
    final correctStr = correctAnswer.toString();
    final isCorrectAnswer = valueStr == correctStr;
    final isSelected = _selectedAnswer?.toString() == valueStr;

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(value),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: _isAnswered
              ? (isCorrectAnswer
              ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF45a049)])
              : (isSelected
              ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)])
              : LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)])))
              : LinearGradient(colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            valueStr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlgebraQuestion(Map<String, dynamic> question) {
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final optionsList = options.whereType<int>().toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            children: [
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isAnswered) ...[
                const SizedBox(height: 8),
                Text(
                  _isCorrect ? '✅ Doğru!' : '❌ Yanlış!',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildCompactNumberOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactNumberOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildCompactNumberOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBasicMathQuestion(Map<String, dynamic> question) {
    final questionText = question['question'] as String? ?? '? = ?';
    final options = question['options'] as List<dynamic>? ?? [];
    final optionsList = options.whereType<int>().toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📝', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isAnswered) ...[
                const SizedBox(width: 10),
                Text(
                  _isCorrect ? '✅' : '❌',
                  style: const TextStyle(fontSize: 22),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 30),

        if (optionsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (optionsList.length > 0)
                      Expanded(child: _buildCompactNumberOption(optionsList[0])),
                    if (optionsList.length > 1) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _buildCompactNumberOption(optionsList[1])),
                    ],
                  ],
                ),
                if (optionsList.length > 2) const SizedBox(height: 8),
                if (optionsList.length > 2)
                  Row(
                    children: [
                      Expanded(child: _buildCompactNumberOption(optionsList[2])),
                      if (optionsList.length > 3) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactNumberOption(optionsList[3])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactNumberOption(int number) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'];
    final isCorrectAnswer = number == correctAnswer;
    final isSelected = _selectedAnswer == number;

    Color bgColor;
    Color borderColor;

    if (_isAnswered) {
      if (isCorrectAnswer) {
        bgColor = Colors.green;
        borderColor = Colors.green.shade700;
      } else if (isSelected) {
        bgColor = Colors.red;
        borderColor = Colors.red.shade700;
      } else {
        bgColor = Colors.white.withOpacity(0.15);
        borderColor = Colors.white.withOpacity(0.4);
      }
    } else {
      bgColor = Colors.white.withOpacity(0.2);
      borderColor = Colors.white.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(number),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 55,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(width: 8),
          // Canlar
          ScaleTransition(
            scale: _heartAnimation,
            child: Row(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    index < _lives ? Icons.favorite : Icons.favorite_border,
                    color: index < _lives ? Colors.red : Colors.red.withOpacity(0.3),
                    size: 24,
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                widget.topicSettings.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.difficulty,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Reklam hakkı göstergesi (kalan hak varsa)
          if (_remainingAds > 0 && !_isGameOver)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_remainingAds',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Soru ${_currentQuestionIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _timeLeft <= 5 ? Colors.red : Colors.white.withOpacity(0.3),
                    border: Border.all(
                      color: _timeLeft <= 5 ? Colors.red.shade300 : Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$_timeLeft',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _questions.isNotEmpty
                    ? (_currentQuestionIndex + 1) / _questions.length
                    : 0,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    _gamePaused = true;
    _timer?.cancel();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.topicSettings.color,
                  widget.topicSettings.color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Oyundan Çıkılsın Mı?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _gamePaused = false;
                          });
                          _startTimer();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('HAYIR', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.pop(context);
                          widget.onBack();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('EVET', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResults() {
    _timer?.cancel();
    _reportGameCompletion();

    final percentage = _questions.isNotEmpty
        ? (_correctAnswers / _questions.length * 100).round()
        : 0;
    final stars = percentage >= 80 ? 3 : percentage >= 60 ? 2 : percentage >= 40 ? 1 : 0;

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
                widget.topicSettings.color,
                widget.topicSettings.color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.topicSettings.emoji} ${widget.topicSettings.title}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                percentage >= 60 ? '🎉 Tebrikler!' : '💪 Daha Çok Çalışmalısın',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 48,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Doğru Cevaplar', '$_correctAnswers / ${_questions.length}'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('Skor', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('Başarı Oranı', '%$percentage'),
                    if (_totalAdsWatched > 0) ...[
                      const Divider(color: Colors.white24),
                      _buildStatRow('İzlenen Reklam', '$_totalAdsWatched'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ana Menü',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _restartGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tekrar Oyna',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _lives = 3;
      _remainingAds = 3; // REKLAM HAKLARI SIFIRLANIR
      _totalAdsWatched = 0;
      _isGameOver = false;
      _gamePaused = false;
      _isAnswered = false;
      _selectedAnswer = null;
      _generateQuestions();
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions.isNotEmpty
        ? _questions[_currentQuestionIndex]
        : <String, dynamic>{};

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1ABC9C), // Turkuaz
              Color(0xFF16A085), // Koyu turkuaz
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgressBar(),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: _questions.isNotEmpty
                      ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _buildQuestionContent(currentQuestion),
                  )
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Analog saat çizen CustomPainter
class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;

  _ClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final framePaint = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, framePaint);

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isHourMark = i % 3 == 0;
      final markLength = isHourMark ? 15.0 : 8.0;
      final markWidth = isHourMark ? 3.0 : 2.0;

      final startX = center.dx + (radius - markLength - 4) * math.cos(angle);
      final startY = center.dy + (radius - markLength - 4) * math.sin(angle);
      final endX = center.dx + (radius - 4) * math.cos(angle);
      final endY = center.dy + (radius - 4) * math.sin(angle);

      final markPaint = Paint()
        ..color = Colors.grey.shade800
        ..strokeWidth = markWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), markPaint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final numberRadius = radius - 30;
      final x = center.dx + numberRadius * math.cos(angle);
      final y = center.dy + numberRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minuteLength = radius * 0.6;
    final minutePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * math.cos(minuteAngle),
        center.dy + minuteLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    final normalizedHour = hour % 12;
    final hourAngle = ((normalizedHour * 30 + minute * 0.5) - 90) * math.pi / 180;
    final hourLength = radius * 0.4;
    final hourPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * math.cos(hourAngle),
        center.dy + hourLength * math.sin(hourAngle),
      ),
      hourPaint,
    );

    final centerDotPaint = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}