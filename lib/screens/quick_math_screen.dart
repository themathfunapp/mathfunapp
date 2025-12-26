import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../localization/app_localizations.dart';
import 'game_start_screen.dart';

/// Hızlı Matematik Oyunu Ekranı
class QuickMathScreen extends StatefulWidget {
  final String gameType; // 'instant', 'daily', 'friend', 'topic_counting', vb.
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  // Yeni eklenen parametreler
  final String? topicId; // 'counting', 'addition', vb.
  final String? topicName; // 'Sayma', 'Toplama', vb.
  final Color? topicColor; // Konu rengi
  final String? topicEmoji; // Konu emojisi
  final String? difficulty; // 'Kolay', 'Orta', 'Zor'
  final int? questionCount; // Özel soru sayısı
  final int? timeLimit; // Özel zaman limiti
  final double? rewardMultiplier; // Ödül çarpanı

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

  // Animasyonlar
  late AnimationController _shakeController;
  late AnimationController _bounceController;
  late AnimationController _progressController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _bounceAnimation;

  // Konuya özel oyun ayarları
  late Color _gameColor;
  late String _gameTitle;
  late String _gameEmoji;

  @override
  void initState() {
    super.initState();

    // Konu ayarlarını başlat
    _initializeGameSettings();

    // Animasyon kontrolcüleri
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Soruları oluştur
    _generateQuestions();
    _currentQuestion = _questions[0];

    // Zamanlayıcıyı başlat
    _startTimer();
  }

  void _initializeGameSettings() {
    // Konu parametrelerini kullan
    if (widget.topicId != null && widget.topicName != null) {
      _gameColor = widget.topicColor ?? const Color(0xFF667eea);
      _gameTitle = widget.topicName!;
      _gameEmoji = widget.topicEmoji ?? '🎮';

      // Özel oyun ayarlarını uygula
      if (widget.questionCount != null) {
        _totalQuestions = widget.questionCount!;
      }

      if (widget.timeLimit != null) {
        _timeLeft = widget.timeLimit!;
      }
    } else {
      // Varsayılan değerler
      _gameColor = const Color(0xFF667eea);
      _gameTitle = 'Hızlı Matematik';
      _gameEmoji = '⚡';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _bounceController.dispose();
    _progressController.dispose();
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
    // Konuya özel soru üret
    if (widget.topicId != null) {
      switch (widget.topicId) {
        case 'counting':
          return _generateCountingQuestion(random);
        case 'addition':
          return _generateAdditionQuestion(random);
        case 'subtraction':
          return _generateSubtractionQuestion(random);
        case 'multiplication':
          return _generateMultiplicationQuestion(random);
        case 'division':
          return _generateDivisionQuestion(random);
        case 'shapes':
          return _generateShapeQuestion(random);
        case 'time':
          return _generateTimeQuestion(random);
        case 'fractions':
          return _generateFractionQuestion(random);
        case 'decimals':
          return _generateDecimalQuestion(random);
        case 'algebra':
          return _generateAlgebraQuestion(random);
      }
    }

    // Varsayılan: Karışık sorular
    return _generateMixedQuestion(random);
  }

  // Konuya özel soru üretme fonksiyonları
  MathQuestion _generateCountingQuestion(math.Random random) {
    final count = random.nextInt(10) + 1;
    final emojis = ['🍎', '🍌', '🍇', '🍊', '🍓', '🍍', '🥝', '🥥'];
    final emoji = emojis[random.nextInt(emojis.length)];

    final options = [count];
    while (options.length < 4) {
      int wrongAnswer;
      if (random.nextBool()) {
        wrongAnswer = count + random.nextInt(3) + 1;
      } else {
        wrongAnswer = count - random.nextInt(3) - 1;
      }
      if (wrongAnswer > 0 && wrongAnswer <= 10 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }
    options.shuffle();

    return MathQuestion(
      num1: count,
      num2: 0,
      operator: '=',
      correctAnswer: count,
      options: options,
      questionText: 'Kaç tane $emoji var?',
      questionImage: emoji * count,
    );
  }

  MathQuestion _generateAdditionQuestion(math.Random random) {
    int num1, num2, answer;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        num1 = random.nextInt(5) + 1;
        num2 = random.nextInt(5) + 1;
        break;
      case AgeGroupSelection.elementary:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        break;
      case AgeGroupSelection.advanced:
        num1 = random.nextInt(20) + 1;
        num2 = random.nextInt(20) + 1;
        break;
    }

    answer = num1 + num2;
    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: num1,
      num2: num2,
      operator: '+',
      correctAnswer: answer,
      options: options,
    );
  }

  MathQuestion _generateSubtractionQuestion(math.Random random) {
    int num1, num2, answer;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(num1) + 1;
        break;
      case AgeGroupSelection.elementary:
        num1 = random.nextInt(20) + 1;
        num2 = random.nextInt(num1) + 1;
        break;
      case AgeGroupSelection.advanced:
        num1 = random.nextInt(50) + 1;
        num2 = random.nextInt(num1) + 1;
        break;
    }

    answer = num1 - num2;
    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: num1,
      num2: num2,
      operator: '-',
      correctAnswer: answer,
      options: options,
    );
  }

  MathQuestion _generateMultiplicationQuestion(math.Random random) {
    int num1, num2, answer;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        num1 = random.nextInt(5) + 1;
        num2 = random.nextInt(5) + 1;
        break;
      case AgeGroupSelection.elementary:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        break;
      case AgeGroupSelection.advanced:
        num1 = random.nextInt(12) + 1;
        num2 = random.nextInt(12) + 1;
        break;
    }

    answer = num1 * num2;
    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: num1,
      num2: num2,
      operator: '×',
      correctAnswer: answer,
      options: options,
    );
  }

  MathQuestion _generateDivisionQuestion(math.Random random) {
    int num2, answer;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        num2 = random.nextInt(5) + 1;
        answer = random.nextInt(5) + 1;
        break;
      case AgeGroupSelection.elementary:
        num2 = random.nextInt(10) + 1;
        answer = random.nextInt(10) + 1;
        break;
      case AgeGroupSelection.advanced:
        num2 = random.nextInt(12) + 1;
        answer = random.nextInt(12) + 1;
        break;
    }

    final num1 = num2 * answer;
    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: num1,
      num2: num2,
      operator: '÷',
      correctAnswer: answer,
      options: options,
    );
  }

  MathQuestion _generateShapeQuestion(math.Random random) {
    final shapes = ['🔺', '⬛', '●', '⭐', '❤️', '🔷'];
    final shape = shapes[random.nextInt(shapes.length)];
    final count = random.nextInt(8) + 3;

    final options = [count];
    while (options.length < 4) {
      int wrongAnswer;
      if (random.nextBool()) {
        wrongAnswer = count + random.nextInt(3) + 1;
      } else {
        wrongAnswer = count - random.nextInt(3) - 1;
      }
      if (wrongAnswer > 0 && wrongAnswer <= 10 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }
    options.shuffle();

    return MathQuestion(
      num1: count,
      num2: 0,
      operator: '=',
      correctAnswer: count,
      options: options,
      questionText: 'Kaç tane $shape var?',
      questionImage: shape * count,
    );
  }

  MathQuestion _generateTimeQuestion(math.Random random) {
    final hour = random.nextInt(12) + 1;
    final minute = random.nextBool() ? 0 : 30;
    final answer = minute == 0 ? hour * 100 : hour * 100 + minute;

    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: hour,
      num2: minute,
      operator: ':',
      correctAnswer: answer,
      options: options,
      questionText: 'Saat kaç?',
      questionImage: '🕐',
    );
  }

  // YENİ EKLENEN FONKSİYONLAR:

  MathQuestion _generateFractionQuestion(math.Random random) {
    // Basit kesir soruları
    final numerators = [1, 1, 2, 3, 1, 1, 2, 3, 4, 5];
    final denominators = [2, 3, 3, 4, 4, 5, 5, 6, 8, 10];

    int index = random.nextInt(numerators.length);
    int numerator = numerators[index];
    int denominator = denominators[index];

    // Kesri sadeleştirilmiş hali
    int simplifiedNumerator = numerator;
    int simplifiedDenominator = denominator;

    // Basit sadeleştirmeler
    if (numerator == 2 && denominator == 4) {
      simplifiedNumerator = 1;
      simplifiedDenominator = 2;
    } else if (numerator == 3 && denominator == 6) {
      simplifiedNumerator = 1;
      simplifiedDenominator = 2;
    } else if (numerator == 4 && denominator == 8) {
      simplifiedNumerator = 1;
      simplifiedDenominator = 2;
    } else if (numerator == 2 && denominator == 8) {
      simplifiedNumerator = 1;
      simplifiedDenominator = 4;
    }

    final answer = simplifiedNumerator * 100 + simplifiedDenominator;
    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: numerator,
      num2: denominator,
      operator: '/',
      correctAnswer: answer,
      options: options,
      questionText: '$numerator/$denominator kesri sadeleşince ne olur?',
      questionImage: '½',
    );
  }

  MathQuestion _generateDecimalQuestion(math.Random random) {
    // Ondalık sayı soruları
    double decimal;
    int answer;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        decimal = random.nextInt(10) / 10.0; // 0.1, 0.2, ..., 0.9
        answer = (decimal * 10).toInt();
        break;
      case AgeGroupSelection.elementary:
        decimal = (random.nextInt(20) + 1) / 10.0; // 0.1, 0.2, ..., 2.0
        answer = (decimal * 10).toInt();
        break;
      case AgeGroupSelection.advanced:
        decimal = (random.nextInt(100) + 1) / 100.0; // 0.01, 0.02, ..., 1.00
        answer = (decimal * 100).toInt();
        break;
      default:
        decimal = random.nextInt(10) / 10.0;
        answer = (decimal * 10).toInt();
    }

    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: (decimal * (widget.ageGroup == AgeGroupSelection.advanced ? 100 : 10)).toInt(),
      num2: widget.ageGroup == AgeGroupSelection.advanced ? 100 : 10,
      operator: '.',
      correctAnswer: answer,
      options: options,
      questionText: '${decimal.toStringAsFixed(widget.ageGroup == AgeGroupSelection.advanced ? 2 : 1)} ondalık sayısını kesre çevirin',
      questionImage: '0️⃣',
    );
  }

  MathQuestion _generateAlgebraQuestion(math.Random random) {
    // Basit cebir soruları
    int xValue;
    int coefficient;
    int constant;
    int answer;

    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        xValue = random.nextInt(5) + 1;
        coefficient = 1;
        constant = random.nextInt(5);
        answer = coefficient * xValue + constant;
        break;
      case AgeGroupSelection.elementary:
        xValue = random.nextInt(10) + 1;
        coefficient = random.nextInt(3) + 1;
        constant = random.nextInt(10);
        answer = coefficient * xValue + constant;
        break;
      case AgeGroupSelection.advanced:
        xValue = random.nextInt(20) + 1;
        coefficient = random.nextInt(5) + 1;
        constant = random.nextInt(20);
        answer = coefficient * xValue + constant;
        break;
      default:
        xValue = random.nextInt(10) + 1;
        coefficient = 1;
        constant = random.nextInt(5);
        answer = coefficient * xValue + constant;
    }

    final options = _generateOptions(answer, random);

    return MathQuestion(
      num1: coefficient,
      num2: constant,
      operator: 'x',
      correctAnswer: answer,
      options: options,
      questionText: 'x = $xValue ise, ${coefficient}x + $constant = ?',
      questionImage: '🔤',
    );
  }

  MathQuestion _generateMixedQuestion(math.Random random) {
    int num1, num2, answer;
    String operator;
    List<int> options;

    // Yaş grubuna göre zorluk ayarla
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
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
    });
    _shakeController.forward().then((_) => _shakeController.reset());

    Future.delayed(const Duration(seconds: 1), () {
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
      _bounceController.forward().then((_) => _bounceController.reset());
      _score += _calculateScore();
      _correctAnswers++;
    } else {
      _shakeController.forward().then((_) => _shakeController.reset());
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      _nextQuestion();
    });
  }

  int _calculateScore() {
    // Kalan süreye göre puan
    int baseScore = 100;
    int timeBonus = _timeLeft * 5;
    int finalScore = baseScore + timeBonus;

    // Zorluk çarpanı
    if (widget.difficulty == 'Orta') {
      finalScore = (finalScore * 1.5).toInt();
    } else if (widget.difficulty == 'Zor') {
      finalScore = finalScore * 2;
    }

    return finalScore;
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

  void _showResults() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultsDialog(),
    );
  }

  Widget _buildResultsDialog() {
    final localizations = AppLocalizations.of(context);
    final percentage = (_correctAnswers / _totalQuestions * 100).round();
    final stars = percentage >= 80 ? 3 : percentage >= 60 ? 2 : percentage >= 40 ? 1 : 0;
    final finalScore = widget.rewardMultiplier != null
        ? (_score * widget.rewardMultiplier!).toInt()
        : _score;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _gameColor,
              _gameColor.withOpacity(0.7),
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
            // Başlık
            Text(
              '${widget.topicEmoji ?? '🎮'} ${widget.topicName ?? 'Oyun'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            Text(
              percentage >= 60
                  ? '🎉 ${localizations.get('congratulations')}!'
                  : '💪 ${localizations.get('keep_trying')}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Yıldızlar
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

            // İstatistikler
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    '✅ ${localizations.get('correct_answers')}',
                    '$_correctAnswers / $_totalQuestions',
                  ),
                  const Divider(color: Colors.white24),
                  _buildStatRow(
                    '⭐ ${localizations.get('score')}',
                    '$_score',
                  ),
                  if (widget.rewardMultiplier != null && widget.rewardMultiplier! > 1.0) ...[
                    const Divider(color: Colors.white24),
                    _buildStatRow(
                      '✨ Bonus Çarpan',
                      'x${widget.rewardMultiplier}',
                    ),
                    const Divider(color: Colors.white24),
                    _buildStatRow(
                      '🏆 Final Skor',
                      '$finalScore',
                      isHighlighted: true,
                    ),
                  ],
                  const Divider(color: Colors.white24),
                  _buildStatRow(
                    '⏱️ ${localizations.get('time')}',
                    '${_totalTime}s',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onBack();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          localizations.get('back'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _restartGame();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          localizations.get('play_again'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.amber : Colors.white,
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
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _gameColor,
              _gameColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(localizations),

              // İlerleme çubuğu
              _buildProgressBar(),

              const SizedBox(height: 8),

              // Zamanlayıcı ve Soru birlikte
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Zamanlayıcı
                    _buildTimer(),
                    const SizedBox(height: 16),
                    // Soru
                    _buildQuestion(),
                  ],
                ),
              ),

              // Seçenekler
              _buildOptions(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitConfirmation(localizations),
            child: Container(
              width: 48,
              height: 48,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.topicName ?? 'Hızlı Matematik',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.difficulty != null)
                Text(
                  widget.difficulty!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
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

  void _showExitConfirmation(AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _gameColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          localizations.get('exit_game'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          localizations.get('exit_game_confirm'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.get('cancel'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBack();
            },
            child: Text(
              localizations.get('yes'),
              style: const TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1} / $_totalQuestions',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$_correctAnswers doğru',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(Colors.amber),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final isLowTime = _timeLeft <= 5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLowTime
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
          border: Border.all(
            color: isLowTime ? Colors.red : Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$_timeLeft',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isLowTime ? Colors.red.shade200 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Soru metni veya görsel
          if (_currentQuestion.questionText != null && _currentQuestion.questionImage != null)
            Column(
              children: [
                Text(
                  _currentQuestion.questionText!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _currentQuestion.questionImage!,
                  style: const TextStyle(fontSize: 40),
                ),
              ],
            )
          else
          // Normal matematik sorusu
            Text(
              '${_currentQuestion.num1} ${_currentQuestion.operator} ${_currentQuestion.num2} = ?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

          if (_isAnswered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCorrect ? 'Doğru! 🎉' : 'Cevap: ${_currentQuestion.correctAnswer}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                ],
              ),
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
              bgColor = Colors.white.withOpacity(0.2);
            }
          } else {
            bgColor = Colors.white.withOpacity(0.2);
          }

          return GestureDetector(
            onTap: () => _checkAnswer(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 1.5,
                ),
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
                    fontSize: 22,
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

/// Matematik sorusu modeli (güncellenmiş)
class MathQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;
  final String? questionText; // Konuya özel soru metni
  final String? questionImage; // Konuya özel görsel

  MathQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
    this.questionText,
    this.questionImage,
  });
}