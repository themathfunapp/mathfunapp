// utils/shape_utils.dart
import 'package:flutter/material.dart';

class ShapeUtils {
  static String getShapeEmoji(String shape) {
    switch (shape) {
      case 'circle': return '🔴';
      case 'square': return '⬛';
      case 'triangle': return '🔺';
      case 'rectangle': return '▭';
      case 'pentagon': return '⬟';
      case 'hexagon': return '⬢';
      default: return '🔶';
    }
  }

  static String getShapeName(String shape) {
    switch (shape) {
      case 'circle': return 'Daire';
      case 'square': return 'Kare';
      case 'triangle': return 'Üçgen';
      case 'rectangle': return 'Dikdörtgen';
      case 'pentagon': return 'Beşgen';
      case 'hexagon': return 'Altıgen';
      default: return 'Şekil';
    }
  }

  static Widget buildInteractiveShape(String shape, {double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shape == 'square' || shape == 'rectangle'
            ? BorderRadius.circular(10)
            : null,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Text(
          getShapeEmoji(shape),
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}