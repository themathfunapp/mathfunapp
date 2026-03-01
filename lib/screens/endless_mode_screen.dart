import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/game_mechanics_service.dart';
import '../services/ad_service.dart';
import '../localization/app_localizations.dart';
import 'game_start_screen.dart';

/// Sonsuz Mod Ekranı
/// Yanlış yapana kadar devam eden sınırsız sorular - REKLAM SİSTEMİ EKLENDİ
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
  bool _gamePaused = false;

  // REKLAM SİSTEMİ - 3 defa reklam izleme hakkı
  int _remainingAds = 3;
  int _totalAdsWatched = 0;
  bool _showAdOption = true;

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
  late AnimationController _adController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _heartAnimation;
  late Animation<double> _levelUpAnimation;
  late Animation<double> _adAnimation;

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

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _levelUpAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );

    _adController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _adAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _adController, curve: Curves.easeInOut),
    );

    _generateQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _heartController.dispose();
    _levelUpController.dispose();
    _adController.dispose();
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
    _loseLife();
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _isGameOver || _gamePaused) return;

    _timer?.cancel();
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect) {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;

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
      _gamePaused = true;

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted || _isGameOver) return;
        setState(() {
          _isAnswered = false;
          _selectedAnswer = null;
          _generateQuestion();
          _gamePaused = false;
        });
        _startTimer();
      });
    }
  }

  // REKLAM İZLEYEREK CAN KAZANMA
  void _reviveWithAd() {
    final adService = AdService();
    
    adService.watchAdForLife(
      onLifeEarned: () {
        if (!mounted) return;
        
        setState(() {
          _lives = 1;
          _remainingAds--;
          _totalAdsWatched++;
          _isGameOver = false;
          _gamePaused = false;
          _isAnswered = false;
          _selectedAnswer = null;
        });

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

        _generateQuestion();
        _startTimer();
      },
      onAdClosed: () {
        if (mounted && _lives <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reklam izlenemedi. Tekrar deneyin.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _gamePaused = true;
      _showAdOption = _remainingAds > 0; // Reklam hakkı varsa göster
    });
    _timer?.cancel();
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
                '💀 OYUN BİTTİ 💀',
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
                    _buildStatRow('⭐ Toplam Puan', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('📊 Ulaşılan Seviye', '$_level'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('✅ Doğru Cevap', '$_questionsAnswered'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('🔥 En Yüksek Combo', '$_maxCombo'),
                    const Divider(color: Colors.white24),
                    _buildStatRow('🎬 İzlenen Reklam', '$_totalAdsWatched'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // REKLAM İZLE BUTONU - Kalan hak varsa göster
              if (_showAdOption) ...[
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

              // NORMAL TEKRAR DENE
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
                  child: const Text(
                    'ÇIKIŞ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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
    setState(() {
      _score = 0;
      _questionsAnswered = 0;
      _lives = 3;
      _combo = 0;
      _maxCombo = 0;
      _level = 1;
      _remainingAds = 3; // REKLAM HAKLARI SIFIRLANIR
      _totalAdsWatched = 0;
      _showAdOption = true;
      _isAnswered = false;
      _selectedAnswer = null;
      _isGameOver = false;
      _gamePaused = false;
      _generateQuestion();
    });
    _startTimer();
  }

  void _showExitConfirmation() {
    _timer?.cancel();
    _gamePaused = true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
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
              const Text(
                '⚠️',
                style: TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Oyundan Çıkılsın Mı?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'İlerleme kaydedilmeyecek.',
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
                      onPressed: () {
                        setState(() {
                          _gamePaused = false;
                        });
                        _startTimer();
                        Navigator.pop(context);
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
                        'HAYIR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'EVET',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              // Üst bar - CANLAR SAĞDA
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Geri butonu
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

                    const SizedBox(width: 12),

                    // Seviye
                    AnimatedBuilder(
                      animation: _levelUpAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _levelUpAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Seviye $_level',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Puan
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.orange.shade600],
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
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_score',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // CANLAR - SAĞ TARAFTA (3 KALP)
                    ScaleTransition(
                      scale: _heartAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(
                              3,
                                  (index) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  index < _lives
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: index < _lives
                                      ? Colors.red.shade400
                                      : Colors.white.withOpacity(0.3),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_lives/3',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
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
                          margin: const EdgeInsets.only(bottom: 20, top: 10),
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
                                'COMBO x$_combo',
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

              if (_combo < 3) const SizedBox(height: 30),

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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final isLowTime = _timeLeft <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
            margin: const EdgeInsets.only(bottom: 8),
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

          const SizedBox(height: 8),

          // Soru
          Row(
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
                    _isCorrect ? 'DOĞRU!' : 'YANLIŞ!',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildOptionButton(_currentQuestion.options[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(_currentQuestion.options[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildOptionButton(_currentQuestion.options[2])),
              const SizedBox(width: 12),
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
    Color textColor = Colors.white;

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
      bgColor = Colors.white.withOpacity(0.2);
      borderColor = Colors.white.withOpacity(0.5);
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: (_isAnswered || _isGameOver || _gamePaused || _lives <= 0)
          ? null
          : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$option',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              shadows: [
                const Shadow(
                  blurRadius: 3,
                  color: Colors.black26,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
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