import 'package:flutter/material.dart';

// Renkler
const Color primaryColor = Color(0xFF4A6FA5);
const Color secondaryColor = Color(0xFF6B48FF);
const Color accentColor = Color(0xFFFF6B6B);

// Gradient'ler
final LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF4A6FA5), Color(0xFF6B48FF)],
);

final LinearGradient shinyGradient = LinearGradient(
  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFF6B6B)],
  stops: [0.0, 0.5, 1.0],
);

final LinearGradient premiumGradient = LinearGradient(
  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
);

// Metin stilleri
const TextStyle titleStyle = TextStyle(
  fontSize: 36,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle subtitleStyle = TextStyle(
  fontSize: 18,
  color: Colors.white70,
);