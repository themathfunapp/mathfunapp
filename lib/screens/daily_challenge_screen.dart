import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/game_mechanics_service.dart';
import '../services/ad_service.dart';
import '../models/game_mechanics.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/game_exit_confirm_dialog.dart';

/// Günlük Meydan Okuma Ekranı - 5 CAN SİSTEMİ (GameMechanicsService ile profil senkron)
class DailyChallengeScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DailyChallengeScreen({super.key, required this.onBack});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with TickerProviderStateMixin {
  // Oyun durumu
  bool _isPlaying = false;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  bool _isAnswered = false;
  int? _selectedAnswer;
  bool _isCorrect = false;

  // CAN SİSTEMİ - GameMechanicsService ile profil senkron (5 can)
  bool _gameOver = false;

  // Soru
  late _ChallengeQuestion _currentQuestion;
  List<_ChallengeQuestion> _questions = [];

  // Zamanlayıcı
  Timer? _timer;
  int _timeLeft = 0;

  // Combo
  int _combo = 0;
  int _maxCombo = 0;

  // Animasyonlar
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sallanma animasyonu (can kaybı için)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startChallenge(DailyChallenge challenge) {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.get('no_lives_play')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _generateQuestions(challenge);
    setState(() {
      _isPlaying = true;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _gameOver = false;
      _combo = 0;
      _maxCombo = 0;
      _timeLeft = challenge.timeLimit;
      _currentQuestion = _questions[0];
      _isAnswered = false;
      _selectedAnswer = null;
    });
    _startTimer();
  }

  // KARIŞIK SORU ÜRETİCİ - Toplama, Çıkarma, Çarpma, Bölme
  void _generateQuestions(DailyChallenge challenge) {
    _questions = [];
    final random = math.Random();
    final allTopics = ['addition', 'subtraction', 'multiplication', 'division'];

    for (int i = 0; i < challenge.targetCorrect + 5; i++) {
      // Karışık topic - rastgele seç
      final topic = allTopics[random.nextInt(allTopics.length)];
      _questions.add(_generateQuestion(topic, challenge.difficulty, random));
    }
  }

  _ChallengeQuestion _generateQuestion(
      String topic,
      String difficulty,
      math.Random random,
      ) {
    int num1, num2, answer;
    String operator;
    int maxNum;

    switch (difficulty) {
      case 'easy':
        maxNum = 10;
        break;
      case 'medium':
        maxNum = 20;
        break;
      case 'hard':
        maxNum = 50;
        break;
      default:
        maxNum = 10;
    }

    switch (topic) {
      case 'addition':
        operator = '+';
        num1 = random.nextInt(maxNum) + 1;
        num2 = random.nextInt(maxNum) + 1;
        answer = num1 + num2;
        break;
      case 'subtraction':
        operator = '-';
        num1 = random.nextInt(maxNum) + 1;
        num2 = random.nextInt(num1) + 1;
        answer = num1 - num2;
        break;
      case 'multiplication':
        operator = '×';
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        answer = num1 * num2;
        break;
      case 'division':
        operator = '÷';
        num2 = random.nextInt(9) + 1;
        answer = random.nextInt(10) + 1;
        num1 = num2 * answer;
        break;
      default:
        operator = '+';
        num1 = random.nextInt(maxNum) + 1;
        num2 = random.nextInt(maxNum) + 1;
        answer = num1 + num2;
    }

    // Seçenekler oluştur
    List<int> options = [answer];
    while (options.length < 4) {
      int wrong = answer + random.nextInt(10) - 5;
      if (wrong > 0 && wrong != answer && !options.contains(wrong)) {
        options.add(wrong);
      }
    }
    options.shuffle();

    return _ChallengeQuestion(
      num1: num1,
      num2: num2,
      operator: operator,
      correctAnswer: answer,
      options: options,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_gameOver) {
        setState(() {
          _timeLeft--;
        });
      } else if (_timeLeft == 0) {
        _endChallenge();
      }
    });
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _gameOver) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = answer == _currentQuestion.correctAnswer;
    });

    if (_isCorrect) {
      // DOĞRU CEVAP
      _correctAnswers++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;

      // Her doğru cevap 10 puan
      _score += 10;
    } else {
      // YANLIŞ CEVAP - 1 CAN GİDER (GameMechanicsService - profil senkron)
      _wrongAnswers++;
      _combo = 0;
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();

      // Sallanma animasyonu
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });

      // CAN BİTTİ Mİ?
      if (mechanicsService.currentLives <= 0) {
        _gameOver = true;
        _timer?.cancel();
        _showGameOverDialog();
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_gameOver) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex];
        _isAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      _endChallenge();
    }
  }

  void _endChallenge() {
    _timer?.cancel();

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    mechanicsService.completeChallenge(_score, _correctAnswers);

    _showResultsDialog();
  }

  // OYUN BİTTİ DİYALOĞU - REKLAM İLE CAN ALMA BUTONU
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
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
                    '$_correctAnswers ${loc.get('correct')}, $_wrongAnswers ${loc.get('wrong')}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // REKLAM İLE CAN ALMA BUTONU (ŞİMDİLİK BASİT)
                  Container(
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            loc.get('watch_ad_continue'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // NORMAL TEKRAR DENE
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
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
                ],
              );
            },
          ),
        ),
        ),
      ),
    );
  }

  // REKLAM İLE CAN ALMA - GameMechanicsService ile profil senkron
  void _reviveWithAd() {
    final adService = AdService();
    adService.watchAdForLife(
      onLifeEarned: () {
        if (mounted) {
          final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
          mechanicsService.earnLifeFromAd();
          setState(() {
            _gameOver = false;
            _isAnswered = false;
            _selectedAnswer = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎬 Reklam izlendi! +1 can kazandın!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          _startTimer();
        }
      },
      onAdClosed: () {
        if (mounted) {
          final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
          if (mechanicsService.currentLives <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reklam izlenemedi. Tekrar deneyin.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  void _showResultsDialog() {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final challenge = mechanicsService.todayChallenge;

    final isSuccess = _correctAnswers >= (challenge?.targetCorrect ?? 0) &&
        _score >= (challenge?.targetScore ?? 0);

    // Her 3 oyunda bir geçiş reklamı göster (Premium değilse)
    final adService = AdService();
    adService.showInterstitialAd();

    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuccess
                    ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
                    : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSuccess ? '🎉 ${loc.get('challenge_success')} 🎉' : '💪 ${loc.get('challenge_try_again')}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Sonuçlar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildResultRow('⭐ ${loc.get('score')}', '$_score'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('✅ ${loc.get('correct')}', '$_correctAnswers'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('❌ ${loc.get('wrong')}', '$_wrongAnswers'),
                    const Divider(color: Colors.white24),
                    _buildResultRow('🔥 ${loc.get('max_combo')}', '$_maxCombo'),
                  ],
                ),
              ),

              if (isSuccess && challenge != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '+${challenge.rewardCoins} ${loc.get('money_market_currency')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onBack();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  loc.get('ok'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
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

  void _showExitConfirmation() {
    GameExitConfirmDialog.show(
      context,
      themeColor: Colors.orange.shade400,
      onStay: () {},
      onExit: () {
        _timer?.cancel();
        widget.onBack();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mechanicsService = Provider.of<GameMechanicsService>(context);
    final challenge = mechanicsService.todayChallenge;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: _isPlaying
              ? _buildPlayingView()
              : _buildChallengeInfoView(challenge),
        ),
      ),
    );
  }

  Widget _buildChallengeInfoView(DailyChallenge? challenge) {
    if (challenge == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Yükleniyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Üst bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Builder(
            builder: (context) {
              final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
              final loc = AppLocalizations(localeProvider.locale);
              final title = _getChallengeTitle(loc, challenge.difficulty);
              final description = loc.get('challenge_description_format')
                  .replaceAll('{count}', '${challenge.targetCorrect}')
                  .replaceAll('{minutes}', '${challenge.timeLimit ~/ 60}');
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Başlık
                    Text(
                      '🎯 ${loc.get('daily_task')} 🎯',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Challenge kartı
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Hedefler
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTargetItem(
                                '⏱️',
                                '${challenge.timeLimit ~/ 60}:${(challenge.timeLimit % 60).toString().padLeft(2, '0')}',
                                loc.get('duration'),
                              ),
                              _buildTargetItem(
                                '✅',
                                '${challenge.targetCorrect}',
                                loc.get('correct'),
                              ),
                              _buildTargetItem(
                                '⭐',
                                '${challenge.targetScore}',
                                loc.get('score'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Ödüller
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🏆 ${loc.get('reward')}: ',
                                    style: const TextStyle(color: Colors.white)),
                            const Text('🪙', style: TextStyle(fontSize: 18)),
                            Text(
                              ' ${challenge.rewardCoins}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text('⭐', style: TextStyle(fontSize: 18)),
                            Text(
                              ' ${challenge.rewardXp} ${loc.get('xp')}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (challenge.isCompleted) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                loc.get('challenge_completed'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Başla butonu
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: GestureDetector(
                    onTap: () => _startChallenge(challenge),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        challenge.isCompleted ? loc.get('play_again_action') : loc.get('start_exclamation'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
            },
          ),
        ),
      ],
    );
  }

  String _getChallengeTitle(AppLocalizations loc, String difficulty) {
    switch (difficulty) {
      case 'easy':
        return loc.get('challenge_easy_title');
      case 'medium':
        return loc.get('challenge_medium_title');
      case 'hard':
        return loc.get('challenge_hard_title');
      default:
        return loc.get('challenge_default_title');
    }
  }

  Widget _buildTargetItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // OYUN EKRANI - CAN GÖSTERGESİ EKLENDİ
  Widget _buildPlayingView() {
    final isLowTime = _timeLeft <= 30;
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);

    return Column(
      children: [
        // Üst bar - CANLAR EKLENDİ
        Container(
          margin: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              // Geri butonu
              GestureDetector(
                onTap: _showExitConfirmation,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
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

              // Puan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
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

              const SizedBox(width: 12),

              // CANLAR - 5 KALP (GameMechanicsService ile profil senkron)
              Consumer<GameMechanicsService>(
                builder: (context, mechanicsService, _) {
                  final lives = mechanicsService.currentLives;
                  final maxLives = mechanicsService.maxLives;
                  return AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Row(
                          children: List.generate(
                            maxLives,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Icon(
                                index < lives
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: index < lives
                                    ? Colors.red
                                    : Colors.white.withOpacity(0.5),
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Combo göstergesi
        if (_combo >= 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.red],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🔥 ${loc.get('combo_format').replaceAll('{0}', '$_combo')}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

        const SizedBox(height: 30),

        // Soru
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
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
                            '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
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
                const Text('🎯', style: TextStyle(fontSize: 28)),
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
                  Text(
                    _isCorrect ? '✅' : '❌',
                    style: const TextStyle(fontSize: 28),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Seçenekler - ekran genişliğinin %80'i ile sınırlandırıldı
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
            ),
          ),
        ),
      ],
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
      onTap: _isAnswered || Provider.of<GameMechanicsService>(context, listen: false).currentLives <= 0 ? null : () => _checkAnswer(option),
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
}

class _ChallengeQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;

  _ChallengeQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
  });
}