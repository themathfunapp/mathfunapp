import 'package:flutter/material.dart';
import 'dart:math' as math;

class KurdistanFlag extends StatelessWidget {
  final double size;

  const KurdistanFlag({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _KurdistanFlagPainter(),
        ),
      ),
    );
  }
}

class _KurdistanFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double stripeHeight = height / 3;

    // Red stripe (top)
    final redPaint = Paint()..color = const Color(0xFFED2024);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, stripeHeight),
      redPaint,
    );

    // White stripe (middle)
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight, width, stripeHeight),
      whitePaint,
    );

    // Green stripe (bottom)
    final greenPaint = Paint()..color = const Color(0xFF21AD4C);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight * 2, width, stripeHeight),
      greenPaint,
    );

    // Yellow sun in center
    final sunPaint = Paint()..color = const Color(0xFFFECC07);
    final center = Offset(width / 2, height / 2);
    final sunRadius = width * 0.18;
    
    // Draw sun circle
    canvas.drawCircle(center, sunRadius, sunPaint);

    // Draw 21 sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFECC07)
      ..style = PaintingStyle.fill;

    const int rayCount = 21;
    final double rayLength = width * 0.15;
    final double rayWidth = width * 0.04;

    for (int i = 0; i < rayCount; i++) {
      final double angle = (2 * math.pi / rayCount) * i - math.pi / 2;
      
      final path = Path();
      final double innerRadius = sunRadius;
      final double outerRadius = sunRadius + rayLength;
      
      // Triangle ray
      final double halfAngle = math.pi / rayCount * 0.5;
      
      path.moveTo(
        center.dx + innerRadius * math.cos(angle - halfAngle * 0.3),
        center.dy + innerRadius * math.sin(angle - halfAngle * 0.3),
      );
      path.lineTo(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      path.lineTo(
        center.dx + innerRadius * math.cos(angle + halfAngle * 0.3),
        center.dy + innerRadius * math.sin(angle + halfAngle * 0.3),
      );
      path.close();
      
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

