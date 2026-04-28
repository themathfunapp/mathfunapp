import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../audio/section_soundscape.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../models/game_mechanics.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import 'game_start_screen.dart';
import '../widgets/game_exit_confirm_dialog.dart';
import '../services/game_session_report.dart';

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
  late final AudioService _audio;
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
  bool _hasReportedSession = false;
  int _fastAnswersSession = 0;
  int _superFastAnswersSession = 0;
  int _runStreak = 0;
  int _bestRunStreak = 0;

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

  /// Anında Matematik: kısa konfeti patlaması
  ConfettiController? _burstConfetti;
  /// Anında Matematik: yanlış / süre bittiğinde üzgün emoji
  String? _reactionEmoji;

  bool get _isInstantMath => widget.gameType == 'instant';

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.forest);

    _initializeGameSettings();
    _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];

    _initializeAnimations();
    if (_isInstantMath) {
      _burstConfetti = ConfettiController(duration: const Duration(milliseconds: 550));
    }
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
    _audio.cancelAmbientSync();
    _timer?.cancel();
    _particleTimer?.cancel();
    _bounceController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _burstConfetti?.dispose();
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
    final int limit = widget.timeLimit ?? 15;
    final int timeUsed = isTimeout ? limit : (limit - _timeLeft).clamp(0, limit);
    if (timeUsed <= 5) {
      _superFastAnswersSession++;
    } else if (timeUsed <= 10) {
      _fastAnswersSession++;
    }

    final wasCorrect = !isTimeout && answer == _currentQuestion.correctAnswer;
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = wasCorrect;
      _reactionEmoji = _isInstantMath && !wasCorrect ? '🥺' : null;
    });

    if (_isCorrect) {
      _runStreak++;
      if (_runStreak > _bestRunStreak) _bestRunStreak = _runStreak;
      // Anında modda doğru cevap başına yıldız/puan artışı kapalı.
      if (!_isInstantMath) {
        _score += _calculateScore();
      }
      _correctAnswers++;
      if (_isInstantMath) {
        _audio.playSound(SoundEffect.characterHappy);
        _burstConfetti?.stop();
        _burstConfetti?.play();
      } else {
        _audio.playAnswerFeedback(true);
      }
      _bounceController.forward(from: 0);
      _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];
    } else {
      _runStreak = 0;
      _wrongAnswers++;
      if (_isInstantMath) {
        _audio.playSound(SoundEffect.characterSad);
      } else {
        _audio.playAnswerFeedback(false);
      }
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
        _reactionEmoji = null;
      });
      _burstConfetti?.stop();
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showGameOverDialog() {
    _timer?.cancel();
    _burstConfetti?.stop();
    _reportSessionToBadges();

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
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${localizations.get('question')} ${_currentQuestionIndex + 1}/$_totalQuestions',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isAnswered && _isCorrect ? _bounceAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(width: 8),
                  Text(_currentCharacter, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
                        maxLines: 1,
                        textAlign: TextAlign.center,
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
                    ),
                  ),
                  if (_isAnswered) ...[
                    const SizedBox(width: 4),
                    AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _bounceController.value * 0.3,
                          child: Text(
                            _isCorrect ? '✅' : '❌',
                            style: const TextStyle(fontSize: 26),
                          ),
                        );
                      },
                    ),
                  ],
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
        _burstConfetti?.stop();
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
    _burstConfetti?.stop();
    _reportSessionToBadges();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultsDialog(),
    );
  }

  Widget _buildResultsDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade400, Colors.blue.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            Text(
              loc.get('game_over'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.get('keep_trying'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
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
                    child: Text(loc.get('main_menu')),
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
                    ),
                    child: Text(loc.get('play_again')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reportSessionToBadges() {
    if (_hasReportedSession || !mounted) return;
    _hasReportedSession = true;
    if (_isInstantMath) {
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      final totalAnswers = _correctAnswers + _wrongAnswers;
      if (totalAnswers > 0) {
        var badges = 1;
        if (_bestRunStreak >= 5) badges += 1;
        if (_superFastAnswersSession >= 2) badges += 1;
        mechanicsService.grantAdventurePassBadges(
          mode: 'instant',
          earnedBadges: badges.clamp(1, 3),
        );
      }
    }
    final answered = (_correctAnswers + _wrongAnswers).clamp(1, 9999);
    final avg = answered > 0 ? _totalTime / answered : 0.0;
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: answered,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        score: _score,
        averageAnswerTimeSeconds: avg,
        fastAnswersCount: _fastAnswersSession,
        superFastAnswersCount: _superFastAnswersSession,
        bestCorrectStreakInSession: _bestRunStreak,
      );
    } catch (e) {
      debugPrint('QuickMath report session error: $e');
    }
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
      _hasReportedSession = false;
      _fastAnswersSession = 0;
      _superFastAnswersSession = 0;
      _runStreak = 0;
      _bestRunStreak = 0;
      _gameOver = false;
      _totalTime = 0;
      _isAnswered = false;
      _selectedAnswer = null;
      _generateQuestions();
      _currentQuestion = _questions[0];
      _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];
      _particles.clear();
      _reactionEmoji = null;
    });
    _burstConfetti?.stop();
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
            if (_isInstantMath && _burstConfetti != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: c.maxHeight,
                          width: c.maxWidth,
                          child: ConfettiWidget(
                            confettiController: _burstConfetti!,
                            blastDirectionality: BlastDirectionality.explosive,
                            shouldLoop: false,
                            emissionFrequency: 0.35,
                            numberOfParticles: 14,
                            gravity: 0.38,
                            colors: const [
                              Color(0xFFFFD54F),
                              Color(0xFFFF80AB),
                              Color(0xFF80DEEA),
                              Color(0xFFA5D6A7),
                              Color(0xFFB39DDB),
                              Color(0xFFFFAB91),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SafeArea(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 8),
                      _buildProgressBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildQuestion(),
                              const SizedBox(height: 16),
                              _buildOptions(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isInstantMath && _reactionEmoji != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('${_currentQuestionIndex}_$_selectedAnswer'),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.elasticOut,
                            builder: (context, t, _) {
                              return Opacity(
                                opacity: (0.4 + 0.6 * t).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.35 + 0.65 * t,
                                  child: Text(
                                    _reactionEmoji!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 96),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
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