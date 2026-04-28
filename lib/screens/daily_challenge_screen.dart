import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../audio/section_soundscape.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
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
  late final AudioService _audio;
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
  bool _sessionReported = false;

  // Animasyonlar
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  /// Oyun içi arka plan / soru alanı için yumuşak döngü animasyonu
  late AnimationController _playfulLoopController;
  late ConfettiController _confettiController;
  /// Yanlış cevapta kısa süreli üzgün emoji katmanı
  String? _reactionEmoji;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();

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

    _playfulLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Kısa patlama: ardışık doğru cevaplarda üst üste binmesin
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 550));
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _timer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    _playfulLoopController.dispose();
    _confettiController.dispose();
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
    scheduleSectionAmbient(context, SoundscapeTheme.mountain);
    setState(() {
      _isPlaying = true;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _gameOver = false;
      _combo = 0;
      _maxCombo = 0;
      _sessionReported = false;
      _timeLeft = challenge.timeLimit;
      _currentQuestion = _questions[0];
      _isAnswered = false;
      _selectedAnswer = null;
      _reactionEmoji = null;
    });
    _confettiController.stop();
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

    final wasCorrect = answer == _currentQuestion.correctAnswer;
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrect = wasCorrect;
      _reactionEmoji = wasCorrect ? null : '🥺';
    });

    if (_isCorrect) {
      // DOĞRU CEVAP
      _correctAnswers++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;

      // Her doğru cevap 10 puan
      _score += 10;
      _audio.playSound(SoundEffect.characterHappy);
      _confettiController.stop();
      _confettiController.play();
    } else {
      // YANLIŞ CEVAP - 1 CAN GİDER (GameMechanicsService - profil senkron)
      _wrongAnswers++;
      _combo = 0;
      _audio.playSound(SoundEffect.characterSad);
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
        _reactionEmoji = null;
      });
      _confettiController.stop();
    } else {
      _endChallenge();
    }
  }

  void _endChallenge() {
    _timer?.cancel();
    _confettiController.stop();

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final challenge = mechanicsService.todayChallenge;
    final success = challenge != null &&
        _score >= challenge.targetScore &&
        _correctAnswers >= challenge.targetCorrect;
    if ((_correctAnswers + _wrongAnswers) > 0) {
      final badges = success ? 2 : 1;
      mechanicsService.grantAdventurePassBadges(
        mode: 'daily',
        earnedBadges: badges,
      );
    }
    mechanicsService.completeChallenge(_score, _correctAnswers);

    _showResultsDialog();
  }

  void _reportDailyChallengeSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final total = _correctAnswers + _wrongAnswers;
    final q = total < 1 ? 1 : total;
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        score: _score,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: _maxCombo,
      );
    } catch (e) {
      debugPrint('DailyChallenge report error: $e');
    }
  }

  // OYUN BİTTİ DİYALOĞU - REKLAM İLE CAN ALMA BUTONU
  void _showGameOverDialog() {
    _reportDailyChallengeSession();
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
    _reportDailyChallengeSession();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPlaying
                ? const [
                    Color(0xFF7C4DFF),
                    Color(0xFF9575FF),
                    Color(0xFFE879F9),
                  ]
                : const [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isPlaying)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _playfulLoopController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _DailySparklePainter(phase: _playfulLoopController.value),
                      );
                    },
                  ),
                ),
              ),
            if (_isPlaying)
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
                            confettiController: _confettiController,
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
              child: _isPlaying
                  ? _buildPlayingView()
                  : _buildChallengeInfoView(challenge),
            ),
          ],
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
        // Üst bar - CANLAR EKLENDİ
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    size: 22,
                  ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 17),
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
                        const SizedBox(width: 8),
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      maxLives,
                                      (index) => Padding(
                                        padding: const EdgeInsets.only(left: 2, right: 2),
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
                                  ),
                                );
                              },
                            );
                          },
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
        if (_combo >= 2)
          AnimatedBuilder(
            animation: _playfulLoopController,
            builder: (context, _) {
              final s = 1.0 + 0.05 * math.sin(_playfulLoopController.value * math.pi * 2);
              return Transform.scale(
                scale: s,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.45),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
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
              );
            },
          ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, expandedConstraints) {
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _playfulLoopController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _DailyPlaygroundPainter(
                                phase: _playfulLoopController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    height: math.min(140, expandedConstraints.maxHeight * 0.22),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _playfulLoopController,
                        builder: (context, _) {
                          const icons = ['🧮', '🎈', '✨', '📐', '🌟'];
                          final t = _playfulLoopController.value * math.pi * 2;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(icons.length, (i) {
                              final dy = 10 * math.sin(t + i * 1.1);
                              final sc = 1.0 + 0.08 * math.sin(t * 1.2 + i * 0.9);
                              return Transform.translate(
                                offset: Offset(0, dy),
                                child: Transform.scale(
                                  scale: sc,
                                  child: Opacity(
                                    opacity: 0.45 + 0.25 * (0.5 + 0.5 * math.sin(t + i)),
                                    child: Text(
                                      icons[i],
                                      style: TextStyle(
                                        fontSize: 28 + (i % 3) * 6,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AnimatedBuilder(
                            animation: _playfulLoopController,
                            builder: (context, _) {
                              final bounce = 1.0 + 0.02 * math.sin(_playfulLoopController.value * math.pi * 2);
                              return Transform.scale(
                                scale: bounce,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD54F),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            loc.get('daily_quest_today_chip'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF5D4037),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          loc.get('daily_challenge'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Soru (dar ekranda yatay taşma yok)
                        AnimatedBuilder(
                          animation: _playfulLoopController,
                          builder: (context, _) {
                            final glow = 0.28 + 0.22 * math.sin(_playfulLoopController.value * math.pi * 2);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              width: double.infinity,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2), Color(0xFFAB47BC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD54F).withOpacity(glow),
                                      blurRadius: 22,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF7E57C2).withOpacity(0.45),
                                      blurRadius: 16,
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
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: isLowTime ? Colors.red : Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isLowTime ? Colors.red.shade300 : Colors.white.withOpacity(0.5),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
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
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedBuilder(
                                      animation: _playfulLoopController,
                                      builder: (context, _) {
                                        final a = 0.08 * math.sin(_playfulLoopController.value * math.pi * 2 + 0.5);
                                        return Transform.rotate(
                                          angle: a,
                                          child: const Text('🎯', style: TextStyle(fontSize: 26)),
                                        );
                                      },
                                    ),
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
                                      Text(
                                        _isCorrect ? '✅' : '❌',
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Seçenekler (çerçevesiz, düzenli aralık)
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
        ),
        if (_reactionEmoji != null)
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
        height: 58,
        decoration: BoxDecoration(
          gradient: _isAnswered
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xE6FFFFFF),
                    Color(0x66E1BEE7),
                    Color(0x99B39DDB),
                  ],
                ),
          color: _isAnswered ? bgColor : null,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: (_isAnswered ? Colors.black : const Color(0xFF7E57C2)).withOpacity(_isAnswered ? 0.2 : 0.28),
              blurRadius: _isAnswered ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$option',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _isAnswered ? Colors.white : const Color(0xFF4A148C),
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withOpacity(_isAnswered ? 0.26 : 0.12),
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Oyun alanının alt yarısını dolduran yumuşak tepeler, bulutlar ve hareketli matematik süsleri.
class _DailyPlaygroundPainter extends CustomPainter {
  _DailyPlaygroundPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p2 = phase * math.pi * 2;

    final aurora = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(0, 0.4),
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color(0x28FFECB3),
          Color(0x38E1BEE7),
          Color(0x30CE93D8),
        ],
        stops: [0.0, 0.38, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.32, w, h * 0.68));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.32, w, h * 0.68), aurora);

    // Tepeler (alt bölgeyi doldurur)
    final hill1 = Path()
      ..moveTo(0, h * 0.5)
      ..quadraticBezierTo(w * 0.22, h * (0.46 + 0.02 * math.sin(p2)), w * 0.45, h * 0.52)
      ..quadraticBezierTo(w * 0.68, h * (0.58 + 0.015 * math.cos(p2 * 1.1)), w, h * 0.48)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill1,
      Paint()..color = const Color(0x2EFFFFFF),
    );
    final hill2 = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * (0.56 + 0.025 * math.cos(p2 * 0.9)), w * 0.7, h * 0.64)
      ..quadraticBezierTo(w * 0.9, h * 0.68, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill2,
      Paint()..color = const Color(0x22F8BBD0),
    );

    _drawCloud(canvas, Offset(w * 0.1 + 6 * math.sin(p2), h * 0.56), 1.0);
    _drawCloud(canvas, Offset(w * 0.78 + 8 * math.cos(p2 * 0.85), h * 0.52), 1.12);
    _drawCloud(canvas, Offset(w * 0.42 + 5 * math.sin(p2 * 1.2), h * 0.74), 1.25);

    for (var i = 0; i < 16; i++) {
      final t = p2 + i * 0.48;
      final bx = w * (0.04 + (i * 0.059) % 0.92) + 8 * math.sin(t);
      final drift = (phase * 0.35 + i * 0.08) % 1.0;
      final by = h * (0.38 + 0.58 * drift);
      final br = 3.0 + (i % 5) * 1.8;
      final o = 0.1 + 0.12 * (0.5 + 0.5 * math.sin(t * 2));
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()..color = Colors.white.withOpacity(o),
      );
    }

    const symbols = ['+', '−', '×', '÷', '=', '★', '✨', '123'];
    for (var i = 0; i < symbols.length; i++) {
      final t = p2 + i * 0.85;
      final x = w * (0.08 + (i % 4) * 0.28) + 16 * math.sin(t);
      final y = h * (0.45 + (i % 3) * 0.12) + 14 * math.cos(t * 1.05);
      _paintGlyph(
        canvas,
        symbols[i],
        x,
        y,
        20.0 + (i % 3) * 6,
        Colors.white.withOpacity(0.16 + 0.14 * (0.5 + 0.5 * math.sin(t))),
      );
    }

    for (var i = 0; i < 7; i++) {
      final t = p2 * 1.4 + i;
      final cx = w * (0.12 + i * 0.13) + 10 * math.sin(t);
      final cy = h * (0.66 + 0.06 * math.sin(t * 1.2));
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 26),
        const Radius.circular(13),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFF80AB),
            const Color(0xFFB388FF),
            (i / 7).clamp(0.0, 1.0),
          )!
              .withOpacity(0.14),
      );
    }
  }

  static void _drawCloud(Canvas canvas, Offset c, double scale) {
    final puff = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(c.translate(-18 * scale, 0), 24 * scale, puff);
    canvas.drawCircle(c.translate(6 * scale, -5 * scale), 28 * scale, puff);
    canvas.drawCircle(c.translate(30 * scale, 2 * scale), 22 * scale, puff);
  }

  static void _paintGlyph(Canvas canvas, String text, double cx, double cy, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DailyPlaygroundPainter oldDelegate) => oldDelegate.phase != phase;
}

class _DailySparklePainter extends CustomPainter {
  _DailySparklePainter({required this.phase});

  final double phase;

  static final List<double> _sx = [0.08, 0.22, 0.38, 0.52, 0.68, 0.82, 0.92, 0.14, 0.44, 0.74, 0.3, 0.6];
  static final List<double> _sy = [0.12, 0.28, 0.48, 0.18, 0.62, 0.38, 0.78, 0.52, 0.88, 0.68, 0.22, 0.92];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _sx.length; i++) {
      final o = 0.04 + 0.1 * (0.5 + 0.5 * math.sin(phase * math.pi * 2 + i * 0.75));
      paint.color = Colors.white.withOpacity(o);
      final r = 1.4 + (i % 4) * 0.65;
      canvas.drawCircle(Offset(_sx[i] * size.width, _sy[i] * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DailySparklePainter oldDelegate) => oldDelegate.phase != phase;
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