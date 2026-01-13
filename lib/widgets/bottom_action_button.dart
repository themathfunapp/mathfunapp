import 'package:flutter/material.dart';

class BottomActionButton extends StatelessWidget {
  final String text;
  final String emoji;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final double fontSize;
  final Color textColor;

  const BottomActionButton({
    super.key,
    required this.text,
    required this.emoji,
    required this.onPressed,
    this.width,
    this.height = 60,
    this.fontSize = 14,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: width == null
          ? const BoxConstraints(
        minWidth: 60,
        maxWidth: 200,
      )
          : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: fontSize + 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}