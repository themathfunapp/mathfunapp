import 'package:cloud_firestore/cloud_firestore.dart';

/// Ödül türleri
enum RewardType {
  coins,        // Altın
  diamonds,     // Elmas
  powerUp,      // Güçlendirici
  avatar,       // Avatar
  theme,        // Tema
  badge,        // Rozet
  hint,         // İpucu hakkı
  multiplier,   // Çarpan
  ticket,       // Bilet
  mystery,      // Gizemli ödül
  stars,        // Profil / hikâye üst çubuğu ile senkron yıldız
}

/// Güçlendirici türleri
enum PowerUpType {
  halfOptions,      // Seçenekleri yarıya indir
  extraTime,        // Ekstra süre
  showHint,         // İpucu göster
  doublePoints,     // 2x puan
  skipQuestion,     // Soruyu geç
  freezeTime,       // Süreyi dondur
}

/// Tek bir ödül öğesi
class RewardItem {
  final RewardType type;
  final int amount;
  final String? itemId;      // Avatar/tema ID'si
  final PowerUpType? powerUpType;
  final String? displayName;
  final String emoji;

  const RewardItem({
    required this.type,
    required this.amount,
    this.itemId,
    this.powerUpType,
    this.displayName,
    required this.emoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'amount': amount,
      'itemId': itemId,
      'powerUpType': powerUpType?.name,
      'displayName': displayName,
      'emoji': emoji,
    };
  }

  factory RewardItem.fromMap(Map<String, dynamic> map) {
    return RewardItem(
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.coins,
      ),
      amount: map['amount'] ?? 0,
      itemId: map['itemId'],
      powerUpType: map['powerUpType'] != null
          ? PowerUpType.values.firstWhere(
              (e) => e.name == map['powerUpType'],
              orElse: () => PowerUpType.showHint,
            )
          : null,
      displayName: map['displayName'],
      emoji: map['emoji'] ?? '🎁',
    );
  }
}

/// Giriş serisi ödülü
class StreakReward {
  final int day;
  final List<RewardItem> rewards;
  final bool isSpecial;

  const StreakReward({
    required this.day,
    required this.rewards,
    this.isSpecial = false,
  });
}

/// Günlük görev
class DailyTask {
  final String id;
  final String titleKey;       // Localization key
  final String descriptionKey; // Localization key
  final String emoji;
  final TaskType type;
  final int targetValue;
  final List<RewardItem> rewards;
  final TaskDifficulty difficulty;

  const DailyTask({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.emoji,
    required this.type,
    required this.targetValue,
    required this.rewards,
    required this.difficulty,
  });
}

enum TaskType {
  solveQuestions,     // Soru çöz
  playGames,          // Oyun oyna
  correctStreak,      // Doğru cevap serisi
  perfectGame,        // Hatasız oyun
  fastAnswers,        // Hızlı cevap
  playMiniGame,       // Mini oyun oyna
  completeStory,      // Hikaye tamamla
  dailyLogin,         // Günlük giriş
}

enum TaskDifficulty {
  easy,
  medium,
  hard,
}

/// Kullanıcının görev ilerlemesi
class UserTaskProgress {
  final String taskId;
  final int currentValue;
  final bool isCompleted;
  final bool isRewardClaimed;
  final DateTime? completedAt;

  UserTaskProgress({
    required this.taskId,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isRewardClaimed = false,
    this.completedAt,
  });

  factory UserTaskProgress.fromMap(Map<String, dynamic> map, String taskId) {
    return UserTaskProgress(
      taskId: taskId,
      currentValue: map['currentValue'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      isRewardClaimed: map['isRewardClaimed'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] is Timestamp
              ? (map['completedAt'] as Timestamp).toDate()
              : DateTime.parse(map['completedAt']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'isRewardClaimed': isRewardClaimed,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  UserTaskProgress copyWith({
    String? taskId,
    int? currentValue,
    bool? isCompleted,
    bool? isRewardClaimed,
    DateTime? completedAt,
  }) {
    return UserTaskProgress(
      taskId: taskId ?? this.taskId,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Şans çarkı dilimi
class WheelSlice {
  final RewardItem reward;
  final double probability; // 0.0 - 1.0 arası
  final int colorIndex;

  const WheelSlice({
    required this.reward,
    required this.probability,
    required this.colorIndex,
  });
}

/// Kullanıcının ödül verileri
class UserRewards {
  final String userId;
  
  // Para birimleri
  final int coins;
  final int diamonds;

  /// Günlük ödül, çark ve sürpriz kutudan gelen yıldızlar (hikâye yıldızına eklenir)
  final int profileBonusStars;
  
  // Güçlendiriciler
  final int hintCount;
  final int halfOptionsCount;
  final int extraTimeCount;
  final int doublePointsCount;
  final int skipQuestionCount;
  final int freezeTimeCount;
  
  // Streak bilgileri
  final int loginStreak;
  final int bestLoginStreak;
  final DateTime? lastLoginDate;
  final DateTime? lastRewardClaimDate;
  
  // Çark bilgileri
  final int freeSpinsToday;
  final int totalSpins;
  final DateTime? lastSpinDate;
  
  // Kutu bilgileri
  final bool dailyBoxOpened;
  final int totalBoxesOpened;
  
  // Görev bilgileri
  final DateTime? tasksResetDate;

  UserRewards({
    required this.userId,
    this.coins = 0,
    this.diamonds = 0,
    this.profileBonusStars = 0,
    this.hintCount = 0,
    this.halfOptionsCount = 0,
    this.extraTimeCount = 0,
    this.doublePointsCount = 0,
    this.skipQuestionCount = 0,
    this.freezeTimeCount = 0,
    this.loginStreak = 0,
    this.bestLoginStreak = 0,
    this.lastLoginDate,
    this.lastRewardClaimDate,
    this.freeSpinsToday = 1,
    this.totalSpins = 0,
    this.lastSpinDate,
    this.dailyBoxOpened = false,
    this.totalBoxesOpened = 0,
    this.tasksResetDate,
  });

  factory UserRewards.fromMap(Map<String, dynamic> map, String userId) {
    return UserRewards(
      userId: userId,
      coins: map['coins'] ?? 0,
      diamonds: map['diamonds'] ?? 0,
      profileBonusStars: map['profileBonusStars'] ?? 0,
      hintCount: map['hintCount'] ?? 0,
      halfOptionsCount: map['halfOptionsCount'] ?? 0,
      extraTimeCount: map['extraTimeCount'] ?? 0,
      doublePointsCount: map['doublePointsCount'] ?? 0,
      skipQuestionCount: map['skipQuestionCount'] ?? 0,
      freezeTimeCount: map['freezeTimeCount'] ?? 0,
      loginStreak: map['loginStreak'] ?? 0,
      bestLoginStreak: map['bestLoginStreak'] ?? 0,
      lastLoginDate: _parseDate(map['lastLoginDate']),
      lastRewardClaimDate: _parseDate(map['lastRewardClaimDate']),
      freeSpinsToday: map['freeSpinsToday'] ?? 1,
      totalSpins: map['totalSpins'] ?? 0,
      lastSpinDate: _parseDate(map['lastSpinDate']),
      dailyBoxOpened: map['dailyBoxOpened'] ?? false,
      totalBoxesOpened: map['totalBoxesOpened'] ?? 0,
      tasksResetDate: _parseDate(map['tasksResetDate']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'coins': coins,
      'diamonds': diamonds,
      'profileBonusStars': profileBonusStars,
      'hintCount': hintCount,
      'halfOptionsCount': halfOptionsCount,
      'extraTimeCount': extraTimeCount,
      'doublePointsCount': doublePointsCount,
      'skipQuestionCount': skipQuestionCount,
      'freezeTimeCount': freezeTimeCount,
      'loginStreak': loginStreak,
      'bestLoginStreak': bestLoginStreak,
      'lastLoginDate': lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
      'lastRewardClaimDate': lastRewardClaimDate != null ? Timestamp.fromDate(lastRewardClaimDate!) : null,
      'freeSpinsToday': freeSpinsToday,
      'totalSpins': totalSpins,
      'lastSpinDate': lastSpinDate != null ? Timestamp.fromDate(lastSpinDate!) : null,
      'dailyBoxOpened': dailyBoxOpened,
      'totalBoxesOpened': totalBoxesOpened,
      'tasksResetDate': tasksResetDate != null ? Timestamp.fromDate(tasksResetDate!) : null,
      'updatedAt': Timestamp.now(),
    };
  }

  UserRewards copyWith({
    String? userId,
    int? coins,
    int? diamonds,
    int? profileBonusStars,
    int? hintCount,
    int? halfOptionsCount,
    int? extraTimeCount,
    int? doublePointsCount,
    int? skipQuestionCount,
    int? freezeTimeCount,
    int? loginStreak,
    int? bestLoginStreak,
    DateTime? lastLoginDate,
    DateTime? lastRewardClaimDate,
    int? freeSpinsToday,
    int? totalSpins,
    DateTime? lastSpinDate,
    bool? dailyBoxOpened,
    int? totalBoxesOpened,
    DateTime? tasksResetDate,
  }) {
    return UserRewards(
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      profileBonusStars: profileBonusStars ?? this.profileBonusStars,
      hintCount: hintCount ?? this.hintCount,
      halfOptionsCount: halfOptionsCount ?? this.halfOptionsCount,
      extraTimeCount: extraTimeCount ?? this.extraTimeCount,
      doublePointsCount: doublePointsCount ?? this.doublePointsCount,
      skipQuestionCount: skipQuestionCount ?? this.skipQuestionCount,
      freezeTimeCount: freezeTimeCount ?? this.freezeTimeCount,
      loginStreak: loginStreak ?? this.loginStreak,
      bestLoginStreak: bestLoginStreak ?? this.bestLoginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastRewardClaimDate: lastRewardClaimDate ?? this.lastRewardClaimDate,
      freeSpinsToday: freeSpinsToday ?? this.freeSpinsToday,
      totalSpins: totalSpins ?? this.totalSpins,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      dailyBoxOpened: dailyBoxOpened ?? this.dailyBoxOpened,
      totalBoxesOpened: totalBoxesOpened ?? this.totalBoxesOpened,
      tasksResetDate: tasksResetDate ?? this.tasksResetDate,
    );
  }
}

