import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';

/// Uygulama genelinde çocuk dostu arka plan müziğini başlatır ve ayar değişimlerine tepki verir.
class BackgroundMusicHost extends StatefulWidget {
  final Widget child;

  const BackgroundMusicHost({super.key, required this.child});

  @override
  State<BackgroundMusicHost> createState() => _BackgroundMusicHostState();
}

class _BackgroundMusicHostState extends State<BackgroundMusicHost>
    with WidgetsBindingObserver {
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AudioService>();
    if (!identical(_audio, next)) {
      _audio?.removeListener(_onAudioChanged);
      _audio = next;
      _audio!.addListener(_onAudioChanged);
      _audio!.warmUpBgm();
      if (!kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncMusic());
      }
    }
  }

  @override
  void dispose() {
    _audio?.removeListener(_onAudioChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAudioChanged() {
    if (!mounted || _audio == null) return;
    if (_audio!.musicEnabled && !_audio!.isPlaying) {
      _syncMusic();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = _audio;
    if (audio == null) return;
    if (state == AppLifecycleState.resumed) {
      audio.ensureBackgroundMusic();
    } else if (!kIsWeb && state == AppLifecycleState.paused) {
      // Web'de inactive sık tetiklenir; müziği gereksiz durdurma.
      audio.pauseBackgroundMusic();
    }
  }

  void _onUserGesture() {
    _audio?.unlockUserAudio();
  }

  void _syncMusic() {
    _audio?.ensureBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserGesture(),
      child: widget.child,
    );
  }
}
