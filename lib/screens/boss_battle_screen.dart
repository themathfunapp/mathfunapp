import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/game_mechanics.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import 'game_start_screen.dart';
import '../widgets/game_exit_confirm_dialog.dart';
import '../services/game_session_report.dart';

/// Boss Savaşı Ekranı - 5 CAN (GameMechanicsService ile profil senkron)
class BossBattleScreen extends StatefulWidget {
  final BossBattle boss;
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;
  final Function(bool won, int score)? onComplete;

  const BossBattleScreen({
    super.key,
    required this.boss,
    required this.ageGroup,
    required this.onBack,
    this.onComplete,
  });

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends State<BossBattleScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  // Boss durumu
  late int _bossHealth;
  late int _bossMaxHealth;

  // OYUNCU CAN SİSTEMİ - GameMechanicsService ile profil senkron (5 can)
  int _score = 0;
  bool _gameOver = false;
  bool _sessionReported = false;
  int _sessionCorrect = 0;
  int _sessionWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
  int _fastAnswersSession = 0;
  int _superFastAnswersSession = 0;
  int _totalAnswerSeconds = 0;

  // Soru durumu
  late _BossQuestion _currentQuestion;
  bool _isAnswered = false;
  int? _selectedAnswer;
  bool _isCorrect = false;

  // Zamanlayıcı
  Timer? _timer;
  int _timeLeft = 0;

  // Animasyonlar
  late AnimationController _bossShakeController;
  late AnimationController _playerShakeController;
  late AnimationController _attackController;
  late AnimationController _lifeShakeController;
  late Animation<double> _bossShakeAnimation;
  late Animation<double> _playerShakeAnimation;
  late Animation<double> _attackAnimation;
  late Animation<double> _lifeShakeAnimation;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio.playMoodLoop(MusicMood.intense);
    });

    _bossHealth = widget.boss.health;
    _bossMaxHealth = widget.boss.health;
    _timeLeft = widget.boss.timePerQuestion;

    // Animasyonlar
    _bossShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bossShakeAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _bossShakeController, curve: Curves.elasticIn),
    );

    _playerShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _playerShakeAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _playerShakeController, curve: Curves.elasticIn),
    );

    _attackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _attackAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _attackController, curve: Curves.easeOut),
    );

    // Can kaybı animasyonu
    _lifeShakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _lifeShakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _lifeShakeController, curve: Curves.elasticIn),
    );

    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _timer?.cancel();
    _bossShakeController.dispose();
    _playerShakeController.dispose();
    _attackController.dispose();
    _lifeShakeController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    int num1, num2, answer;
    String operator;

    int maxNum;
    switch (widget.boss.difficulty) {
      case 'easy':
        maxNum = 10;
        break;
      case 'medium':
        maxNum = 20;
        break;
      case 'hard':
        maxNum = 30;
        break;
      case 'expert':
        maxNum = 50;
        break;
      default:
        maxNum = 10;
    }

    // Her boss kendi işlem türünde sorar; yalnız Sayı Canavarı dört işlem karışık.
    final List<String> operators;
    switch (widget.boss.id) {
      case 'count_monster':
        operators = ['+', '-', '×', '÷'];
        break;
      case 'plus_dragon':
        operators = ['+'];
        break;
      case 'minus_wizard':
        operators = ['-'];
        break;
      case 'multiply_titan':
        operators = ['×'];
        break;
      default:
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

    List<int> options = [answer];
    while (options.length < 4) {
      int wrong = answer + _random.nextInt(10) - 5;
      if (wrong > 0 && wrong != answer && !options.contains(wrong)) {
        options.add(wrong);
      }
    }
    options.shuffle();

    _currentQuestion = _BossQuestion(
      num1: num1,
      num2: num2,
      operator: operator,
      correctAnswer: answer,
      options: options,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = widget.boss.timePerQuestion;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_gameOver) {
        setState(() {
          _timeLeft--;
        });
      } else if (_timeLeft == 0 && !_gameOver) {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _checkAnswer(-1); // Yanlış cevap
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _gameOver) return;

    _timer?.cancel();
    final int limit = widget.boss.timePerQuestion;
    final int timeUsed = (limit - _timeLeft).clamp(0, limit);
    _totalAnswerSeconds += timeUsed;
    if (timeUsed <= 5) {
      _superFastAnswersSession++;
    } else if (timeUsed <= 10) {
      _fastAnswersSession++;
    }

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect) {
      _sessionCorrect++;
      _runStreak++;
      if (_runStreak > _bestStreak) _bestStreak = _runStreak;
      _audio.playAnswerFeedback(true);
      // DOĞRU CEVAP - Boss'a hasar ver
      _attackController.forward().then((_) => _attackController.reset());
      _bossShakeController.forward().then((_) => _bossShakeController.reset());

      setState(() {
        _bossHealth -= widget.boss.damagePerCorrect;
        _score += 10;
      });

      if (_bossHealth <= 0) {
        _victory();
        return;
      }
    } else {
      _sessionWrong++;
      _runStreak = 0;
      _audio.playAnswerFeedback(false);
      // YANLIŞ CEVAP - 1 CAN GİDER (GameMechanicsService - profil senkron)
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();

      // Can kaybı animasyonu
      _lifeShakeController.forward().then((_) => _lifeShakeController.reset());
      _playerShakeController.forward().then((_) => _playerShakeController.reset());

      // CAN BİTTİ Mİ?
      if (mechanicsService.currentLives <= 0) {
        _gameOver = true;
        _defeat();
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || _gameOver) return;
      setState(() {
        _isAnswered = false;
        _selectedAnswer = null;
        _generateQuestion();
      });
      _startTimer();
    });
  }

  void _victory() {
    _timer?.cancel();
    widget.onComplete?.call(true, _score);
    _showResultDialog(true);
  }

  void _defeat() {
    _timer?.cancel();
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (mechanicsService.currentLives <= 0) {
      _showGameOverDialog(); // CAN BİTTİĞİNDE ÖZEL DİYALOG
    } else {
      widget.onComplete?.call(false, _score);
      _showResultDialog(false);
    }
  }

  // OYUN BİTTİ DİYALOĞU - REKLAM İLE 1 CAN ALMA
  void _showGameOverDialog() {
    _reportBossSession();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFFE74C3C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
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
                  const Text('💔', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    loc.get('lives_finished'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Boss\'a ${_bossMaxHealth - _bossHealth} hasar verdin',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),

              // NORMAL TEKRAR DENE
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _restartBattle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(loc.get('try_again')),
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
                  ),
                  child: Text(loc.get('exit_game')),
                ),
              ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showResultDialog(bool won) {
    _reportBossSession();
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations(localeProvider.locale);
    final bossName = loc.get('boss_${widget.boss.id}');
    final resultText = won
        ? '$bossName ${loc.get('boss_defeated')}'
        : '$bossName ${loc.get('boss_won')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: won
                  ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                  : [const Color(0xFF833ab4), const Color(0xFFfd1d1d)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '🎉 ZAFER! 🎉' : '💀 YENİLDİN 💀',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.boss.emoji,
                style: TextStyle(
                  fontSize: 64,
                  color: won ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                resultText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),

              if (won) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⭐ Puan: ',
                              style: TextStyle(color: Colors.white)),
                          Text(
                            '$_score',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙 Ödül: ',
                              style: TextStyle(color: Colors.white)),
                          Text(
                            '+${widget.boss.rewardCoins}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ÇIKIŞ'),
                    ),
                  ),
                  if (!won) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _restartBattle();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('TEKRAR'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportBossSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if ((_sessionCorrect + _sessionWrong) > 0) {
      var badges = 1;
      if (_bossHealth <= 0) badges += 1;
      if (_bestStreak >= 5 || _sessionCorrect >= 8) badges += 1;
      mechanicsService.grantAdventurePassBadges(
        mode: 'boss',
        earnedBadges: badges.clamp(1, 3),
      );
    }
    final q = (_sessionCorrect + _sessionWrong).clamp(1, 9999);
    final avg = q > 0 ? _totalAnswerSeconds / q : 0.0;
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _sessionCorrect,
        wrongAnswers: _sessionWrong,
        score: _score,
        averageAnswerTimeSeconds: avg,
        fastAnswersCount: _fastAnswersSession,
        superFastAnswersCount: _superFastAnswersSession,
        bestCorrectStreakInSession: _bestStreak,
      );
    } catch (e) {
      debugPrint('Boss battle report error: $e');
    }
  }

  void _restartBattle() {
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
      _bossHealth = _bossMaxHealth;
      _score = 0;
      _gameOver = false;
      _sessionReported = false;
      _sessionCorrect = 0;
      _sessionWrong = 0;
      _runStreak = 0;
      _bestStreak = 0;
      _fastAnswersSession = 0;
      _superFastAnswersSession = 0;
      _totalAnswerSeconds = 0;
      _isAnswered = false;
      _selectedAnswer = null;
      _generateQuestion();
    });
    _startTimer();
  }

  void _showExitConfirmation() {
    GameExitConfirmDialog.show(
      context,
      themeColor: const Color(0xFF667eea),
      onStay: () {},
      onExit: () {
        _timer?.cancel();
        widget.onBack();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f0c29),
              Color(0xFF302b63),
              Color(0xFF24243e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      _buildBossArea(),
                      const SizedBox(height: 12),
                      _buildQuestion(),
                      const SizedBox(height: 12),
                      _buildOptions(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showExitConfirmation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _lifeShakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_lifeShakeAnimation.value, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Consumer<GameMechanicsService>(
                              builder: (context, mechanicsService, _) {
                                final lives = mechanicsService.currentLives;
                                final maxLives = mechanicsService.maxLives;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🦸', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    ...List.generate(
                                      maxLives,
                                      (index) => Padding(
                                        padding: const EdgeInsets.only(right: 2),
                                        child: Icon(
                                          index < lives
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: index < lives
                                              ? Colors.red
                                              : Colors.white.withOpacity(0.5),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 17),
                          const SizedBox(width: 4),
                          Text(
                            '$_score',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossArea() {
    final healthPercent = (_bossHealth / _bossMaxHealth).clamp(0.0, 1.0);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final loc = AppLocalizations(localeProvider.locale);
    final bossName = loc.get('boss_${widget.boss.id}');

    return AnimatedBuilder(
      animation: _bossShakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _bossShakeAnimation.value *
                math.sin(_bossShakeController.value * math.pi * 4),
            0,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Boss ismi
                Text(
                  bossName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Boss can barı
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 180 * healthPercent,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: healthPercent > 0.5
                                ? [Colors.red, Colors.orange]
                                : [Colors.red.shade900, Colors.red],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$_bossHealth / $_bossMaxHealth',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Boss emoji
                Text(
                  widget.boss.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestion() {
    final isLowTime = _timeLeft <= 3;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLowTime ? Colors.red : Colors.white.withOpacity(0.2),
              border: Border.all(
                color: isLowTime ? Colors.red.shade300 : Colors.white.withOpacity(0.5),
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
          const SizedBox(width: 8),
          const Text('⚔️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_isAnswered) ...[
            const SizedBox(width: 6),
            Text(
              _isCorrect ? '✅' : '❌',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildOptionButton(_currentQuestion.options[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildOptionButton(_currentQuestion.options[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildOptionButton(_currentQuestion.options[2])),
              const SizedBox(width: 8),
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

    return GestureDetector(
      onTap: _isAnswered || _gameOver || Provider.of<GameMechanicsService>(context, listen: false).currentLives <= 0 ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 45,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
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
            '$option',
            style: const TextStyle(
              fontSize: 22,
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
}

class _BossQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;

  _BossQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
  });
}