import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/castle_door.dart';
import 'shape_painter.dart';

/// Şato kapısı widget'ı - farklı kapı stillerinde hedef şekli gösterir
class CastleDoorWidget extends StatelessWidget {
  final CastleDoorType doorType;
  final ShapeType targetShape;
  final double size;
  final Color doorColor;
  final Color frameColor;

  const CastleDoorWidget({
    super.key,
    required this.doorType,
    required this.targetShape,
    this.size = 120,
    this.doorColor = const Color(0xFF5D4037),
    this.frameColor = const Color(0xFF3E2723),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: CustomPaint(
        painter: CastleDoorPainter(
          doorType: doorType,
          targetShape: targetShape,
          doorColor: doorColor,
          frameColor: frameColor,
        ),
      ),
    );
  }
}

/// Kapı çerçevesi ve içindeki şekil silüetini çizer
class CastleDoorPainter extends CustomPainter {
  final CastleDoorType doorType;
  final ShapeType targetShape;
  final Color doorColor;
  final Color frameColor;

  CastleDoorPainter({
    required this.doorType,
    required this.targetShape,
    this.doorColor = const Color(0xFF5D4037),
    this.frameColor = const Color(0xFF3E2723),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final doorWidth = size.width * 0.85;
    final doorHeight = size.height * 0.75;

    // Kapı arka planı
    _drawDoorBackground(canvas, size, doorWidth, doorHeight);

    // Şekil alanı (ortada)
    final shapeSize = math.min(doorWidth, doorHeight) * 0.45;
    final shapeCanvasSize = shapeSize + 20;
    canvas.save();
    canvas.translate(
      center.dx - shapeCanvasSize / 2,
      center.dy - shapeCanvasSize / 2,
    );
    ShapePainter(
      shapeType: targetShape,
      fillColor: Colors.grey.shade700,
      strokeColor: Colors.grey.shade900,
      strokeWidth: 2,
      size: shapeSize,
    ).paint(canvas, Size(shapeCanvasSize, shapeCanvasSize));
    canvas.restore();

    // Kapı çerçevesi (tipine göre)
    _drawDoorFrame(canvas, size, doorWidth, doorHeight);
  }

  void _drawDoorBackground(Canvas canvas, Size size, double w, double h) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: w, height: h);

    final bgPaint = Paint()
      ..color = doorColor
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    switch (doorType) {
      case CastleDoorType.arched:
        _drawArchedPath(canvas, rect, bgPaint, framePaint);
        break;
      case CastleDoorType.rectangular:
        canvas.drawRect(rect, bgPaint);
        canvas.drawRect(rect, framePaint);
        break;
      case CastleDoorType.gothic:
        _drawGothicPath(canvas, rect, bgPaint, framePaint);
        break;
      case CastleDoorType.wooden:
        canvas.drawRect(rect, bgPaint);
        canvas.drawRect(rect, framePaint);
        _drawWoodenDetails(canvas, rect);
        break;
      case CastleDoorType.doubleLeaf:
        _drawDoubleLeafPath(canvas, rect, bgPaint, framePaint);
        break;
      case CastleDoorType.medieval:
        canvas.drawRect(rect, bgPaint);
        canvas.drawRect(rect, framePaint);
        _drawMedievalStuds(canvas, rect);
        break;
      case CastleDoorType.squareArch:
        _drawSquareArchPath(canvas, rect, bgPaint, framePaint);
        break;
      case CastleDoorType.roundTop:
        _drawRoundTopPath(canvas, rect, bgPaint, framePaint);
        break;
    }
  }

  void _drawArchedPath(Canvas canvas, Rect rect, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height * 0.4)
      ..quadraticBezierTo(
        rect.left, rect.top,
        rect.center.dx, rect.top,
      )
      ..quadraticBezierTo(
        rect.right, rect.top,
        rect.right, rect.top + rect.height * 0.4,
      )
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawGothicPath(Canvas canvas, Rect rect, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height * 0.35)
      ..quadraticBezierTo(rect.left, rect.top - 10, rect.center.dx - 5, rect.top + 15)
      ..lineTo(rect.center.dx + 5, rect.top + 15)
      ..quadraticBezierTo(rect.right, rect.top - 10, rect.right, rect.top + rect.height * 0.35)
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawDoubleLeafPath(Canvas canvas, Rect rect, Paint fill, Paint stroke) {
    final halfW = rect.width / 2;
    final leftRect = Rect.fromLTWH(rect.left, rect.top, halfW - 2, rect.height);
    final rightRect = Rect.fromLTWH(rect.center.dx + 2, rect.top, halfW - 2, rect.height);
    canvas.drawRect(leftRect, fill);
    canvas.drawRect(rightRect, fill);
    canvas.drawRect(rect, stroke);
  }

  void _drawSquareArchPath(Canvas canvas, Rect rect, Paint fill, Paint stroke) {
    final topRect = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.25);
    final mainRect = Rect.fromLTWH(rect.left, rect.top + rect.height * 0.2, rect.width, rect.height * 0.8);
    final path = Path()
      ..addRect(mainRect)
      ..addRect(topRect);
    canvas.drawPath(path, fill);
    canvas.drawRect(rect, stroke);
  }

  void _drawRoundTopPath(Canvas canvas, Rect rect, Paint fill, Paint stroke) {
    final r = rect.width / 2;
    final path = Path()
      ..moveTo(rect.left, rect.center.dy)
      ..lineTo(rect.left, rect.top + r)
      ..arcTo(Rect.fromCircle(center: rect.center, radius: r), math.pi, math.pi, false)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawWoodenDetails(Canvas canvas, Rect rect) {
    final detailPaint = Paint()
      ..color = frameColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(rect.center.dx, rect.top), Offset(rect.center.dx, rect.bottom), detailPaint);
    canvas.drawLine(Offset(rect.left + rect.width * 0.25, rect.top), Offset(rect.left + rect.width * 0.25, rect.bottom), detailPaint);
    canvas.drawLine(Offset(rect.right - rect.width * 0.25, rect.top), Offset(rect.right - rect.width * 0.25, rect.bottom), detailPaint);
  }

  void _drawMedievalStuds(Canvas canvas, Rect rect) {
    final studPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;
    const count = 3;
    const inset = 0.12;
    const radius = 4.0;
    for (var i = 0; i < count; i++) {
      for (var j = 0; j < count; j++) {
        final x = rect.left + rect.width * (inset + (1 - 2 * inset) * (i + 1) / (count + 1));
        final y = rect.top + rect.height * (inset + (1 - 2 * inset) * (j + 1) / (count + 1));
        canvas.drawCircle(Offset(x, y), radius, studPaint);
      }
    }
  }

  void _drawDoorFrame(Canvas canvas, Size size, double w, double h) {
    // Ek çerçeve detayları
  }

  @override
  bool shouldRepaint(covariant CastleDoorPainter oldDelegate) =>
      oldDelegate.doorType != doorType ||
      oldDelegate.targetShape != targetShape ||
      oldDelegate.doorColor != doorColor ||
      oldDelegate.frameColor != frameColor;
}
