import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/game_mechanics_service.dart';
import '../localization/app_localizations.dart';
import 'game_start_screen.dart';

/// Sonsuz Mod Ekranı
/// Yanlış yapana kadar devam eden sınırsız sorular
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
  // Oyun durumu
  int _score = 0;
  int _questionsAnswered = 0;
  int _lives = 3;
  int _combo = 0;
  int _maxCombo = 0;
  int _level = 1;
  bool _isAnswered = false;
  int? _selectedAnswer;
  bool _isCorrect = false;
  bool _isGameOver = false;

  // Soru
  late _EndlessQuestion _currentQuestion;

  // Zamanlayıcı
  Timer? _timer;
  int _timeLeft = 10;
  int _baseTime = 10;

  // Animasyonlar
  late AnimationController _shakeController;
  late AnimationController _heartController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _heartAnimation;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

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

    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _heartController.dispose();
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
    // Seviye arttıkça süre azalır
    _baseTime = math.max(5, 10 - (_level ~/ 3));
    _timeLeft = _baseTime;

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
    _timer?.cancel();
    _loseLife();
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _isGameOver) return;

    _timer?.cancel();
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect) {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;

      // Puan hesapla
      int comboMultiplier = 1;
      if (_combo >= 15) comboMultiplier = 4;
      else if (_combo >= 10) comboMultiplier = 3;
      else if (_combo >= 5) comboMultiplier = 2;

      int timeBonus = _timeLeft * 5;
      int levelBonus = _level * 10;
      _score += (100 + timeBonus + levelBonus) * comboMultiplier;

      _questionsAnswered++;

      // Her 5 soruda seviye atla
      if (_questionsAnswered % 5 == 0) {
        _level++;
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
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
    
    setState(() {
      _lives--;
    });

    if (_lives <= 0) {
      _gameOver();
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
          _generateQuestion();
        });
        _startTimer();
      });
    }
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
    });
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💀 OYUN BİTTİ 💀',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // İstatistikler
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow('⭐ Toplam Puan', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('📊 Seviye', '$_level'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('✅ Doğru Cevap', '$_questionsAnswered'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('🔥 Max Combo', '$_maxCombo'),
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ÇIKIŞ'),
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
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _questionsAnswered = 0;
      _lives = 3;
      _combo = 0;
      _maxCombo = 0;
      _level = 1;
      _isAnswered = false;
      _selectedAnswer = null;
      _isGameOver = false;
      _generateQuestion();
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Combo göstergesi
              if (_combo >= 3)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _combo >= 10
                          ? [Colors.red, Colors.orange]
                          : [Colors.orange, Colors.amber],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    '🔥 COMBO x$_combo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Soru
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _shakeAnimation.value *
                              math.sin(_shakeController.value * math.pi * 4),
                          0,
                        ),
                        child: _buildQuestion(),
                      );
                    },
                  ),
                ),
              ),

              // Seçenekler
              _buildOptions(),

              const SizedBox(height: 16),
            ],
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
          // Geri butonu
          GestureDetector(
            onTap: () => _showExitConfirmation(),
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

          const SizedBox(width: 12),

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

          // Seviye
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.purple, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Lv.$_level',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Puan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 14,
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

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkmak istiyor musun?',
            style: TextStyle(color: Colors.white)),
        content: const Text('İlerleme kaydedilmeyecek.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HAYIR', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: const Text('EVET', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final isLowTime = _timeLeft <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLowTime
              ? Colors.red.withOpacity(0.8)
              : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zamanlayıcı
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLowTime
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isLowTime ? Colors.red : Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$_timeLeft',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLowTime ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),

          // Soru
          Text(
            '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          if (_isAnswered) ...[
            const SizedBox(height: 16),
            Icon(
              _isCorrect ? Icons.check_circle : Icons.cancel,
              color: _isCorrect ? Colors.green : Colors.red,
              size: 40,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$option',
                  style: const TextStyle(
                    fontSize: 24,
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

