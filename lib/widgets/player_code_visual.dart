import 'package:flutter/material.dart';

import '../models/app_user.dart';

/// Tam oyuncu kodunda [AppUser.playerCodePrefix] soluk, rakamlar belirgin (RTL uyumlu).
class PlayerCodeVisual extends StatelessWidget {
  const PlayerCodeVisual({
    super.key,
    required this.fullCode,
    this.fontSize = 12,
    this.letterSpacing = 1,
    this.fontWeight = FontWeight.bold,
    this.color = Colors.white,
    this.prefixOpacity = 0.42,
  });

  final String fullCode;
  final double fontSize;
  final double letterSpacing;
  final FontWeight fontWeight;
  final Color color;
  final double prefixOpacity;

  @override
  Widget build(BuildContext context) {
    final u = fullCode.trim().toUpperCase();
    if (!u.startsWith(AppUser.playerCodePrefix)) {
      return Text(
        fullCode,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
        ),
      );
    }
    final digits = u.length > AppUser.playerCodePrefix.length
        ? u.substring(AppUser.playerCodePrefix.length)
        : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Opacity(
          opacity: prefixOpacity,
          child: Text(
            AppUser.playerCodePrefix,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          digits,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }
}
