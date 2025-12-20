import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ses ve Müzik Servisi
/// Uyarlamalı müzik ve ses manzaraları sistemi
class AudioService extends ChangeNotifier {
  // Ses ayarları
  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  double _musicVolume = 0.7;
  double _effectsVolume = 1.0;
  
  // Mevcut durum
  MusicMood _currentMood = MusicMood.normal;
  SoundscapeTheme _currentSoundscape = SoundscapeTheme.forest;
  bool _isPlaying = false;

  // Getters
  bool get musicEnabled => _musicEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;
  MusicMood get currentMood => _currentMood;
  SoundscapeTheme get currentSoundscape => _currentSoundscape;
  bool get isPlaying => _isPlaying;

  SharedPreferences? _prefs;

  /// Servisi başlat
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    _musicEnabled = _prefs?.getBool('music_enabled') ?? true;
    _soundEffectsEnabled = _prefs?.getBool('effects_enabled') ?? true;
    _musicVolume = _prefs?.getDouble('music_volume') ?? 0.7;
    _effectsVolume = _prefs?.getDouble('effects_volume') ?? 1.0;
    
    notifyListeners();
  }

  /// Müzik aç/kapat
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs?.setBool('music_enabled', enabled);
    
    if (!enabled) {
      stopMusic();
    }
    
    notifyListeners();
  }

  /// Ses efektleri aç/kapat
  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _soundEffectsEnabled = enabled;
    await _prefs?.setBool('effects_enabled', enabled);
    notifyListeners();
  }

  /// Müzik ses seviyesi
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('music_volume', _musicVolume);
    notifyListeners();
  }

  /// Efekt ses seviyesi
  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _prefs?.setDouble('effects_volume', _effectsVolume);
    notifyListeners();
  }

  /// Müzik modunu değiştir
  void setMusicMood(MusicMood mood) {
    if (_currentMood == mood) return;
    
    _currentMood = mood;
    notifyListeners();
    
    // TODO: Gerçek müzik değişimi buraya gelecek
    debugPrint('Music mood changed to: ${mood.name}');
  }

  /// Ses manzarasını değiştir
  void setSoundscape(SoundscapeTheme theme) {
    if (_currentSoundscape == theme) return;
    
    _currentSoundscape = theme;
    notifyListeners();
    
    // TODO: Gerçek soundscape değişimi buraya gelecek
    debugPrint('Soundscape changed to: ${theme.name}');
  }

  /// Müzik çal
  void playMusic() {
    if (!_musicEnabled) return;
    
    _isPlaying = true;
    notifyListeners();
    
    // TODO: Müzik çalma implementasyonu
    debugPrint('Playing music: ${_currentMood.trackName}');
  }

  /// Müzik durdur
  void stopMusic() {
    _isPlaying = false;
    notifyListeners();
    
    // TODO: Müzik durdurma implementasyonu
    debugPrint('Music stopped');
  }

  /// Ses efekti çal
  void playSound(SoundEffect effect) {
    if (!_soundEffectsEnabled) return;
    
    // TODO: Ses efekti çalma implementasyonu
    debugPrint('Playing sound: ${effect.name}');
  }

  /// Bağlama göre otomatik müzik ayarla
  void adaptToContext(GameContext context) {
    switch (context) {
      case GameContext.menu:
        setMusicMood(MusicMood.normal);
        break;
      case GameContext.playing:
        setMusicMood(MusicMood.normal);
        break;
      case GameContext.timed:
        setMusicMood(MusicMood.intense);
        break;
      case GameContext.thinking:
        setMusicMood(MusicMood.thinking);
        break;
      case GameContext.success:
        setMusicMood(MusicMood.celebration);
        playSound(SoundEffect.success);
        break;
      case GameContext.failure:
        setMusicMood(MusicMood.encouraging);
        playSound(SoundEffect.wrong);
        break;
      case GameContext.levelUp:
        setMusicMood(MusicMood.celebration);
        playSound(SoundEffect.levelUp);
        break;
    }
  }

  /// Konuya göre ses manzarası ayarla
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
}

/// Müzik Modları
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

/// Ses Manzaraları
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

/// Ses Efektleri
enum SoundEffect {
  // Genel
  buttonTap('button_tap'),
  buttonHover('button_hover'),
  pageFlip('page_flip'),
  
  // Oyun
  correct('correct_answer'),
  wrong('wrong_answer'),
  timeout('timeout'),
  hint('hint_reveal'),
  
  // Başarı
  levelUp('level_up'),
  achievement('achievement_unlock'),
  streak('streak_bonus'),
  combo('combo_hit'),
  
  // Ödüller
  coinCollect('coin_collect'),
  starEarn('star_earn'),
  boxOpen('box_open'),
  spinWheel('spin_wheel'),
  
  // Karakterler
  characterHappy('character_happy'),
  characterSad('character_sad'),
  characterCheer('character_cheer'),
  
  // UI
  notification('notification'),
  error('error_beep'),
  success('success_chime');

  final String fileName;

  const SoundEffect(this.fileName);
}

/// Oyun Bağlamı
enum GameContext {
  menu,
  playing,
  timed,
  thinking,
  success,
  failure,
  levelUp,
}

/// Matematik Konuları
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

/// Sesli Geri Bildirim Metinleri
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

