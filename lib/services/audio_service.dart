import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ses ve müzik: `assets/sounds/` altındaki WAV dosyalarını çalar.
/// Ambient döngüler bölüm/konuya göre; kısa SFX doğru/yanlış ve UI için.
class AudioService extends ChangeNotifier {
  AudioService() {
    _ambientPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    _ambientPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _sfxPlayer.setReleaseMode(ReleaseMode.release);
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  late final AudioPlayer _ambientPlayer;
  late final AudioPlayer _sfxPlayer;

  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  double _musicVolume = 0.7;
  double _effectsVolume = 1.0;

  MusicMood _currentMood = MusicMood.normal;
  SoundscapeTheme _currentSoundscape = SoundscapeTheme.forest;
  bool _isPlaying = false;
  bool _disposed = false;
  String? _playingBgmAsset;
  /// Web: tarayıcı ilk dokunuş olmadan ses çalmaz (autoplay politikası).
  bool _userAudioUnlocked = !kIsWeb;
  bool _pendingBgmStart = false;

  /// Kısa döngü (~800 KB) — hızlı yükleme; tam parça: music_kids_bgm.mp3 (3 MB).
  static const String _globalBgmAsset = 'sounds/music_kids_bgm_loop.mp3';

  Uint8List? _cachedBgmBytes;
  final Map<String, Uint8List> _sfxByteCache = {};
  bool _bgmBytesLoading = false;
  Completer<void>? _bgmBytesLoadCompleter;
  bool _bgmStartInProgress = false;
  /// Web: bir kez bulunan hızlı asset yolu (her seferinde iki URL denemesin).
  String? _resolvedWebBgmUrl;
  /// Müzik sesi (cızırtıyı önlemek için orta).
  static const double _bgmVolumeScale = 0.45;

  bool get musicEnabled => _musicEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;
  MusicMood get currentMood => _currentMood;
  SoundscapeTheme get currentSoundscape => _currentSoundscape;
  bool get isPlaying => _isPlaying;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _musicEnabled = _prefs?.getBool('music_enabled') ?? true;
    _soundEffectsEnabled = _prefs?.getBool('effects_enabled') ??
        _prefs?.getBool('sound_enabled') ??
        true;
    _musicVolume = _prefs?.getDouble('music_volume') ?? 0.7;
    _effectsVolume = _prefs?.getDouble('effects_volume') ?? 1.0;
    notifyListeners();
    if (_musicEnabled) {
      warmUpBgm();
      if (!kIsWeb) {
        await ensureBackgroundMusic();
      }
    }
  }

  /// Uygulama açılırken MP3'ü arka planda yükle (çalma için dokunuş yine gerekir — web).
  void warmUpBgm() {
    // ignore: discarded_futures
    _preloadBgmBytes();
    warmUpSfx();
  }

  /// Sık kullanılan efektleri önbelleğe al (gecikmeyi azaltır).
  void warmUpSfx() {
    const warm = [
      SoundEffect.buttonTap,
      SoundEffect.correct,
      SoundEffect.wrong,
      SoundEffect.characterHappy,
      SoundEffect.characterSad,
      SoundEffect.levelUp,
    ];
    for (final effect in warm) {
      // ignore: discarded_futures
      _preloadSfx(effect);
    }
  }

  Future<void> _preloadSfx(SoundEffect effect) async {
    final fileName = effect.fileName;
    if (_sfxByteCache.containsKey(fileName)) return;
    try {
      final data = await rootBundle.load('assets/sounds/sfx_$fileName.wav');
      _sfxByteCache[fileName] = data.buffer.asUint8List();
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs?.setBool('music_enabled', enabled);
    if (!enabled) {
      await stopMusic();
    } else {
      _userAudioUnlocked = true;
      await ensureBackgroundMusic();
    }
    notifyListeners();
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _soundEffectsEnabled = enabled;
    await _prefs?.setBool('effects_enabled', enabled);
    await _prefs?.setBool('sound_enabled', enabled);
    notifyListeners();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('music_volume', _musicVolume);
    await _ambientPlayer.setVolume(_effectiveBgmVolume);
    notifyListeners();
  }

  double get _effectiveBgmVolume => _musicVolume * _bgmVolumeScale;

  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('effects_volume', _effectsVolume);
    notifyListeners();
  }

  void setMusicMood(MusicMood mood) {
    if (_currentMood == mood) return;
    _currentMood = mood;
    notifyListeners();
  }

  void setSoundscape(SoundscapeTheme theme) {
    if (_currentSoundscape == theme) return;
    _currentSoundscape = theme;
    notifyListeners();
  }

  /// Uygulama geneli arka plan müziği (menü, oyun, tüm ekranlar).
  Future<void> playMenuAmbientLoop() => ensureBackgroundMusic();

  /// Bölüm değişiminde de aynı global müzik devam eder.
  Future<void> playAmbientLoop() => ensureBackgroundMusic();

  /// Yoğun modda da aynı parça; yalnızca ruh hali kaydı güncellenir.
  Future<void> playMoodLoop(MusicMood mood) async {
    setMusicMood(mood);
    await ensureBackgroundMusic();
  }

  Future<void> playMusic() => ensureBackgroundMusic();

  /// İlk dokunuş / buton — web autoplay kilidini açar, müziği hemen başlatır.
  Future<void> unlockUserAudio() async {
    _userAudioUnlocked = true;
    if (!_musicEnabled) return;
    if (_bgmActuallyPlaying()) return;

    _bgmStartInProgress = true;
    try {
      await _ambientPlayer.setVolume(_effectiveBgmVolume);
      final started = await _startBgmPlayback(restart: false);
      if (started) {
        _playingBgmAsset = _globalBgmAsset;
        _isPlaying = true;
        _pendingBgmStart = false;
        notifyListeners();
      } else {
        await ensureBackgroundMusic(force: true);
      }
    } finally {
      _bgmStartInProgress = false;
    }
  }

  Future<void> _preloadBgmBytes() async {
    if (_cachedBgmBytes != null) return;
    if (_bgmBytesLoading) {
      await (_bgmBytesLoadCompleter?.future ?? Future.value());
      return;
    }
    _bgmBytesLoading = true;
    _bgmBytesLoadCompleter = Completer<void>();
    try {
      final data = await rootBundle.load('assets/$_globalBgmAsset');
      _cachedBgmBytes = data.buffer.asUint8List();
    } catch (e) {
      debugPrint('BGM ön yükleme: $e');
    } finally {
      _bgmBytesLoading = false;
      _bgmBytesLoadCompleter?.complete();
      _bgmBytesLoadCompleter = null;
    }
  }

  bool _bgmActuallyPlaying() =>
      _ambientPlayer.state == PlayerState.playing &&
      _playingBgmAsset == _globalBgmAsset;

  /// Müzik açıksa global döngüyü başlatır (gereksiz stop/play yok).
  Future<void> ensureBackgroundMusic({bool force = false}) async {
    if (_disposed || !_musicEnabled || _bgmStartInProgress) return;

    if (kIsWeb && !_userAudioUnlocked) {
      _pendingBgmStart = true;
      return;
    }

    if (!force && _bgmActuallyPlaying()) return;

    final state = _ambientPlayer.state;
    if (!force && state == PlayerState.paused && _playingBgmAsset == _globalBgmAsset) {
      try {
        await _ambientPlayer.setVolume(_effectiveBgmVolume);
        await _ambientPlayer.resume();
        _isPlaying = true;
        return;
      } catch (e) {
        debugPrint('BGM resume: $e');
      }
    }

    _bgmStartInProgress = true;
    try {
      final started = await _startBgmPlayback(restart: force || !_bgmActuallyPlaying());
      if (started) {
        _playingBgmAsset = _globalBgmAsset;
        _isPlaying = true;
        _pendingBgmStart = false;
        notifyListeners();
      } else {
        _isPlaying = false;
        _playingBgmAsset = null;
        debugPrint('Arka plan müziği başlatılamadı');
      }
    } catch (e) {
      _isPlaying = false;
      _playingBgmAsset = null;
      final msg = e.toString();
      if (msg.contains('NotAllowed') || msg.contains("didn't interact")) {
        _userAudioUnlocked = false;
        _pendingBgmStart = true;
      } else {
        debugPrint('Arka plan müziği: $e');
      }
    } finally {
      _bgmStartInProgress = false;
    }
  }

  /// Beğenilen parça: music_kids_bgm.mp3 — web'de URL önce (3 MB bayt beklenmez).
  Future<bool> _startBgmPlayback({required bool restart}) async {
    if (!restart && _ambientPlayer.state == PlayerState.playing) return true;

    if (restart) {
      try {
        await _ambientPlayer.stop();
      } catch (_) {}
    }

    if (kIsWeb) {
      if (await _playWebBgmUrl()) return true;
    } else if (_cachedBgmBytes != null) {
      try {
        await _ambientPlayer.play(
          BytesSource(_cachedBgmBytes!, mimeType: 'audio/mpeg'),
        );
        return true;
      } catch (e) {
        debugPrint('BGM bytes: $e');
      }
    }

    if (!kIsWeb) {
      try {
        await _ambientPlayer.play(AssetSource(_globalBgmAsset));
        return true;
      } catch (e) {
        debugPrint('BGM asset: $e');
      }
    }

    await _preloadBgmBytes();
    if (_cachedBgmBytes != null) {
      try {
        await _ambientPlayer.play(
          BytesSource(_cachedBgmBytes!, mimeType: 'audio/mpeg'),
        );
        return true;
      } catch (e) {
        debugPrint('BGM bytes (geç): $e');
      }
    }

    if (kIsWeb) {
      return _playWebBgmUrl();
    }
    return false;
  }

  Future<bool> _playWebBgmUrl() async {
    final candidates = _resolvedWebBgmUrl != null
        ? [_resolvedWebBgmUrl!]
        : [
            'assets/assets/$_globalBgmAsset',
            'assets/$_globalBgmAsset',
          ];
    for (final url in candidates) {
      try {
        await _ambientPlayer.play(UrlSource(url));
        _resolvedWebBgmUrl = url;
        return true;
      } catch (e) {
        debugPrint('BGM web ($url): $e');
      }
    }
    return false;
  }

  /// Uygulama arka plana giderken geçici duraklatma.
  Future<void> pauseBackgroundMusic() async {
    if (!_isPlaying) return;
    try {
      await _ambientPlayer.pause();
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _ambientPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
    _playingBgmAsset = null;
    notifyListeners();
  }

  /// Ekran dispose — global müzik durmaz (oyun boyunca devam).
  void cancelAmbientSync() {}

  Future<void> playSound(SoundEffect effect) async {
    if (!_soundEffectsEnabled || _disposed) return;
    try {
      await _sfxPlayer.setVolume(_effectsVolume * 0.75);
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);

      final fileName = effect.fileName;
      Uint8List? bytes = _sfxByteCache[fileName];
      if (bytes == null) {
        try {
          final data = await rootBundle.load('assets/sounds/sfx_$fileName.wav');
          bytes = data.buffer.asUint8List();
          _sfxByteCache[fileName] = bytes;
        } catch (e) {
          debugPrint('SFX yükleme $fileName: $e');
        }
      }

      if (bytes != null) {
        await _sfxPlayer.play(BytesSource(bytes, mimeType: 'audio/wav'));
      } else {
        await _sfxPlayer.play(AssetSource('sounds/sfx_$fileName.wav'));
      }
    } catch (e) {
      debugPrint('SFX ${effect.name}: $e');
    }
  }

  void playUiTap() => playSound(SoundEffect.buttonTap);

  void playUiHover() => playSound(SoundEffect.buttonHover);

  void playAnswerFeedback(bool correct) {
    if (correct) {
      playSound(SoundEffect.correct);
    } else {
      playSound(SoundEffect.wrong);
    }
  }

  void adaptToContext(GameContext context) {
    switch (context) {
      case GameContext.menu:
        setMusicMood(MusicMood.relaxed);
        ensureBackgroundMusic();
        break;
      case GameContext.playing:
        setMusicMood(MusicMood.normal);
        ensureBackgroundMusic();
        break;
      case GameContext.timed:
        setMusicMood(MusicMood.intense);
        ensureBackgroundMusic();
        break;
      case GameContext.thinking:
        setMusicMood(MusicMood.thinking);
        ensureBackgroundMusic();
        break;
      case GameContext.success:
        playSound(SoundEffect.correct);
        break;
      case GameContext.failure:
        playSound(SoundEffect.wrong);
        break;
      case GameContext.levelUp:
        playSound(SoundEffect.levelUp);
        break;
    }
  }

  void adaptToTopic(MathTopic topic) {
    switch (topic) {
      case MathTopic.counting:
      case MathTopic.addition:
        setSoundscape(SoundscapeTheme.forest);
        break;
      case MathTopic.subtraction:
        setSoundscape(SoundscapeTheme.river);
        break;
      case MathTopic.geometry:
        setSoundscape(SoundscapeTheme.castle);
        break;
      case MathTopic.time:
        setSoundscape(SoundscapeTheme.clockTower);
        break;
      case MathTopic.fractions:
        setSoundscape(SoundscapeTheme.bakery);
        break;
      case MathTopic.multiplication:
      case MathTopic.division:
        setSoundscape(SoundscapeTheme.space);
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ambientPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}

// --- Aşağıdaki enum ve yardımcı sınıflar mevcut API ile uyumludur ---

enum MusicMood {
  normal(
    name: 'Normal',
    description: 'Sakin, enstrümantal',
    trackName: 'calm_instrumental',
    tempo: 100,
  ),
  intense(
    name: 'Yoğun',
    description: 'Hızlanan tempo',
    trackName: 'intense_beat',
    tempo: 140,
  ),
  thinking(
    name: 'Düşünce',
    description: 'Gizemli, düşündürücü',
    trackName: 'mystery_thinking',
    tempo: 80,
  ),
  celebration(
    name: 'Kutlama',
    description: 'Coşkulu, neşeli',
    trackName: 'celebration_fanfare',
    tempo: 120,
  ),
  encouraging(
    name: 'Teşvik',
    description: 'Yumuşak, destekleyici',
    trackName: 'soft_encouragement',
    tempo: 90,
  ),
  relaxed(
    name: 'Rahat',
    description: 'Gevşetici, huzurlu',
    trackName: 'relaxed_ambient',
    tempo: 70,
  );

  final String name;
  final String description;
  final String trackName;
  final int tempo;

  const MusicMood({
    required this.name,
    required this.description,
    required this.trackName,
    required this.tempo,
  });
}

enum SoundscapeTheme {
  forest(
    ambientStem: 'forest',
    name: 'Sayı Ormanı',
    description: 'Kuş sesleri, yaprak hışırtısı',
    ambientSounds: ['birds', 'leaves', 'wind'],
  ),
  river(
    ambientStem: 'river',
    name: 'Rakam Nehri',
    description: 'Su akışı, kurbağa sesleri',
    ambientSounds: ['water_flow', 'frogs', 'crickets'],
  ),
  castle(
    ambientStem: 'castle',
    name: 'Geometri Şatosu',
    description: 'Rüzgar, bayrak dalgalanması',
    ambientSounds: ['wind', 'flags', 'distant_horn'],
  ),
  space(
    ambientStem: 'space',
    name: 'Uzay Matematik',
    description: 'Uzay sesleri, elektronik bip\'ler',
    ambientSounds: ['space_ambient', 'beeps', 'stars'],
  ),
  bakery(
    ambientStem: 'bakery',
    name: 'Kesir Pastanesi',
    description: 'Fırın sesleri, mutfak',
    ambientSounds: ['oven', 'mixing', 'happy_hum'],
  ),
  clockTower(
    ambientStem: 'clockTower',
    name: 'Zaman Kulesi',
    description: 'Saat tik-takları, çanlar',
    ambientSounds: ['clock_tick', 'bells', 'gears'],
  ),
  underwater(
    ambientStem: 'underwater',
    name: 'Deniz Altı',
    description: 'Su altı sesleri, baloncuklar',
    ambientSounds: ['bubbles', 'whale', 'current'],
  ),
  mountain(
    ambientStem: 'mountain',
    name: 'Dağ Zirvesi',
    description: 'Rüzgar, kartal sesleri',
    ambientSounds: ['mountain_wind', 'eagle', 'echo'],
  );

  /// `assets/sounds/ambient_<ambientStem>.wav` ile eşleşir.
  final String ambientStem;
  final String name;
  final String description;
  final List<String> ambientSounds;

  const SoundscapeTheme({
    required this.ambientStem,
    required this.name,
    required this.description,
    required this.ambientSounds,
  });
}

enum SoundEffect {
  buttonTap('button_tap'),
  buttonHover('button_hover'),
  pageFlip('page_flip'),
  correct('correct_answer'),
  wrong('wrong_answer'),
  timeout('timeout'),
  hint('hint_reveal'),
  levelUp('level_up'),
  achievement('achievement_unlock'),
  streak('streak_bonus'),
  combo('combo_hit'),
  coinCollect('coin_collect'),
  starEarn('star_earn'),
  boxOpen('box_open'),
  spinWheel('spin_wheel'),
  characterHappy('character_happy'),
  characterSad('character_sad'),
  characterCheer('character_cheer'),
  notification('notification'),
  error('error_beep'),
  success('success_chime');

  final String fileName;

  const SoundEffect(this.fileName);
}

enum GameContext {
  menu,
  playing,
  timed,
  thinking,
  success,
  failure,
  levelUp,
}

enum MathTopic {
  counting,
  addition,
  subtraction,
  multiplication,
  division,
  geometry,
  fractions,
  time,
}

class VoiceFeedback {
  static const Map<String, List<String>> phrases = {
    'correct_tr': [
      'Harika!',
      'Mükemmel!',
      'Doğru cevap!',
      'Çok iyi!',
      'Aferin!',
      'Süper!',
    ],
    'wrong_tr': [
      'Tekrar dene!',
      'Yaklaştın!',
      'Bir daha bakalım.',
      'Olur böyle şeyler.',
    ],
    'streak_tr': [
      'Müthiş gidiyorsun!',
      'Durdurulamıyorsun!',
      'Harika seri!',
    ],
    'levelUp_tr': [
      'Tebrikler! Yeni seviye!',
      'Seviye atladın!',
      'İlerliyorsun!',
    ],
    'timeout_tr': [
      'Süre doldu!',
      'Biraz daha hızlı olmalısın.',
    ],
    'hint_tr': [
      'İşte bir ipucu.',
      'Bu yardımcı olabilir.',
      'Bir bakalım...',
    ],
  };

  static String getRandomPhrase(String key) {
    final phraseList = phrases[key];
    if (phraseList == null || phraseList.isEmpty) return '';
    final index = DateTime.now().millisecondsSinceEpoch % phraseList.length;
    return phraseList[index];
  }
}
