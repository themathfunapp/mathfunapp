import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/section_soundscape.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/fraction_bakery_question_history.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../models/story_invite_payload.dart';
import '../widgets/story_parent_invite_strip.dart';

/// Kesir Pastanesi - Şef Sincap ile Pastane Temalı Kesir Oyunu
/// Pastaları eşit parçalara böl, partiyi hazırla!
class FractionBakeryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final StoryInvitePayload? parentPanelStoryInvite;

  const FractionBakeryScreen({
    super.key,
    required this.onBack,
    this.parentPanelStoryInvite,
  });

  @override
  State<FractionBakeryScreen> createState() => _FractionBakeryScreenState();
}

class _FractionBakeryScreenState extends State<FractionBakeryScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late Animation<double> _pulseAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _correctParts = 2; // Her parçadaki doğru cevap sayısı
  int _fractionType = 2; // 1=bütün, 2=yarım, 4=çeyrek (parça sayısı)
  List<int> _options = [];
  String _currentPastry = '🍰';
  String _currentPastryKey = 'fraction_bakery_tech_pasta';
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _gameOver = false;
  bool _hasShownNoLivesDialog = false;
  bool _sessionReported = false;
  int _sessQuestions = 0;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;

  // Soru verileri
  int _totalItems = 8; // Başlangıçtaki toplam
  int _eatenItems = 0; // Yenen/yok edilen
  int _remainingItems = 8; // Kalan (kesir hesabı için bu kullanılır)

  // Renk paleti: #FAD0C4 (Pastel Pembe), #B2FEFA (Açık Turkuaz), #8E44AD (Yaban Mersini Moru)
  static const Color _pastelPink = Color(0xFFFAD0C4);
  static const Color _lightTurquoise = Color(0xFFB2FEFA);
  static const Color _blueberryPurple = Color(0xFF8E44AD);
  static const Color _cream = Color(0xFFFFF8F0);

  // Pastane nesneleri - emoji -> localization key (isim / iyelik)
  static const Map<String, String> _pastryKeys = {
    '🍰': 'fraction_bakery_tech_pasta',
    '🍕': 'fraction_bakery_tech_pizza',
    '🍪': 'fraction_bakery_tech_kurabiye',
    '🥧': 'fraction_bakery_tech_turta',
    '🥐': 'fraction_bakery_tech_croissant',
    '🍩': 'fraction_bakery_tech_donut',
  };
  static const Map<String, String> _pastryPossKeys = {
    '🍰': 'fraction_bakery_poss_pasta',
    '🍕': 'fraction_bakery_poss_pizza',
    '🍪': 'fraction_bakery_poss_kurabiye',
    '🥧': 'fraction_bakery_poss_turta',
    '🥐': 'fraction_bakery_poss_croissant',
    '🍩': 'fraction_bakery_poss_donut',
  };
  final List<String> _pastries = _pastryKeys.keys.toList();
  final Set<String> _sessionQuestionFingerprints = {};
  bool _generatingQuestion = false;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.bakery);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateQuestion();
    });
  }

  String _pastryNoun(AppLocalizations loc) =>
      loc.get(_currentPastryKey);

  String _pastryPossessive(AppLocalizations loc) {
    final key = _pastryPossKeys[_currentPastry] ?? _currentPastryKey;
    return loc.get(key);
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _pulseController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  String _getQuestionText(AppLocalizations loc) {
    final noun = _pastryNoun(loc);
    final fracTypeKey = {
      1: 'fraction_bakery_frac_type_whole',
      2: 'fraction_bakery_frac_type_half',
      4: 'fraction_bakery_frac_type_quarter',
    }[_fractionType] ?? 'fraction_bakery_frac_type_half';
    final fracType = loc.get(fracTypeKey);

    if (_eatenItems > 0) {
      final format = loc.get('fraction_bakery_question_format_eaten');
      return format
          .replaceAll('{0}', '$_totalItems')
          .replaceAll('{1}', _pastryPossessive(loc))
          .replaceAll('{2}', '$_eatenItems')
          .replaceAll('{3}', '$_remainingItems')
          .replaceAll('{4}', '$_fractionType');
    }

    final format = loc.get('fraction_bakery_how_many_format');
    return format.replaceAll('{0}', noun).replaceAll('{1}', fracType);
  }

  String _getCharacterMessage(AppLocalizations loc) {
    final noun = _pastryNoun(loc);
    final fracTypeKey = {
      1: 'fraction_bakery_frac_type_whole',
      2: 'fraction_bakery_frac_type_half',
      4: 'fraction_bakery_frac_type_quarter',
    }[_fractionType] ?? 'fraction_bakery_frac_type_half';
    final fracType = loc.get(fracTypeKey);

    if (_eatenItems > 0) {
      final format = loc.get('fraction_bakery_character_format_eaten');
      return format
          .replaceAll('{0}', '$_totalItems')
          .replaceAll('{1}', _pastryPossessive(loc))
          .replaceAll('{2}', '$_eatenItems')
          .replaceAll('{3}', '$_remainingItems')
          .replaceAll('{4}', '$_fractionType');
    }

    final format = loc.get('fraction_bakery_character_message_format');
    return format.replaceAll('{0}', noun).replaceAll('{1}', fracType);
  }

  void _rollQuestionParams(math.Random random) {
    final partChoices = [1, 2, 4];
    _fractionType = partChoices[random.nextInt(3)];
    _currentPastry = _pastries[random.nextInt(_pastries.length)];
    _currentPastryKey =
        _pastryKeys[_currentPastry] ?? 'fraction_bakery_tech_pasta';

    if (_fractionType == 4) {
      _correctParts = 2 + random.nextInt(5);
      _remainingItems = _correctParts * 4;
      _eatenItems = (random.nextInt(3) + 2) * 2;
      _totalItems = _remainingItems + _eatenItems;
    } else if (_fractionType == 2) {
      _correctParts = 2 + random.nextInt(7);
      _remainingItems = _correctParts * 2;
      _eatenItems = random.nextInt(6) + 2;
      _totalItems = _remainingItems + _eatenItems;
    } else {
      _remainingItems = 1 + random.nextInt(8);
      _correctParts = _remainingItems;
      _eatenItems = random.nextInt(5);
      _totalItems = _remainingItems + _eatenItems;
    }
  }

  String _questionFingerprint() => FractionBakeryQuestionHistory.fingerprint(
        _currentPastry,
        _totalItems,
        _eatenItems,
        _remainingItems,
        _fractionType,
      );

  Future<void> _generateQuestion() async {
    if (!mounted || _generatingQuestion) return;
    _generatingQuestion = true;

    try {
      final random = math.Random();
      Set<String> askedToday = {};
      try {
        askedToday = await FractionBakeryQuestionHistory.loadToday().timeout(
          const Duration(seconds: 2),
          onTimeout: () => <String>{},
        );
      } catch (e) {
        debugPrint('FractionBakery loadToday error: $e');
      }

      final excluded = <String>{...askedToday, ..._sessionQuestionFingerprints};
      String? chosenFp;

      for (var attempt = 0; attempt < 300; attempt++) {
        _rollQuestionParams(random);
        final fp = _questionFingerprint();
        if (!excluded.contains(fp)) {
          chosenFp = fp;
          break;
        }
      }

      if (chosenFp == null) {
        _rollQuestionParams(random);
        chosenFp = _questionFingerprint();
      }

      _sessionQuestionFingerprints.add(chosenFp);
      _options = _generateOptions(_correctParts, random);

      if (mounted) {
        setState(() {
          _isAnswered = false;
          _isCorrect = false;
        });
      }

      FractionBakeryQuestionHistory.record(chosenFp).catchError((Object e) {
        debugPrint('FractionBakery record error: $e');
      });
    } catch (e, st) {
      debugPrint('FractionBakery _generateQuestion error: $e\n$st');
      if (mounted) {
        setState(() {
          _isAnswered = false;
          _isCorrect = false;
        });
      }
    } finally {
      _generatingQuestion = false;
    }
  }

  List<int> _generateOptions(int correct, math.Random random) {
    final Set<int> opts = {correct};
    while (opts.length < 3) {
      int wrong = correct + (random.nextInt(5) - 2); // -2, -1, +1, +2
      if (wrong < 1) wrong = correct + 2;
      if (wrong != correct) opts.add(wrong);
    }
    return opts.toList()..shuffle(random);
  }

  void _checkAnswer(int answer) {
    if (_isAnswered || _gameOver) return;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    final correct = answer == _correctParts;
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _sessQuestions++;
      _sessCorrect++;
      _runStreak++;
      if (_runStreak > _bestStreak) _bestStreak = _runStreak;
      if (_sessCorrect % 10 == 0) mechanicsService.addCoins(5);
      _score += 10;
      _audio.playAnswerFeedback(true);
      _celebrationController.forward(from: 0);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted || _gameOver) return;
        _currentLevel++;
        _generateQuestion();
      });
      return;
    }

    _sessQuestions++;
    _sessWrong++;
    _runStreak = 0;
    _audio.playAnswerFeedback(false);
    mechanicsService.onWrongAnswer();

    if (!mechanicsService.hasLives) {
      setState(() => _gameOver = true);
      _showGameOver();
      return;
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _gameOver) return;
      _generateQuestion();
    });
  }

  void _reportFractionSession() {
    if (_sessionReported || !mounted) return;
    _sessionReported = true;
    final q = (_sessCorrect + _sessWrong).clamp(1, 9999);
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
      debugPrint('FractionBakery report error: $e');
    }
  }

  void _showNoLivesDialog() {
    _reportFractionSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍰', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(loc.get('lives_finished')),
          ],
        ),
        content: Text(loc.get('no_lives_play')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.get('ok')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBack();
            },
            child: Text(loc.get('profile')),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    _reportFractionSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Flexible(child: Text(loc.get('lives_finished'), textAlign: TextAlign.center)),
          ],
        ),
        content: Text(loc.get('no_lives_play')),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBack();
            },
            child: Text(loc.get('ok')),
          ),
        ],
      ),
    );
  }

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);

  /// Şef Sincap - sincap emoji, dairesel arka plan içinde (taşma/clipping düzeltmesi)
  Widget _buildChefSquirrel() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: _blueberryPurple.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: _blueberryPurple.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Center(
          child: Text('🐿️', style: const TextStyle(fontSize: 40)),
        ),
      ),
    );
  }

  /// Yenmiş cupcake - sadece kağıt/kalıp (can kaybedilince)
  Widget _buildCupcakeWrapper({bool compact = false}) {
    final s = compact ? 18.0 : 24.0;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _CupcakeWrapperPainter(color: _cream),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: true);
    if (!mechanicsService.hasLives && !_hasShownNoLivesDialog) {
      _hasShownNoLivesDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNoLivesDialog();
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _pastelPink,
              _cream,
              _lightTurquoise,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              ..._buildPastryBackground(),
              Column(
                children: [
            _buildTopBar(loc),
            storyParentInviteStrip(widget.parentPanelStoryInvite),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCharacterMessage(loc),
                    const SizedBox(height: 12),
                    _buildQuestionArea(loc),
                    const SizedBox(height: 12),
                    _buildAnswerOptions(loc),
                    const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isCorrect && _isAnswered) _buildCelebration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _cream.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: _blueberryPurple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: _blueberryPurple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: _blueberryPurple),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🍰 ${loc.get('fraction_bakery')}',
                  style: _textStyle(_blueberryPurple, size: 22, bold: true),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  loc.get('fraction_bakery_subtitle'),
                  style: _textStyle(_blueberryPurple.withOpacity(0.8), size: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxLives, (i) {
                  final hasLife = i < lives;
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: hasLife
                        ? const Text('🧁', style: TextStyle(fontSize: 18))
                        : _buildCupcakeWrapper(compact: true),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterMessage(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blueberryPurple.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: _blueberryPurple.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildChefSquirrel(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.get('fraction_bakery_character_name'),
                  style: _textStyle(_blueberryPurple, size: 16, bold: true),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCharacterMessage(loc),
                  style: _textStyle(_blueberryPurple.withOpacity(0.9), size: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _blueberryPurple.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: _blueberryPurple.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getQuestionText(loc),
            style: _textStyle(_blueberryPurple, size: 17, bold: true),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildRemainingItemsVisual(loc),
          const SizedBox(height: 10),
          // Kesir dilimleri görseli
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: _buildFractionVisual(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingItemsVisual(AppLocalizations loc) {
    final items = List.generate(
      _remainingItems.clamp(4, 16),
      (i) => Padding(
        padding: const EdgeInsets.all(4),
        child: Text(_currentPastry, style: const TextStyle(fontSize: 24)),
      ),
    );
    final remainingText = loc
        .get('fraction_bakery_remaining_format')
        .replaceAll('{0}', '$_remainingItems')
        .replaceAll('{1}', _pastryNoun(loc));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _pastelPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blueberryPurple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            remainingText,
            style: _textStyle(_blueberryPurple, size: 14, bold: true),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildFractionVisual() {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _PastryDivisionPainter(
              parts: _fractionType, // Parça sayısı (1, 2, 4)
              color: _blueberryPurple,
            ),
            size: const Size(100, 100),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cream.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Text(_currentPastry, style: const TextStyle(fontSize: 40)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(AppLocalizations loc) {
    final questionText = loc
        .get('fraction_bakery_how_many_per_part')
        .replaceAll('{0}', _pastryPossessive(loc));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            questionText,
            style: _textStyle(_blueberryPurple, size: 16, bold: true),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _options.map((opt) => _buildAnswerButton(opt)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int value) {
    final isCorrectAnswer = value == _correctParts;
    final isSelected = _isAnswered && value == _correctParts;

    Color buttonColor;
    if (_isAnswered) {
      buttonColor = isCorrectAnswer
          ? _lightTurquoise.withOpacity(0.8)
          : _pastelPink.withOpacity(0.5);
    } else {
      buttonColor = _cream.withOpacity(0.9);
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && !_gameOver && mechanicsService.hasLives;
    return GestureDetector(
      onTap: canTap ? () => _checkAnswer(value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 88,
        height: 68,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _blueberryPurple : _blueberryPurple.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _blueberryPurple.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$value',
            style: GoogleFonts.quicksand(
              color: _blueberryPurple,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(20, (index) {
                final random = math.Random(index);
                final startX = random.nextDouble();
                final delay = random.nextDouble() * 0.5;
                final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);

                return Positioned(
                  left: MediaQuery.of(context).size.width * startX,
                  top: -50 + (MediaQuery.of(context).size.height * progress * 1.2),
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Transform.rotate(
                      angle: progress * 4 * math.pi,
                      child: Text(
                        ['🍰', '🧁', '🎉', '⭐'][random.nextInt(4)],
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPastryBackground() {
    return List.generate(8, (index) {
      final random = math.Random(index);
      final pastries = ['🍰', '🧁', '🍪', '🥧'];
      return Positioned(
        left: random.nextDouble() * 320,
        top: 100 + random.nextDouble() * 500,
        child: Opacity(
          opacity: 0.15 + random.nextDouble() * 0.1,
          child: Text(
            pastries[index % pastries.length],
            style: TextStyle(fontSize: 36 + random.nextDouble() * 24),
          ),
        ),
      );
    });
  }
}

/// Pastayı parçalara bölünmüş olarak çizer (daire dilimleri)
class _PastryDivisionPainter extends CustomPainter {
  final int parts;
  final Color color;

  _PastryDivisionPainter({required this.parts, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    for (int i = 0; i < parts; i++) {
      final startAngle = (i * 2 * math.pi / parts) - math.pi / 2;
      final sweepAngle = 2 * math.pi / parts;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PastryDivisionPainter oldDelegate) {
    return oldDelegate.parts != parts;
  }
}

/// Yenmiş cupcake - sadece kağıt kalıbı (krem rengi, girintili alt)
class _CupcakeWrapperPainter extends CustomPainter {
  final Color color;

  _CupcakeWrapperPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height;

    // Cupcake kağıdı - trapezoid/konik şekil (altta dar, üstte geniş)
    final path = Path()
      ..moveTo(centerX - 6, 4)
      ..lineTo(centerX - 10, bottomY - 2)
      ..lineTo(centerX + 10, bottomY - 2)
      ..lineTo(centerX + 6, 4)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _CupcakeWrapperPainter oldDelegate) =>
      oldDelegate.color != color;
}
