import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../audio/section_soundscape.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../models/daily_reward.dart' show TaskType;
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../widgets/child_exit_dialog.dart';

enum SimonDifficulty { easy, medium, hard }

enum SimonGameMode { classic, timeAttack, challenge }

class SimonSaysScreen extends StatefulWidget {
  final String ageGroup;

  const SimonSaysScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<SimonSaysScreen> createState() => _SimonSaysScreenState();
}

class _SimonSaysScreenState extends State<SimonSaysScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  // Menu state
  bool _showMenu = true;
  SimonDifficulty _difficulty = SimonDifficulty.medium;
  SimonGameMode _gameMode = SimonGameMode.classic;
  int _highScore = 0;

  // Game state
  int _level = 1;
  int _score = 0;
  List<int> _sequence = [];
  List<int> _playerInput = [];
  bool _isPlaying = false;
  bool _isPlayerTurn = false;
  int _currentFlash = -1;
  int _timeRemaining = 30; // For time attack
  bool _timeAttackActive = false;

  final List<Color> _colors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.amber.shade400,
    Colors.green.shade400,
  ];

  bool _sessionReported = false;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;

  late final math.Random _random = math.Random();
  static const String _highScoreKey = 'simon_says_high_score';

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio.playMenuAmbientLoop();
    });
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
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, score);
      setState(() => _highScore = score);
    }
  }

  int get _initialSteps {
    switch (_difficulty) {
      case SimonDifficulty.easy:
        return 4;
      case SimonDifficulty.medium:
        return 5;
      case SimonDifficulty.hard:
        return 6;
    }
  }

  int get _flashDurationMs {
    if (_gameMode == SimonGameMode.challenge) {
      return (500 + _random.nextInt(1000)); // 500-1500 ms random
    }
    switch (_difficulty) {
      case SimonDifficulty.easy:
        return 1500;
      case SimonDifficulty.medium:
        return 1000;
      case SimonDifficulty.hard:
        return 500;
    }
  }

  int get _gapBetweenFlashesMs {
    switch (_difficulty) {
      case SimonDifficulty.easy:
        return 400;
      case SimonDifficulty.medium:
        return 300;
      case SimonDifficulty.hard:
        return 200;
    }
  }

  void _startGame() {
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
    scheduleSectionAmbient(context, SoundscapeTheme.forest);
    setState(() {
      _showMenu = false;
      _sequence = [];
      _playerInput = [];
      _level = 1;
      _score = 0;
      _timeAttackActive = _gameMode == SimonGameMode.timeAttack;
      _timeRemaining = 30;
      _sessionReported = false;
      _sessCorrect = 0;
      _sessWrong = 0;
      _runStreak = 0;
      _bestStreak = 0;
    });
    _initializeSequence();
  }

  void _initializeSequence() {
    setState(() {
      _sequence = List.generate(_initialSteps, (_) => _random.nextInt(4));
      _playerInput = [];
      _isPlayerTurn = false;
    });
    _playSequence();
    if (_timeAttackActive) _startTimeAttack();
  }

  void _startTimeAttack() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timeAttackActive) return false;
      // Sadece oyuncu sırasındayken süreyi say (dizi gösterilirken sayma)
      if (!_isPlayerTurn || _isPlaying) return true;
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          _timeAttackActive = false;
          _sessWrong++;
          _runStreak = 0;
          _audio.playAnswerFeedback(false);
          _gameOver();
        }
      });
      return _timeAttackActive && _timeRemaining > 0;
    });
  }

  void _addToSequence() {
    setState(() {
      _sequence.add(_random.nextInt(4));
      _playerInput = [];
      _isPlayerTurn = false;
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() => _isPlaying = true);

    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      await _flashButton(_sequence[i]);
      await Future.delayed(Duration(milliseconds: _gapBetweenFlashesMs));
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPlayerTurn = true;
      });
    }
  }

  Future<void> _flashButton(int index) async {
    setState(() => _currentFlash = index);
    await Future.delayed(Duration(milliseconds: _flashDurationMs));
    if (mounted) setState(() => _currentFlash = -1);
  }

  void _onButtonTap(int index) {
    if (!_isPlayerTurn || _isPlaying) return;

    setState(() {
      _playerInput.add(index);
      _currentFlash = index;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _currentFlash = -1);
    });

    if (_playerInput.length == _sequence.length) {
      _checkSequence();
    } else {
      if (_playerInput.last != _sequence[_playerInput.length - 1]) {
        _showWrongFeedback();
        _sessWrong++;
        _runStreak = 0;
        _audio.playAnswerFeedback(false);
        final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
        mechanicsService.onWrongAnswer();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _gameOver();
        });
      }
    }
  }

  void _checkSequence() {
    bool correct = true;
    for (int i = 0; i < _sequence.length; i++) {
      if (_playerInput[i] != _sequence[i]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      _sessCorrect++;
      _runStreak++;
      if (_runStreak > _bestStreak) _bestStreak = _runStreak;
      _audio.playAnswerFeedback(true);
      setState(() {
        _score += 10;
        _level++;
      });

      _saveHighScore(_score);
      _showCorrectFeedback();

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _addToSequence();
      });
    } else {
      _showWrongFeedback();
      _sessWrong++;
      _runStreak = 0;
      _audio.playAnswerFeedback(false);
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _gameOver();
      });
    }
  }

  void _reportSimonSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final total = _sessCorrect + _sessWrong;
    final q = total < 1 ? 1 : total;
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
        bestCorrectStreakInSession: _bestStreak,
      );
    } catch (e) {
      debugPrint('SimonSays report error: $e');
    }
  }

  void _showCorrectFeedback() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('✅', style: GoogleFonts.quicksand(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              loc.get('simon_correct_feedback'),
              style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showWrongFeedback() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('😅', style: GoogleFonts.quicksand(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              loc.get('simon_wrong_feedback'),
              style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _gameOver() {
    _reportSimonSession();
    _saveHighScore(_score);
    _timeAttackActive = false;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);

    // Brain games: completion reward (base 2 + level-based bonus up to 6)
    final bonus = ((_level - 1) ~/ 2).clamp(0, 6);
    // ignore: discarded_futures
    mechanicsService.grantBrainGameCompletionCoins(baseCoins: _score > 0 ? 2 : 0, bonusCoins: bonus);
    // Daily tasks
    // ignore: discarded_futures
    rewardService.updateTaskProgress(TaskType.playBrainGame, 1);
    if (_level >= 8) {
      // ignore: discarded_futures
      rewardService.updateTaskProgress(TaskType.simonReachLevel8, 1);
    }

    if (!mechanicsService.hasLives) {
      _showNoLivesDialog(loc);
    } else {
      _showNormalGameOverDialog();
    }
  }

  void _showNoLivesDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text('💔', style: GoogleFonts.quicksand(fontSize: 40)),
            const SizedBox(width: 12),
            Expanded(child: Text(loc.get('lives_finished'), style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.get('level')}: $_level • ${loc.get('score')}: $_score', style: GoogleFonts.quicksand(fontSize: 16)),
            const SizedBox(height: 12),
            Text(loc.get('no_lives_message'), style: GoogleFonts.quicksand(fontSize: 14)),
          ],
        ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() => _showMenu = true);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) _audio.playMenuAmbientLoop();
            });
          },
          child: Text(loc.get('simon_back_to_menu'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.teal)),
        ),
      ],
      ),
    );
  }

  void _showNormalGameOverDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text('🏆', style: GoogleFonts.quicksand(fontSize: 40)),
            const SizedBox(width: 12),
            Text(loc.get('simon_great_job'), style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⭐ ${loc.get('level')}: $_level', style: GoogleFonts.quicksand(fontSize: 18)),
            const SizedBox(height: 4),
            Text('🌟 ${loc.get('score')}: $_score', style: GoogleFonts.quicksand(fontSize: 18)),
            if (_score >= _highScore && _score > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('🎉', style: GoogleFonts.quicksand(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        loc.get('simon_new_record'),
                        style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showMenu = true);
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) _audio.playMenuAmbientLoop();
              });
            },
            child: Text(loc.get('simon_back_to_menu'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.teal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: Text(loc.get('simon_play_again'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text('🎮', style: GoogleFonts.quicksand(fontSize: 32)),
            const SizedBox(width: 12),
            Text(loc.get('how_to_play'), style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1️⃣', loc.get('simon_help_1')),
              _buildHelpItem('2️⃣', loc.get('simon_help_2')),
              _buildHelpItem('3️⃣', loc.get('simon_help_3')),
              _buildHelpItem('4️⃣', loc.get('simon_help_4')),
              _buildHelpItem('5️⃣', loc.get('simon_help_5')),
              const Divider(),
              Text('💡 ${loc.get('simon_help_tip')}', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(loc.get('simon_help_tip_text'), style: GoogleFonts.quicksand(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('got_it'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: GoogleFonts.quicksand(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.quicksand(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.shade200,
              Colors.teal.shade200,
              Colors.green.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: _showMenu ? _buildMenu() : _buildGame(),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMenuTopBar(),
          const SizedBox(height: 24),
          _buildMenuTitle(),
          const SizedBox(height: 24),
          _buildLivesCard(),
          const SizedBox(height: 16),
          _buildHighScoreCard(),
          const SizedBox(height: 24),
          _buildDifficultySection(),
          const SizedBox(height: 20),
          _buildGameModeSection(),
          const SizedBox(height: 32),
          _buildStartButton(),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline, color: Colors.teal),
            label: Text(loc.get('how_to_play'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.teal.shade700)),
          ),
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
            BoxShadow(color: Colors.teal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Colors.teal.shade200, width: 2),
        ),
        child: Center(
          child: Icon(Icons.keyboard_arrow_left_rounded, color: Colors.teal.shade700, size: 30),
        ),
      ),
    );
  }

  Widget _buildMenuTopBar() {
    return Row(
      children: [
        _buildBackButton(() => Navigator.pop(context)),
        const Spacer(),
      ],
    );
  }

  Widget _buildMenuTitle() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text('🎯', style: GoogleFonts.quicksand(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            loc.get('game_simon_says'),
            style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            loc.get('simon_subtitle_menu'),
            style: GoogleFonts.quicksand(fontSize: 15, color: Colors.teal.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLivesCard() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Consumer<GameMechanicsService>(
      builder: (context, mechanicsService, _) {
        final lives = mechanicsService.currentLives;
        final maxLives = mechanicsService.maxLives;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.teal.shade200, width: 2),
            boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎯', style: GoogleFonts.quicksand(fontSize: 22)),
              const SizedBox(width: 12),
              Text('${loc.get('lives')}: ', style: GoogleFonts.quicksand(fontSize: 16, color: Colors.teal.shade800)),
              ...List.generate(
                maxLives,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: i < lives ? Colors.teal.shade400 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: i < lives ? Colors.teal.shade600 : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighScoreCard() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🏆', style: GoogleFonts.quicksand(fontSize: 32)),
          const SizedBox(width: 12),
          Text('${loc.get('simon_best_score')}: ', style: GoogleFonts.quicksand(fontSize: 16, color: Colors.amber.shade900)),
          Text(
            '$_highScore',
            style: GoogleFonts.quicksand(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.get('simon_select_difficulty'), style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDifficultyChip(loc.get('simon_easy'), SimonDifficulty.easy, loc.get('simon_easy_desc')),
              const SizedBox(width: 8),
              _buildDifficultyChip(loc.get('simon_medium'), SimonDifficulty.medium, loc.get('simon_medium_desc')),
              const SizedBox(width: 8),
              _buildDifficultyChip(loc.get('simon_hard'), SimonDifficulty.hard, loc.get('simon_hard_desc')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, SimonDifficulty diff, String subtitle) {
    final selected = _difficulty == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = diff),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.teal.shade400 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.teal.shade600 : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.quicksand(
                  fontSize: 10,
                  color: selected ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeSection() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.get('simon_game_mode'), style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 12),
          _buildModeOption(loc.get('simon_classic'), SimonGameMode.classic, loc.get('simon_classic_desc')),
          const SizedBox(height: 8),
          _buildModeOption(loc.get('simon_time_attack'), SimonGameMode.timeAttack, loc.get('simon_time_attack_desc')),
          const SizedBox(height: 8),
          _buildModeOption(loc.get('simon_challenge'), SimonGameMode.challenge, loc.get('simon_challenge_desc')),
        ],
      ),
    );
  }

  Widget _buildModeOption(String label, SimonGameMode mode, String subtitle) {
    final selected = _gameMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _gameMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.green.shade400 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.green.shade400 : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(subtitle, style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          shadowColor: Colors.green.withOpacity(0.4),
        ),
        child: Text('🎮 ${loc.get('simon_play')}', style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGame() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 20),
        _buildTitle(),
        const Spacer(),
        _buildGameBoard(),
        const Spacer(),
        if (_isPlayerTurn)
          Text(
            '🎯 ${loc.get('simon_your_turn')}',
            style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
          ),
        if (_isPlaying)
          Text(
            '👀 ${loc.get('simon_watch_sequence')}',
            style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTopBar() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildBackButton(() {
            ChildExitDialog.show(
              context,
              themeColor: Colors.teal,
              onStay: () {},
              onSectionSelect: () => setState(() => _showMenu = true),
              onExit: () => Navigator.pop(context),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 6)],
            ),
            child: Text('${loc.get('level')} $_level', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          ),
          const Spacer(),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: i < lives ? Colors.teal.shade400 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: i < lives ? Colors.teal.shade600 : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          if (_timeAttackActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _timeRemaining <= 10 ? Colors.orange.shade400 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: (_timeRemaining <= 10 ? Colors.orange : Colors.teal).withOpacity(0.3), blurRadius: 6)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⏱️', style: GoogleFonts.quicksand(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '$_timeRemaining',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _timeRemaining <= 10 ? Colors.white : Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Text('⭐', style: GoogleFonts.quicksand(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('$_score', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.scale(scale: value, child: child!),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text('🎯', style: GoogleFonts.quicksand(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              loc.get('game_simon_says'),
              style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              loc.get('simon_remember_steps').replaceAll('%1', '$_sequence.length'),
              style: GoogleFonts.quicksand(fontSize: 15, color: Colors.teal.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            bool isFlashing = _currentFlash == index;
            return GestureDetector(
              key: ValueKey('simon-$index-$_currentFlash'),
              onTap: () => _onButtonTap(index),
              child: AnimatedScale(
                scale: isFlashing ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isFlashing
                        ? _colors[index]
                        : _colors[index].withOpacity(0.35),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isFlashing ? Colors.white : Colors.white70,
                      width: isFlashing ? 5 : 3,
                    ),
                    boxShadow: isFlashing
                        ? [
                            BoxShadow(
                              color: _colors[index].withOpacity(0.9),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
