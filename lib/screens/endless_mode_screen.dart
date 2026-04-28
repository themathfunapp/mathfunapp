import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../audio/section_soundscape.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'game_start_screen.dart';
import '../widgets/game_exit_confirm_dialog.dart';

/// Sonsuz Mod Ekranı
/// Yanlış yapana kadar devam eden sınırsız sorular - 5 CAN (GameMechanicsService ile profil senkron)
class EndlessModeScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const EndlessModeScreen({
    super.key,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  State<EndlessModeScreen> createState() => _EndlessModeScreenState();
}

class _EndlessModeScreenState extends State<EndlessModeScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  // Oyun durumu
  int _score = 0;
  int _questionsAnswered = 0;
  int _wrongAnswers = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _level = 1;
  bool _isAnswered = false;
  int? _selectedAnswer;
  bool _isCorrect = false;
  bool _isGameOver = false;
  bool _gamePaused = false;
  bool _sessionReported = false;

  // Soru
  late _EndlessQuestion _currentQuestion;

  // Zamanlayıcı
  Timer? _timer;
  int _timeLeft = 10;
  int _baseTime = 10;

  // Animasyonlar
  late AnimationController _shakeController;
  late AnimationController _heartController;
  late AnimationController _levelUpController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _heartAnimation;

  final math.Random _random = math.Random();

  late ConfettiController _burstConfetti;
  String? _reactionEmoji;
  late AnimationController _playfulLoopController;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.forest);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _burstConfetti = ConfettiController(duration: const Duration(milliseconds: 550));

    _playfulLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _timer?.cancel();
    _shakeController.dispose();
    _heartController.dispose();
    _levelUpController.dispose();
    _burstConfetti.dispose();
    _playfulLoopController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    int num1, num2, answer;
    String operator;

    // Seviyeye göre zorluk
    int maxNum = 10 + (_level * 5);
    if (widget.ageGroup == AgeGroupSelection.preschool) {
      maxNum = math.min(maxNum, 20);
    } else if (widget.ageGroup == AgeGroupSelection.elementary) {
      maxNum = math.min(maxNum, 50);
    }

    // Operatör seçimi
    List<String> operators;
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        operators = ['+', '-'];
        break;
      case AgeGroupSelection.elementary:
        operators = ['+', '-', '×'];
        break;
      case AgeGroupSelection.advanced:
        operators = ['+', '-', '×', '÷'];
        break;
    }

    operator = operators[_random.nextInt(operators.length)];

    switch (operator) {
      case '+':
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(maxNum) + 1;
        answer = num1 + num2;
        break;
      case '-':
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(num1) + 1;
        answer = num1 - num2;
        break;
      case '×':
        num1 = _random.nextInt(12) + 1;
        num2 = _random.nextInt(12) + 1;
        answer = num1 * num2;
        break;
      case '÷':
        num2 = _random.nextInt(10) + 1;
        answer = _random.nextInt(10) + 1;
        num1 = num2 * answer;
        break;
      default:
        num1 = _random.nextInt(maxNum) + 1;
        num2 = _random.nextInt(maxNum) + 1;
        answer = num1 + num2;
    }

    // Seçenekler
    List<int> options = [answer];
    while (options.length < 4) {
      int wrong = answer + _random.nextInt(10) - 5;
      if (wrong > 0 && wrong != answer && !options.contains(wrong)) {
        options.add(wrong);
      }
    }
    options.shuffle();

    _currentQuestion = _EndlessQuestion(
      num1: num1,
      num2: num2,
      operator: operator,
      correctAnswer: answer,
      options: options,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    if (_isGameOver || _gamePaused) return;

    // Seviye arttıkça süre azalır
    _baseTime = math.max(5, 10 - (_level ~/ 3));
    _timeLeft = _baseTime;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isGameOver && !_gamePaused) {
        setState(() {
          _timeLeft--;
        });
      } else if (_timeLeft == 0 && !_isGameOver && !_gamePaused) {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    if (_isGameOver || _gamePaused) return;
    setState(() => _reactionEmoji = '😰');
    _loseLife();
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _isGameOver || _gamePaused) return;

    _timer?.cancel();
    final wasCorrect = answer == _currentQuestion.correctAnswer;
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = wasCorrect;
      _reactionEmoji = wasCorrect ? null : '🥺';
    });

    if (wasCorrect) {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      _audio.playSound(SoundEffect.characterHappy);
      _burstConfetti.stop();
      _burstConfetti.play();

      // Her soru için 10 puan + combo bonusu
      _score += 10 + (_combo * 2);

      _questionsAnswered++;

      // Her 5 soruda seviye atla
      if (_questionsAnswered % 5 == 0) {
        _level++;
        _levelUpController.forward().then((_) => _levelUpController.reset());
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _isGameOver) return;
        _burstConfetti.stop();
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
          _reactionEmoji = null;
          _generateQuestion();
        });
        _startTimer();
      });
    } else {
      _combo = 0;
      _shakeController.forward().then((_) => _shakeController.reset());
      _loseLife();
    }
  }

  void _loseLife() {
    _heartController.forward().then((_) => _heartController.reset());
    _audio.playSound(SoundEffect.characterSad);

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    setState(() => _wrongAnswers++);
    mechanicsService.onWrongAnswer();

    if (mechanicsService.currentLives <= 0) {
      _burstConfetti.stop();
      _gameOver();
    } else {
      _gamePaused = true;

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted || _isGameOver) return;
        _burstConfetti.stop();
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
          _reactionEmoji = null;
          _generateQuestion();
          _gamePaused = false;
        });
        _startTimer();
      });
    }
  }

  void _gameOver() {
    _burstConfetti.stop();
    setState(() {
      _isGameOver = true;
      _gamePaused = true;
    });
    _timer?.cancel();
    _showGameOverDialog();
  }

  void _reportEndlessSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if ((_questionsAnswered + _wrongAnswers) > 0) {
      var badges = 1;
      if (_level >= 3) badges += 1;
      if (_maxCombo >= 6 || _score >= 120) badges += 1;
      mechanicsService.grantAdventurePassBadges(
        mode: 'endless',
        earnedBadges: badges.clamp(1, 3),
      );
    }
    final total = _questionsAnswered + _wrongAnswers;
    final q = total < 1 ? 1 : total;
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _questionsAnswered,
        wrongAnswers: _wrongAnswers,
        score: _score,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: _maxCombo,
      );
    } catch (e) {
      debugPrint('EndlessMode report error: $e');
    }
  }

  void _showGameOverDialog() {
    _reportEndlessSession();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
          child: Builder(
            builder: (context) {
              final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
              final loc = AppLocalizations(localeProvider.locale);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💀 ${loc.get('game_over')} 💀',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // İstatistikler
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildStatRow('⭐ ${loc.get('total_score')}', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('📊 ${loc.get('level_reached')}', '$_level'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('✅ ${loc.get('correct_answer')}', '$_questionsAnswered'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('🔥 ${loc.get('highest_combo')}', '$_maxCombo'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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
                  child: Text(
                    loc.get('try_again'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // ÇIKIŞ
              Container(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onBack();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    loc.get('exit_game'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
                ],
              );
            },
          ),
        ),
      ),
    ).then((_) {
      // Diyalog kapandığında
      if (!_isGameOver) {
        setState(() {
          _gamePaused = false;
        });
      }
    });
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
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
      _score = 0;
      _questionsAnswered = 0;
      _wrongAnswers = 0;
      _combo = 0;
      _maxCombo = 0;
      _level = 1;
      _isAnswered = false;
      _selectedAnswer = null;
      _reactionEmoji = null;
      _isGameOver = false;
      _gamePaused = false;
      _sessionReported = false;
      _generateQuestion();
    });
    _burstConfetti.stop();
    _startTimer();
  }

  void _showExitConfirmation() {
    _timer?.cancel();
    _gamePaused = true;

    GameExitConfirmDialog.show(
      context,
      themeColor: const Color(0xFF667eea),
      onStay: () {
        setState(() => _gamePaused = false);
        _startTimer();
      },
      onExit: () {
        _timer?.cancel();
        _burstConfetti.stop();
        widget.onBack();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xFF1a1a2e),
                const Color(0xFF4a0072),
                (_level / 20).clamp(0.0, 1.0),
              )!,
              Color.lerp(
                const Color(0xFF16213e),
                const Color(0xFF800080),
                (_level / 20).clamp(0.0, 1.0),
              )!,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _playfulLoopController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _EndlessPlaygroundPainter(
                        phase: _playfulLoopController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
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
                          confettiController: _burstConfetti,
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
              // Üst bar: çıkış solda; puan + canlar sağda (dar ekranda taşmayı önlemek için FittedBox)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showExitConfirmation,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade400,
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '⭐',
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$_score',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ScaleTransition(
                                scale: _heartAnimation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Consumer<GameMechanicsService>(
                                    builder: (context, mechanicsService, _) {
                                      final lives = mechanicsService.currentLives;
                                      final maxLives = mechanicsService.maxLives;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          maxLives,
                                          (index) => Padding(
                                            padding: const EdgeInsets.only(right: 3),
                                            child: Icon(
                                              index < lives
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: index < lives
                                                  ? Colors.red.shade400
                                                  : Colors.white.withOpacity(0.3),
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Combo göstergesi
              if (_combo >= 3)
                Center(
                  child: AnimatedBuilder(
                    animation: _levelUpController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_levelUpController.value * 0.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 6, top: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _combo >= 10
                                  ? [Colors.red.shade600, Colors.orange.shade600]
                                  : [Colors.orange.shade400, Colors.amber.shade600],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _combo >= 10
                                    ? Colors.red.withOpacity(0.5)
                                    : Colors.orange.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🔥',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.get('combo_format').replaceAll('{0}', '$_combo'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Soru + şıklar bitişik; üstte gereksiz boşluk yok
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: constraints.maxHeight * 0.04),
                              AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      _shakeAnimation.value *
                                          math.sin(_shakeController.value * math.pi * 4),
                                      0,
                                    ),
                                    child: _buildQuestion(loc),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildOptions(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
                    ],
                  ),
                  if (_reactionEmoji != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('${_questionsAnswered}_${_wrongAnswers}_${_selectedAnswer ?? -1}'),
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

  Widget _buildQuestion(AppLocalizations loc) {
    final isLowTime = _timeLeft <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
            Colors.pink.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zamanlayıcı
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: isLowTime ? Colors.red.shade300 : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_timeLeft s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLowTime ? Colors.red.shade300 : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Soru (dar ekranda taşmayı önlemek için)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentQuestion.num1}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _currentQuestion.operator,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_currentQuestion.num2}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '=',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sonuç ikonu
          if (_isAnswered)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isCorrect ? '✅' : '❌',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isCorrect ? loc.get('correct_feedback') : loc.get('wrong_feedback'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.clamp(280.0, 780.0);
          final gap = maxWidth < 420 ? 6.0 : 10.0;
          final buttonWidth = (maxWidth - (gap * 3)) / 4;
          final buttonHeight = (buttonWidth * 0.72).clamp(48.0, 70.0);
          final fontSize = (buttonHeight * 0.46).clamp(22.0, 34.0);

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildOptionButton(
                      _currentQuestion.options[0],
                      buttonHeight: buttonHeight,
                      fontSize: fontSize,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _buildOptionButton(
                      _currentQuestion.options[1],
                      buttonHeight: buttonHeight,
                      fontSize: fontSize,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _buildOptionButton(
                      _currentQuestion.options[2],
                      buttonHeight: buttonHeight,
                      fontSize: fontSize,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _buildOptionButton(
                      _currentQuestion.options[3],
                      buttonHeight: buttonHeight,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionButton(
    int option, {
    double buttonHeight = 68,
    double fontSize = 32,
  }) {
    final isSelected = _selectedAnswer == option;
    final isCorrectAnswer = option == _currentQuestion.correctAnswer;

    final bool idle = !_isAnswered;
    Color bgColor = Colors.transparent;
    late Color borderColor;
    late Color textColor;

    if (_isAnswered) {
      if (isCorrectAnswer) {
        bgColor = Colors.green.shade500;
        borderColor = Colors.green.shade700;
        textColor = Colors.white;
      } else if (isSelected) {
        bgColor = Colors.red.shade500;
        borderColor = Colors.red.shade700;
        textColor = Colors.white;
      } else {
        bgColor = Colors.white.withOpacity(0.15);
        borderColor = Colors.white.withOpacity(0.3);
        textColor = Colors.white70;
      }
    } else {
      borderColor = Colors.white.withOpacity(0.55);
      textColor = const Color(0xFF4A148C);
    }

    return GestureDetector(
      onTap: (_isAnswered || _isGameOver || _gamePaused || Provider.of<GameMechanicsService>(context, listen: false).currentLives <= 0)
          ? null
          : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: buttonHeight,
        decoration: BoxDecoration(
          gradient: idle
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFDFBFF),
                    Color(0xFFEDE7F6),
                  ],
                )
              : null,
          color: idle ? null : bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isAnswered ? Colors.black : const Color(0xFF7E57C2)).withOpacity(_isAnswered ? 0.2 : 0.25),
              blurRadius: _isAnswered ? 10 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$option',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
              shadows: [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black.withOpacity(_isAnswered ? 0.26 : 0.12),
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Arka planda hafif hareketli çocuk dostu süsler (gradient üzerinde).
class _EndlessPlaygroundPainter extends CustomPainter {
  _EndlessPlaygroundPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p2 = phase * math.pi * 2;

    final wash = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(0, -0.2),
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.03),
          const Color(0x18FFECB3),
          const Color(0x12E1BEE7),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Offset.zero & size, wash);

    for (var i = 0; i < 14; i++) {
      final t = p2 + i * 0.5;
      final bx = w * (0.05 + (i * 0.07) % 0.9) + 10 * math.sin(t);
      final by = h * (0.08 + 0.85 * ((phase * 0.4 + i * 0.07) % 1.0));
      final br = 2.5 + (i % 4) * 1.8;
      final o = 0.08 + 0.1 * (0.5 + 0.5 * math.sin(t * 2));
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()..color = Colors.white.withOpacity(o),
      );
    }

    const glyphs = ['+', '−', '×', '⭐', '✨', '🔢'];
    for (var i = 0; i < glyphs.length; i++) {
      final t = p2 + i * 0.9;
      final x = w * (0.08 + (i % 3) * 0.32) + 14 * math.sin(t);
      final y = h * (0.12 + (i % 2) * 0.35) + 12 * math.cos(t * 1.1);
      _paintGlyph(
        canvas,
        glyphs[i],
        x,
        y,
        18.0 + (i % 3) * 5,
        Colors.white.withOpacity(0.12 + 0.1 * (0.5 + 0.5 * math.sin(t))),
      );
    }

    for (var i = 0; i < 5; i++) {
      final t = p2 * 1.2 + i;
      final cx = w * (0.15 + i * 0.18) + 8 * math.sin(t);
      final cy = h * (0.55 + 0.12 * math.sin(t * 1.3));
      final puff = Paint()..color = Colors.white.withOpacity(0.07);
      canvas.drawCircle(Offset(cx, cy), 22 + (i % 3) * 6, puff);
      canvas.drawCircle(Offset(cx + 16, cy - 4), 18 + (i % 2) * 5, puff);
    }
  }

  static void _paintGlyph(Canvas canvas, String text, double cx, double cy, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EndlessPlaygroundPainter oldDelegate) => oldDelegate.phase != phase;
}

class _EndlessQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;

  _EndlessQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
  });
}