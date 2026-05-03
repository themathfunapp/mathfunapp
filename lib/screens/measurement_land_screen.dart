import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../audio/section_soundscape.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../models/story_invite_payload.dart';
import '../widgets/story_parent_invite_strip.dart';

/// Ölçüm Diyarı - Büyük-küçük, uzun-kısa kavramlarını öğren!
class MeasurementLandScreen extends StatefulWidget {
  final VoidCallback onBack;
  final StoryInvitePayload? parentPanelStoryInvite;

  const MeasurementLandScreen({
    super.key,
    required this.onBack,
    this.parentPanelStoryInvite,
  });

  @override
  State<MeasurementLandScreen> createState() => _MeasurementLandScreenState();
}

class _MeasurementLandScreenState extends State<MeasurementLandScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _celebrationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isBonusLevel = false;
  bool _gameOver = false;
  bool _hasShownNoLivesDialog = false;
  bool _sessionReported = false;
  int _sessQuestions = 0;
  int _sessCorrect = 0;
  int _sessWrong = 0;
  int _runStreak = 0;
  int _bestStreak = 0;
  String? _lastLocale;

  String _questionType = 'bigSmall';
  String _questionText = '';
  List<String> _options = [];
  String _correctAnswer = '';
  final List<_AmbientRuler> _ambientRulers = List.generate(8, (i) {
    final r = math.Random(i);
    return _AmbientRuler(
      topFactor: r.nextDouble() * 0.65,
      leftFactor: r.nextDouble(),
      icon: i.isEven ? '📐' : '📏',
      size: 16 + r.nextDouble() * 10,
      opacity: 0.18 + r.nextDouble() * 0.15,
    );
  });

  static const Color _orange = Color(0xFFFF9800);
  static const Color _yellow = Color(0xFFFFC107);

  /// Soru tipleri: questionKey ile lokalizasyon
  static final List<Map<String, dynamic>> _questionSets = [
    {'questionKey': 'measurement_q_bigger', 'correctPool': ['🐘', '🦣', '🦛', '🐫', '🦒', '🐋'], 'wrongPool': ['🐜', '🐛', '🦗', '🐝', '🐞', '🦟']},
    {'questionKey': 'measurement_q_smaller', 'correctPool': ['🐜', '🐛', '🦗', '🐝', '🐞', '🦟'], 'wrongPool': ['🐘', '🦣', '🦛', '🐫', '🦒']},
    {'questionKey': 'measurement_q_longer', 'correctPool': ['🦒', '🐍', '🦎', '🐘'], 'wrongPool': ['🐢', '🐁', '🐹', '🐸', '🐌']},
    {'questionKey': 'measurement_q_shorter', 'correctPool': ['🐢', '🐁', '🐹', '🐸', '🐌'], 'wrongPool': ['🦒', '🐍', '🦎', '🐘']},
    {'questionKey': 'measurement_q_heavier', 'correctPool': ['🐘', '🦣', '🦛', '🚗', '🏔️', '🐋'], 'wrongPool': ['🪶', '🪁', '🍃', '🦋', '🪺', '🪹']},
    {'questionKey': 'measurement_q_lighter', 'correctPool': ['🪶', '🪁', '🍃', '🦋', '🪺'], 'wrongPool': ['🐘', '🦣', '🦛', '🚗', '🐋']},
    {'questionKey': 'measurement_q_taller', 'correctPool': ['🦒', '🌳', '🏢', '🐘'], 'wrongPool': ['🐜', '🐁', '🌱', '🐌', '🐹']},
    {'questionKey': 'measurement_q_shorter_height', 'correctPool': ['🐜', '🐁', '🌱', '🐌', '🐹'], 'wrongPool': ['🦒', '🌳', '🏢', '🐘']},
    {'questionKey': 'measurement_q_wider', 'correctPool': ['🐘', '🦣', '🦛', '🐋', '🦭', '🐫'], 'wrongPool': ['🦒', '🐍', '🪶', '🐸', '🐌']},
    {'questionKey': 'measurement_q_narrower', 'correctPool': ['🦒', '🐍', '🪶', '🐸', '🐌'], 'wrongPool': ['🐘', '🦣', '🦛', '🐋']},
    {'questionKey': 'measurement_q_bigger_fruit', 'correctPool': ['🍎', '🍐', '🍊', '🍉', '🍈'], 'wrongPool': ['🍒', '🍇', '🫐', '🍓', '🫒']},
    {'questionKey': 'measurement_q_smaller_fruit', 'correctPool': ['🍒', '🍇', '🫐', '🍓', '🫒'], 'wrongPool': ['🍎', '🍐', '🍊', '🍉']},
    {'questionKey': 'measurement_q_bigger_building', 'correctPool': ['🏰', '🏢', '🏛️', '🏗️'], 'wrongPool': ['🏠', '🏚️', '🏕️', '⛺']},
    {'questionKey': 'measurement_q_smaller_house', 'correctPool': ['🏠', '🏚️', '🏕️', '⛺'], 'wrongPool': ['🏰', '🏢', '🏛️']},
  ];

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.river);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    _lastLocale = locale.toString();
    _generateQuestion(AppLocalizations(locale));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final localeStr = locale.toString();
    if (_lastLocale != null && _lastLocale != localeStr) {
      _lastLocale = localeStr;
      _generateQuestion(AppLocalizations(locale));
    } else {
      _lastLocale = localeStr;
    }
  }

  @override
  void dispose() {
    _audio.cancelAmbientSync();
    _pulseController.dispose();
    _bounceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAvailableQuestionSets() {
    if (_currentLevel <= 2) return _questionSets.take(4).toList();
    if (_currentLevel <= 5) return _questionSets.take(6).toList();
    if (_currentLevel <= 8) return _questionSets.take(8).toList();
    return _questionSets;
  }

  void _generateQuestion(AppLocalizations loc) {
    final random = math.Random();
    _isBonusLevel = _currentLevel % 5 == 0 && _currentLevel > 0;

    if (_isBonusLevel) {
      _generateBonusQuestion(loc);
      return;
    }

    final available = _getAvailableQuestionSets();
    final set = available[random.nextInt(available.length)];
    final correctPool = (set['correctPool'] as List).cast<String>();
    final wrongPool = (set['wrongPool'] as List).cast<String>();

    _questionText = loc.get(set['questionKey'] as String);
    _correctAnswer = correctPool[random.nextInt(correctPool.length)];
    final wrongOptions = wrongPool.toList()..shuffle(random);
    _options = [_correctAnswer, wrongOptions[0], wrongOptions[1]];
    _options.shuffle(random);

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _generateBonusQuestion(AppLocalizations loc) {
    final random = math.Random();
    final set = _questionSets[random.nextInt(_questionSets.length)];
    final correctPool = (set['correctPool'] as List).cast<String>();
    final wrongPool = (set['wrongPool'] as List).cast<String>();

    _questionText = '⭐ BONUS: ${loc.get(set['questionKey'] as String)}';
    _correctAnswer = correctPool[random.nextInt(correctPool.length)];
    final wrongOptions = wrongPool.toList()..shuffle(random);
    _options = [_correctAnswer, wrongOptions[0], wrongOptions[1]];
    _options.shuffle(random);

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer(String selected) {
    if (_isAnswered || _gameOver) return;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    final correct = selected == _correctAnswer;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _sessQuestions++;
        _sessCorrect++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _score += _isBonusLevel ? 25 : 10;
        _stars += _isBonusLevel ? 2 : 1;
        _audio.playAnswerFeedback(true);
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateQuestion(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale));
          }
        });
      } else {
        _sessQuestions++;
        _sessWrong++;
        _runStreak = 0;
        _audio.playAnswerFeedback(false);
        mechanicsService.onWrongAnswer();
        if (!mechanicsService.hasLives) {
          _gameOver = true;
          _showGameOver();
          return;
        }
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && !_gameOver) _generateQuestion(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale));
        });
      }
    });
  }

  void _reportMeasurementSession() {
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
      debugPrint('MeasurementLand report error: $e');
    }
  }

  void _showNoLivesDialog() {
    _reportMeasurementSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📏', style: TextStyle(fontSize: 32)),
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
    _reportMeasurementSession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📏', style: TextStyle(fontSize: 28)),
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
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
              Color(0xFF81D4FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildAmbientEffects(),
              Column(
                children: [
                  _buildTopBar(loc),
                  storyParentInviteStrip(widget.parentPanelStoryInvite),
                  _buildProgressPath(loc),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, viewportConstraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: viewportConstraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuestionCard(loc, viewportConstraints),
                                  SizedBox(height: (viewportConstraints.maxHeight * 0.015).clamp(8.0, 16.0)),
                                  _buildVisualDisplay(loc, viewportConstraints),
                                  SizedBox(height: (viewportConstraints.maxHeight * 0.015).clamp(8.0, 16.0)),
                                  _buildOptionsGrid(loc, viewportConstraints),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (_isCorrect) _buildCelebration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPath(AppLocalizations loc) {
    const totalFloors = 10;
    final currentFloor = (_currentLevel - 1) % totalFloors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final dotSize = ((w - 72) / totalFloors).clamp(11.0, 18.0);
          final iconSize = (dotSize * 0.65).clamp(7.0, 11.0);
          final levelLabel = '${currentFloor + 1}/$totalFloors';

          return Row(
            children: [
              Text('📏', style: TextStyle(fontSize: (18 * (w / 400)).clamp(16.0, 22.0))),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(totalFloors, (i) {
                    final isPassed = i < currentFloor;
                    final isCurrent = i == currentFloor;
                    return Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? _yellow
                            : (isCurrent ? Colors.white : Colors.white.withOpacity(0.4)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: isPassed
                          ? Icon(Icons.check, size: iconSize, color: _orange)
                          : null,
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                levelLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: (11 * (w / 400)).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAmbientEffects() {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: 60 + _bounceAnimation.value,
                    right: 30,
                    child: const Text('📏', style: TextStyle(fontSize: 40)),
                  );
                },
              ),
              ..._ambientRulers.map((ruler) {
                return Positioned(
                  top: constraints.maxHeight * ruler.topFactor,
                  left: constraints.maxWidth * ruler.leftFactor,
                  child: Opacity(
                    opacity: ruler.opacity,
                    child: Text(
                      ruler.icon,
                      style: TextStyle(fontSize: ruler.size),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final scale = (w / 400.0).clamp(0.82, 1.0);
          final titleSize = (20 * scale).clamp(15.0, 20.0);
          final descSize = (12 * scale).clamp(10.0, 12.0);
          final starSize = (16 * scale).clamp(12.0, 16.0);
          final turtleEmoji = (20 * scale).clamp(16.0, 22.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: (44 * scale).clamp(40.0, 46.0),
                  height: (44 * scale).clamp(40.0, 46.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange.withOpacity(0.6)),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 22 * scale),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📏 ${loc.get('world_measurement_land')}',
                      style: _textStyle(Colors.white, size: titleSize, bold: true),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.get('world_measurement_land_desc'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: descSize,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Consumer<GameMechanicsService>(
                builder: (context, mechanicsService, _) {
                  final lives = mechanicsService.currentLives;
                  final maxLives = mechanicsService.maxLives;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      maxLives,
                      (i) => Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child: Text(
                          i < lives ? '🐢' : '🐚',
                          style: TextStyle(fontSize: turtleEmoji),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (10 * scale).clamp(8.0, 12.0),
                  vertical: (6 * scale).clamp(4.0, 7.0),
                ),
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '⭐ $_stars',
                  style: _textStyle(Colors.amber, size: starSize, bold: true),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(AppLocalizations loc, BoxConstraints viewportConstraints) {
    final w = viewportConstraints.maxWidth;
    final scale = (w / 400.0).clamp(0.75, 1.05);
    final avatar = (56 * scale).clamp(44.0, 64.0);
    final turtleEmoji = (32 * scale).clamp(24.0, 38.0);
    final nameSize = (16 * scale).clamp(13.0, 18.0);
    final questionSize = (18 * scale).clamp(14.0, 20.0);
    final pad = (16 * scale).clamp(12.0, 20.0);
    final gap = (14 * scale).clamp(10.0, 16.0);
    final radius = (20 * scale).clamp(16.0, 22.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _orange.withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: avatar,
                  height: avatar,
                  decoration: BoxDecoration(
                    color: _yellow.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange, width: 2),
                  ),
                  child: Center(child: Text('🐢', style: TextStyle(fontSize: turtleEmoji))),
                ),
              );
            },
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.get('helper_turtle_name'), style: _textStyle(_orange, size: nameSize, bold: true)),
                SizedBox(height: (6 * scale).clamp(4.0, 8.0)),
                Text(
                  _questionText,
                  style: _textStyle(Colors.black87, size: questionSize),
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

  /// Üst (inceleme) ve alt (cevap) kartlarında aynı emoji boyutu — FittedBox.contain şişirmesini önler.
  double _measurementEmojiFontSize(double scale) =>
      (34 * scale).clamp(28.0, 40.0);

  /// Geniş web ekranında [AspectRatio] 1:1 hücre yüksekliği satır genişliğine eşitlenip devleşiyordu.
  double _measurementEmojiCellHeight(BoxConstraints viewportConstraints, double scale) {
    final w = viewportConstraints.maxWidth;
    final h = viewportConstraints.maxHeight;
    final gap = (10 * scale).clamp(6.0, 12.0);
    final approxCellWidth = (w - 56) / 3 - gap;
    final fromWidth = approxCellWidth.clamp(52.0, 80.0);
    final fromHeight = (h * 0.13).clamp(54.0, 80.0);
    return math.min(fromWidth, fromHeight);
  }

  Widget _buildVisualDisplay(AppLocalizations loc, BoxConstraints viewportConstraints) {
    final w = viewportConstraints.maxWidth;
    final scale = (w / 400.0).clamp(0.75, 1.05);
    final gap = (10 * scale).clamp(6.0, 12.0);
    final pad = (8 * scale).clamp(6.0, 12.0);
    final cellH = _measurementEmojiCellHeight(viewportConstraints, scale);
    final emojiFont =
        math.min(_measurementEmojiFontSize(scale), cellH * 0.5).clamp(24.0, 40.0);
    final headerSize = (16 * scale).clamp(13.0, 17.0);

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value * 0.3),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all((14 * scale).clamp(10.0, 18.0)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _orange.withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: _orange.withOpacity(0.2), blurRadius: 20)],
            ),
            child: Column(
              children: [
                Text(
                  '🔍 ${loc.get('measurement_look_carefully')}',
                  style: _textStyle(_orange, size: headerSize, bold: true),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: (12 * scale).clamp(8.0, 16.0)),
                Row(
                  children: _options.map((emoji) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap / 2),
                        child: SizedBox(
                          height: cellH,
                          child: Container(
                            padding: EdgeInsets.all(pad),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _orange.withOpacity(0.3)),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                emoji,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: emojiFont, height: 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsGrid(AppLocalizations loc, BoxConstraints viewportConstraints) {
    final w = viewportConstraints.maxWidth;
    final scale = (w / 400.0).clamp(0.75, 1.05);
    final labelSize = (16 * scale).clamp(13.0, 17.0);
    final gap = (10 * scale).clamp(6.0, 12.0);
    final cellH = _measurementEmojiCellHeight(viewportConstraints, scale);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all((14 * scale).clamp(10.0, 18.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Text(loc.get('choose_answer'), style: _textStyle(_orange, size: labelSize, bold: true)),
          SizedBox(height: (10 * scale).clamp(8.0, 14.0)),
          Row(
            children: _options.map((emoji) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _buildOptionButton(emoji, scale, cellH),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String emoji, double scale, double cellHeight) {
    final isCorrect = emoji == _correctAnswer;
    final isSelected = _isAnswered && isCorrect;

    Color bgColor = Colors.white.withOpacity(0.9);
    if (_isAnswered) {
      bgColor = isCorrect ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.2);
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && !_gameOver && mechanicsService.hasLives;
    final emojiFont =
        math.min(_measurementEmojiFontSize(scale), cellHeight * 0.5).clamp(24.0, 40.0);

    return GestureDetector(
      onTap: canTap ? () => _checkAnswer(emoji) : null,
      child: SizedBox(
        height: cellHeight,
        width: double.infinity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.green : _orange.withOpacity(0.5),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                emoji,
                style: TextStyle(fontSize: emojiFont, height: 1.0),
              ),
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
              children: List.generate(30, (i) {
                final r = math.Random(i);
                final progress = (_celebrationController.value - r.nextDouble() * 0.2).clamp(0.0, 1.0);
                return Positioned(
                  left: MediaQuery.of(context).size.width * r.nextDouble(),
                  top: -20 + MediaQuery.of(context).size.height * progress,
                  child: Opacity(
                    opacity: (1.0 - progress).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: progress * 6 * math.pi,
                      child: Text(
                        ['📏', '📐', '🦒', '🐘', '✨', '⭐', '🐢', '🐜', '🦣'][r.nextInt(9)],
                        style: TextStyle(fontSize: 24 + r.nextDouble() * 16),
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

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);
}

class _AmbientRuler {
  final double topFactor;
  final double leftFactor;
  final String icon;
  final double size;
  final double opacity;

  const _AmbientRuler({
    required this.topFactor,
    required this.leftFactor,
    required this.icon,
    required this.size,
    required this.opacity,
  });
}
