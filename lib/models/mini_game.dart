/// Mini Oyunlar Veri Modelleri

/// Oyun kategorileri
enum GameCategory {
  counting,      // Sayı oyunları
  shapes,        // Şekil oyunları
  operations,    // Toplama-Çıkarma
  time,          // Saat oyunları
  creative,      // Yaratıcı oyunlar
  special,       // Özel oyunlar
}

/// Zorluk seviyeleri
enum GameDifficulty {
  easy,    // Kolay: 3 seçenek, sınırsız zaman
  medium,  // Orta: 4 seçenek, 30 sn
  hard,    // Zor: 5+ seçenek, 20 sn
}

/// Görsel temalar
enum GameTheme {
  forest,     // Orman
  space,      // Uzay
  underwater, // Deniz altı
  fairytale,  // Masal diyarı
  city,       // Şehir
}

/// Mini oyun tanımı
class MiniGame {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final String iconEmoji;
  final GameCategory category;
  final int minAge;
  final int maxAge;
  final List<String> colors;
  final bool isUnlocked;
  final int requiredStars;
  final GameTheme theme;

  const MiniGame({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.iconEmoji,
    required this.category,
    required this.minAge,
    required this.maxAge,
    required this.colors,
    this.isUnlocked = true,
    this.requiredStars = 0,
    this.theme = GameTheme.forest,
  });
}

/// Balon verisi
class Balloon {
  final int id;
  final int number;
  final String color;
  double x;
  double y;
  double speed;
  bool isPopped;
  double scale;

  Balloon({
    required this.id,
    required this.number,
    required this.color,
    required this.x,
    required this.y,
    this.speed = 1.0,
    this.isPopped = false,
    this.scale = 1.0,
  });
}

/// Meyve verisi
class Fruit {
  final int id;
  final String emoji;
  final String name;
  double x;
  double y;
  bool isCollected;
  bool isInBasket;

  Fruit({
    required this.id,
    required this.emoji,
    required this.name,
    required this.x,
    required this.y,
    this.isCollected = false,
    this.isInBasket = false,
  });
}

/// Geometrik şekil
class GeometricShape {
  final String id;
  final String nameKey;
  final String emoji;
  final int sides;
  final String color;

  const GeometricShape({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.sides,
    required this.color,
  });

  static const List<GeometricShape> allShapes = [
    GeometricShape(id: 'circle', nameKey: 'shape_circle', emoji: '⭕', sides: 0, color: '#FF6B6B'),
    GeometricShape(id: 'square', nameKey: 'shape_square', emoji: '⬜', sides: 4, color: '#4ECDC4'),
    GeometricShape(id: 'triangle', nameKey: 'shape_triangle', emoji: '🔺', sides: 3, color: '#45B7D1'),
    GeometricShape(id: 'rectangle', nameKey: 'shape_rectangle', emoji: '▬', sides: 4, color: '#96CEB4'),
    GeometricShape(id: 'star', nameKey: 'shape_star', emoji: '⭐', sides: 5, color: '#FFEAA7'),
    GeometricShape(id: 'heart', nameKey: 'shape_heart', emoji: '❤️', sides: 0, color: '#FF6B6B'),
    GeometricShape(id: 'diamond', nameKey: 'shape_diamond', emoji: '💎', sides: 4, color: '#74B9FF'),
  ];
}

/// Saat verisi
class ClockTime {
  final int hour;
  final int minute;
  final String periodKey; // morning, afternoon, evening, night

  const ClockTime({
    required this.hour,
    required this.minute,
    required this.periodKey,
  });

  String get displayTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Oyun sonucu
class MiniGameResult {
  final String gameId;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int stars;
  final int coinsEarned;
  final Duration timeTaken;
  final GameDifficulty difficulty;
  final DateTime playedAt;

  const MiniGameResult({
    required this.gameId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.stars,
    required this.coinsEarned,
    required this.timeTaken,
    required this.difficulty,
    required this.playedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'stars': stars,
      'coinsEarned': coinsEarned,
      'timeTaken': timeTaken.inSeconds,
      'difficulty': difficulty.name,
      'playedAt': playedAt.toIso8601String(),
    };
  }
}

/// Oyuncu mini oyun ilerlemesi
class MiniGameProgress {
  final String oderId;
  final Map<String, GameStats> gameStats;
  final int totalStars;
  final int totalCoins;
  final List<String> unlockedGames;
  final List<String> earnedBadges;

  const MiniGameProgress({
    required this.oderId,
    this.gameStats = const {},
    this.totalStars = 0,
    this.totalCoins = 0,
    this.unlockedGames = const [],
    this.earnedBadges = const [],
  });

  factory MiniGameProgress.fromMap(Map<String, dynamic> map) {
    Map<String, GameStats> stats = {};
    if (map['gameStats'] != null) {
      (map['gameStats'] as Map<String, dynamic>).forEach((key, value) {
        stats[key] = GameStats.fromMap(value);
      });
    }

    return MiniGameProgress(
      oderId: map['userId'] ?? '',
      gameStats: stats,
      totalStars: map['totalStars'] ?? 0,
      totalCoins: map['totalCoins'] ?? 0,
      unlockedGames: List<String>.from(map['unlockedGames'] ?? []),
      earnedBadges: List<String>.from(map['earnedBadges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': oderId,
      'gameStats': gameStats.map((key, value) => MapEntry(key, value.toMap())),
      'totalStars': totalStars,
      'totalCoins': totalCoins,
      'unlockedGames': unlockedGames,
      'earnedBadges': earnedBadges,
    };
  }
}

/// Tek oyun istatistikleri
class GameStats {
  final String gameId;
  final int timesPlayed;
  final int bestScore;
  final int totalStars;
  final int bestStreak;
  final int totalCorrectAnswers;
  final DateTime? lastPlayedAt;

  const GameStats({
    required this.gameId,
    this.timesPlayed = 0,
    this.bestScore = 0,
    this.totalStars = 0,
    this.bestStreak = 0,
    this.totalCorrectAnswers = 0,
    this.lastPlayedAt,
  });

  factory GameStats.fromMap(Map<String, dynamic> map) {
    return GameStats(
      gameId: map['gameId'] ?? '',
      timesPlayed: map['timesPlayed'] ?? 0,
      bestScore: map['bestScore'] ?? 0,
      totalStars: map['totalStars'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      totalCorrectAnswers: map['totalCorrectAnswers'] ?? 0,
      lastPlayedAt: map['lastPlayedAt'] != null
          ? DateTime.parse(map['lastPlayedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'timesPlayed': timesPlayed,
      'bestScore': bestScore,
      'totalStars': totalStars,
      'bestStreak': bestStreak,
      'totalCorrectAnswers': totalCorrectAnswers,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }
}

/// Tren oyunu için yolcu
class TrainPassenger {
  final int id;
  final String emoji;
  bool isOnTrain;

  TrainPassenger({
    required this.id,
    required this.emoji,
    this.isOnTrain = false,
  });
}

/// Renk kodu matematik
class ColorNumber {
  final int number;
  final String colorName;
  final String colorHex;

  const ColorNumber({
    required this.number,
    required this.colorName,
    required this.colorHex,
  });

  static const List<ColorNumber> colors = [
    ColorNumber(number: 1, colorName: 'red', colorHex: '#FF6B6B'),
    ColorNumber(number: 2, colorName: 'blue', colorHex: '#4ECDC4'),
    ColorNumber(number: 3, colorName: 'yellow', colorHex: '#FFE66D'),
    ColorNumber(number: 4, colorName: 'green', colorHex: '#95E1D3'),
    ColorNumber(number: 5, colorName: 'purple', colorHex: '#DDA0DD'),
    ColorNumber(number: 6, colorName: 'orange', colorHex: '#F7B731'),
    ColorNumber(number: 7, colorName: 'pink', colorHex: '#FF9FF3'),
    ColorNumber(number: 8, colorName: 'brown', colorHex: '#CD853F'),
    ColorNumber(number: 9, colorName: 'gray', colorHex: '#A5B1C2'),
    ColorNumber(number: 10, colorName: 'black', colorHex: '#2C3E50'),
  ];
}

/// Müzik enstrümanı
class MusicInstrument {
  final String id;
  final String nameKey;
  final String emoji;
  final String soundPath;

  const MusicInstrument({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.soundPath,
  });

  static const List<MusicInstrument> instruments = [
    MusicInstrument(id: 'piano', nameKey: 'instrument_piano', emoji: '🎹', soundPath: 'piano'),
    MusicInstrument(id: 'guitar', nameKey: 'instrument_guitar', emoji: '🎸', soundPath: 'guitar'),
    MusicInstrument(id: 'drums', nameKey: 'instrument_drums', emoji: '🥁', soundPath: 'drums'),
    MusicInstrument(id: 'violin', nameKey: 'instrument_violin', emoji: '🎻', soundPath: 'violin'),
    MusicInstrument(id: 'trumpet', nameKey: 'instrument_trumpet', emoji: '🎺', soundPath: 'trumpet'),
    MusicInstrument(id: 'flute', nameKey: 'instrument_flute', emoji: '🪈', soundPath: 'flute'),
  ];
}

