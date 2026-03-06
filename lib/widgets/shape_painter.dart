import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter ile çizilen geometrik şekiller
/// Flaticon / Icons8 polygon stillerine uygun geniş çeşitlilik
enum ShapeType {
  circle,
  oval,
  semicircle,
  square,
  rectangle,
  roundedRect,
  triangle,
  rightTriangle,
  diamond,
  kite,
  trapezoid,
  parallelogram,
  pentagon,
  hexagon,
  heptagon,
  octagon,
  nonagon,
  decagon,
  hendecagon,
  dodecagon,
  star,
  star6,
  cross,
}

class ShapePainter extends CustomPainter {
  final ShapeType shapeType;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final bool filled;
  final double size;

  ShapePainter({
    required this.shapeType,
    this.fillColor = Colors.blue,
    this.strokeColor = const Color(0xFF1565C0),
    this.strokeWidth = 2,
    this.filled = true,
    this.size = 60,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final r = size / 2;

    final paint = Paint()
      ..color = filled ? fillColor : Colors.transparent
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    switch (shapeType) {
      case ShapeType.circle:
        canvas.drawCircle(center, r - strokeWidth, paint);
        canvas.drawCircle(center, r - strokeWidth, strokePaint);
        break;
      case ShapeType.oval:
        _drawOval(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.semicircle:
        _drawSemicircle(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.square:
        _drawSquare(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.rectangle:
        _drawRectangle(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.roundedRect:
        _drawRoundedRect(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.rightTriangle:
        _drawRightTriangle(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.diamond:
        _drawDiamond(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.kite:
        _drawKite(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.trapezoid:
        _drawTrapezoid(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.parallelogram:
        _drawParallelogram(canvas, center, r, paint, strokePaint);
        break;
      case ShapeType.pentagon:
        _drawPolygon(canvas, center, r, 5, paint, strokePaint);
        break;
      case ShapeType.hexagon:
        _drawPolygon(canvas, center, r, 6, paint, strokePaint);
        break;
      case ShapeType.heptagon:
        _drawPolygon(canvas, center, r, 7, paint, strokePaint);
        break;
      case ShapeType.octagon:
        _drawPolygon(canvas, center, r, 8, paint, strokePaint);
        break;
      case ShapeType.nonagon:
        _drawPolygon(canvas, center, r, 9, paint, strokePaint);
        break;
      case ShapeType.decagon:
        _drawPolygon(canvas, center, r, 10, paint, strokePaint);
        break;
      case ShapeType.hendecagon:
        _drawPolygon(canvas, center, r, 11, paint, strokePaint);
        break;
      case ShapeType.dodecagon:
        _drawPolygon(canvas, center, r, 12, paint, strokePaint);
        break;
      case ShapeType.star:
        _drawStar(canvas, center, r, 5, paint, strokePaint);
        break;
      case ShapeType.star6:
        _drawStar(canvas, center, r, 6, paint, strokePaint);
        break;
      case ShapeType.cross:
        _drawCross(canvas, center, r, paint, strokePaint);
        break;
    }
  }

  void _drawSquare(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 2);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  void _drawRectangle(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    // Dikdörtgen: genişlik > yükseklik (2:1 oran)
    final w = r * 1.6;
    final h = r * 0.8;
    final rect = Rect.fromCenter(center: center, width: w * 2, height: h * 2);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  void _drawTriangle(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawPolygon(Canvas canvas, Offset center, double r, int sides, Paint fill, Paint stroke) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawOval(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 1.2);
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, stroke);
  }

  void _drawSemicircle(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 2);
    final path = Path()..addArc(rect, 0, math.pi)..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawRoundedRect(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final rect = Rect.fromCenter(center: center, width: r * 1.6, height: r * 1.2);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.3));
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, stroke);
  }

  void _drawRightTriangle(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - r, center.dy + r)
      ..lineTo(center.dx - r, center.dy - r)
      ..lineTo(center.dx + r, center.dy + r)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawKite(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.7, center.dy)
      ..lineTo(center.dx, center.dy + r * 0.6)
      ..lineTo(center.dx - r * 0.7, center.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawCross(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final w = r * 0.28;
    final path = Path()
      ..moveTo(center.dx - w, center.dy - r)
      ..lineTo(center.dx + w, center.dy - r)
      ..lineTo(center.dx + w, center.dy - w)
      ..lineTo(center.dx + r, center.dy - w)
      ..lineTo(center.dx + r, center.dy + w)
      ..lineTo(center.dx + w, center.dy + w)
      ..lineTo(center.dx + w, center.dy + r)
      ..lineTo(center.dx - w, center.dy + r)
      ..lineTo(center.dx - w, center.dy + w)
      ..lineTo(center.dx - r, center.dy + w)
      ..lineTo(center.dx - r, center.dy - w)
      ..lineTo(center.dx - w, center.dy - w)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawDiamond(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.9, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.9, center.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawTrapezoid(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final topW = r * 0.6;
    final bottomW = r * 1.4;
    final path = Path()
      ..moveTo(center.dx - topW, center.dy - r * 0.8)
      ..lineTo(center.dx + topW, center.dy - r * 0.8)
      ..lineTo(center.dx + bottomW, center.dy + r * 0.8)
      ..lineTo(center.dx - bottomW, center.dy + r * 0.8)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawParallelogram(Canvas canvas, Offset center, double r, Paint fill, Paint stroke) {
    final skew = r * 0.4;
    final path = Path()
      ..moveTo(center.dx - r - skew, center.dy - r * 0.6)
      ..lineTo(center.dx + r - skew, center.dy - r * 0.6)
      ..lineTo(center.dx + r + skew, center.dy + r * 0.6)
      ..lineTo(center.dx - r + skew, center.dy + r * 0.6)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawStar(Canvas canvas, Offset center, double r, int points, Paint fill, Paint stroke) {
    final path = Path();
    final innerR = r * 0.4;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) =>
      shapeType != oldDelegate.shapeType ||
      fillColor != oldDelegate.fillColor ||
      strokeColor != oldDelegate.strokeColor;
}
