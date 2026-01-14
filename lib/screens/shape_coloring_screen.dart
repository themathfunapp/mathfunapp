import 'package:flutter/material.dart';
import 'dart:math' as math;

class ShapeColoringScreen extends StatefulWidget {
  final String ageGroup;

  const ShapeColoringScreen({
    Key? key,
    required this.ageGroup,
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

  void _loadLevel() {
    setState(() {
      _shapeColor = null;
      _selectedColor = null;
      
      // Seviyeye göre şekil belirle
      List<String> shapes = [
        'Daire', 'Kare', 'Üçgen', 'Dikdörtgen', 'Yıldız', // 1-5: Temel
        'Kalp', 'Altıgen', 'Oval', 'Paralel', 'Yamuk', // 6-10: Karışık
        'Beşgen', 'Sekizgen', 'Çember', 'Eşkenar Üçgen', 'Dikdörtgen Üçgen', // 11-15: Gelişmiş
        'Elips', 'Trapez', 'Baklava', 'Pentagon', 'Hexagon', // 16-20: Karmaşık
      ];
      
      if (_currentLevel <= shapes.length) {
        _currentShape = shapes[_currentLevel - 1];
      }
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Seviye $_currentLevel/20',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo() {
    String levelType = '';
    if (_currentLevel <= 5) {
      levelType = 'Temel Şekiller';
    } else if (_currentLevel <= 10) {
      levelType = 'Karışık Şekiller';
    } else if (_currentLevel <= 15) {
      levelType = 'Kompozisyonlar';
    } else {
      levelType = 'Karmaşık Desenler';
    }

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
            'Şekil: $_currentShape',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Önce bir renk seçin!'),
                      duration: Duration(seconds: 2),
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
            Text(
              _currentShape,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildColorPalette() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            '🎨 Renk Paleti',
            style: TextStyle(
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
    bool isShapeColored = _shapeColor != null;
    
    return Center(
      child: SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: isShapeColored
              ? () {
                  // Sonraki seviyeye geç
                  if (_currentLevel < 20) {
                    setState(() {
                      _currentLevel++;
                      _loadLevel();
                      _shapeColor = null;
                      _selectedColor = null;
                    });
                  } else {
                    // Oyun tamamlandı
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('🏆 Tebrikler!'),
                        content: const Text('Tüm şekilleri boyadınız!'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Bitir'),
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
            isShapeColored ? 'Tamamla ✓' : 'Önce şekli boyayın',
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

