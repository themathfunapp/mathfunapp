import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../models/castle_door.dart';
import '../audio/section_soundscape.dart';
import '../providers/locale_provider.dart';
import '../services/audio_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/game_session_report.dart';
import '../widgets/castle_door_widget.dart';
import '../widgets/shape_painter.dart';
import '../models/story_invite_payload.dart';
import '../widgets/story_parent_invite_strip.dart';

/// Geometri Şatosu - Şekilleri kullanarak gizli kapıları aç!
class GeometryCastleScreen extends StatefulWidget {
  final VoidCallback onBack;
  final StoryInvitePayload? parentPanelStoryInvite;

  const GeometryCastleScreen({
    super.key,
    required this.onBack,
    this.parentPanelStoryInvite,
  });

  @override
  State<GeometryCastleScreen> createState() => _GeometryCastleScreenState();
}

enum QuestionType { shapeName, vertexCount, equalEdges }

class _GeometryCastleScreenState extends State<GeometryCastleScreen>
    with TickerProviderStateMixin {
  late final AudioService _audio;
  /// Yavaş, düzgün faz — parıltı / baykuş için hafif hareket (titreme yok)
  late AnimationController _gentleMotionController;
  late AnimationController _floatController;
  late AnimationController _celebrationController;
  late AnimationController _bgController;
  late Animation<double> _floatAnimation;
  late Animation<double> _bgAnimation;

  /// Tur içindeki adım (1–10). Her 10 adımda tur biter; puan tur sonunda verilir.
  int _stepInRound = 1;
  /// İlk girişte false; "Tekrar oyna" ile başlayan turlarda true (bonus adım + tur sonunda +6 puan).
  bool _replayRound = false;
  /// 1–10 arası; sadece [_replayRound] true iken rastgele atanır (bir bonus soru).
  int? _bonusStepSlot;

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

  // Şekil tanımları: type, nameKey (lokalizasyon), köşe sayısı, kenar eşitliği
  final List<Map<String, dynamic>> _shapes = [
    {'type': ShapeType.circle, 'nameKey': 'geometry_castle_shape_circle', 'vertices': 0, 'equalEdges': false, 'color': Color(0xFFE91E63)},
    {'type': ShapeType.oval, 'nameKey': 'geometry_castle_shape_oval', 'vertices': 0, 'equalEdges': false, 'color': Color(0xFFE040FB)},
    {'type': ShapeType.semicircle, 'nameKey': 'geometry_castle_shape_semicircle', 'vertices': 0, 'equalEdges': false, 'color': Color(0xFFAB47BC)},
    {'type': ShapeType.square, 'nameKey': 'geometry_castle_shape_square', 'vertices': 4, 'equalEdges': true, 'color': Color(0xFF2196F3)},
    {'type': ShapeType.rectangle, 'nameKey': 'geometry_castle_shape_rectangle', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFFFF9800)},
    {'type': ShapeType.roundedRect, 'nameKey': 'geometry_castle_shape_rounded_rect', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFF42A5F5)},
    {'type': ShapeType.triangle, 'nameKey': 'geometry_castle_shape_triangle', 'vertices': 3, 'equalEdges': true, 'color': Color(0xFF4CAF50)},
    {'type': ShapeType.rightTriangle, 'nameKey': 'geometry_castle_shape_right_triangle', 'vertices': 3, 'equalEdges': false, 'color': Color(0xFF81C784)},
    {'type': ShapeType.diamond, 'nameKey': 'geometry_castle_shape_diamond', 'vertices': 4, 'equalEdges': true, 'color': Color(0xFF80DEEA)},
    {'type': ShapeType.kite, 'nameKey': 'geometry_castle_shape_kite', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFF8D6E63)},
    {'type': ShapeType.trapezoid, 'nameKey': 'geometry_castle_shape_trapezoid', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFFA1887F)},
    {'type': ShapeType.parallelogram, 'nameKey': 'geometry_castle_shape_parallelogram', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFF7E57C2)},
    {'type': ShapeType.pentagon, 'nameKey': 'geometry_castle_shape_pentagon', 'vertices': 5, 'equalEdges': true, 'color': Color(0xFF9C27B0)},
    {'type': ShapeType.hexagon, 'nameKey': 'geometry_castle_shape_hexagon', 'vertices': 6, 'equalEdges': true, 'color': Color(0xFF00BCD4)},
    {'type': ShapeType.heptagon, 'nameKey': 'geometry_castle_shape_heptagon', 'vertices': 7, 'equalEdges': true, 'color': Color(0xFFEF5350)},
    {'type': ShapeType.octagon, 'nameKey': 'geometry_castle_shape_octagon', 'vertices': 8, 'equalEdges': true, 'color': Color(0xFF795548)},
    {'type': ShapeType.nonagon, 'nameKey': 'geometry_castle_shape_nonagon', 'vertices': 9, 'equalEdges': true, 'color': Color(0xFF5C6BC0)},
    {'type': ShapeType.decagon, 'nameKey': 'geometry_castle_shape_decagon', 'vertices': 10, 'equalEdges': true, 'color': Color(0xFF66BB6A)},
    {'type': ShapeType.hendecagon, 'nameKey': 'geometry_castle_shape_hendecagon', 'vertices': 11, 'equalEdges': true, 'color': Color(0xFFEC407A)},
    {'type': ShapeType.dodecagon, 'nameKey': 'geometry_castle_shape_dodecagon', 'vertices': 12, 'equalEdges': true, 'color': Color(0xFF26C6DA)},
    {'type': ShapeType.star, 'nameKey': 'geometry_castle_shape_star', 'vertices': 10, 'equalEdges': true, 'color': Color(0xFFFFC107)},
    {'type': ShapeType.star6, 'nameKey': 'geometry_castle_shape_star6', 'vertices': 12, 'equalEdges': true, 'color': Color(0xFFFF7043)},
    {'type': ShapeType.cross, 'nameKey': 'geometry_castle_shape_cross', 'vertices': 12, 'equalEdges': true, 'color': Color(0xFFBDBDBD)},
  ];

  ShapeType _targetShapeType = ShapeType.circle;
  String _targetShapeNameKey = '';
  Color _targetColor = Colors.blue;
  String? _lastLocale;
  String _questionText = '';
  QuestionType _questionType = QuestionType.shapeName;
  List<Map<String, dynamic>> _options = [];
  Map<String, dynamic>? _correctOption;

  static const Color _castlePurple = Color(0xFF9C27B0);
  static const Color _castlePink = Color(0xFFE91E63);

  static const List<CastleDoorType> _doorTypes = CastleDoorType.values;

  /// Seviyeye göre kapı tipi (her 2 seviyede bir değişir)
  CastleDoorType get _currentDoorType =>
      _doorTypes[(_stepInRound - 1) % _doorTypes.length];

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    scheduleSectionAmbient(context, SoundscapeTheme.castle);
    _gentleMotionController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bgController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOut),
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
    // Dil değiştiğinde soruyu her zaman yeniden oluştur (karışık dil sorununu önler)
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
    _gentleMotionController.dispose();
    _floatController.dispose();
    _celebrationController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAvailableShapes() {
    if (_stepInRound <= 2) {
      return _shapes.take(4).toList();
    } else if (_stepInRound <= 4) {
      return _shapes.take(8).toList();
    } else if (_stepInRound <= 6) {
      return _shapes.take(14).toList();
    } else if (_stepInRound <= 8) {
      return _shapes.take(18).toList();
    }
    return _shapes;
  }

  void _generateQuestion(AppLocalizations loc) {
    final random = math.Random();
    final available = _getAvailableShapes();

    _isBonusLevel =
        _replayRound && _bonusStepSlot != null && _stepInRound == _bonusStepSlot;

    if (_isBonusLevel) {
      _generateBonusLevel(loc);
      return;
    }

    final target = available[random.nextInt(available.length)];
    _targetShapeType = target['type'] as ShapeType;
    _targetShapeNameKey = target['nameKey'] as String;
    _targetColor = target['color'] as Color;

    final wrongShapes = available.where((s) => s['nameKey'] != _targetShapeNameKey).toList();
    wrongShapes.shuffle(random);
    _options = [target, wrongShapes[0], wrongShapes[1]];
    _options.shuffle(random);
    _correctOption = target;

    if (_stepInRound >= 4 && (target['vertices'] as int) > 0 && random.nextBool()) {
      _questionType = QuestionType.vertexCount;
      _questionText = loc.get('geometry_castle_find_vertices').replaceAll('{0}', '${target['vertices']}');
    } else if (_stepInRound >= 6) {
      final equalEdgesShapes = available.where((s) => s['equalEdges'] == true).toList();
      final eqWrong = available.where((s) => s['equalEdges'] != true).toList();
      if (equalEdgesShapes.isNotEmpty && eqWrong.length >= 2 && random.nextBool()) {
        final eqTarget = equalEdgesShapes[random.nextInt(equalEdgesShapes.length)];
        _targetShapeType = eqTarget['type'] as ShapeType;
        _targetShapeNameKey = eqTarget['nameKey'] as String;
        _targetColor = eqTarget['color'] as Color;
        _questionType = QuestionType.equalEdges;
        _questionText = loc.get('geometry_castle_find_equal_edges');
        eqWrong.shuffle(random);
        _options = [eqTarget, eqWrong[0], eqWrong[1]];
        _options.shuffle(random);
        _correctOption = eqTarget;
      } else {
        _questionType = QuestionType.shapeName;
        _questionText = loc.get('geometry_castle_find_shape_format').replaceAll('{0}', loc.get(_targetShapeNameKey));
      }
    } else {
      _questionType = QuestionType.shapeName;
      _questionText = loc.get('geometry_castle_find_shape_format').replaceAll('{0}', loc.get(_targetShapeNameKey));
    }

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _generateBonusLevel(AppLocalizations loc) {
    final random = math.Random();
    final target = _shapes[random.nextInt(_shapes.length)];
    _targetShapeType = target['type'] as ShapeType;
    _targetShapeNameKey = target['nameKey'] as String;
    _targetColor = target['color'] as Color;
    _questionText = loc.get('geometry_castle_bonus_find').replaceAll('{0}', loc.get(_targetShapeNameKey));
    final wrongShapes = _shapes.where((s) => s['nameKey'] != _targetShapeNameKey).toList();
    wrongShapes.shuffle(random);
    _options = [target, wrongShapes[0], wrongShapes[1]];
    _options.shuffle(random);
    _correctOption = target;
    _questionType = QuestionType.shapeName;
    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _checkAnswer(Map<String, dynamic> selected) {
    if (_isAnswered || _gameOver) return;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) return;

    final correct = selected == _correctOption;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _sessQuestions++;
        _sessCorrect++;
        _runStreak++;
        if (_runStreak > _bestStreak) _bestStreak = _runStreak;
        _audio.playAnswerFeedback(true);
        _bgController.forward(from: 0);
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (_stepInRound < 10) {
            setState(() {
              _stepInRound++;
            });
            _generateQuestion(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale));
          } else {
            final gained = _replayRound ? 6 : 5;
            setState(() {
              _score += gained;
              _stars += 1;
            });
            _showRoundCompleteDialog(gained);
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

  void _reportGeometrySession() {
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
      debugPrint('GeometryCastle report error: $e');
    }
  }

  void _showNoLivesDialog() {
    _reportGeometrySession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏰', style: TextStyle(fontSize: 32)),
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

  void _showRoundCompleteDialog(int pointsEarned) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Flexible(child: Text(loc.get('geometry_castle_round_complete_title'), textAlign: TextAlign.center)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.get('geometry_castle_round_complete_body').replaceAll('{0}', '$pointsEarned'),
              textAlign: TextAlign.center,
              style: _textStyle(Colors.black87, size: 16),
            ),
            if (!_replayRound) ...[
              const SizedBox(height: 12),
              Text(
                loc.get('geometry_castle_round_complete_replay_hint'),
                textAlign: TextAlign.center,
                style: _textStyle(Colors.black54, size: 13),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _stepInRound = 1;
                _replayRound = true;
                _bonusStepSlot = math.Random().nextInt(10) + 1;
              });
              _generateQuestion(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale));
            },
            child: Text(loc.get('play_again')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBack();
            },
            child: Text(loc.get('exit')),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    _reportGeometrySession();
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏰', style: TextStyle(fontSize: 28)),
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
      body: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isCorrect
                    ? [
                        Color.lerp(const Color(0xFF1a237e), const Color(0xFFFFD700), _bgAnimation.value)!,
                        Color.lerp(const Color(0xFF4a148c), const Color(0xFFFFA500), _bgAnimation.value)!,
                        Color.lerp(const Color(0xFF880e4f), const Color(0xFFFFD700), _bgAnimation.value)!,
                      ]
                    : [
                        const Color(0xFF1a237e),
                        const Color(0xFF4a148c),
                        const Color(0xFF880e4f),
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
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildDoorCard(loc),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCorrect) _buildCelebration(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressPath(AppLocalizations loc) {
    const totalFloors = 10;
    final currentFloor = _stepInRound - 1;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('🏰', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(totalFloors, (i) {
                final isPassed = i < currentFloor;
                final isCurrent = i == currentFloor;
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.amber : (isCurrent ? Colors.white : Colors.white.withOpacity(0.3)),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: isCurrent ? 2 : 1),
                  ),
                  child: isPassed ? const Icon(Icons.check, size: 12, color: Colors.brown) : null,
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(loc.get('geometry_castle_floor').replaceAll('{0}', '${currentFloor + 1}').replaceAll('{1}', '$totalFloors'), style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAmbientEffects() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const headerReserve = 132.0;
        final topMax = math.max(headerReserve + 40, h - 24);
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Positioned(
                  top: math.min(72.0, h * 0.12) + _floatAnimation.value,
                  right: 12,
                  child: RepaintBoundary(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.32,
                        child: Text('🏰', style: TextStyle(fontSize: math.min(44, w * 0.11))),
                      ),
                    ),
                  ),
                );
              },
            ),
            ...List.generate(5, (i) {
              final r = math.Random(i);
              final top = headerReserve + r.nextDouble() * (topMax - headerReserve);
              final left = w * 0.08 + r.nextDouble() * (w * 0.84);
              return Positioned(
                top: top,
                left: left,
                child: RepaintBoundary(
                  child: Opacity(
                    opacity: 0.24,
                    child: Text(
                      '✨',
                      style: TextStyle(fontSize: 12 + r.nextDouble() * 6),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Consumer<GameMechanicsService>(
      builder: (context, mechanicsService, _) {
        final lives = mechanicsService.currentLives;
        final maxLives = mechanicsService.maxLives;
        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 400;
            final titleStyle = _textStyle(Colors.white, size: narrow ? 17 : 20, bold: true);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: narrow ? 42 : 44,
                      height: narrow ? 42 : 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _castlePurple.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white, size: narrow ? 22 : 24),
                    ),
                  ),
                  SizedBox(width: narrow ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('🏰 ', style: titleStyle),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  loc.get('world_geometry_castle'),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: titleStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          loc.get('world_geometry_castle_desc'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: narrow ? 11 : 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: narrow ? 4 : 8),
                  if (narrow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Text(
                        '🛡️ $lives/$maxLives',
                        style: _textStyle(Colors.white, size: 11, bold: true),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        maxLives,
                        (i) => Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            i < lives ? '🛡️' : '💨',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: narrow ? 4 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 8 : 12,
                      vertical: narrow ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '⭐ $_stars',
                      style: _textStyle(Colors.amber, size: narrow ? 13 : 16, bold: true),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Tek bir kapı kartı: soru + hedef şekil + anahtarlar (her anahtarda küçük geometrik şekil)
  Widget _buildDoorCard(AppLocalizations loc) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.3),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.98),
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _castlePurple.withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                BoxShadow(color: _castlePurple.withOpacity(0.2), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kapı başlığı - soru
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _gentleMotionController,
                      builder: (context, child) {
                        final ang = _gentleMotionController.value * 2 * math.pi;
                        return RepaintBoundary(
                          child: Transform.translate(
                            offset: Offset(0, 1.2 * math.sin(ang)),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _castlePink.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: _castlePurple, width: 2),
                              ),
                              child: const Center(child: Text('🦉', style: TextStyle(fontSize: 26))),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.get('helper_owl_name'), style: _textStyle(_castlePurple, size: 14, bold: true)),
                          const SizedBox(height: 2),
                          Text(
                            _isBonusLevel ? '⭐ BONUS: $_questionText' : '${loc.get('geometry_castle_open_door')}$_questionText',
                            style: _textStyle(Colors.black87, size: 14),
                            maxLines: 5,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Kapı gövdesi - seviyeye göre farklı kapı tipi
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _castlePurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _castlePurple.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🔐', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: _textStyle(_castlePurple, size: 14, bold: true),
                                children: [
                                  TextSpan(text: loc.get('geometry_castle_secret_door')),
                                  TextSpan(
                                    text: ' (${loc.get(_targetShapeNameKey)})',
                                    style: _textStyle(_castlePurple.withOpacity(0.75), size: 12, bold: false),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              maxLines: 4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CastleDoorWidget(
                        doorType: _currentDoorType,
                        targetShape: _targetShapeType,
                        size: 100,
                        doorColor: const Color(0xFF5D4037),
                        frameColor: const Color(0xFF3E2723),
                      ),
                      const SizedBox(height: 8),
                      Text(loc.get('geometry_castle_choose_key'), style: _textStyle(_castlePurple.withOpacity(0.8), size: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Anahtarlar - her birinde küçük geometrik şekil
                Text(loc.get('geometry_castle_keys'), style: _textStyle(_castlePurple, size: 14, bold: true)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _options
                      .map(
                        (opt) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildKeyButton(opt),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Anahtar butonu - üzerinde küçük geometrik şekil
  Widget _buildKeyButton(Map<String, dynamic> shape) {
    final isCorrect = shape == _correctOption;
    final isSelected = _isAnswered && isCorrect;
    final type = shape['type'] as ShapeType;
    final color = shape['color'] as Color;

    Color keyColor = const Color(0xFFD4AF37);
    Color borderColor = const Color(0xFFB8860B);
    if (_isAnswered) {
      keyColor = isCorrect ? const Color(0xFF2E7D32) : const Color(0xFF8B4513);
      borderColor = isCorrect ? const Color(0xFF1B5E20) : const Color(0xFF654321);
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && !_gameOver && mechanicsService.hasLives;
    return GestureDetector(
      onTap: canTap ? () => _checkAnswer(shape) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Anahtar başı - üzerinde küçük geometrik şekil
            Container(
              width: 72,
              height: 56,
              decoration: BoxDecoration(
                color: keyColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Küçük geometrik şekil anahtarın üzerinde
                  CustomPaint(
                    size: const Size(36, 36),
                    painter: ShapePainter(
                      shapeType: type,
                      fillColor: color.withOpacity(0.6),
                      strokeColor: color,
                      strokeWidth: 2,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            // Anahtar gövdesi (sap)
            Container(
              width: 14,
              height: 36,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: keyColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 1),
              ),
            ),
          ],
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
                        ['⭐', '✨', '🏰', '🔺', '⭕', '⬛'][r.nextInt(6)],
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
