import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/ad_service.dart';
import '../services/game_mechanics_service.dart';
import '../widgets/child_exit_dialog.dart';

class FindDifferentScreen extends StatefulWidget {
  final String ageGroup;

  const FindDifferentScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<FindDifferentScreen> createState() => _FindDifferentScreenState();
}

class _FindDifferentScreenState extends State<FindDifferentScreen> {
  static const String _highScoreKey = 'find_different_high_score';
  static const String _completedSectionsKey = 'find_different_sections';

  bool _showLevelSelect = true;
  Set<int> _completedSections = {};
  int _currentSection = 1; // 1-100 (bölüm 1-10, her bölümde 10 seviye)
  int _score = 0;
  int _highScore = 0;
  int _correctIndex = 0;
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
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
    _generateQuestion();
  }

  void _generateQuestion() {
    final random = math.Random();

    List<Map<String, dynamic>> questionTypes = [
      {
        'type': 'numbers',
        'items': ['5', '5', '5', '7', '5', '5'],
        'different': '7',
      },
      {
        'type': 'shapes',
        'items': ['⭐', '⭐', '⭐', '❤️', '⭐', '⭐'],
        'different': '❤️',
      },
      {
        'type': 'operations',
        'items': ['2+2', '1+3', '5-1', '3×2', '8÷2', '0+4'],
        'different': '3×2',
      },
    ];

    var question = questionTypes[random.nextInt(questionTypes.length)];
    _items = List<String>.from(question['items']);
    _items.shuffle();
    _correctIndex = _items.indexOf(question['different']);
    if (mounted) setState(() {});
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
              return Text('🎉 ${loc.get('section_completed')} +$points ${loc.score}',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold));
            },
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    _saveCompletedSection(_currentSection);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _currentSection++);
        if (_currentSection <= 100) {
          _generateQuestion();
        } else {
          setState(() => _showLevelSelect = true);
        }
      }
    });
  }

  void _gameOver() {
    _saveHighScore(_score);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
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
              Expanded(
                  child: Text(loc.get('lives_finished'),
                      style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(
              '${loc.score}: $_score\n${loc.level}: ${((_currentSection - 1) % 10) + 1}/10',
              style: GoogleFonts.quicksand()),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(loc.menu, style: GoogleFonts.quicksand(color: Colors.red.shade700))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                Navigator.pop(ctx);
                _reviveWithAd();
              },
              child: Text(loc.get('watch_ad_gain_life'),
                  style: GoogleFonts.quicksand(fontSize: 11)),
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
          content: Text(
              '${loc.score}: $_score\n${loc.level}: ${((_currentSection - 1) % 10) + 1}/10',
              style: GoogleFonts.quicksand()),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _showLevelSelect = true);
                },
                child: Text(loc.sectionSelect,
                    style: GoogleFonts.quicksand(color: Colors.red.shade700))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final firstOfBolum = ((_currentSection - 1) ~/ 10) * 10 + 1;
                setState(() {
                  _currentSection = firstOfBolum;
                  _score = 0;
                });
                _generateQuestion();
              },
              child: Text(loc.repeat, style: GoogleFonts.quicksand()),
            ),
          ],
        ),
      );
    }
  }

  void _reviveWithAd() {
    AdService().watchAdForLife(
      onLifeEarned: () {
        if (!mounted) return;
        Provider.of<GameMechanicsService>(context, listen: false).earnLifeFromAd();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎬 +1 can!', style: GoogleFonts.quicksand()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        _generateQuestion();
      },
      onAdClosed: () {},
    );
  }

  void _checkAnswer(int index) {
    if (index == _correctIndex) {
      _saveCompletedSection(_currentSection);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Builder(
            builder: (ctx) => Text('✅ ${AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale).get('correct_answer')}!'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      _onLevelComplete();
    } else {
      final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
      mechanicsService.onWrongAnswer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Builder(
            builder: (ctx) {
              final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
              return Text('❌ ${loc.get('wrong')}! ${loc.get('try_again')}!');
            },
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      if (!mechanicsService.hasLives) {
        _gameOver();
      }
    }
  }

  void _startGame(int bolum) {
    setState(() {
      _showLevelSelect = false;
      _score = 0;
      _currentSection = (bolum - 1) * 10 + 1;
    });
    _loadSection(_currentSection);
  }

  void _showHelpDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🔍 '),
            Text(loc.howToPlay, style: GoogleFonts.quicksand()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1️⃣', loc.get('help_find_different_1')),
              _buildHelpItem('2️⃣', loc.get('help_find_different_2')),
              _buildHelpItem('3️⃣', loc.get('help_find_different_3')),
              _buildHelpItem('4️⃣', loc.get('help_find_different_4')),
              _buildHelpItem('5️⃣', loc.get('help_find_different_5')),
              _buildHelpItem('6️⃣', loc.get('help_find_different_6')),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            BoxShadow(
                color: Colors.orange.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        child: Center(
            child: Icon(Icons.keyboard_arrow_left_rounded,
                color: Colors.orange.shade700, size: 30)),
      ),
    );
  }

  Widget _buildLevelSelect() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade300, Colors.orange.shade100],
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
                      child: Builder(
                        builder: (ctx) {
                          final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.gameFindDifferent,
                                  style: GoogleFonts.quicksand(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800)),
                              Text(
                                  '${loc.sectionsInfo} $_highScore',
                              style: GoogleFonts.quicksand(
                                  fontSize: 12, color: Colors.orange.shade600)),
                            ],
                          );
                        },
                      ),
                    ),
                    Builder(
                      builder: (ctx) {
                        final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                        return IconButton(
                          icon: Icon(Icons.help_outline, color: Colors.orange.shade800, size: 28),
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
                    final completed =
                        _completedSections.contains(lastSectionOfBolum);
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
                              color: locked
                                  ? Colors.grey
                                  : Colors.orange.shade200,
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
                              Builder(
                                builder: (ctx) {
                                  final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                                  return Text('${loc.section} $bolum',
                                    style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800));
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildBackButton(() {
            ChildExitDialog.show(
              context,
              themeColor: Colors.orange,
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
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 6),
                ]),
            child: Text(
                '${((_currentSection - 1) % 10) + 1}/10',
                style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.amber.withOpacity(0.3), blurRadius: 6),
                ]),
            child: Row(
              children: [
                Text('⭐', style: GoogleFonts.quicksand(fontSize: 18)),
                const SizedBox(width: 6),
                Text('$_score',
                    style: GoogleFonts.quicksand(
                        fontSize: 18, fontWeight: FontWeight.bold)),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 6),
                    ]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.favorite,
                        color: i < lives
                            ? Colors.orange.shade600
                            : Colors.grey.shade300,
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

  Widget _buildTitle() {
    return Builder(
      builder: (ctx) {
        final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Text(
                '${loc.gameFindDifferent}!',
                style: GoogleFonts.quicksand(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc.get('help_find_different_1'),
                style: GoogleFonts.quicksand(
                    fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 55,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _checkAnswer(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _items[index],
                style: GoogleFonts.quicksand(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
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
              Colors.orange.shade300,
              Colors.orange.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildTitle(),
              Expanded(child: _buildItemsGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
