import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Matematik Sanat Galerisi
/// Fraktallar, sayı resimleri, geometrik sanat
class MathArtGalleryScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MathArtGalleryScreen({super.key, required this.onBack});

  @override
  State<MathArtGalleryScreen> createState() => _MathArtGalleryScreenState();
}

class _MathArtGalleryScreenState extends State<MathArtGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedArtIndex = 0;

  final List<MathArt> _fractals = [
    MathArt(
      name: 'Sierpinski Üçgeni',
      description: 'Sonsuz kere bölünen üçgen',
      type: ArtType.fractal,
    ),
    MathArt(
      name: 'Koch Kar Tanesi',
      description: 'Kar tanesi şeklinde fraktal',
      type: ArtType.fractal,
    ),
    MathArt(
      name: 'Fraktal Ağaç',
      description: 'Dallanarak büyüyen ağaç',
      type: ArtType.fractal,
    ),
  ];

  final List<MathArt> _geometricArts = [
    MathArt(
      name: 'Mandala',
      description: 'Simetrik geometrik desen',
      type: ArtType.geometric,
    ),
    MathArt(
      name: 'Altın Spiral',
      description: 'Fibonacci spirali',
      type: ArtType.geometric,
    ),
    MathArt(
      name: 'Tessellation',
      description: 'Tekrarlayan şekil deseni',
      type: ArtType.geometric,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Tab bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(text: '🌀 Fraktallar'),
                    Tab(text: '🔷 Geometrik'),
                    Tab(text: '🎨 Oluştur'),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFractalGallery(),
                    _buildGeometricGallery(),
                    _buildArtCreator(),
                  ],
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
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎨 Matematik Sanat Galerisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Matematiğin güzelliğini keşfet!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFractalGallery() {
    return Column(
      children: [
        // Fraktal görüntüleme alanı
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildFractalViewer(_selectedArtIndex),
            ),
          ),
        ),

        // Fraktal seçimi
        Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _fractals.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedArtIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedArtIndex = index;
                  });
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.amber
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌀', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        _fractals[index].name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFractalViewer(int index) {
    switch (index) {
      case 0:
        return CustomPaint(
          painter: SierpinskiPainter(),
          size: Size.infinite,
        );
      case 1:
        return CustomPaint(
          painter: KochSnowflakePainter(),
          size: Size.infinite,
        );
      case 2:
        return CustomPaint(
          painter: FractalTreePainter(),
          size: Size.infinite,
        );
      default:
        return const Center(
          child: Text('🌀', style: TextStyle(fontSize: 80)),
        );
    }
  }

  Widget _buildGeometricGallery() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _geometricArts.length + 3, // + bonus kartlar
      itemBuilder: (context, index) {
        if (index < _geometricArts.length) {
          return _buildGeometricCard(_geometricArts[index]);
        }
        // Bonus kartlar
        return _buildBonusCard(index - _geometricArts.length);
      },
    );
  }

  Widget _buildGeometricCard(MathArt art) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.blue.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: CustomPaint(
                painter: MandalaPatternPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  art.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  art.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusCard(int index) {
    final bonusItems = [
      {'emoji': '🌈', 'name': 'Renk Çarkı'},
      {'emoji': '✨', 'name': 'Yıldız Deseni'},
      {'emoji': '🔮', 'name': 'Sihirli Kare'},
    ];

    if (index >= bonusItems.length) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bonusItems[index]['emoji']!,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            bonusItems[index]['name']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtCreator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Çizim alanı
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomPaint(
                painter: GridPainter(),
                child: const Center(
                  child: Text(
                    '🎨 Çizmeye Başla!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Araç çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton('🔺', 'Üçgen'),
                _buildToolButton('🔷', 'Kare'),
                _buildToolButton('⚪', 'Daire'),
                _buildToolButton('⭐', 'Yıldız'),
                _buildToolButton('🌈', 'Renk'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class MathArt {
  final String name;
  final String description;
  final ArtType type;

  MathArt({
    required this.name,
    required this.description,
    required this.type,
  });
}

enum ArtType { fractal, geometric, numberArt }

// Sierpinski Üçgeni Painter
class SierpinskiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    _drawSierpinski(
      canvas,
      paint,
      Offset(size.width / 2, 20),
      Offset(20, size.height - 20),
      Offset(size.width - 20, size.height - 20),
      5,
    );
  }

  void _drawSierpinski(Canvas canvas, Paint paint, Offset a, Offset b, Offset c, int depth) {
    if (depth == 0) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
      canvas.drawPath(path, paint);
      return;
    }

    final ab = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final bc = Offset((b.dx + c.dx) / 2, (b.dy + c.dy) / 2);
    final ca = Offset((c.dx + a.dx) / 2, (c.dy + a.dy) / 2);

    _drawSierpinski(canvas, paint, a, ab, ca, depth - 1);
    _drawSierpinski(canvas, paint, ab, b, bc, depth - 1);
    _drawSierpinski(canvas, paint, ca, bc, c, depth - 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Koch Kar Tanesi Painter
class KochSnowflakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Altıgen çiz
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final nextAngle = (i + 1) * math.pi / 3;
      
      final p1 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(nextAngle),
        center.dy + radius * math.sin(nextAngle),
      );
      
      _drawKochLine(canvas, paint, p1, p2, 3);
    }
  }

  void _drawKochLine(Canvas canvas, Paint paint, Offset start, Offset end, int depth) {
    if (depth == 0) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    
    final p1 = Offset(start.dx + dx / 3, start.dy + dy / 3);
    final p3 = Offset(start.dx + 2 * dx / 3, start.dy + 2 * dy / 3);
    
    final angle = math.atan2(dy, dx) - math.pi / 3;
    final length = math.sqrt(dx * dx + dy * dy) / 3;
    final p2 = Offset(
      p1.dx + length * math.cos(angle),
      p1.dy + length * math.sin(angle),
    );

    _drawKochLine(canvas, paint, start, p1, depth - 1);
    _drawKochLine(canvas, paint, p1, p2, depth - 1);
    _drawKochLine(canvas, paint, p2, p3, depth - 1);
    _drawKochLine(canvas, paint, p3, end, depth - 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Fraktal Ağaç Painter
class FractalTreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _drawBranch(
      canvas,
      paint,
      Offset(size.width / 2, size.height - 20),
      size.height * 0.25,
      -math.pi / 2,
      7,
    );
  }

  void _drawBranch(Canvas canvas, Paint paint, Offset start, double length, double angle, int depth) {
    if (depth == 0) return;

    final end = Offset(
      start.dx + length * math.cos(angle),
      start.dy + length * math.sin(angle),
    );

    paint.strokeWidth = depth.toDouble();
    paint.color = depth > 3 ? Colors.brown : Colors.green;
    canvas.drawLine(start, end, paint);

    _drawBranch(canvas, paint, end, length * 0.7, angle - 0.5, depth - 1);
    _drawBranch(canvas, paint, end, length * 0.7, angle + 0.5, depth - 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Mandala Desen Painter
class MandalaPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    for (int ring = 1; ring <= 5; ring++) {
      final radius = maxRadius * ring / 5;
      final petals = 6 + ring * 2;
      
      final paint = Paint()
        ..color = Colors.purple.withOpacity(0.3 + ring * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < petals; i++) {
        final angle = i * 2 * math.pi / petals;
        final petalCenter = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawCircle(petalCenter, maxRadius / (5 + ring), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Izgara Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

