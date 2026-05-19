import 'package:flutter/material.dart';

import '../constants/fruit_collect_catalog.dart';
import '../constants/fruit_icon_assets.dart';

/// Meyve toplama — OpenMoji/Twemoji PNG (mesajlaşma emoji stili).
class FruitPhoto extends StatelessWidget {
  final String fruitId;
  final double size;

  const FruitPhoto({
    super.key,
    required this.fruitId,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        fruitIconAssetPath(fruitId),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            fruitEmoji(fruitId),
            style: TextStyle(fontSize: size * 0.92, height: 1.0),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
