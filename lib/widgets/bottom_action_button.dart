import 'package:flutter/material.dart';

class BottomActionButton extends StatelessWidget {
  final String text;
  /// [icon] verilmişse kullanılır; aksi halde [emoji] metni gösterilir.
  final String emoji;
  final Widget? icon;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final double fontSize;
  final Color textColor;

  const BottomActionButton({
    super.key,
    required this.text,
    this.emoji = '',
    this.icon,
    required this.onPressed,
    this.width,
    this.height = 76,
    this.fontSize = 13,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final Widget top = icon ??
        Text(
          emoji,
          style: TextStyle(fontSize: fontSize + 4),
        );

    return Container(
      width: width ?? double.infinity,
      height: height,
      constraints: const BoxConstraints(minWidth: 60),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                top,
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ebeveyn paneli: emoji / sistem fontu yerine [CustomPaint] ile sabit renkler — tüm platformlarda aynı.
class ParentPanelLeadingIcon extends StatelessWidget {
  const ParentPanelLeadingIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 30,
      child: CustomPaint(
        painter: _ParentPanelFamilyBadgePainter(),
      ),
    );
  }
}

class _ParentPanelFamilyBadgePainter extends CustomPainter {
  const _ParentPanelFamilyBadgePainter();

  static const Color _adult = Color(0xFF42A5F5);
  static const Color _heart = Color(0xFFE57373);
  static const Color _child = Color(0xFFFFB74D);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final midY = h * 0.5;

    final adultPaint = Paint()..color = _adult;
    canvas.drawCircle(Offset(h * 0.42, midY), h * 0.38, adultPaint);

    final heartPaint = Paint()..color = _heart;
    canvas.drawCircle(Offset(size.width * 0.5, midY), h * 0.14, heartPaint);

    final childPaint = Paint()..color = _child;
    canvas.drawCircle(Offset(size.width - h * 0.4, midY), h * 0.34, childPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
