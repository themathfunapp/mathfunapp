import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../localization/app_localizations.dart';
import '../models/game_mechanics.dart';
import 'game_start_screen.dart';

/// Hızlı Matematik Oyunu Ekranı - Çocuklar için özel tasarım
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
  bool _isAnswered = false;
  bool _isCorrect = false;
  int? _selectedAnswer;

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

  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _emojiFloatAnimation;

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

    // Animasyonları başlat
    _initializeAnimations();

    // Soruları oluştur
    _generateQuestions();
    _currentQuestion = _questions[0];

    // Parçacıkları başlat
    _startParticles();

    // Zamanlayıcıyı başlat
    _startTimer();
  }

  void _initializeAnimations() {
    // Bounce animasyonu (doğru cevap)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    // Shake animasyonu (yanlış cevap)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    // Pulse animasyonu (zamanlayıcı)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Konfeti animasyonu
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Emoji float animasyonu
    _emojiFloatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _emojiFloatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _emojiFloatController, curve: Curves.easeInOut),
    );
  }

  void _startParticles() {
    _particleTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;

      final random = math.Random();
      final newParticle = _Particle(
        x: random.nextDouble() * MediaQuery.of(context).size.width,
        y: -50,
        size: random.nextDouble() * 15 + 5,
        speed: random.nextDouble() * 2 + 1,
        color: _getParticleColor(),
        emoji: _getParticleEmoji(random),
      );

      setState(() {
        _particles.add(newParticle);
      });

      // Eski parçacıkları temizle
      if (_particles.length > 20) {
        _particles.removeAt(0);
      }
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
    super.dispose();
  }

  void _generateQuestions() {
    final random = math.Random();
    _questions = [];
    for (int i = 0; i < _totalQuestions; i++) {
      _questions.add(_generateQuestion(random));
    }
  }

  MathQuestion _generateQuestion(math.Random random) {
    // Konuya özel soru üret (önceki koddan aynı)
    // ...
    return _generateMixedQuestion(random);
  }

  MathQuestion _generateMixedQuestion(math.Random random) {
    int num1, num2, answer;
    String operator;
    List<int> options;

    // Yaş grubuna göre zorluk
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
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          _totalTime++;
        });
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    _shakeController.forward().then((_) {
      _shakeController.reset();
      _nextQuestion();
    });
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
      _score += _calculateScore();
      _correctAnswers++;
      _bounceController.forward(from: 0);
      _currentCharacter = _happyCharacters[math.Random().nextInt(_happyCharacters.length)];
      _confettiController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      _nextQuestion();
    });
  }

  int _calculateScore() {
    return 10;
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

  Widget _buildTopBar() {
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
          // Geri butonu
          GestureDetector(
            onTap: () => _showExitConfirmation(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const Spacer(),

          // Başlık
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.topicName ?? 'Hızlı Matematik',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              if (widget.difficulty != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.difficulty!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Puan
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
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
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
                'Soru ${_currentQuestionIndex + 1}/$_totalQuestions',
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

  Widget _buildTimer() {
    final isLowTime = _timeLeft <= 5;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isLowTime ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLowTime
                    ? [Colors.red.shade400, Colors.orange.shade400]
                    : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isLowTime ? Colors.red.shade300 : Colors.white.withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLowTime ? Colors.red : Colors.white).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Süre
                Center(
                  child: Text(
                    '$_timeLeft',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isLowTime ? Colors.white : Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Zamanlayıcı simgesi
                Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    Icons.timer,
                    color: isLowTime ? Colors.red.shade200 : Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: Opacity(
              opacity: 1.0,
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
                    // Zamanlayıcı
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
                                style: TextStyle(
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

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(option),
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
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.orange.shade400],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Oyundan Çıkılsın Mı?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Oyundan çıkarsan skorun kaydedilmez.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('HAYIR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('EVET'),
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

  void _showResults() {
    _timer?.cancel();
    _particleTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultsDialog(),
    );
  }

  Widget _buildResultsDialog() {
    final percentage = (_correctAnswers / _totalQuestions * 100).round();
    final stars = percentage >= 80 ? 3 : percentage >= 60 ? 2 : percentage >= 40 ? 1 : 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              const Text(
                '🎉 OYUN BİTTİ 🎉',
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

              const SizedBox(height: 20),

              // Yıldızlar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 500 + index * 200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 60,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),

              const SizedBox(height: 30),

              // İstatistikler
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildResultRow('📊 Doğru Cevaplar', '$_correctAnswers / $_totalQuestions'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('⭐ Toplam Puan', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('🎯 Başarı Oranı', '%$percentage'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('⏱️ Toplam Süre', '${_totalTime}s'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

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
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home),
                          SizedBox(width: 8),
                          Text('Ana Menü', style: TextStyle(fontSize: 16)),
                        ],
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
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Tekrar Oyna', style: TextStyle(fontSize: 16)),
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
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
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
            colors: [
              _gameColor,
              _gameColor.withOpacity(0.8),
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Arka plan parçacıkları
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