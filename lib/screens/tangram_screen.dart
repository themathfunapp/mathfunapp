import 'package:flutter/material.dart';
import 'dart:math' as math;

class TangramScreen extends StatefulWidget {
  final String ageGroup;

  const TangramScreen({
    Key? key,
    required this.ageGroup,
  }) : super(key: key);

  @override
  State<TangramScreen> createState() => _TangramScreenState();
}

class _TangramScreenState extends State<TangramScreen> {
  int _level = 1;
  int _score = 0;
  String _targetShape = 'Kare';
  List<TangramPiece> _pieces = [];
  List<TangramPiece> _placedPieces = [];
  Map<int, Offset> _piecePositions = {};
  Offset? _lastDropLocalPosition;
  Size _workAreaSize = Size.zero;
  bool _isLevelComplete = false;
  final GlobalKey _workAreaKey = GlobalKey();

  static const List<String> _targetShapes = [
    'Kare', 'Üçgen', 'Dikdörtgen', 'Yamuk', 'Paralelkenar', 'Baklava', 'Altıgen',
  ];

  /// Her hedef için 4 FARKLI ama uyumlu parça (birbirine geçerek hedefi oluşturur)
  static const Map<String, List<Map<String, String>>> _targetPieces = {
    'Kare': [
      {'shape': 'Triangle', 'size': 'Large'},
      {'shape': 'Triangle', 'size': 'Large'},
      {'shape': 'Square', 'size': 'Medium'},
      {'shape': 'Parallelogram', 'size': 'Medium'},
    ],
    'Üçgen': [
      {'shape': 'Triangle', 'size': 'Large'},
      {'shape': 'Triangle', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Small'},
    ],
    'Dikdörtgen': [
      {'shape': 'Rectangle', 'size': 'Large'},
      {'shape': 'Rectangle', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Medium'},
    ],
    'Yamuk': [
      {'shape': 'Trapezoid', 'size': 'Large'},
      {'shape': 'Trapezoid', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Small'},
    ],
    'Paralelkenar': [
      {'shape': 'Parallelogram', 'size': 'Large'},
      {'shape': 'Parallelogram', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Medium'},
      {'shape': 'Triangle', 'size': 'Small'},
    ],
    'Baklava': [
      {'shape': 'Diamond', 'size': 'Medium'},
      {'shape': 'Diamond', 'size': 'Medium'},
      {'shape': 'Diamond', 'size': 'Medium'},
      {'shape': 'Diamond', 'size': 'Medium'},
    ],
    'Altıgen': [
      {'shape': 'Triangle', 'size': 'Large'},
      {'shape': 'Triangle', 'size': 'Medium'},
      {'shape': 'Trapezoid', 'size': 'Medium'},
      {'shape': 'Diamond', 'size': 'Small'},
    ],
  };

  static const List<Color> _pieceColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _initializeLevel();
  }

  void _initializeLevel() {
    final random = math.Random();
    _targetShape = _targetShapes[random.nextInt(_targetShapes.length)];
    final pieceDefs = _targetPieces[_targetShape] ?? _targetPieces['Kare']!;
    _pieces = List.generate(4, (i) {
      final p = pieceDefs[i];
      return TangramPiece(
        id: i + 1,
        shape: p['shape']!,
        color: _pieceColors[i],
        size: p['size']!,
      );
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
              Colors.teal.shade300,
              Colors.teal.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildTargetShape(),
              const SizedBox(height: 12),
              _buildCheckButton(),
              const SizedBox(height: 12),
              _buildWorkArea(),
              const SizedBox(height: 20),
              _buildPiecesPalette(),
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
          const Text(
            '🔺 Tangram',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetShape() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade600, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Bu 4 parçayı birleştirerek hedef şekli oluştur:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade400, width: 3),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(80, 80),
                    painter: _TargetShapePainter(_targetShape),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hedef şekil:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _targetShape,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkArea() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: DragTarget<TangramPiece>(
          onWillAcceptWithDetails: (details) => true,
          onMove: (details) {
            final box = _workAreaKey.currentContext?.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              final local = box.globalToLocal(details.offset);
              final pieceSize = details.data.size == 'Large' ? 80.0 : details.data.size == 'Small' ? 50.0 : 60.0;
              _lastDropLocalPosition = Offset(
                local.dx - pieceSize / 2,
                local.dy - pieceSize / 2,
              );
            }
          },
          onAcceptWithDetails: (details) {
            setState(() {
              final piece = details.data;
              final isRepositioning = _placedPieces.any((p) => p.id == piece.id);
              Offset localPos;
              if (isRepositioning && _lastDropLocalPosition != null) {
                localPos = _lastDropLocalPosition!;
                _lastDropLocalPosition = null;
              } else {
                localPos = _getCenterPosition(piece);
              }
              if (isRepositioning) {
                _piecePositions[piece.id] = localPos;
                _placedPieces.removeWhere((p) => p.id == piece.id);
                _placedPieces.add(piece);
              } else {
                _pieces.removeWhere((p) => p.id == piece.id);
                _placedPieces.add(piece);
                _piecePositions[piece.id] = localPos;
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkCompletion());
          },
          builder: (context, candidateData, rejectedData) {
            return LayoutBuilder(
              builder: (context, constraints) {
                _workAreaSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Container(
                  key: _workAreaKey,
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.teal.shade100.withOpacity(0.8)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: candidateData.isNotEmpty
                          ? Colors.teal.shade600
                          : Colors.teal.shade300,
                      width: candidateData.isNotEmpty ? 4 : 3,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                  Center(
                    child: Text(
                      _placedPieces.isEmpty
                          ? '4 parçayı buraya sürükle ve birleştir'
                          : '${_placedPieces.length}/4 parça yerleştirildi',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._placedPieces.map((piece) => _buildPlacedPiece(piece)),
                ],
              ),
            );
              },
            );
          },
        ),
      ),
    );
  }

  int get _totalPieceCount => _pieces.length + _placedPieces.length;

  void _checkCompletion() {
    if (!mounted || _isLevelComplete) return;
    final total = _totalPieceCount;
    if (total > 0 && _pieces.isEmpty && _placedPieces.length == total) {
      _isLevelComplete = true;
      setState(() {
        _score += 10;
        _level++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉 ', style: TextStyle(fontSize: 24)),
              Text(
                'Doğru! 4 parça yerleştirildi! +10 puan',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _isLevelComplete = false;
          _initializeLevel();
          _placedPieces.clear();
          _piecePositions.clear();
        });
      });
    }
  }

  Widget _buildCheckButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onCheckTapped,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Kontrol Et'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _onCheckTapped() {
    final total = _totalPieceCount;
    if (total > 0 && _pieces.isEmpty && _placedPieces.length == total) {
      _checkCompletion();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '4 parçanın hepsini yerleştir (${_placedPieces.length}/4)',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Offset _getCenterPosition(TangramPiece piece) {
    final pieceSize = piece.size == 'Large' ? 80.0 : piece.size == 'Small' ? 50.0 : 60.0;
    if (_workAreaSize.width > 0 && _workAreaSize.height > 0) {
      return Offset(
        _workAreaSize.width / 2 - pieceSize / 2,
        _workAreaSize.height / 2 - pieceSize / 2,
      );
    }
    return const Offset(80, 80);
  }

  Widget _buildPlacedPiece(TangramPiece piece) {
    final pos = _piecePositions[piece.id] ?? const Offset(50, 50);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Draggable<TangramPiece>(
        data: piece,
        feedback: _buildPieceWidget(piece, isDragging: true),
        childWhenDragging: Container(),
        child: _buildPieceWidget(piece),
      ),
    );
  }

  Widget _buildPiecesPalette() {
    return DragTarget<TangramPiece>(
      onWillAcceptWithDetails: (details) => _placedPieces.any((p) => p.id == details.data.id),
      onAcceptWithDetails: (details) {
        setState(() {
          final piece = details.data;
          if (_placedPieces.any((p) => p.id == piece.id)) {
            _placedPieces.removeWhere((p) => p.id == piece.id);
            _piecePositions.remove(piece.id);
            _pieces.add(piece);
            _pieces.sort((a, b) => a.id.compareTo(b.id));
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 140,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.teal.shade100
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.teal : Colors.transparent,
              width: candidateData.isNotEmpty ? 3 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: _pieces.isEmpty
              ? Center(
                  child: Text(
                    'Parçaları buraya geri bırak',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _pieces.map((piece) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Draggable<TangramPiece>(
                          data: piece,
                          feedback: _buildPieceWidget(piece, isDragging: true),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildPieceWidget(piece),
                          ),
                          child: _buildPieceWidget(piece),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Parça ${piece.id}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildPieceWidget(TangramPiece piece, {bool isDragging = false}) {
    double size = 60;
    if (piece.size == 'Large') size = 80;
    if (piece.size == 'Small') size = 50;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: piece.color.withOpacity(isDragging ? 0.7 : 1.0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: CustomPaint(
              size: Size(size * 0.7, size * 0.7),
              painter: _PieceShapePainter(piece.shape),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: piece.color, width: 2),
              ),
              child: Center(
                child: Text(
                  '${piece.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: piece.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TangramPiece {
  final int id;
  final String shape;
  final Color color;
  final String size;

  TangramPiece({
    required this.id,
    required this.shape,
    required this.color,
    required this.size,
  });
}

class _TargetShapePainter extends CustomPainter {
  final String shape;

  _TargetShapePainter(this.shape);

  Path _pathForShape(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width * 0.45;
    final h = size.height * 0.45;

    switch (shape) {
      case 'Kare':
        return Path()..addRect(Rect.fromCenter(center: center, width: w * 2, height: h * 2));
      case 'Üçgen':
        return Path()
          ..moveTo(center.dx, center.dy - h)
          ..lineTo(center.dx - w, center.dy + h)
          ..lineTo(center.dx + w, center.dy + h)
          ..close();
      case 'Dikdörtgen':
        return Path()..addRect(Rect.fromCenter(center: center, width: w * 2.2, height: h * 1.6));
      case 'Yamuk':
        return Path()
          ..moveTo(center.dx - w * 1.2, center.dy + h)
          ..lineTo(center.dx + w * 1.2, center.dy + h)
          ..lineTo(center.dx + w * 0.6, center.dy - h)
          ..lineTo(center.dx - w * 0.6, center.dy - h)
          ..close();
      case 'Paralelkenar':
        return Path()
          ..moveTo(center.dx - w * 1.2, center.dy + h)
          ..lineTo(center.dx + w * 0.8, center.dy + h)
          ..lineTo(center.dx + w * 1.2, center.dy - h)
          ..lineTo(center.dx - w * 0.8, center.dy - h)
          ..close();
      case 'Eşkenar Üçgen':
        final h2 = h * 1.2;
        return Path()
          ..moveTo(center.dx, center.dy - h2)
          ..lineTo(center.dx - w * 1.15, center.dy + h2 * 0.5)
          ..lineTo(center.dx + w * 1.15, center.dy + h2 * 0.5)
          ..close();
      case 'Altıgen':
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (i * 60 - 90) * math.pi / 180;
          final p = Offset(center.dx + w * math.cos(angle), center.dy + h * math.sin(angle));
          if (i == 0) path.moveTo(p.dx, p.dy);
          else path.lineTo(p.dx, p.dy);
        }
        path.close();
        return path;
      case 'Baklava':
        return Path()
          ..moveTo(center.dx, center.dy - h)
          ..lineTo(center.dx + w, center.dy)
          ..lineTo(center.dx, center.dy + h)
          ..lineTo(center.dx - w, center.dy)
          ..close();
      case 'Ok':
        return Path()
          ..moveTo(center.dx, center.dy - h)
          ..lineTo(center.dx + w * 0.5, center.dy)
          ..lineTo(center.dx, center.dy + h * 0.3)
          ..lineTo(center.dx - w * 0.5, center.dy)
          ..close();
      default:
        return Path()..addRect(Rect.fromCenter(center: center, width: w * 2, height: h * 2));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.teal.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(_pathForShape(size), paint);
    canvas.drawPath(_pathForShape(size), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieceShapePainter extends CustomPainter {
  final String shape;

  _PieceShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 3;

    switch (shape) {
      case 'Triangle':
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx - r, center.dy + r)
          ..lineTo(center.dx + r, center.dy + r)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'Square':
        canvas.drawRect(Rect.fromCenter(center: center, width: r * 2, height: r * 2), paint);
        break;
      case 'Parallelogram':
        final path = Path()
          ..moveTo(center.dx - r * 1.2, center.dy + r)
          ..lineTo(center.dx + r * 0.8, center.dy + r)
          ..lineTo(center.dx + r * 1.2, center.dy - r)
          ..lineTo(center.dx - r * 0.8, center.dy - r)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'Diamond':
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'Rectangle':
        canvas.drawRect(Rect.fromCenter(center: center, width: r * 2.2, height: r * 1.4), paint);
        break;
      case 'Circle':
        canvas.drawCircle(center, r, paint);
        break;
      case 'Pentagon':
        final path = Path();
        for (var i = 0; i < 5; i++) {
          final angle = (i * 72 - 90) * math.pi / 180;
          final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
          if (i == 0) path.moveTo(p.dx, p.dy);
          else path.lineTo(p.dx, p.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'Hexagon':
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (i * 60 - 90) * math.pi / 180;
          final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
          if (i == 0) path.moveTo(p.dx, p.dy);
          else path.lineTo(p.dx, p.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'Star':
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final angle = (i * 36 - 90) * math.pi / 180;
          final rad = i.isEven ? r : r * 0.5;
          final p = Offset(center.dx + rad * math.cos(angle), center.dy + rad * math.sin(angle));
          if (i == 0) path.moveTo(p.dx, p.dy);
          else path.lineTo(p.dx, p.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'Trapezoid':
        final path = Path()
          ..moveTo(center.dx - r * 1.1, center.dy + r)
          ..lineTo(center.dx + r * 1.1, center.dy + r)
          ..lineTo(center.dx + r * 0.5, center.dy - r)
          ..lineTo(center.dx - r * 0.5, center.dy - r)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'Heart':
        final path = Path();
        path.moveTo(center.dx, center.dy + r * 0.3);
        path.cubicTo(center.dx - r * 1.2, center.dy - r * 0.5, center.dx - r, center.dy - r * 1.2, center.dx, center.dy - r * 0.5);
        path.cubicTo(center.dx + r, center.dy - r * 1.2, center.dx + r * 1.2, center.dy - r * 0.5, center.dx, center.dy + r * 0.3);
        path.close();
        canvas.drawPath(path, paint);
        break;
      default:
        canvas.drawRect(Rect.fromCenter(center: center, width: r * 2, height: r * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
