import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/game_mechanics_service.dart';
import '../services/daily_reward_service.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../widgets/child_exit_dialog.dart';
import '../models/daily_reward.dart' show TaskType;

class ShapeColoringScreen extends StatefulWidget {
  final String ageGroup;
  /// 1=Temel, 2=Karışık, 3=Gelişmiş, 4=Karmaşık
  final int levelMode;
  final int totalLevels;

  const ShapeColoringScreen({
    Key? key,
    required this.ageGroup,
    this.levelMode = 1,
    this.totalLevels = 20,
  }) : super(key: key);

  @override
  State<ShapeColoringScreen> createState() => _ShapeColoringScreenState();
}

class _ShapeColoringScreenState extends State<ShapeColoringScreen> {
  int _currentLevel = 1; // 1-20
  String _currentShape = 'Daire';
  Color? _selectedColor; // Seçili renk
  Color? _shapeColor; // Şeklin boyanmış rengi
  
  // Renk paleti
  final List<Color> _colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  static const List<String> _allShapes = [
    'Daire', 'Kare', 'Üçgen', 'Dikdörtgen', 'Yıldız', // 1-5: Temel
    'Kalp', 'Altıgen', 'Oval', 'Paralel', 'Yamuk', // 6-10: Karışık
    'Beşgen', 'Sekizgen', 'Çember', 'Eşkenar Üçgen', 'Dikdörtgen Üçgen', // 11-15: Gelişmiş
    'Elips', 'Trapez', 'Baklava', 'Pentagon', 'Hexagon', // 16-20: Karmaşık
  ];

  static const Map<String, String> _shapeToKey = {
    'Daire': 'shape_circle', 'Çember': 'shape_circle',
    'Kare': 'shape_square',
    'Üçgen': 'shape_triangle', 'Eşkenar Üçgen': 'shape_equilateral_triangle', 'Dikdörtgen Üçgen': 'shape_right_triangle',
    'Dikdörtgen': 'shape_rectangle',
    'Yıldız': 'shape_star',
    'Kalp': 'shape_heart',
    'Altıgen': 'shape_hexagon', 'Hexagon': 'shape_hexagon',
    'Oval': 'shape_oval', 'Elips': 'shape_ellipse',
    'Paralel': 'shape_parallelogram',
    'Yamuk': 'shape_trapezoid', 'Trapez': 'shape_trapezoid',
    'Beşgen': 'shape_pentagon', 'Pentagon': 'shape_pentagon',
    'Sekizgen': 'shape_octagon',
    'Baklava': 'shape_baklava',
  };

  void _loadLevel() {
    setState(() {
      _shapeColor = null;
      _selectedColor = null;
      
      final mode = widget.levelMode;
      final totalLevels = widget.totalLevels;
      int shapeIndex;
      if (mode == 1) {
        shapeIndex = (_currentLevel - 1).clamp(0, 4);
      } else if (mode == 2) {
        shapeIndex = 5 + (_currentLevel - 1).clamp(0, 4);
      } else if (mode == 3) {
        shapeIndex = 10 + (_currentLevel - 1).clamp(0, 4);
      } else {
        shapeIndex = 15 + (_currentLevel - 1).clamp(0, 4);
      }
      _currentShape = _allShapes[shapeIndex.clamp(0, _allShapes.length - 1)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade200,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildLevelInfo(),
                      const SizedBox(height: 30),
                      _buildShapeCanvas(),
                      const SizedBox(height: 30),
                      _buildColorPalette(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ChildExitDialog.show(
                context,
                themeColor: Colors.green,
                onStay: () {},
                onSectionSelect: () => Navigator.pop(context),
                onExit: () => Navigator.pop(context),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.green),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
              ),
              child: Text(
                '${loc.get('level')} $_currentLevel/${widget.totalLevels}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<GameMechanicsService>(
            builder: (context, mechanicsService, _) {
              final lives = mechanicsService.currentLives;
              final maxLives = mechanicsService.maxLives;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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

  Widget _buildLevelInfo() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    String levelType = '';
    final mode = widget.levelMode;
    if (mode == 1) levelType = loc.get('shape_mode_basic');
    else if (mode == 2) levelType = loc.get('shape_mode_mixed');
    else if (mode == 3) levelType = loc.get('shape_mode_advanced');
    else levelType = loc.get('shape_mode_complex');

    final shapeKey = _shapeToKey[_currentShape] ?? 'shape_circle';
    final shapeName = loc.get(shapeKey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            levelType,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.get('shape_label').replaceAll('%1', shapeName),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeCanvas() {
    return Center(
      child: Container(
        width: 350,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (_selectedColor != null) {
                  setState(() {
                    _shapeColor = _selectedColor;
                  });
                } else {
                  final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.get('select_color_first')),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Container(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _ShapePainter(
                    shape: _currentShape,
                    color: _shapeColor ?? Colors.grey[300]!,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
                final shapeKey = _shapeToKey[_currentShape] ?? 'shape_circle';
                return Text(
                  loc.get(shapeKey),
                  style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildColorPalette() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            '🎨 ${loc.get('color_palette')}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorPalette.map((color) {
              bool isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 4 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    bool isShapeColored = _shapeColor != null;
    
    return Center(
      child: SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: isShapeColored
              ? () {
                  final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
                  final rewardService = Provider.of<DailyRewardService>(context, listen: false);
                  // Sonraki seviyeye geç
                  if (_currentLevel < widget.totalLevels) {
                    // ignore: discarded_futures
                    mechanicsService.grantColorMathProgressCoins(baseCoins: 1, bonusCoins: 0);
                    // ignore: discarded_futures
                    mechanicsService.setColorMathProgress(module: 'shape', completedLevel: _currentLevel, totalLevels: widget.totalLevels);
                    // ignore: discarded_futures
                    rewardService.updateTaskProgress(TaskType.playColorMathStep, 1);
                    setState(() {
                      _currentLevel++;
                      _loadLevel();
                      _shapeColor = null;
                      _selectedColor = null;
                    });
                  } else {
                    // Mod tamam ödülü
                    // ignore: discarded_futures
                    mechanicsService.grantColorMathProgressCoins(baseCoins: 15, bonusCoins: 0);
                    // ignore: discarded_futures
                    mechanicsService.setColorMathProgress(module: 'shape', completedLevel: widget.totalLevels, totalLevels: widget.totalLevels);
                    // ignore: discarded_futures
                    rewardService.updateTaskProgress(TaskType.completeColorMath, 1);
                    // Oyun tamamlandı
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('🏆 ${loc.get('congratulations')}'),
                        content: Text(loc.get('all_shapes_colored')),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text(loc.get('finish')),
                          ),
                        ],
                      ),
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isShapeColored ? loc.get('complete_check') : loc.get('color_shape_first'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// Şekil çizen CustomPainter
class _ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  _ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;

    switch (shape) {
      case 'Daire':
      case 'Çember':
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, borderPaint);
        break;
        
      case 'Kare':
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 1.8,
          height: radius * 1.8,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
        break;
        
      case 'Üçgen':
      case 'Eşkenar Üçgen':
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx - radius, center.dy + radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Dikdörtgen':
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 2.2,
          height: radius * 1.4,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
        break;
        
      case 'Yıldız':
        final path = _createStarPath(center, radius, 5);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Kalp':
        final path = _createHeartPath(center, radius);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Altıgen':
      case 'Hexagon':
        final path = _createPolygonPath(center, radius, 6);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Beşgen':
      case 'Pentagon':
        final path = _createPolygonPath(center, radius, 5);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Sekizgen':
        final path = _createPolygonPath(center, radius, 8);
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Oval':
      case 'Elips':
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 2.2,
          height: radius * 1.4,
        );
        canvas.drawOval(rect, paint);
        canvas.drawOval(rect, borderPaint);
        break;
        
      case 'Baklava':
      case 'Elmas':
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Dikdörtgen Üçgen':
        final path = Path()
          ..moveTo(center.dx - radius, center.dy + radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy - radius)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      case 'Paralel':
      case 'Trapez':
      case 'Yamuk':
        final path = Path()
          ..moveTo(center.dx - radius * 0.7, center.dy - radius)
          ..lineTo(center.dx + radius * 0.7, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy + radius)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
        
      default:
        // Varsayılan: Daire
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, borderPaint);
    }
  }

  Path _createStarPath(Offset center, double radius, int points) {
    final path = Path();
    final angle = math.pi / points;
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < points * 2; i++) {
      final currentRadius = i.isEven ? radius : innerRadius;
      final x = center.dx + currentRadius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + currentRadius * math.sin(i * angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _createHeartPath(Offset center, double radius) {
    final path = Path();
    final width = radius * 1.5;
    final height = radius * 1.5;
    
    path.moveTo(center.dx, center.dy + height * 0.3);
    
    path.cubicTo(
      center.dx - width * 0.5, center.dy - height * 0.3,
      center.dx - width, center.dy + height * 0.1,
      center.dx, center.dy + height * 0.7,
    );
    
    path.cubicTo(
      center.dx + width, center.dy + height * 0.1,
      center.dx + width * 0.5, center.dy - height * 0.3,
      center.dx, center.dy + height * 0.3,
    );
    
    path.close();
    return path;
  }

  Path _createPolygonPath(Offset center, double radius, int sides) {
    final path = Path();
    final angle = 2 * math.pi / sides;
    
    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shape != shape;
  }
}

