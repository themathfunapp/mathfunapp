import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/game_mechanics.dart';
import '../localization/app_localizations.dart';
import 'game_start_screen.dart';

/// Boss Savaşı Ekranı
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
  // Boss durumu
  late int _bossHealth;
  late int _bossMaxHealth;

  // Oyuncu durumu
  int _playerHealth = 100;
  final int _playerMaxHealth = 100;
  int _score = 0;

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
  late Animation<double> _bossShakeAnimation;
  late Animation<double> _playerShakeAnimation;
  late Animation<double> _attackAnimation;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

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

    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bossShakeController.dispose();
    _playerShakeController.dispose();
    _attackController.dispose();
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
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _checkAnswer(-1); // Yanlış cevap
  }

  void _checkAnswer(int answer) {
    if (_isAnswered) return;

    _timer?.cancel();
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect) {
      // Boss'a hasar ver
      _attackController.forward().then((_) => _attackController.reset());
      _bossShakeController.forward().then((_) => _bossShakeController.reset());

      setState(() {
        _bossHealth -= widget.boss.damagePerCorrect;
        _score += 100 + (_timeLeft * 10);
      });

      if (_bossHealth <= 0) {
        _victory();
        return;
      }
    } else {
      // Oyuncuya hasar
      _playerShakeController.forward().then((_) => _playerShakeController.reset());

      setState(() {
        _playerHealth -= widget.boss.damagePerWrong;
      });

      if (_playerHealth <= 0) {
        _defeat();
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
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
    widget.onComplete?.call(false, _score);
    _showResultDialog(false);
  }

  void _showResultDialog(bool won) {
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
                won
                    ? '${widget.boss.name} yenildi!'
                    : '${widget.boss.name} kazandı!',
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

  void _restartBattle() {
    setState(() {
      _bossHealth = _bossMaxHealth;
      _playerHealth = _playerMaxHealth;
      _score = 0;
      _isAnswered = false;
      _selectedAnswer = null;
      _generateQuestion();
    });
    _startTimer();
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
              // Üst bar
              _buildTopBar(),

              // Boss alanı
              Expanded(
                flex: 2,
                child: _buildBossArea(),
              ),

              // Soru
              _buildQuestion(),

              // Seçenekler
              _buildOptions(),

              // Oyuncu alanı
              _buildPlayerArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossArea() {
    final healthPercent = _bossHealth / _bossMaxHealth;

    return AnimatedBuilder(
      animation: _bossShakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _bossShakeAnimation.value *
                math.sin(_bossShakeController.value * math.pi * 4),
            0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Boss ismi
              Text(
                widget.boss.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Boss can barı
              Container(
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 200 * healthPercent,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: healthPercent > 0.5
                              ? [Colors.red, Colors.orange]
                              : [Colors.red.shade900, Colors.red],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$_bossHealth / $_bossMaxHealth',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Boss emoji
              Text(
                widget.boss.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestion() {
    final isLowTime = _timeLeft <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLowTime ? Colors.red : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Zamanlayıcı
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLowTime
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '$_timeLeft',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLowTime ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Soru
          Text(
            '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // Sonuç ikonu
          if (_isAnswered)
            Icon(
              _isCorrect ? Icons.check_circle : Icons.cancel,
              color: _isCorrect ? Colors.green : Colors.red,
              size: 32,
            ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
        ),
        itemCount: _currentQuestion.options.length,
        itemBuilder: (context, index) {
          final option = _currentQuestion.options[index];
          final isSelected = _selectedAnswer == option;
          final isCorrectAnswer = option == _currentQuestion.correctAnswer;

          Color bgColor;
          if (_isAnswered) {
            if (isCorrectAnswer) {
              bgColor = Colors.green;
            } else if (isSelected && !isCorrectAnswer) {
              bgColor = Colors.red;
            } else {
              bgColor = Colors.white.withOpacity(0.1);
            }
          } else {
            bgColor = Colors.white.withOpacity(0.15);
          }

          return GestureDetector(
            onTap: () => _checkAnswer(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$option',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerArea() {
    final healthPercent = _playerHealth / _playerMaxHealth;

    return AnimatedBuilder(
      animation: _playerShakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _playerShakeAnimation.value *
                math.sin(_playerShakeController.value * math.pi * 4),
            0,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Oyuncu avatarı
                const Text('🦸', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                // Oyuncu can barı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SEN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: MediaQuery.of(context).size.width *
                                  0.5 *
                                  healthPercent,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: healthPercent > 0.5
                                      ? [Colors.green, Colors.lightGreen]
                                      : [Colors.orange, Colors.red],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_playerHealth / $_playerMaxHealth',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

