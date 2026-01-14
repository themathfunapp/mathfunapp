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

  @override
  void initState() {
    super.initState();
    _initializePieces();
  }

  void _initializePieces() {
    _pieces = [
      TangramPiece(id: 1, shape: 'Triangle', color: Colors.red, size: 'Large'),
      TangramPiece(id: 2, shape: 'Triangle', color: Colors.blue, size: 'Large'),
      TangramPiece(id: 3, shape: 'Triangle', color: Colors.green, size: 'Medium'),
      TangramPiece(id: 4, shape: 'Square', color: Colors.yellow, size: 'Small'),
      TangramPiece(id: 5, shape: 'Parallelogram', color: Colors.orange, size: 'Small'),
    ];
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
              const SizedBox(height: 20),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
        children: [
          const Text(
            'Hedef Şekil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              border: Border.all(color: Colors.teal, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _TargetShapePainter(_targetShape),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _targetShape,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkArea() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.teal.shade300,
            width: 3,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                'Parçaları buraya sürükle',
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
      ),
    );
  }

  Widget _buildPlacedPiece(TangramPiece piece) {
    return Positioned(
      left: 100,
      top: 100,
      child: Draggable<TangramPiece>(
        data: piece,
        feedback: _buildPieceWidget(piece, isDragging: true),
        childWhenDragging: Container(),
        child: _buildPieceWidget(piece),
      ),
    );
  }

  Widget _buildPiecesPalette() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _pieces.map((piece) {
          return Draggable<TangramPiece>(
            data: piece,
            feedback: _buildPieceWidget(piece, isDragging: true),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildPieceWidget(piece),
            ),
            child: _buildPieceWidget(piece),
            onDragCompleted: () {
              // Piece was placed
            },
          );
        }).toList(),
      ),
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
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.8, size * 0.8),
          painter: _PieceShapePainter(piece.shape),
        ),
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

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    
    if (shape == 'Kare') {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * 0.8,
        height: size.height * 0.8,
      );
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }
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
    final radius = math.min(size.width, size.height) / 3;

    if (shape == 'Triangle') {
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx - radius, center.dy + radius)
        ..lineTo(center.dx + radius, center.dy + radius)
        ..close();
      canvas.drawPath(path, paint);
    } else if (shape == 'Square') {
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
