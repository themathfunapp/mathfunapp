import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';

/// Menü / kart dokunuşlarında çocuk dostu tık sesi.
extension GameSfxContext on BuildContext {
  AudioService get _audio => read<AudioService>();

  void playTapSfx() => _audio.playUiTap();

  void playHoverSfx() => _audio.playUiHover();
}

/// [onTap] öncesi UI tık sesi çalar.
class SfxTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool playSound;

  const SfxTap({
    super.key,
    required this.child,
    this.onTap,
    this.playSound = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              if (playSound) context.playTapSfx();
              onTap!();
            },
      child: child,
    );
  }
}
