import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ses ve müzik: `assets/sounds/` altındaki WAV dosyalarını çalar.
/// Ambient döngüler bölüm/konuya göre; kısa SFX doğru/yanlış ve UI için.
class AudioService extends ChangeNotifier {
  AudioService() {
    _ambientPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    _sfxPlayer.setReleaseMode(ReleaseMode.release);
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
    _soundEffectsEnabled = _prefs?.getBool('effects_enabled') ?? true;
    _musicVolume = _prefs?.getDouble('music_volume') ?? 0.7;
    _effectsVolume = _prefs?.getDouble('effects_volume') ?? 1.0;
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs?.setBool('music_enabled', enabled);
    if (!enabled) {
      await stopMusic();
    }
    notifyListeners();
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _soundEffectsEnabled = enabled;
    await _prefs?.setBool('effects_enabled', enabled);
    notifyListeners();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('music_volume', _musicVolume);
    await _ambientPlayer.setVolume(_musicVolume * 0.5);
    notifyListeners();
  }

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

  /// Menü / genel ekranlar için yumuşak döngü (konu ambient’inden bağımsız).
  Future<void> playMenuAmbientLoop() async {
    if (!_musicEnabled) return;
    try {
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.play(AssetSource('sounds/music_relaxed_ambient.wav'));
      await _ambientPlayer.setVolume(_musicVolume * 0.42);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Menu ambient: $e');
    }
  }

  /// Seçili [SoundscapeTheme] için döngüsel ortam sesi.
  Future<void> playAmbientLoop() async {
    if (!_musicEnabled) return;
    try {
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      final path = 'sounds/ambient_${_currentSoundscape.name}.wav';
      await _ambientPlayer.play(AssetSource(path));
      await _ambientPlayer.setVolume(_musicVolume * 0.48);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Ambient: $e');
    }
  }

  /// [MusicMood] ile kısa döngü (süre baskısı, boss vb.).
  Future<void> playMoodLoop(MusicMood mood) async {
    if (!_musicEnabled) return;
    setMusicMood(mood);
    try {
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.play(AssetSource('sounds/music_${mood.trackName}.wav'));
      await _ambientPlayer.setVolume(_musicVolume * 0.5);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Mood loop: $e');
    }
  }

  Future<void> playMusic() => playAmbientLoop();

  Future<void> stopMusic() async {
    try {
      await _ambientPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
    notifyListeners();
  }

  /// [dispose] sırasında güvenli senkron durdurma (await yok).
  void cancelAmbientSync() {
    // ignore: discarded_futures
    _ambientPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> playSound(SoundEffect effect) async {
    if (!_soundEffectsEnabled) return;
    try {
      final path = 'sounds/sfx_${effect.fileName}.wav';
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.play(AssetSource(path));
      await _sfxPlayer.setVolume(_effectsVolume * 0.85);
    } catch (e) {
      debugPrint('SFX ${effect.name}: $e');
    }
  }

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
        playMenuAmbientLoop();
        break;
      case GameContext.playing:
        setMusicMood(MusicMood.normal);
        break;
      case GameContext.timed:
        setMusicMood(MusicMood.intense);
        playMoodLoop(MusicMood.intense);
        break;
      case GameContext.thinking:
        setMusicMood(MusicMood.thinking);
        playMoodLoop(MusicMood.thinking);
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
    name: 'Sayı Ormanı',
    description: 'Kuş sesleri, yaprak hışırtısı',
    ambientSounds: ['birds', 'leaves', 'wind'],
  ),
  river(
    name: 'Rakam Nehri',
    description: 'Su akışı, kurbağa sesleri',
    ambientSounds: ['water_flow', 'frogs', 'crickets'],
  ),
  castle(
    name: 'Geometri Şatosu',
    description: 'Rüzgar, bayrak dalgalanması',
    ambientSounds: ['wind', 'flags', 'distant_horn'],
  ),
  space(
    name: 'Uzay Matematik',
    description: 'Uzay sesleri, elektronik bip\'ler',
    ambientSounds: ['space_ambient', 'beeps', 'stars'],
  ),
  bakery(
    name: 'Kesir Pastanesi',
    description: 'Fırın sesleri, mutfak',
    ambientSounds: ['oven', 'mixing', 'happy_hum'],
  ),
  clockTower(
    name: 'Zaman Kulesi',
    description: 'Saat tik-takları, çanlar',
    ambientSounds: ['clock_tick', 'bells', 'gears'],
  ),
  underwater(
    name: 'Deniz Altı',
    description: 'Su altı sesleri, baloncuklar',
    ambientSounds: ['bubbles', 'whale', 'current'],
  ),
  mountain(
    name: 'Dağ Zirvesi',
    description: 'Rüzgar, kartal sesleri',
    ambientSounds: ['mountain_wind', 'eagle', 'echo'],
  );

  final String name;
  final String description;
  final List<String> ambientSounds;

  const SoundscapeTheme({
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
