import 'package:cloud_firestore/cloud_firestore.dart';

/// Rozet kategorileri
enum BadgeCategory {
  gameplay,    // Oyun oynama ile ilgili
  streak,      // Seri ile ilgili
  speed,       // Hız ile ilgili
  accuracy,    // Doğruluk ile ilgili
  social,      // Sosyal (arkadaşlar)
  loyalty,     // Sadakat (günlük giriş)
  mastery,     // Ustalık
  special,     // Özel rozetler
}

/// Rozet nadirlik seviyesi
enum BadgeRarity {
  common,      // Yaygın - Gri
  uncommon,    // Nadir değil - Yeşil
  rare,        // Nadir - Mavi
  epic,        // Epik - Mor
  legendary,   // Efsanevi - Altın
}

/// Rozet tanımı (statik bilgiler)
class BadgeDefinition {
  final String id;
  final String nameKey;           // Localization key
  final String descriptionKey;    // Localization key
  final String emoji;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final int targetValue;          // Hedefe ulaşmak için gereken değer
  final String statKey;           // UserStats'daki hangi değere bakılacak

  const BadgeDefinition({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.emoji,
    required this.category,
    required this.rarity,
    required this.targetValue,
    required this.statKey,
  });

  /// Yerelleştirme: `badge_ht_$id` (ör. `badge_ht_first_game`) — hangi oyun / koşul.
  String get howToEarnKey => 'badge_ht_$id';

  /// Rozet renklerini döndür
  Map<String, dynamic> get colors {
    switch (rarity) {
      case BadgeRarity.common:
        return {'primary': 0xFF9E9E9E, 'secondary': 0xFFBDBDBD, 'glow': 0x40757575};
      case BadgeRarity.uncommon:
        return {'primary': 0xFF4CAF50, 'secondary': 0xFF81C784, 'glow': 0x402E7D32};
      case BadgeRarity.rare:
        return {'primary': 0xFF2196F3, 'secondary': 0xFF64B5F6, 'glow': 0x401565C0};
      case BadgeRarity.epic:
        return {'primary': 0xFF9C27B0, 'secondary': 0xFFBA68C8, 'glow': 0x406A1B9A};
      case BadgeRarity.legendary:
        return {'primary': 0xFFFF9800, 'secondary': 0xFFFFB74D, 'glow': 0x40E65100};
    }
  }

  /// Nadirlik yıldız sayısı
  int get starCount {
    switch (rarity) {
      case BadgeRarity.common:
        return 1;
      case BadgeRarity.uncommon:
        return 2;
      case BadgeRarity.rare:
        return 3;
      case BadgeRarity.epic:
        return 4;
      case BadgeRarity.legendary:
        return 5;
    }
  }
}

/// Kullanıcının kazandığı rozet
class EarnedBadge {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final int valueAtEarn;  // Kazanıldığındaki değer

  EarnedBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    required this.valueAtEarn,
  });

  factory EarnedBadge.fromMap(Map<String, dynamic> map, String docId) {
    return EarnedBadge(
      userId: map['userId'] ?? '',
      badgeId: docId.isNotEmpty ? docId : (map['badgeId'] ?? ''),
      earnedAt: map['earnedAt'] is Timestamp
          ? (map['earnedAt'] as Timestamp).toDate()
          : DateTime.parse(map['earnedAt'] ?? DateTime.now().toIso8601String()),
      valueAtEarn: map['valueAtEarn'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'valueAtEarn': valueAtEarn,
    };
  }
}

/// Kullanıcı istatistikleri
class UserStats {
  final String userId;
  
  // Oyun istatistikleri
  final int totalGamesPlayed;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final int totalWrongAnswers;
  final int totalScore;
  
  // Seri istatistikleri
  final int currentStreak;
  final int bestStreak;
  final int currentDailyStreak;
  final int bestDailyStreak;
  
  // Hız istatistikleri
  final int fastAnswers;          // 3 saniyeden az sürede verilen cevaplar
  final int superFastAnswers;     // 1 saniyeden az sürede verilen cevaplar
  final double bestAverageTime;   // En iyi ortalama cevap süresi
  
  // Doğruluk istatistikleri
  final int perfectGames;         // Hatasız tamamlanan oyunlar
  final double bestAccuracy;      // En yüksek doğruluk oranı
  
  // Sosyal istatistikler
  final int friendsCount;
  final int friendRequestsSent;
  
  // Sadakat istatistikleri
  final int totalDaysPlayed;
  final int consecutiveDays;
  final DateTime? lastPlayedAt;
  
  // Seviye istatistikleri
  final int levelsCompleted;
  final int chaptersCompleted;
  
  // Özel
  final int coinsEarned;
  final int achievementsUnlocked;

  /// Tamamlanan oyun oturumu sayısı, uygulama dili anahtarına göre (rozet: `localeGames_*`).
  final Map<String, int> localeGamesPlayed;

  UserStats({
    required this.userId,
    this.totalGamesPlayed = 0,
    this.totalQuestionsAnswered = 0,
    this.totalCorrectAnswers = 0,
    this.totalWrongAnswers = 0,
    this.totalScore = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.currentDailyStreak = 0,
    this.bestDailyStreak = 0,
    this.fastAnswers = 0,
    this.superFastAnswers = 0,
    this.bestAverageTime = 999.0,
    this.perfectGames = 0,
    this.bestAccuracy = 0.0,
    this.friendsCount = 0,
    this.friendRequestsSent = 0,
    this.totalDaysPlayed = 0,
    this.consecutiveDays = 0,
    this.lastPlayedAt,
    this.levelsCompleted = 0,
    this.chaptersCompleted = 0,
    this.coinsEarned = 0,
    this.achievementsUnlocked = 0,
    this.localeGamesPlayed = const {},
  });

  factory UserStats.fromMap(Map<String, dynamic> map, String userId) {
    return UserStats(
      userId: userId,
      totalGamesPlayed: map['totalGamesPlayed'] ?? 0,
      totalQuestionsAnswered: map['totalQuestionsAnswered'] ?? 0,
      totalCorrectAnswers: map['totalCorrectAnswers'] ?? 0,
      totalWrongAnswers: map['totalWrongAnswers'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      currentDailyStreak: map['currentDailyStreak'] ?? 0,
      bestDailyStreak: map['bestDailyStreak'] ?? 0,
      fastAnswers: map['fastAnswers'] ?? 0,
      superFastAnswers: map['superFastAnswers'] ?? 0,
      bestAverageTime: (map['bestAverageTime'] ?? 999.0).toDouble(),
      perfectGames: map['perfectGames'] ?? 0,
      bestAccuracy: (map['bestAccuracy'] ?? 0.0).toDouble(),
      friendsCount: map['friendsCount'] ?? 0,
      friendRequestsSent: map['friendRequestsSent'] ?? 0,
      totalDaysPlayed: map['totalDaysPlayed'] ?? 0,
      consecutiveDays: map['consecutiveDays'] ?? 0,
      lastPlayedAt: map['lastPlayedAt'] != null
          ? (map['lastPlayedAt'] is Timestamp
              ? (map['lastPlayedAt'] as Timestamp).toDate()
              : DateTime.parse(map['lastPlayedAt']))
          : null,
      levelsCompleted: map['levelsCompleted'] ?? 0,
      chaptersCompleted: map['chaptersCompleted'] ?? 0,
      coinsEarned: map['coinsEarned'] ?? 0,
      achievementsUnlocked: map['achievementsUnlocked'] ?? 0,
      localeGamesPlayed: _localeGamesFromMap(map['localeGamesPlayed']),
    );
  }

  static Map<String, int> _localeGamesFromMap(dynamic raw) {
    if (raw == null || raw is! Map) return const {};
    final out = <String, int>{};
    for (final e in raw.entries) {
      final k = e.key?.toString();
      if (k == null || k.isEmpty) continue;
      final v = e.value;
      final n = v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
      out[k.toLowerCase()] = n;
    }
    return out;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalWrongAnswers': totalWrongAnswers,
      'totalScore': totalScore,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'currentDailyStreak': currentDailyStreak,
      'bestDailyStreak': bestDailyStreak,
      'fastAnswers': fastAnswers,
      'superFastAnswers': superFastAnswers,
      'bestAverageTime': bestAverageTime,
      'perfectGames': perfectGames,
      'bestAccuracy': bestAccuracy,
      'friendsCount': friendsCount,
      'friendRequestsSent': friendRequestsSent,
      'totalDaysPlayed': totalDaysPlayed,
      'consecutiveDays': consecutiveDays,
      'lastPlayedAt': lastPlayedAt != null ? Timestamp.fromDate(lastPlayedAt!) : null,
      'levelsCompleted': levelsCompleted,
      'chaptersCompleted': chaptersCompleted,
      'coinsEarned': coinsEarned,
      'achievementsUnlocked': achievementsUnlocked,
      'localeGamesPlayed': localeGamesPlayed,
      'updatedAt': Timestamp.now(),
    };
  }

  /// Belirli bir stat değerini al
  int getStatValue(String statKey) {
    switch (statKey) {
      case 'totalGamesPlayed':
        return totalGamesPlayed;
      case 'totalQuestionsAnswered':
        return totalQuestionsAnswered;
      case 'totalCorrectAnswers':
        return totalCorrectAnswers;
      case 'totalScore':
        return totalScore;
      case 'currentStreak':
        return currentStreak;
      case 'bestStreak':
        return bestStreak;
      case 'currentDailyStreak':
        return currentDailyStreak;
      case 'bestDailyStreak':
        return bestDailyStreak;
      case 'fastAnswers':
        return fastAnswers;
      case 'superFastAnswers':
        return superFastAnswers;
      case 'perfectGames':
        return perfectGames;
      case 'friendsCount':
        return friendsCount;
      case 'totalDaysPlayed':
        return totalDaysPlayed;
      case 'consecutiveDays':
        return consecutiveDays;
      case 'levelsCompleted':
        return levelsCompleted;
      case 'chaptersCompleted':
        return chaptersCompleted;
      case 'coinsEarned':
        return coinsEarned;
      case 'achievementsUnlocked':
        return achievementsUnlocked;
      case 'bestAccuracy':
        return bestAccuracy.toInt();
      default:
        if (statKey.startsWith('localeGames_')) {
          final code = statKey.substring('localeGames_'.length).toLowerCase();
          return localeGamesPlayed[code] ?? 0;
        }
        return 0;
    }
  }

  UserStats copyWith({
    String? userId,
    int? totalGamesPlayed,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
    int? totalWrongAnswers,
    int? totalScore,
    int? currentStreak,
    int? bestStreak,
    int? currentDailyStreak,
    int? bestDailyStreak,
    int? fastAnswers,
    int? superFastAnswers,
    double? bestAverageTime,
    int? perfectGames,
    double? bestAccuracy,
    int? friendsCount,
    int? friendRequestsSent,
    int? totalDaysPlayed,
    int? consecutiveDays,
    DateTime? lastPlayedAt,
    int? levelsCompleted,
    int? chaptersCompleted,
    int? coinsEarned,
    int? achievementsUnlocked,
    Map<String, int>? localeGamesPlayed,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalWrongAnswers: totalWrongAnswers ?? this.totalWrongAnswers,
      totalScore: totalScore ?? this.totalScore,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      currentDailyStreak: currentDailyStreak ?? this.currentDailyStreak,
      bestDailyStreak: bestDailyStreak ?? this.bestDailyStreak,
      fastAnswers: fastAnswers ?? this.fastAnswers,
      superFastAnswers: superFastAnswers ?? this.superFastAnswers,
      bestAverageTime: bestAverageTime ?? this.bestAverageTime,
      perfectGames: perfectGames ?? this.perfectGames,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      friendsCount: friendsCount ?? this.friendsCount,
      friendRequestsSent: friendRequestsSent ?? this.friendRequestsSent,
      totalDaysPlayed: totalDaysPlayed ?? this.totalDaysPlayed,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      chaptersCompleted: chaptersCompleted ?? this.chaptersCompleted,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      localeGamesPlayed: localeGamesPlayed ?? this.localeGamesPlayed,
    );
  }
}

