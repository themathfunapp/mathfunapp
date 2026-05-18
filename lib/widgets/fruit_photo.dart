import 'package:flutter/material.dart';

import '../constants/fruit_collect_catalog.dart';

/// Meyve toplama — gerçek fotoğraf varlığı; yoksa doğru emoji yedek.
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
    return Image.asset(
      fruitImageAssetPath(fruitId),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Text(
        fruitEmojiFallback(fruitId),
        style: TextStyle(fontSize: size * 0.88),
      ),
    );
  }
}
