import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/daily_reward_service.dart';
import '../models/daily_reward.dart' show TaskType;
import '../services/game_mechanics_service.dart';
import '../widgets/child_exit_dialog.dart';

class MemoryCardsScreen extends StatefulWidget {
  final String ageGroup;

  const MemoryCardsScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen> {
  static const String _highScoreKey = 'memory_cards_high_score';
  static const String _completedSectionsKey = 'memory_cards_sections';

  bool _showLevelSelect = true;
  Set<int> _completedSections = {};
  int _currentSection = 1; // 1-100 (bölüm 1-10, her bölümde 10 seviye)
  int _score = 0;
  int _highScore = 0;
  int _moves = 0;
  DateTime? _firstMoveAt;

  List<String> _cards = [];
  List<int> _cardPairIds = [];
  List<bool> _revealed = [];
  List<bool> _matched = [];
  int? _firstCardIndex;
  bool _isProcessing = false;
  bool _canTap = true;

  static final List<List<String>> _pairPool = [
    ['1+1', '2'], ['2+1', '3'], ['2+2', '4'], ['3+2', '5'], ['4+2', '6'],
    ['4+3', '7'], ['5+3', '8'], ['6+3', '9'], ['5+5', '10'], ['6+5', '11'],
    ['6+6', '12'], ['7+6', '13'], ['8+6', '14'], ['10+5', '15'], ['10+6', '16'],
    ['10+7', '17'], ['10+8', '18'], ['10+9', '19'], ['10+10', '20'],
    ['15+10', '25'], ['20+10', '30'], ['25+15', '40'], ['30+20', '50'],
    ['40+20', '60'], ['50+20', '70'], ['60+20', '80'], ['70+30', '100'],
  ];

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

  int _getPairCount() {
    return 5 + ((_currentSection - 1) ~/ 10);
  }

  List<List<String>> _getPairsForSection() {
    int pairCount = _getPairCount();
    return _pairPool.take(pairCount).toList();
  }

  void _initializeGame() {
    final pairs = _getPairsForSection();
    int pairCount = pairs.length;

    _cards = [];
    _cardPairIds = [];

    for (int i = 0; i < pairCount; i++) {
      _cards.add(pairs[i][0]);
      _cardPairIds.add(i);
      _cards.add(pairs[i][1]);
      _cardPairIds.add(i);
    }

    final indices = List.generate(_cards.length, (i) => i);
    indices.shuffle();

    final shuffledCards = <String>[];
    final shuffledPairIds = <int>[];
    for (int i in indices) {
      shuffledCards.add(_cards[i]);
      shuffledPairIds.add(_cardPairIds[i]);
    }
    _cards = shuffledCards;
    _cardPairIds = shuffledPairIds;

    _revealed = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _moves = 0;
    _firstCardIndex = null;
    _isProcessing = false;
    _canTap = true;
    _firstMoveAt = null;
  }

  void _loadSection(int section) {
    setState(() {
      _currentSection = section;
      _initializeGame();
    });
  }

  void _startGame(int bolum) {
    setState(() {
      _showLevelSelect = false;
      _score = 0;
      _currentSection = (bolum - 1) * 10 + 1;
      _firstMoveAt = null;
    });
    _loadSection(_currentSection);
  }

  Widget _buildBackButton(VoidCallback onPressed, {bool compact = false}) {
    final double size = compact ? 42 : 48;
    final double iconSize = compact ? 26 : 30;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.purple.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
          border: Border.all(color: Colors.purple.shade200, width: 2),
        ),
        child: Center(
            child: Icon(Icons.keyboard_arrow_left_rounded,
                color: Colors.purple.shade700, size: iconSize)),
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
              Colors.purple.shade400,
              Colors.purple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildScoreBar(),
              _buildLevelIndicator(),
              Expanded(
                child: Center(child: _buildCardGrid()),
              ),
            ],
          ),
        ),
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
            colors: [Colors.purple.shade400, Colors.purple.shade100],
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
                              Text(loc.gameMemoryCards,
                                  style: GoogleFonts.quicksand(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade800)),
                              Text(
                                  '${loc.sectionsInfo} $_highScore',
                              style: GoogleFonts.quicksand(
                                  fontSize: 12, color: Colors.purple.shade600)),
                            ],
                          );
                        },
                      ),
                    ),
                    Builder(
                      builder: (ctx) {
                        final loc = AppLocalizations(Provider.of<LocaleProvider>(ctx, listen: false).locale);
                        return IconButton(
                          icon: Icon(Icons.help_outline, color: Colors.purple.shade800, size: 28),
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
                                  : Colors.purple.shade200,
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
                                        color: Colors.purple.shade800));
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
    final levelText = '${((_currentSection - 1) % 10) + 1}/10';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final hPad = compact ? 10.0 : 16.0;
        final vPad = compact ? 10.0 : 16.0;
        final gap = compact ? 8.0 : 12.0;
        final chipHPad = compact ? 10.0 : 16.0;
        final chipVPad = compact ? 6.0 : 8.0;
        final chipFont = compact ? 14.0 : 16.0;
        final starFont = compact ? 15.0 : 18.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
          child: Consumer<LocaleProvider>(
            builder: (context, localeProv, _) {
              final loc = AppLocalizations(localeProv.locale);
              final levelChipLabel = '${loc.level} $levelText';
              return Row(
            children: [
              _buildBackButton(
                () {
                  ChildExitDialog.show(
                    context,
                    themeColor: Colors.purple,
                    onStay: () {},
                    onSectionSelect: () =>
                        setState(() => _showLevelSelect = true),
                    onExit: () => Navigator.pop(context),
                  );
                },
                compact: compact,
              ),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: chipHPad, vertical: chipVPad),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            levelChipLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              fontSize: chipFont,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: chipHPad, vertical: chipVPad),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('⭐',
                                  style: GoogleFonts.quicksand(
                                      fontSize: starFont)),
                              SizedBox(width: compact ? 4 : 6),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
              );
            },
          ),
        );
      },
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
            const Text('🎮 '),
            Text(loc.howToPlay, style: GoogleFonts.quicksand()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1️⃣', loc.get('help_memory_1')),
              _buildHelpItem('2️⃣', loc.get('help_memory_2')),
              _buildHelpItem('3️⃣', loc.get('help_memory_3')),
              _buildHelpItem('4️⃣', loc.get('help_memory_4')),
              _buildHelpItem('5️⃣', loc.get('help_memory_5')),
              _buildHelpItem('6️⃣', loc.get('help_memory_6')),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(loc.gotIt,
                style: GoogleFonts.quicksand(color: Colors.white)),
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

  int _getMatchedPairCount() {
    return _matched.where((m) => m).length ~/ 2;
  }

  Widget _buildScoreBar() {
    int totalPairs = _getPairCount();
    int matchedPairs = _getMatchedPairCount();

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: narrow ? 10 : 16),
          padding: EdgeInsets.symmetric(
              horizontal: narrow ? 8 : 16, vertical: narrow ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Consumer<LocaleProvider>(
            builder: (ctx, localeProv, _) {
              final loc = AppLocalizations(localeProv.locale);
              final levelVal = '${((_currentSection - 1) % 10) + 1}/10';
              final items = <Widget>[
                _buildStatItem(loc.level, levelVal, Colors.purple,
                    narrow: narrow),
                _buildStatItem(
                    loc.match, '$matchedPairs/$totalPairs', Colors.teal,
                    narrow: narrow),
                _buildStatItem(loc.moves, '$_moves', Colors.blue,
                    narrow: narrow),
                _buildStatItem(loc.score, '$_score', Colors.orange,
                    narrow: narrow),
              ];
              return Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) SizedBox(width: narrow ? 4 : 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: items[i],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color,
      {bool narrow = false}) {
    final labelSize = narrow ? 9.5 : 11.0;
    final valueSize = narrow ? 13.0 : 16.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.quicksand(
              fontSize: labelSize, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.quicksand(
              fontSize: valueSize, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildLevelIndicator() {
    final levelInBolum = ((_currentSection - 1) % 10) + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(10, (index) {
          bool isCompleted = index + 1 < levelInBolum;
          bool isCurrent = index + 1 == levelInBolum;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? Colors.orange
                        : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCardGrid() {
    int cardCount = _cards.length;
    int columns = math.max(2, math.sqrt(cardCount).ceil());
    int rows = (cardCount / columns).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth - 32;
        double maxHeight = constraints.maxHeight - 16;

        double cardWidth = (maxWidth - (columns - 1) * 8) / columns;
        double cardHeight = (maxHeight - (rows - 1) * 8) / rows;
        double cardSize = math.min(cardWidth, cardHeight);
        cardSize = math.min(cardSize, 90);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rows, (row) {
              return Padding(
                padding: EdgeInsets.only(bottom: row < rows - 1 ? 8 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(columns, (col) {
                    int index = row * columns + col;
                    if (index >= cardCount) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(right: col < columns - 1 ? 8 : 0),
                      child: SizedBox(
                        width: cardSize,
                        height: cardSize,
                        child: _buildCard(index),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildCard(int index) {
    bool isRevealed = _revealed[index];
    bool isMatched = _matched[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isMatched
              ? Colors.green.shade100
              : isRevealed
                  ? Colors.white
                  : Colors.purple.shade500,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? Colors.green.shade600
                : isRevealed
                    ? Colors.purple.shade300
                    : Colors.purple.shade700,
            width: isMatched ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: (isRevealed || isMatched)
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      _cards[index],
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMatched ? Colors.green.shade800 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Icon(
                  Icons.question_mark,
                  size: 28,
                  color: Colors.white.withOpacity(0.9),
                ),
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    if (!_canTap) return;
    if (_isProcessing) return;
    if (_revealed[index]) return;
    if (_matched[index]) return;

    _firstMoveAt ??= DateTime.now();

    if (_firstCardIndex == null) {
      setState(() {
        _revealed[index] = true;
        _firstCardIndex = index;
      });
    } else {
      final firstIndex = _firstCardIndex!;
      final secondIndex = index;

      setState(() {
        _revealed[index] = true;
        _moves++;
        _isProcessing = true;
        _canTap = false;
      });

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        bool isMatch = _cardPairIds[firstIndex] == _cardPairIds[secondIndex];

        setState(() {
          if (isMatch) {
            _matched[firstIndex] = true;
            _matched[secondIndex] = true;
          } else {
            _revealed[firstIndex] = false;
            _revealed[secondIndex] = false;
          }

          _firstCardIndex = null;
          _isProcessing = false;
          _canTap = true;
        });

        if (!isMatch) {
          final loc = AppLocalizations(
            Provider.of<LocaleProvider>(context, listen: false).locale,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ ${loc.memoryWrongMatch}',
                style: GoogleFonts.quicksand(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        Future.microtask(() {
          if (!mounted) return;
          if (_matched.isNotEmpty && _matched.every((m) => m)) {
            _onLevelComplete();
          }
        });
      });
    }
  }

  void _onLevelComplete() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final levelInBolum = ((_currentSection - 1) % 10) + 1;
    final bolumComplete = levelInBolum == 10;
    const int points = 10;

    if (bolumComplete) {
      setState(() => _score += points);
      _saveHighScore(_score);
      final sectionMsg =
          loc.get('fast_math_section_completed').replaceAll('%1', '$points');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $sectionMsg',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${loc.levelCompleted}',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }

    _saveCompletedSection(_currentSection);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentSection < 100) {
        setState(() => _currentSection++);
        _initializeGame();
      } else {
        _showFinalDialog();
      }
    });
  }

  void _showFinalDialog() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);

    final seconds = _firstMoveAt == null
        ? 999999
        : DateTime.now().difference(_firstMoveAt!).inSeconds;
    final bonus = ((_score / 50).floor()).clamp(0, 6); // basit performans bonusu
    // ignore: discarded_futures
    mechanicsService.grantBrainGameCompletionCoins(baseCoins: _score > 0 ? 2 : 0, bonusCoins: bonus);
    // ignore: discarded_futures
    rewardService.updateTaskProgress(TaskType.playBrainGame, 1);
    if (seconds <= 60) {
      // ignore: discarded_futures
      rewardService.updateTaskProgress(TaskType.memoryUnder60s, 1);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🏆 ${loc.get('congratulations')}',
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(fontSize: 24, color: Colors.purple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎊 ${loc.memoryChampion}',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildResultRow(loc.totalMoves, '$_moves'),
                  const Divider(),
                  _buildResultRow(loc.totalScore, '$_score', isBold: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showLevelSelect = true);
            },
            icon: const Icon(Icons.replay, color: Colors.white),
            label: Text(loc.get('play_again'), style: GoogleFonts.quicksand(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.home, color: Colors.white),
            label: Text(loc.get('main_menu'), style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.quicksand(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: isBold ? Colors.purple : Colors.black87,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
