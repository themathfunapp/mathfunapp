import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../audio/section_soundscape.dart';
import '../models/pattern_completion_model.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../models/daily_reward.dart' show TaskType;
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../widgets/child_exit_dialog.dart';

class PatternCompletionScreen extends StatefulWidget {
  final String ageGroup;

  const PatternCompletionScreen({Key? key, required this.ageGroup}) : super(key: key);

  @override
  State<PatternCompletionScreen> createState() => _PatternCompletionScreenState();
}

class _PatternCompletionScreenState extends State<PatternCompletionScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  static const String _highScoreKey = 'pattern_completion_high_score';
  static const String _completedSectionsKey = 'pattern_completion_sections';

  bool _showLevelSelect = true;
  Set<int> _completedSections = {};
  List<PatternModel> _allPatterns = [];
  int _currentSection = 1; // 1-100 (bölüm 1-10, her bölümde 10 seviye)
  int _score = 0;
  int _highScore = 0;
  List<List<int>> _userGrid = [];
  List<int> _emptyIndices = [];
  PatternModel? _currentPattern;
  int? _shakeIndex;
  int? _correctIndex;
  int? _selectedSymbol; // 11-84 (şekil*10+renk), null = no selection
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;
  bool _sessionReported = false;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;

  final _colorMap = [
    Colors.transparent,
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.amber.shade400,
  ];

  /// Şekil 1-8: daire, kare, üçgen, elips, yıldız, elmas, artı, çiçek
  static Widget _shapeWidget(int shape, double size, Color color) {
    switch (shape) {
      case 1: return Icon(Icons.circle, color: color, size: size);
      case 2: return Icon(Icons.square, color: color, size: size);
      case 3: return Icon(Icons.change_history, color: color, size: size);
      case 4: return Icon(Icons.egg, color: color, size: size);
      case 5: return Icon(Icons.star, color: color, size: size);
      case 6: return Icon(Icons.diamond, color: color, size: size);
      case 7: return Icon(Icons.add, color: color, size: size);
      case 8: return Icon(Icons.local_florist, color: color, size: size);
      default: return Icon(Icons.circle, color: color, size: size);
    }
  }

  Color _colorFromVal(int val) {
    if (val < 11) return Colors.grey;
    final c = val % 10;
    return _colorMap[c.clamp(0, 4)];
  }

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio.playMenuAmbientLoop();
    });
    _allPatterns = PatternGenerator.generateAllPatterns();
    _loadHighScore();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
      _completedSections = (prefs.getStringList(_completedSectionsKey) ?? []).map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
    });
  }

  Future<void> _saveCompletedSection(int section) async {
    _completedSections.add(section);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedSectionsKey, _completedSections.map((e) => e.toString()).toList());
  }

  Future<void> _saveHighScore(int s) async {
    if (s > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, s);
      setState(() => _highScore = s);
    }
  }

  void _loadSection(int section) {
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.get('no_lives_play')), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
      setState(() {
        _showLevelSelect = true;
      });
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _audio.playMenuAmbientLoop();
      });
      return;
    }
    final sectionPatterns = _allPatterns.where((p) => p.section == section).toList();
    if (sectionPatterns.isEmpty && section <= 100) {
      _loadSection(section + 1);
      return;
    }
    if (sectionPatterns.isEmpty) return;
    final p = sectionPatterns[math.Random().nextInt(sectionPatterns.length)];
    final cols = p.cols;
    setState(() {
      _currentSection = section;
      _currentPattern = p;
      _userGrid = p.matrix.map((r) => r.map((c) => c).toList()).toList();
      _emptyIndices = List<int>.from(p.emptyIndices);
      for (final i in _emptyIndices) _userGrid[i ~/ cols][i % cols] = 0;
      _shakeIndex = null;
      _correctIndex = null;
    });
  }

  void _showColorSelectHint() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => const _ColorSelectHintOverlay(),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 1), () {
      try { entry.remove(); } catch (_) {}
    });
  }

  void _onCellTap(int index) {
    if (_currentPattern == null || !_emptyIndices.contains(index)) return;
    final cols = _currentPattern!.cols;
    final row = index ~/ cols, col = index % cols;
    final correctVal = _currentPattern!.matrix[row][col];

    // Şekil seçilmediyse veya yanlış şekil - can kaybı
    if (_selectedSymbol == null) {
      _showColorSelectHint();
      return;
    }
    if (_selectedSymbol != correctVal) {
      _onWrongTap(index);
      return;
    }

    _audio.playAnswerFeedback(true);
    setState(() {
      _sessCorrect++;
      _runStreak++;
      if (_runStreak > _bestStreak) _bestStreak = _runStreak;
      _userGrid[row][col] = correctVal;
      _emptyIndices.remove(index);
      _selectedSymbol = null;
    });

    if (_emptyIndices.isEmpty) {
      _onLevelComplete();
    } else {
      setState(() => _correctIndex = index);
      Future.delayed(const Duration(milliseconds: 300), () => setState(() => _correctIndex = null));
    }
  }

  void _onLevelComplete() {
    final levelInBolum = ((_currentSection - 1) % 10) + 1;
    final bolumComplete = levelInBolum == 10;
    const int points = 10;
    if (bolumComplete) {
      setState(() => _score += points);
      _saveHighScore(_score);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Builder(
            builder: (ctx) {
              final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
              return Text('🎉 ${loc.get('section_completed')} +$points ${loc.score}', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold));
            },
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    _saveCompletedSection(_currentSection);
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _loadSection(_currentSection + 1);
    });
  }

  void _onWrongTap(int index) {
    _audio.playAnswerFeedback(false);
    setState(() {
      _sessWrong++;
      _runStreak = 0;
      _shakeIndex = index;
      _selectedSymbol = null;
    });
    _shakeController.forward(from: 0);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    mechanicsService.onWrongAnswer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Builder(
          builder: (ctx) => Text('❌ ${AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale).get('wrong')}!', style: GoogleFonts.quicksand()),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _shakeIndex = null));
    if (!mechanicsService.hasLives) _gameOver();
  }

  void _reportPatternSession() {
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
      debugPrint('PatternCompletion report error: $e');
    }
  }

  void _gameOver() {
    _reportPatternSession();
    _saveHighScore(_score);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);

    // Brain games: completion reward (base 2 + streak-based bonus up to 6)
    final bonus = (_bestStreak ~/ 2).clamp(0, 6);
    // ignore: discarded_futures
    mechanicsService.grantBrainGameCompletionCoins(baseCoins: _score > 0 ? 2 : 0, bonusCoins: bonus);
    // ignore: discarded_futures
    rewardService.updateTaskProgress(TaskType.playBrainGame, 1);

    if (!mechanicsService.hasLives) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Text('💔', style: GoogleFonts.quicksand(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(child: Text(loc.get('lives_finished'), style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text('${loc.score}: $_score\n${loc.level}: ${((_currentSection - 1) % 10) + 1}/10', style: GoogleFonts.quicksand()),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: Text(loc.menu, style: GoogleFonts.quicksand(color: Colors.red.shade700))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final firstOfBolum = ((_currentSection - 1) ~/ 10) * 10 + 1;
                _loadSection(firstOfBolum);
                setState(() => _score = 0);
              },
              child: Text(loc.repeat, style: GoogleFonts.quicksand()),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(loc.get('game_over'), style: GoogleFonts.quicksand()),
          content: Text('${loc.score}: $_score\n${loc.level}: ${((_currentSection - 1) % 10) + 1}/10', style: GoogleFonts.quicksand()),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(ctx);
              setState(() => _showLevelSelect = true);
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) _audio.playMenuAmbientLoop();
              });
            }, child: Text(loc.sectionSelect, style: GoogleFonts.quicksand(color: Colors.red.shade700))),
            ElevatedButton(onPressed: () {
              Navigator.pop(ctx);
              final firstOfBolum = ((_currentSection - 1) ~/ 10) * 10 + 1;
              _loadSection(firstOfBolum);
              setState(() => _score = 0);
            }, child: Text(loc.repeat, style: GoogleFonts.quicksand())),
          ],
        ),
      );
    }
  }

  Widget _buildLevelSelect() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.green.shade300, Colors.green.shade100]),
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
                      child: Builder(
                        builder: (ctx) {
                          final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.gamePatternCompletion, style: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              Text('${loc.sectionsInfo} $_highScore', style: GoogleFonts.quicksand(fontSize: 12, color: Colors.green.shade600)),
                            ],
                          );
                        },
                      ),
                    ),
                    Builder(
                      builder: (ctx) {
                        final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                        return IconButton(
                          icon: Icon(Icons.help_outline, color: Colors.green.shade800, size: 28),
                          onPressed: _showHelpDialog,
                          tooltip: loc.howToPlay,
                        );
                      },
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
                    final locked = bolum > 1 && !_completedSections.contains(lastSectionOfPrevBolum);
                    return GestureDetector(
                      onTap: locked ? null : () => _startGame(bolum),
                      child: Container(
                        decoration: BoxDecoration(
                          color: locked ? Colors.grey.shade300 : (completed ? Colors.amber.shade100 : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: locked ? Colors.grey : Colors.green.shade200, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (locked) Icon(Icons.lock, color: Colors.grey.shade600, size: 28)
                            else if (completed) Text('⭐', style: GoogleFonts.quicksand(fontSize: 32))
                            else Builder(
                              builder: (ctx) {
                                final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                                return Text('${loc.section} $bolum', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800));
                              },
                            ),
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

  Widget _buildBackButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.green.shade200, width: 2),
        ),
        child: Center(child: Icon(Icons.keyboard_arrow_left_rounded, color: Colors.green.shade700, size: 30)),
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
            const Text('🧩 '),
            Text(loc.howToPlay, style: GoogleFonts.quicksand()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1️⃣', loc.get('help_pattern_completion_1')),
              _buildHelpItem('2️⃣', loc.get('help_pattern_completion_2')),
              _buildHelpItem('3️⃣', loc.get('help_pattern_completion_3')),
              _buildHelpItem('4️⃣', loc.get('help_pattern_completion_4')),
              _buildHelpItem('5️⃣', loc.get('help_pattern_completion_5')),
              _buildHelpItem('6️⃣', loc.get('help_pattern_completion_6')),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(loc.gotIt, style: GoogleFonts.quicksand(color: Colors.white)),
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

  void _startGame(int bolum) {
    scheduleSectionAmbient(context, SoundscapeTheme.forest);
    setState(() {
      _showLevelSelect = false;
      _score = 0;
      _sessionReported = false;
      _sessCorrect = 0;
      _sessWrong = 0;
      _runStreak = 0;
      _bestStreak = 0;
    });
    final firstSection = (bolum - 1) * 10 + 1;
    _loadSection(firstSection);
  }

  @override
  Widget build(BuildContext context) {
    if (_showLevelSelect) return _buildLevelSelect();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.green.shade300, Colors.green.shade100]),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableW = constraints.maxWidth;
                        final availableH = constraints.maxHeight;
                        final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🧩', style: GoogleFonts.quicksand(fontSize: 24)),
                                    const SizedBox(width: 8),
                                    Builder(
                                      builder: (ctx) => Text(
                                        AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale).gamePatternCompletion,
                                        style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_currentPattern != null) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildPatternSection(loc.get('sample_pattern'), _currentPattern!.matrix, false, availableW / 2)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildPatternSection(loc.get('complete'), _userGrid, true, availableW / 2)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  color: Colors.white.withOpacity(0.95),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(loc.get('select_shape_touch_cell'), style: GoogleFonts.quicksand(fontSize: 12, color: Colors.green.shade700)),
                                      const SizedBox(height: 6),
                                      _buildShapePalette(),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.5,
                numberOfParticles: 25,
                gravity: 0.2,
                colors: const [Colors.green, Colors.yellow, Colors.blue, Colors.orange],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        final hPad = narrow ? 10.0 : 16.0;
        final vPad = narrow ? 10.0 : 16.0;
        final gap = narrow ? 8.0 : 12.0;
        final chipHP = narrow ? 10.0 : 16.0;
        final chipVP = narrow ? 6.0 : 8.0;
        final chipFont = narrow ? 14.0 : 16.0;
        final starFont = narrow ? 15.0 : 18.0;
        final iconSize = narrow ? 19.0 : 22.0;
        final iconPad = narrow ? 3.0 : 4.0;
        final levelText = '${((_currentSection - 1) % 10) + 1}/10';

        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
          child: Row(
            children: [
              _buildBackButton(() {
                ChildExitDialog.show(
                  context,
                  themeColor: Colors.green,
                  onStay: () {},
                  onSectionSelect: () {
                    setState(() => _showLevelSelect = true);
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _audio.playMenuAmbientLoop();
                    });
                  },
                  onExit: () => Navigator.pop(context),
                );
              }),
              SizedBox(width: gap),
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
                          padding: EdgeInsets.symmetric(horizontal: chipHP, vertical: chipVP),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                            ],
                          ),
                          child: Text(
                            levelText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              fontSize: chipFont,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        SizedBox(width: narrow ? 6 : 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: chipHP, vertical: chipVP),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('⭐', style: GoogleFonts.quicksand(fontSize: starFont)),
                              SizedBox(width: narrow ? 4 : 6),
                              Text(
                                '$_score',
                                style: GoogleFonts.quicksand(
                                  fontSize: starFont,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: narrow ? 6 : 12),
                        Consumer<GameMechanicsService>(
                          builder: (context, mechanicsService, _) {
                            final lives = mechanicsService.currentLives;
                            final maxLives = mechanicsService.maxLives;
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: narrow ? 8 : 10,
                                vertical: narrow ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 6),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  maxLives,
                                  (i) => Padding(
                                    padding: EdgeInsets.only(right: iconPad),
                                    child: Icon(
                                      Icons.extension,
                                      color: i < lives
                                          ? Colors.green.shade600
                                          : Colors.grey.shade300,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧩', style: GoogleFonts.quicksand(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Builder(
              builder: (ctx) {
                final loc = AppLocalizations(
                  Provider.of<LocaleProvider>(ctx, listen: false).locale,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.gamePatternCompletion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      loc.get('help_pattern_completion_2'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternSection(String title, List<List<int>> grid, bool interactive, [double? maxWidth]) {
    if (_currentPattern == null) return const SizedBox.shrink();
    final rows = _currentPattern!.rows;
    final cols = _currentPattern!.cols;
    final maxW = maxWidth ?? (MediaQuery.of(context).size.width - 80);
    final cellSize = (maxW / cols - 8).clamp(24.0, 60.0);
    final gridW = math.min(maxW, cellSize * cols + 6 * (cols - 1));
    final gridH = cellSize * rows + 6 * (rows - 1);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
          const SizedBox(height: 8),
          SizedBox(
            width: gridW,
            height: gridH,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: rows * cols,
              itemBuilder: (context, i) {
                final row = i ~/ cols, col = i % cols;
                final val = grid[row][col];
                final isEmpty = val < 11 || val > 84;
                final isCorrect = _correctIndex == i;
                final isShake = _shakeIndex == i;
                return AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    double dx = 0;
                    if (isShake) dx = 8 * math.sin(_shakeAnimation.value * 4 * math.pi);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                    child: GestureDetector(
                    onTap: interactive && isEmpty && _emptyIndices.contains(i) ? () => _onCellTap(i) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isEmpty ? Colors.grey.shade200 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect ? Colors.green : (isEmpty ? Colors.grey.shade400 : Colors.green.shade200),
                          width: isCorrect ? 3 : 2,
                        ),
                        boxShadow: isCorrect ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: isEmpty ? null : Center(
                        child: _shapeWidget(PatternModel.shapeFromVal(val), (cellSize * 0.6).clamp(20.0, 36.0), _colorFromVal(val)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapePalette() {
    if (_currentPattern == null) return const SizedBox.shrink();
    final symbolsInPattern = <int>{};
    for (final r in _currentPattern!.matrix) {
      for (final c in r) if (c >= 11 && c <= 84) symbolsInPattern.add(c);
    }
    final symbols = symbolsInPattern.toList()..sort();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: symbols.map((sym) => GestureDetector(
        onTap: () => setState(() => _selectedSymbol = _selectedSymbol == sym ? null : sym),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _selectedSymbol == sym ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selectedSymbol == sym ? Colors.green.shade700 : Colors.grey.shade400,
              width: _selectedSymbol == sym ? 4 : 2,
            ),
            boxShadow: _selectedSymbol == sym ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 8)] : null,
          ),
          child: Center(
            child: _shapeWidget(PatternModel.shapeFromVal(sym), 22, _colorFromVal(sym)),
          ),
        ),
      )).toList(),
    );
  }

}

/// Çocuk dostu animasyonlu "Önce şekil seç!" uyarısı
class _ColorSelectHintOverlay extends StatefulWidget {
  const _ColorSelectHintOverlay();

  @override
  State<_ColorSelectHintOverlay> createState() => _ColorSelectHintOverlayState();
}

class _ColorSelectHintOverlayState extends State<_ColorSelectHintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 72,
      right: 72,
      bottom: 180,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (_, value, __) => Transform.scale(
                        scale: value,
                        child: Text('🎨', style: GoogleFonts.quicksand(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Önce şekil seç!',
                      style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
