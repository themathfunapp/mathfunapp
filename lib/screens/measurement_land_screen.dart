import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/game_mechanics_service.dart';

/// Ölçüm Diyarı - Büyük-küçük, uzun-kısa kavramlarını öğren!
class MeasurementLandScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MeasurementLandScreen({super.key, required this.onBack});

  @override
  State<MeasurementLandScreen> createState() => _MeasurementLandScreenState();
}

class _MeasurementLandScreenState extends State<MeasurementLandScreen>
    with TickerProviderStateMixin {
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
        _score += _isBonusLevel ? 25 : 10;
        _stars += _isBonusLevel ? 2 : 1;
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateQuestion(AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale));
          }
        });
      } else {
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

  void _showNoLivesDialog() {
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
                  _buildProgressPath(loc),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildQuestionCard(loc),
                          const SizedBox(height: 24),
                          _buildVisualDisplay(loc),
                          const SizedBox(height: 24),
                          _buildOptionsGrid(loc),
                          const SizedBox(height: 24),
                        ],
                      ),
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
          final compact = constraints.maxWidth < 430;
          final dotSize = compact ? 14.0 : 20.0;
          final iconSize = compact ? 10.0 : 12.0;
          final levelText = loc
              .get('measurement_level_format')
              .replaceAll('{0}', '${currentFloor + 1}')
              .replaceAll('{1}', '$totalFloors');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact)
                Text(
                  levelText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                  ),
                ),
              if (!compact) const SizedBox(height: 8),
              Row(
                children: [
                  Text('📏', style: TextStyle(fontSize: compact ? 18 : 20)),
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
                                : (isCurrent
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: isPassed
                              ? Icon(Icons.check,
                                  size: iconSize, color: _orange)
                              : null,
                        );
                      }),
                    ),
                  ),
                  if (compact) const SizedBox(width: 8),
                  if (compact)
                    Text(
                      '${currentFloor + 1}/$totalFloors',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
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
          final compact = constraints.maxWidth < 430;
          return Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange.withOpacity(0.6)),
                  ),
                  child:
                      const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📏 ${loc.get('world_measurement_land')}',
                      style: _textStyle(
                        Colors.white,
                        size: compact ? 16 : 20,
                        bold: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact)
                      Text(
                        loc.get('world_measurement_land_desc'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 1,
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
                  if (compact) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 1),
                      ),
                      child: Text(
                        '🐢 $lives/$maxLives',
                        style: _textStyle(Colors.white, size: 12, bold: true),
                      ),
                    );
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      maxLives,
                      (i) => Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          i < lives ? '🐢' : '🐚',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '⭐ $_stars',
                  style: _textStyle(
                    Colors.amber,
                    size: compact ? 13 : 16,
                    bold: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orange.withOpacity(0.6), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15)],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _yellow.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange, width: 2),
                  ),
                  child: const Center(child: Text('🐢', style: TextStyle(fontSize: 32))),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.get('helper_turtle_name'), style: _textStyle(_orange, size: 16, bold: true)),
                const SizedBox(height: 6),
                Text(
                  _questionText,
                  style: _textStyle(Colors.black87, size: 18),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualDisplay(AppLocalizations loc) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value * 0.3),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _orange.withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: _orange.withOpacity(0.2), blurRadius: 20)],
            ),
            child: Column(
              children: [
                Text('🔍 ${loc.get('measurement_look_carefully')}', style: _textStyle(_orange, size: 16, bold: true)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _options.map((emoji) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _orange.withOpacity(0.3)),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 48)),
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

  Widget _buildOptionsGrid(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          Text(loc.get('choose_answer'), style: _textStyle(_orange, size: 16, bold: true)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _options.map((emoji) => _buildOptionButton(emoji)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String emoji) {
    final isCorrect = emoji == _correctAnswer;
    final isSelected = _isAnswered && isCorrect;

    Color bgColor = Colors.white.withOpacity(0.9);
    if (_isAnswered) {
      bgColor = isCorrect ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.2);
    }

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    final canTap = !_isAnswered && !_gameOver && mechanicsService.hasLives;
    return GestureDetector(
      onTap: canTap ? () => _checkAnswer(emoji) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : _orange.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
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
