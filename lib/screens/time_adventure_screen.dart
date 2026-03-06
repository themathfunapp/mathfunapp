import 'package:flutter/material.dart';
import 'time_island_screen.dart';

/// Zaman Macerası - Saati öğrenerek sihirli kapıları aç!
/// Matematik Gezginleri (6-8 yaş) için animasyonlu saat öğrenme ekranı
class TimeAdventureScreen extends StatelessWidget {
  final VoidCallback onBack;

  const TimeAdventureScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return TimeIslandScreen(
      ageGroup: 'early',
      key: const ValueKey('time_adventure'),
    );
  }
}
