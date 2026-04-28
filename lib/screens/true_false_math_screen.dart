import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../audio/section_soundscape.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../models/daily_reward.dart' show TaskType;
import '../services/game_session_report.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/game_mechanics_service.dart';
import '../widgets/child_exit_dialog.dart';

class TrueFalseMathScreen extends StatefulWidget {
  final String ageGroup;

  const TrueFalseMathScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<TrueFalseMathScreen> createState() => _TrueFalseMathScreenState();
}

class _TrueFalseMathScreenState extends State<TrueFalseMathScreen> {
  late final AudioService _audio;
  static const String _highScoreKey = 'true_false_math_high_score';
  static const String _completedSectionsKey = 'true_false_math_sections';

  bool _showLevelSelect = true;
  Set<int> _completedSections = {};
  int _currentSection = 1; // 1-100 (bölüm 1-10, her bölümde 10 seviye)
  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 25; // saniye per soru
  String _question = '';
  bool _isCorrect = true;
  int _streak = 0;
  bool _sessionReported = false;
  int _sessQuestions = 0;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _bestStreakInSession = 0;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    _loadHighScore();
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
      _completedSections = (prefs.getStringList(_completedSectionsKey) ?? [])
          .map((e) => int.tryParse(e) ?? 0)
          .where((e) => e > 0)
          .toSet();
    });
  }

  Future<void> _saveCompletedSection(int section) async {
    _completedSections.add(section);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _completedSectionsKey, _completedSections.map((e) => e.toString()).toList());
  }

  Future<void> _saveHighScore(int s) async {
    if (s > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, s);
      setState(() => _highScore = s);
    }
  }

  void _startGame(int bolum) {
    scheduleSectionAmbient(context, SoundscapeTheme.forest);
    setState(() {
      _showLevelSelect = false;
      _score = 0;
      _currentSection = (bolum - 1) * 10 + 1;
      _timeLeft = 25;
      _streak = 0;
      _sessionReported = false;
      _sessQuestions = 0;
      _sessCorrect = 0;
      _sessWrong = 0;
      _bestStreakInSession = 0;
    });
    _loadSection(_currentSection);
  }

  void _loadSection(int section) {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.get('no_lives_play')),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    setState(() => _timeLeft = 25);
    _generateQuestion();
    _startTimer();
  }

  void _showNoLivesSnackbar() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.get('no_lives_play')),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        _startTimer();
      } else {
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    _sessQuestions++;
    _sessWrong++;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    mechanicsService.onWrongAnswer();
    _audio.playAnswerFeedback(false);
    setState(() => _streak = 0);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ ${loc.get('fast_math_time_out')}', style: GoogleFonts.quicksand()),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (!mechanicsService.hasLives) {
      _gameOver();
    } else {
      _advanceToNext();
    }
  }

  void _generateQuestion() {
    final random = math.Random();
    int a = random.nextInt(10) + 1;
    int b = random.nextInt(10) + 1;
    
    List<String> operations = ['+', '-', '×', '÷'];
    String op = operations[random.nextInt(operations.length)];
    
    int correctAnswer = 0;
    switch (op) {
      case '+':
        correctAnswer = a + b;
        break;
      case '-':
        correctAnswer = a - b;
        break;
      case '×':
        correctAnswer = a * b;
        break;
      case '÷':
        a = a * b; // Make sure division is clean
        correctAnswer = a ~/ b;
        break;
    }
    
    // Randomly make it wrong
    bool shouldBeCorrect = random.nextBool();
    int displayedAnswer = shouldBeCorrect
        ? correctAnswer
        : correctAnswer + random.nextInt(5) + 1;
    
    setState(() {
      _question = '$a $op $b = $displayedAnswer';
      _isCorrect = shouldBeCorrect;
    });
  }

  void _checkAnswer(bool playerAnswer) {
    if (playerAnswer == _isCorrect) {
      _sessQuestions++;
      _sessCorrect++;
      _audio.playAnswerFeedback(true);
      setState(() => _streak++);
      if (_streak > _bestStreakInSession) {
        _bestStreakInSession = _streak;
      }
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${loc.get('fast_math_correct_streak').replaceAll('%1', '$_streak')}', style: GoogleFonts.quicksand()),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _onLevelComplete();
    } else {
      _sessQuestions++;
      _sessWrong++;
      _audio.playAnswerFeedback(false);
      setState(() => _streak = 0);
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${loc.get('fast_math_wrong')}', style: GoogleFonts.quicksand()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mechanicsService.hasLives) {
        _gameOver();
      } else {
        _advanceToNext();
      }
    }
  }

  void _onLevelComplete() {
    final levelInBolum = ((_currentSection - 1) % 10) + 1;
    final bolumComplete = levelInBolum == 10;
    const int points = 10;
    if (bolumComplete) {
      setState(() => _score += points);
      _saveHighScore(_score);
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${loc.get('fast_math_section_completed').replaceAll('%1', '$points')}',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    _saveCompletedSection(_currentSection);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _advanceToNext();
    });
  }

  void _advanceToNext() {
    if (_currentSection >= 100) {
      setState(() => _showLevelSelect = true);
      return;
    }
    setState(() {
      _currentSection++;
      _timeLeft = 25;
    });
    _generateQuestion();
    _startTimer();
  }

  void _gameOver() {
    _reportTrueFalseSession();
    _saveHighScore(_score);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);

    // Brain games: completion reward (base 2 + correct-streak bonus up to 6)
    final bonus = (_bestStreakInSession ~/ 2).clamp(0, 6);
    // ignore: discarded_futures
    mechanicsService.grantBrainGameCompletionCoins(baseCoins: _score > 0 ? 2 : 0, bonusCoins: bonus);
    // ignore: discarded_futures
    rewardService.updateTaskProgress(TaskType.playBrainGame, 1);

    if (!mechanicsService.hasLives) {
      _showNoLivesDialog(loc);
    } else {
      _showNormalGameOverDialog(loc);
    }
  }

  void _reportTrueFalseSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final q = _sessQuestions.clamp(1, 9999);
    try {
      GameSessionReport.submit(
        context,
        questionsAnswered: q,
        correctAnswers: _sessCorrect,
        wrongAnswers: _sessWrong,
        score: _score,
        averageAnswerTimeSeconds: 5.0,
        fastAnswersCount: 0,
        superFastAnswersCount: 0,
        bestCorrectStreakInSession: _bestStreakInSession,
      );
    } catch (e) {
      debugPrint('TrueFalse report error: $e');
    }
  }

  void _showNoLivesDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade100,
                  Colors.white,
                  Colors.amber.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                    ),
                    child: Text('💔', style: GoogleFonts.quicksand(fontSize: 48)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.get('lives_finished'),
                    style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text('${loc.get('score')}: $_score • ${loc.get('fast_math_streak')}: $_streak', style: GoogleFonts.quicksand(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(loc.get('no_lives_message'), style: GoogleFonts.quicksand(fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _showLevelSelect = true);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.red.shade300, width: 2),
                            ),
                          ),
                          child: Text(loc.get('section_select'), style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reklamsız akış: sadece tekrar dene ve menü
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNormalGameOverDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade100,
                  Colors.white,
                  Colors.amber.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, val, _) => Transform.scale(
                      scale: val,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text('⏰', style: GoogleFonts.quicksand(fontSize: 56)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.get('fast_math_time_finished'),
                    style: GoogleFonts.quicksand(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade200, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('⭐', style: GoogleFonts.quicksand(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              '${loc.get('score')}: $_score',
                              style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🔥', style: GoogleFonts.quicksand(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              '${loc.get('fast_math_streak')}: $_streak',
                              style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _showLevelSelect = true);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.red.shade300, width: 2),
                            ),
                          ),
                          child: Text(
                            loc.get('section_select'),
                            style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final firstOfBolum = ((_currentSection - 1) ~/ 10) * 10 + 1;
                            setState(() {
                              _currentSection = firstOfBolum;
                              _score = 0;
                              _timeLeft = 25;
                              _streak = 0;
                            });
                            _loadSection(_currentSection);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            loc.get('simon_play_again'),
                            style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚡ '),
            Text(loc.get('how_to_play'), style: GoogleFonts.quicksand()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1️⃣', loc.get('help_fast_math_1')),
              _buildHelpItem('2️⃣', loc.get('help_fast_math_2')),
              _buildHelpItem('3️⃣', loc.get('help_fast_math_3')),
              _buildHelpItem('4️⃣', loc.get('help_fast_math_4')),
              _buildHelpItem('5️⃣', loc.get('help_fast_math_5')),
              _buildHelpItem('6️⃣', loc.get('help_fast_math_6')),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('got_it'), style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.quicksand())),
        ],
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Colors.red.shade200, width: 2),
        ),
        child: Center(
          child: Icon(Icons.keyboard_arrow_left_rounded, color: Colors.red.shade700, size: 30),
        ),
      ),
    );
  }

  Widget _buildLevelSelect() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade300, Colors.red.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildBackButton(() => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.get('game_fast_math'),
                              style: GoogleFonts.quicksand(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800)),
                          Text(
                              '${loc.get('sections_info')} $_highScore',
                              style: GoogleFonts.quicksand(
                                  fontSize: 12, color: Colors.red.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.help_outline, color: Colors.red.shade800, size: 28),
                      onPressed: _showHelpDialog,
                      tooltip: loc.get('how_to_play'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 500 ? 5 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, i) {
                    final bolum = i + 1;
                    final lastSectionOfPrevBolum = (bolum - 1) * 10;
                    final lastSectionOfBolum = bolum * 10;
                    final completed = _completedSections.contains(lastSectionOfBolum);
                    final locked = bolum > 1 &&
                        !_completedSections.contains(lastSectionOfPrevBolum);
                    return GestureDetector(
                      onTap: locked ? null : () => _startGame(bolum),
                      child: Container(
                        decoration: BoxDecoration(
                          color: locked
                              ? Colors.grey.shade300
                              : (completed ? Colors.amber.shade100 : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: locked ? Colors.grey : Colors.red.shade200,
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (locked)
                              Icon(Icons.lock,
                                  color: Colors.grey.shade600, size: 28)
                            else if (completed)
                              Text('⭐', style: GoogleFonts.quicksand(fontSize: 32))
                            else
                              Text('${loc.get('section')} $bolum',
                                  style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showLevelSelect) return _buildLevelSelect();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade300,
              Colors.red.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildTimer(),
              const Spacer(),
              _buildQuestionCard(),
              const Spacer(),
              _buildAnswerButtons(),
              const SizedBox(height: 40),
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
          _buildBackButton(() {
            ChildExitDialog.show(
              context,
              themeColor: Colors.red,
              onStay: () {},
              onSectionSelect: () => setState(() => _showLevelSelect = true),
              onExit: () => Navigator.pop(context),
            );
          }),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
            ),
            child: Text(
              '${((_currentSection - 1) % 10) + 1}/10',
              style: GoogleFonts.quicksand(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade800),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '$_score',
                  style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.bolt,
                        color: i < lives ? Colors.amber.shade600 : Colors.grey.shade300,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _timeLeft < 10 ? Colors.red : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: _timeLeft < 10 ? Colors.red : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            '$_timeLeft ${loc.get('fast_math_seconds')}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _timeLeft < 10 ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '⚡',
            style: TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 20),
          Text(
            _question,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            loc.get('fast_math_true_false'),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _checkAnswer(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.get('fast_math_true'),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _checkAnswer(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '✗',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.get('fast_math_false'),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

