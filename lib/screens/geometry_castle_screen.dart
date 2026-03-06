import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../models/castle_door.dart';
import '../providers/locale_provider.dart';
import '../widgets/castle_door_widget.dart';
import '../widgets/shape_painter.dart';

/// Geometri Şatosu - Şekilleri kullanarak gizli kapıları aç!
class GeometryCastleScreen extends StatefulWidget {
  final VoidCallback onBack;

  const GeometryCastleScreen({super.key, required this.onBack});

  @override
  State<GeometryCastleScreen> createState() => _GeometryCastleScreenState();
}

enum QuestionType { shapeName, vertexCount, equalEdges }

class _GeometryCastleScreenState extends State<GeometryCastleScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _celebrationController;
  late AnimationController _bgController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _bgAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  int _lives = 5;
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isBonusLevel = false;

  // Şekil tanımları: type, isim, köşe sayısı, kenar eşitliği
  // Flaticon / Icons8 polygon stillerine uygun geniş çeşitlilik
  final List<Map<String, dynamic>> _shapes = [
    {'type': ShapeType.circle, 'name': 'daire', 'vertices': 0, 'equalEdges': false, 'color': Color(0xFFE91E63)},
    {'type': ShapeType.oval, 'name': 'oval', 'vertices': 0, 'equalEdges': false, 'color': Color(0xFFE040FB)},
    {'type': ShapeType.semicircle, 'name': 'yarım daire', 'vertices': 0, 'equalEdges': false, 'color': Color(0xFFAB47BC)},
    {'type': ShapeType.square, 'name': 'kare', 'vertices': 4, 'equalEdges': true, 'color': Color(0xFF2196F3)},
    {'type': ShapeType.rectangle, 'name': 'dikdörtgen', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFFFF9800)},
    {'type': ShapeType.roundedRect, 'name': 'yuvarlatılmış dikdörtgen', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFF42A5F5)},
    {'type': ShapeType.triangle, 'name': 'üçgen', 'vertices': 3, 'equalEdges': true, 'color': Color(0xFF4CAF50)},
    {'type': ShapeType.rightTriangle, 'name': 'dik üçgen', 'vertices': 3, 'equalEdges': false, 'color': Color(0xFF81C784)},
    {'type': ShapeType.diamond, 'name': 'elmas', 'vertices': 4, 'equalEdges': true, 'color': Color(0xFF26A69A)},
    {'type': ShapeType.kite, 'name': 'uçurtma', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFF8D6E63)},
    {'type': ShapeType.trapezoid, 'name': 'yamuk', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFFA1887F)},
    {'type': ShapeType.parallelogram, 'name': 'paralelkenar', 'vertices': 4, 'equalEdges': false, 'color': Color(0xFF7E57C2)},
    {'type': ShapeType.pentagon, 'name': 'beşgen', 'vertices': 5, 'equalEdges': true, 'color': Color(0xFF9C27B0)},
    {'type': ShapeType.hexagon, 'name': 'altıgen', 'vertices': 6, 'equalEdges': true, 'color': Color(0xFF00BCD4)},
    {'type': ShapeType.heptagon, 'name': 'yedigen', 'vertices': 7, 'equalEdges': true, 'color': Color(0xFFEF5350)},
    {'type': ShapeType.octagon, 'name': 'sekizgen', 'vertices': 8, 'equalEdges': true, 'color': Color(0xFF795548)},
    {'type': ShapeType.nonagon, 'name': 'dokuzgen', 'vertices': 9, 'equalEdges': true, 'color': Color(0xFF5C6BC0)},
    {'type': ShapeType.decagon, 'name': 'ongen', 'vertices': 10, 'equalEdges': true, 'color': Color(0xFF66BB6A)},
    {'type': ShapeType.hendecagon, 'name': 'onbirgen', 'vertices': 11, 'equalEdges': true, 'color': Color(0xFFEC407A)},
    {'type': ShapeType.dodecagon, 'name': 'onikigen', 'vertices': 12, 'equalEdges': true, 'color': Color(0xFF26C6DA)},
    {'type': ShapeType.star, 'name': 'beş köşeli yıldız', 'vertices': 10, 'equalEdges': true, 'color': Color(0xFFFFC107)},
    {'type': ShapeType.star6, 'name': 'altı köşeli yıldız', 'vertices': 12, 'equalEdges': true, 'color': Color(0xFFFF7043)},
    {'type': ShapeType.cross, 'name': 'artı', 'vertices': 12, 'equalEdges': true, 'color': Color(0xFFBDBDBD)},
  ];

  ShapeType _targetShapeType = ShapeType.circle;
  String _targetShapeName = '';
  Color _targetColor = Colors.blue;
  String _questionText = '';
  QuestionType _questionType = QuestionType.shapeName;
  List<Map<String, dynamic>> _options = [];
  Map<String, dynamic>? _correctOption;

  static const Color _castlePurple = Color(0xFF9C27B0);
  static const Color _castlePink = Color(0xFFE91E63);

  static const List<CastleDoorType> _doorTypes = CastleDoorType.values;

  /// Seviyeye göre kapı tipi (her 2 seviyede bir değişir)
  CastleDoorType get _currentDoorType =>
      _doorTypes[(_currentLevel - 1) % _doorTypes.length];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
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

    _generateQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _celebrationController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAvailableShapes() {
    if (_currentLevel <= 2) {
      return _shapes.take(4).toList();
    } else if (_currentLevel <= 4) {
      return _shapes.take(8).toList();
    } else if (_currentLevel <= 6) {
      return _shapes.take(14).toList();
    } else if (_currentLevel <= 8) {
      return _shapes.take(18).toList();
    }
    return _shapes;
  }

  void _generateQuestion() {
    final random = math.Random();
    final available = _getAvailableShapes();

    _isBonusLevel = _currentLevel % 5 == 0 && _currentLevel > 0;

    if (_isBonusLevel) {
      _generateBonusLevel();
      return;
    }

    final target = available[random.nextInt(available.length)];
    _targetShapeType = target['type'] as ShapeType;
    _targetShapeName = target['name'] as String;
    _targetColor = target['color'] as Color;

    final wrongShapes = available.where((s) => s['name'] != _targetShapeName).toList();
    wrongShapes.shuffle(random);
    _options = [target, wrongShapes[0], wrongShapes[1]];
    _options.shuffle(random);
    _correctOption = target;

    if (_currentLevel >= 4 && (target['vertices'] as int) > 0 && random.nextBool()) {
      _questionType = QuestionType.vertexCount;
      _questionText = '${target['vertices']} köşesi olan şekli bul!';
    } else if (_currentLevel >= 6) {
      final equalEdgesShapes = available.where((s) => s['equalEdges'] == true).toList();
      final eqWrong = available.where((s) => s['equalEdges'] != true).toList();
      if (equalEdgesShapes.isNotEmpty && eqWrong.length >= 2 && random.nextBool()) {
        final eqTarget = equalEdgesShapes[random.nextInt(equalEdgesShapes.length)];
        _targetShapeType = eqTarget['type'] as ShapeType;
        _targetShapeName = eqTarget['name'] as String;
        _targetColor = eqTarget['color'] as Color;
        _questionType = QuestionType.equalEdges;
        _questionText = 'Kenarları eşit olan şekli bul!';
        eqWrong.shuffle(random);
        _options = [eqTarget, eqWrong[0], eqWrong[1]];
        _options.shuffle(random);
        _correctOption = eqTarget;
      } else {
        _questionType = QuestionType.shapeName;
        _questionText = '$_targetShapeName şeklini bul!';
      }
    } else {
      _questionType = QuestionType.shapeName;
      _questionText = '$_targetShapeName şeklini bul!';
    }

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _generateBonusLevel() {
    final random = math.Random();
    final target = _shapes[random.nextInt(_shapes.length)];
    _targetShapeType = target['type'] as ShapeType;
    _targetShapeName = target['name'] as String;
    _targetColor = target['color'] as Color;
    _questionText = '$_targetShapeName şeklini bul! Bonus yıldız kazan!';
    final wrongShapes = _shapes.where((s) => s['name'] != _targetShapeName).toList();
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
    if (_isAnswered) return;
    final correct = selected == _correctOption;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      if (correct) {
        _score += _isBonusLevel ? 25 : 10;
        _stars += _isBonusLevel ? 2 : 1;
        _bgController.forward(from: 0);
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateQuestion();
          }
        });
      } else {
        _lives = (_lives - 1).clamp(0, 5);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _generateQuestion();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);

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
                      _buildProgressPath(),
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

  Widget _buildProgressPath() {
    final totalFloors = 10;
    final currentFloor = (_currentLevel - 1) % totalFloors;
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
          Text('Kat ${currentFloor + 1}/$totalFloors', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAmbientEffects() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              top: 60 + _floatAnimation.value,
              right: 20,
              child: Text('🏰', style: TextStyle(fontSize: 50)),
            );
          },
        ),
        ...List.generate(6, (i) {
          final r = math.Random(i);
          return Positioned(
            top: r.nextDouble() * 300,
            left: r.nextDouble() * 300,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + _pulseAnimation.value * 0.2,
                  child: Text('✨', style: TextStyle(fontSize: 16 + r.nextDouble() * 8)),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _castlePurple.withOpacity(0.5)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏰 Geometri Şatosu', style: _textStyle(Colors.white, size: 20, bold: true)),
                Text(_getLocalized('world_geometry_castle_desc'), style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(i < _lives ? '🛡️' : '💨', style: const TextStyle(fontSize: 20)),
            )),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('⭐ $_stars', style: _textStyle(Colors.amber, size: 16, bold: true)),
          ),
        ],
      ),
    );
  }

  String _getLocalized(String key) {
    return AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale).get(key);
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
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
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
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Şekil Ustası Baykuş', style: _textStyle(_castlePurple, size: 14, bold: true)),
                          const SizedBox(height: 2),
                          Text(
                            _isBonusLevel ? '⭐ BONUS: $_questionText' : 'Bu kapıyı aç! $_questionText',
                            style: _textStyle(Colors.black87, size: 14),
                            maxLines: 2,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔐', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text('Gizli kapı', style: _textStyle(_castlePurple, size: 15, bold: true)),
                          const SizedBox(width: 6),
                          Text('(${_currentDoorType.displayName})', style: _textStyle(_castlePurple.withOpacity(0.7), size: 12)),
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
                      Text('Doğru anahtarı seç', style: _textStyle(_castlePurple.withOpacity(0.8), size: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Anahtarlar - her birinde küçük geometrik şekil
                Text('Anahtarlar:', style: _textStyle(_castlePurple, size: 14, bold: true)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _options.map((opt) => _buildKeyButton(opt)).toList(),
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

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(shape),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 88,
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
