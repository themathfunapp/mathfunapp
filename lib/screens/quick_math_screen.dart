import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../models/game_mechanics.dart';
import '../services/game_mechanics_service.dart';
import 'game_start_screen.dart';
import '../widgets/game_exit_confirm_dialog.dart';

/// Hızlı Matematik Oyunu Ekranı - 3 CAN SİSTEMİ VE REKLAM EKLENDİ
class QuickMathScreen extends StatefulWidget {
  final String gameType;
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  // Yeni eklenen parametreler
  final String? topicId;
  final String? topicName;
  final Color? topicColor;
  final String? topicEmoji;
  final String? difficulty;
  final int? questionCount;
  final int? timeLimit;
  final double? rewardMultiplier;

  const QuickMathScreen({
    super.key,
    required this.gameType,
    required this.ageGroup,
    required this.onBack,
    this.topicId,
    this.topicName,
    this.topicColor,
    this.topicEmoji,
    this.difficulty,
    this.questionCount,
    this.timeLimit,
    this.rewardMultiplier,
  });

  @override
  State<QuickMathScreen> createState() => _QuickMathScreenState();
}

class _QuickMathScreenState extends State<QuickMathScreen>
    with TickerProviderStateMixin {
  // Oyun durumu
  int _currentQuestionIndex = 0;
  int _totalQuestions = 5;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int? _selectedAnswer;

  // CAN SİSTEMİ - GameMechanicsService'ten (profil ile senkron)
  bool _gameOver = false;

  // Mevcut soru
  late MathQuestion _currentQuestion;
  List<MathQuestion> _questions = [];

  // Zamanlayıcı
  Timer? _timer;
  int _timeLeft = 15;
  int _totalTime = 0;

  // Animasyon kontrolcüleri
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late AnimationController _emojiFloatController;
  late AnimationController _lifeShakeController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _emojiFloatAnimation;
  late Animation<double> _lifeShakeAnimation;

  // Oyun ayarları
  late Color _gameColor;
  late String _gameTitle;
  late String _gameEmoji;

  // Çocuklar için eğlenceli karakterler
  final List<String> _happyCharacters = ['😊', '🤩', '🥳', '🤗', '😎', '😇', '🦄', '🐱', '🐶', '🐼'];
  String _currentCharacter = '😊';

  // Parçacıklar animasyonu için
  List<_Particle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();

    _initializeGameSettings();
    _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];

    _initializeAnimations();
    _generateQuestions();
    _currentQuestion = _questions[0];
    _startParticles();
    _startTimer();
  }

  void _initializeAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _emojiFloatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _emojiFloatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _emojiFloatController, curve: Curves.easeInOut),
    );

    _lifeShakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _lifeShakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _lifeShakeController, curve: Curves.elasticIn),
    );
  }

  void _startParticles() {
    _particleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      final random = math.Random();
      final newParticle = _Particle(
        x: random.nextDouble() * MediaQuery.of(context).size.width,
        y: -50,
        size: random.nextDouble() * 15 + 5,
        speed: random.nextDouble() * 5 + 4,
        color: _getParticleColor(),
        emoji: _getParticleEmoji(random),
      );

      setState(() {
        _particles.add(newParticle);
      });

      for (var particle in _particles) {
        particle.y += particle.speed;
        particle.opacity -= 0.005;
        particle.rotation += 0.05;
      }

      _particles.removeWhere((p) => p.opacity <= 0 || p.y > MediaQuery.of(context).size.height + 50);
    });
  }

  Color _getParticleColor() {
    final colors = [
      Colors.red.shade200,
      Colors.orange.shade200,
      Colors.yellow.shade200,
      Colors.green.shade200,
      Colors.blue.shade200,
      Colors.purple.shade200,
      Colors.pink.shade200,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  String _getParticleEmoji(math.Random random) {
    final emojis = ['✨', '⭐', '🌟', '💫', '🎊', '🎉', '🎈', '🧩', '🔢', '➕', '➖', '✖️', '➗'];
    return emojis[random.nextInt(emojis.length)];
  }

  void _initializeGameSettings() {
    if (widget.topicId != null && widget.topicName != null) {
      _gameColor = widget.topicColor ?? _getThemeColor();
      _gameTitle = widget.topicName!;
      _gameEmoji = widget.topicEmoji ?? '🎮';
    } else {
      _gameColor = _getThemeColor();
      _gameTitle = 'Hızlı Matematik';
      _gameEmoji = '⚡';
    }

    if (widget.questionCount != null) {
      _totalQuestions = widget.questionCount!;
    }
    if (widget.timeLimit != null) {
      _timeLeft = widget.timeLimit!;
    }
  }

  Color _getThemeColor() {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFD166),
      const Color(0xFF06D6A0),
      const Color(0xFF118AB2),
      const Color(0xFF9B5DE5),
      const Color(0xFFF15BB5),
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _particleTimer?.cancel();
    _bounceController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _emojiFloatController.dispose();
    _lifeShakeController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = math.Random();
    _questions = [];
    for (int i = 0; i < _totalQuestions; i++) {
      _questions.add(_generateMixedQuestion(random));
    }
  }

  MathQuestion _generateMixedQuestion(math.Random random) {
    int num1, num2, answer;
    String operator;
    List<int> options;

    int maxNumber;
    List<String> operators;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        maxNumber = 10;
        operators = ['+', '-'];
        break;
      case AgeGroupSelection.elementary:
        maxNumber = 20;
        operators = ['+', '-', '×'];
        break;
      case AgeGroupSelection.advanced:
        maxNumber = 50;
        operators = ['+', '-', '×', '÷'];
        break;
    }

    operator = operators[random.nextInt(operators.length)];

    switch (operator) {
      case '+':
        num1 = random.nextInt(maxNumber) + 1;
        num2 = random.nextInt(maxNumber) + 1;
        answer = num1 + num2;
        break;
      case '-':
        num1 = random.nextInt(maxNumber) + 1;
        num2 = random.nextInt(num1) + 1;
        answer = num1 - num2;
        break;
      case '×':
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        answer = num1 * num2;
        break;
      case '÷':
        num2 = random.nextInt(9) + 1;
        answer = random.nextInt(10) + 1;
        num1 = num2 * answer;
        break;
      default:
        num1 = random.nextInt(maxNumber) + 1;
        num2 = random.nextInt(maxNumber) + 1;
        answer = num1 + num2;
    }

    options = _generateOptions(answer, random);

    return MathQuestion(
      num1: num1,
      num2: num2,
      operator: operator,
      correctAnswer: answer,
      options: options,
    );
  }

  List<int> _generateOptions(int correctAnswer, math.Random random) {
    final options = <int>[correctAnswer];
    while (options.length < 4) {
      int wrongAnswer;
      if (random.nextBool()) {
        wrongAnswer = correctAnswer + random.nextInt(5) + 1;
      } else {
        wrongAnswer = correctAnswer - random.nextInt(5) - 1;
      }
      if (wrongAnswer > 0 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }
    return options..shuffle();
  }

  void _startTimer() {
    _timeLeft = widget.timeLimit ?? 15;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_gameOver) {
        setState(() {
          _timeLeft--;
          _totalTime++;
        });
      } else if (_timeLeft == 0 && !_gameOver) {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    _checkAnswer(-1, isTimeout: true);
  }

  void _checkAnswer(int answer, {bool isTimeout = false}) {
    if (_isAnswered || _gameOver) return;

    _timer?.cancel();
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = !isTimeout && answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect) {
      _score += _calculateScore();
      _correctAnswers++;
      _bounceController.forward(from: 0);
      _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];
      _confettiController.forward(from: 0);
    } else {
      _wrongAnswers++;
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      if (!kDebugMode) {
        mechanicsService.onWrongAnswer();
      }
      _shakeController.forward(from: 0);
      _lifeShakeController.forward().then((_) => _lifeShakeController.reset());

      if (!kDebugMode && mechanicsService.currentLives <= 0) {
        _gameOver = true;
        _particleTimer?.cancel();
        _showGameOverDialog();
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _gameOver) return;
      _nextQuestion();
    });
  }

  int _calculateScore() {
    int baseScore = 10;
    if (_timeLeft > 0) {
      baseScore += _timeLeft;
    }
    if (_correctAnswers > 0 && _correctAnswers % 3 == 0) {
      baseScore = (baseScore * 1.5).round();
    }
    return baseScore;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex];
        _isAnswered = false;
        _selectedAnswer = null;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showGameOverDialog() {
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
        final loc = AppLocalizations(localeProvider.locale);
        final screenWidth = MediaQuery.of(context).size.width;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 40),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.deepOrange.shade300,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üstte kalp animasyonu
                  AnimatedBuilder(
                    animation: _emojiFloatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _emojiFloatAnimation.value),
                        child: child,
                      );
                    },
                    child: const Text('💔', style: TextStyle(fontSize: 70)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.get('lives_finished'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_correctAnswers ${loc.get('correct')}, $_wrongAnswers ${loc.get('wrong')}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          loc.get('no_lives_play'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.get('try_again'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _restartGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade500,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            loc.get('try_again'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onBack();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            loc.get('exit_game'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
  }

  Widget _buildTopBar() {
    return Consumer<GameMechanicsService>(
      builder: (context, mechanicsService, _) {
        final lives = mechanicsService.currentLives;
        final maxLives = mechanicsService.maxLives;
        return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitConfirmation(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          AnimatedBuilder(
            animation: _lifeShakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_lifeShakeAnimation.value, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      ...List.generate(
                        maxLives,
                            (index) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            index < lives
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: index < lives
                                ? Colors.red
                                : Colors.white.withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildProgressBar() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctAnswers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2ECC71),
                    ),
                  ),
                ],
              ),
              Text(
                '${localizations.get('question')} ${_currentQuestionIndex + 1}/$_totalQuestions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final isLowTime = _timeLeft <= 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isAnswered && _isCorrect ? _bounceAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gameColor.withOpacity(0.9), _gameColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: _gameColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isLowTime ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isLowTime ? Colors.red : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLowTime ? Colors.red.shade300 : Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$_timeLeft',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(_currentCharacter, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isAnswered)
                    AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _bounceController.value * 0.3,
                          child: Text(
                            _isCorrect ? '✅' : '❌',
                            style: const TextStyle(fontSize: 28),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildOptionButton(_currentQuestion.options[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildOptionButton(_currentQuestion.options[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildOptionButton(_currentQuestion.options[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildOptionButton(_currentQuestion.options[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int option) {
    final isSelected = _selectedAnswer == option;
    final isCorrectAnswer = option == _currentQuestion.correctAnswer;

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

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final noLivesAndEnforced = !kDebugMode && mechanicsService.currentLives <= 0;

    return GestureDetector(
      onTap: _isAnswered || _gameOver || noLivesAndEnforced ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 55,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$option',
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

  Widget _buildBackgroundParticles() {
    return SizedBox.expand(
      child: Stack(
        children: _particles.map((particle) {
          return Positioned(
            left: particle.x,
            top: particle.y,
            child: Opacity(
              opacity: particle.opacity,
              child: Transform.rotate(
                angle: particle.rotation,
                child: Text(
                  particle.emoji,
                  style: TextStyle(
                    fontSize: particle.size,
                    color: particle.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showExitConfirmation() {
    GameExitConfirmDialog.show(
      context,
      themeColor: widget.topicColor ?? Colors.orange.shade400,
      onStay: () {},
      onExit: () {
        _timer?.cancel();
        _particleTimer?.cancel();
        widget.onBack();
      },
    );
  }

  void _showResults() {
    // Eğer oyun canlar bittiği için zaten bitmişse, sonuç ekranını gösterme (sadece release'te).
    if (_gameOver) return;

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!kDebugMode && mechanicsService.currentLives <= 0) return;

    _timer?.cancel();
    _particleTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultsDialog(),
    );
  }

  Widget _buildResultsDialog() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final percentage = _totalQuestions > 0 ? (_correctAnswers / _totalQuestions * 100).round() : 0;
    final stars = percentage >= 80 ? 3 : percentage >= 60 ? 2 : percentage >= 40 ? 1 : 0;

    final screenWidth = MediaQuery.of(context).size.width;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 40),
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık ve emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 6),
                  Text(
                    loc.get('game_over'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🎉', style: TextStyle(fontSize: 26)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                percentage >= 80
                    ? loc.get('great_job')
                    : percentage >= 40
                        ? loc.get('keep_going')
                        : loc.get('you_can_do_better'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 16),

              // Yıldız animasyonu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 500 + index * 200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),

              const SizedBox(height: 18),

              // Sonuç kartı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildResultRow('📚 ${loc.get('correct_answers')}', '$_correctAnswers / $_totalQuestions'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('❌ ${loc.get('wrong_answers')}', '$_wrongAnswers'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('⭐ ${loc.get('total_score')}', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('🎯 ${loc.get('success_rate')}', '%$percentage'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('⏱️ ${loc.get('total_time')}', '${_totalTime}s'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('❤️ ${loc.get('lives_remaining')}', '${mechanicsService.currentLives}/${mechanicsService.maxLives}'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.18),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            loc.get('main_menu'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      _restartGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            loc.get('play_again'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
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

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  void _restartGame() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!kDebugMode && !mechanicsService.hasLives) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale).get('no_lives_play')),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _gameOver = false;
      _totalTime = 0;
      _isAnswered = false;
      _selectedAnswer = null;
      _generateQuestions();
      _currentQuestion = _questions[0];
      _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];
      _particles.clear();
    });
    _startTimer();
    _startParticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gameColor, _gameColor.withOpacity(0.8), Colors.deepPurple.shade900],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundParticles(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildProgressBar(),
                  const SizedBox(height: 30),
                  _buildQuestion(),
                  const SizedBox(height: 30),
                  _buildOptions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  Color color;
  String emoji;
  double opacity = 1.0;
  double rotation = 0.0;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.emoji,
  });
}

class MathQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;

  MathQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
  });
}