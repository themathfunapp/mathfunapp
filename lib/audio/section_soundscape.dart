import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/game_mechanics.dart';
import '../services/audio_service.dart';

/// Konu türü → arka plan ses manzarası (ambient döngü).
SoundscapeTheme soundscapeForTopicType(TopicType type) {
  switch (type) {
    case TopicType.counting:
    case TopicType.addition:
    case TopicType.patterns:
      return SoundscapeTheme.forest;
    case TopicType.subtraction:
    case TopicType.measurements:
    case TopicType.decimals:
      return SoundscapeTheme.river;
    case TopicType.geometry:
      return SoundscapeTheme.castle;
    case TopicType.time:
      return SoundscapeTheme.clockTower;
    case TopicType.fractions:
      return SoundscapeTheme.bakery;
    case TopicType.multiplication:
    case TopicType.division:
    case TopicType.algebra:
    case TopicType.statistics:
      return SoundscapeTheme.space;
  }
}

/// İlk kareden sonra güvenli [context] ile bölüm ambient’ini başlatır.
void scheduleSectionAmbient(BuildContext context, SoundscapeTheme theme) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final audio = context.read<AudioService>();
    audio.setSoundscape(theme);
    audio.playAmbientLoop();
  });
}

/// Hikâye dünyası `id` → ambient (LevelPlay vb.).
SoundscapeTheme soundscapeForStoryWorldId(String worldId) {
  switch (worldId) {
    case 'periler_diyari':
    case 'number_forest_preschool':
      return SoundscapeTheme.forest;
    case 'geometry_castle_preschool':
    case 'geometry_castle_late':
    case 'multipliers_tower':
      return SoundscapeTheme.castle;
    case 'measurement_land_preschool':
      return SoundscapeTheme.river;
    case 'fraction_bakery':
      return SoundscapeTheme.bakery;
    case 'time_adventure':
      return SoundscapeTheme.clockTower;
    case 'number_forest_early':
    case 'algebra_realm':
      return SoundscapeTheme.space;
    case 'money_market':
      return SoundscapeTheme.mountain;
    default:
      return SoundscapeTheme.forest;
  }
}
