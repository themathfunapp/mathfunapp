/// Oyun Mekanikleri Modelleri
/// Combo, Can, İpucu, Güç-Up sistemleri

/// Güç-Up Türleri
enum PowerUpType {
  fiftyFifty,      // İki yanlış şıkkı eler
  freezeTime,      // Zamanı durdurur
  doublePoints,    // 2x puan
  skipQuestion,    // Soruyu atla
  extraLife,       // Ekstra can
  showHint,        // İpucu göster
  slowMotion,      // Zaman yavaşlatma
  shield,          // Bir yanlışı engeller
}

/// Güç-Up Modeli
class PowerUp {
  final PowerUpType type;
  final String name;
  final String description;
  final String emoji;
  final int cost; // Coin maliyeti
  final int duration; // Saniye cinsinden süre (varsa)

  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.cost,
    this.duration = 0,
  });

  static List<PowerUp> get allPowerUps => [
    const PowerUp(
      type: PowerUpType.fiftyFifty,
      name: '%50-50',
      description: 'İki yanlış şıkkı eler',
      emoji: '✂️',
      cost: 50,
    ),
    const PowerUp(
      type: PowerUpType.freezeTime,
      name: 'Zaman Dondur',
      description: '10 saniye zaman durur',
      emoji: '❄️',
      cost: 75,
      duration: 10,
    ),
    const PowerUp(
      type: PowerUpType.doublePoints,
      name: '2x Puan',
      description: 'Sonraki 3 soru için 2x puan',
      emoji: '✨',
      cost: 100,
      duration: 3,
    ),
    const PowerUp(
      type: PowerUpType.skipQuestion,
      name: 'Soruyu Atla',
      description: 'Bu soruyu doğru say',
      emoji: '⏭️',
      cost: 60,
    ),
    const PowerUp(
      type: PowerUpType.extraLife,
      name: 'Ekstra Can',
      description: '+1 can kazan',
      emoji: '❤️',
      cost: 80,
    ),
    const PowerUp(
      type: PowerUpType.showHint,
      name: 'İpucu',
      description: 'Sorunun ipucunu göster',
      emoji: '💡',
      cost: 30,
    ),
    const PowerUp(
      type: PowerUpType.slowMotion,
      name: 'Yavaş Mod',
      description: 'Zaman 2x yavaş akar',
      emoji: '🐢',
      cost: 40,
      duration: 15,
    ),
    const PowerUp(
      type: PowerUpType.shield,
      name: 'Kalkan',
      description: 'Bir yanlışı engeller',
      emoji: '🛡️',
      cost: 70,
    ),
  ];
}

/// Can Sistemi
class LivesSystem {
  int maxLives;
  int currentLives;
  DateTime? lastLifeLostAt;
  Duration lifeRegenTime;

  LivesSystem({
    this.maxLives = 5,
    this.currentLives = 5,
    this.lastLifeLostAt,
    this.lifeRegenTime = const Duration(minutes: 30),
  });

  bool get hasLives => currentLives > 0;
  bool get isFullLives => currentLives >= maxLives;

  void loseLife() {
    if (currentLives > 0) {
      currentLives--;
      lastLifeLostAt = DateTime.now();
    }
  }

  void gainLife() {
    if (currentLives < maxLives) {
      currentLives++;
    }
  }

  void refillLives() {
    currentLives = maxLives;
  }

  Duration? get timeUntilNextLife {
    if (isFullLives || lastLifeLostAt == null) return null;
    final elapsed = DateTime.now().difference(lastLifeLostAt!);
    if (elapsed >= lifeRegenTime) return Duration.zero;
    return lifeRegenTime - elapsed;
  }

  Map<String, dynamic> toJson() => {
    'maxLives': maxLives,
    'currentLives': currentLives,
    'lastLifeLostAt': lastLifeLostAt?.toIso8601String(),
  };

  factory LivesSystem.fromJson(Map<String, dynamic> json) => LivesSystem(
    maxLives: json['maxLives'] ?? 5,
    currentLives: json['currentLives'] ?? 5,
    lastLifeLostAt: json['lastLifeLostAt'] != null 
        ? DateTime.parse(json['lastLifeLostAt']) 
        : null,
  );
}

/// Combo Sistemi
class ComboSystem {
  int currentCombo;
  int maxCombo;
  int comboMultiplier;
  DateTime? lastCorrectAt;
  Duration comboTimeout;

  ComboSystem({
    this.currentCombo = 0,
    this.maxCombo = 0,
    this.comboMultiplier = 1,
    this.lastCorrectAt,
    this.comboTimeout = const Duration(seconds: 5),
  });

  /// Doğru cevap verildiğinde
  void onCorrectAnswer() {
    currentCombo++;
    if (currentCombo > maxCombo) {
      maxCombo = currentCombo;
    }
    lastCorrectAt = DateTime.now();
    _updateMultiplier();
  }

  /// Yanlış cevap verildiğinde
  void onWrongAnswer() {
    currentCombo = 0;
    comboMultiplier = 1;
  }

  /// Combo'nun zaman aşımına uğrayıp uğramadığını kontrol et
  bool checkTimeout() {
    if (lastCorrectAt == null) return false;
    final elapsed = DateTime.now().difference(lastCorrectAt!);
    if (elapsed > comboTimeout) {
      currentCombo = 0;
      comboMultiplier = 1;
      return true;
    }
    return false;
  }

  void _updateMultiplier() {
    if (currentCombo >= 20) {
      comboMultiplier = 5;
    } else if (currentCombo >= 15) {
      comboMultiplier = 4;
    } else if (currentCombo >= 10) {
      comboMultiplier = 3;
    } else if (currentCombo >= 5) {
      comboMultiplier = 2;
    } else {
      comboMultiplier = 1;
    }
  }

  /// Combo bonus metnini al
  String get comboText {
    if (currentCombo >= 20) return '🔥 SÜPER COMBO! x5';
    if (currentCombo >= 15) return '🔥 MEGA COMBO! x4';
    if (currentCombo >= 10) return '🔥 COMBO! x3';
    if (currentCombo >= 5) return '⚡ x2';
    return '';
  }

  int calculateScore(int baseScore) {
    return baseScore * comboMultiplier;
  }
}

/// İpucu Sistemi
class HintSystem {
  int availableHints;
  int maxFreeHints;
  DateTime? lastFreeHintAt;
  Duration freeHintCooldown;

  HintSystem({
    this.availableHints = 3,
    this.maxFreeHints = 3,
    this.lastFreeHintAt,
    this.freeHintCooldown = const Duration(hours: 4),
  });

  bool get hasHints => availableHints > 0;

  void useHint() {
    if (availableHints > 0) {
      availableHints--;
    }
  }

  void addHint([int count = 1]) {
    availableHints += count;
  }

  bool canClaimFreeHint() {
    if (lastFreeHintAt == null) return true;
    return DateTime.now().difference(lastFreeHintAt!) >= freeHintCooldown;
  }

  void claimFreeHint() {
    if (canClaimFreeHint()) {
      availableHints++;
      lastFreeHintAt = DateTime.now();
    }
  }

  Duration? get timeUntilFreeHint {
    if (canClaimFreeHint()) return Duration.zero;
    final elapsed = DateTime.now().difference(lastFreeHintAt!);
    return freeHintCooldown - elapsed;
  }

  /// Soru için ipucu oluştur
  static String generateHint(int num1, int num2, String operator, int answer) {
    switch (operator) {
      case '+':
        if (num1 > num2) {
          return '$num1 sayısına $num2 tane daha ekle';
        } else {
          return '$num2 sayısına $num1 tane daha ekle';
        }
      case '-':
        return '$num1 sayısından $num2 tane çıkar';
      case '×':
        return '$num1 sayısını $num2 kere topla';
      case '÷':
        return '$num1 sayısını $num2 eşit parçaya böl';
      default:
        return 'Cevap ${answer ~/ 2} ile ${answer + answer ~/ 2} arasında';
    }
  }
}

/// Günlük Challenge
class DailyChallenge {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final int targetScore;
  final int targetCorrect;
  final int timeLimit; // saniye
  final String difficulty;
  final List<String> topics;
  final int rewardCoins;
  final int rewardXp;
  bool isCompleted;
  int bestScore;

  DailyChallenge({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.targetScore,
    required this.targetCorrect,
    required this.timeLimit,
    required this.difficulty,
    required this.topics,
    required this.rewardCoins,
    required this.rewardXp,
    this.isCompleted = false,
    this.bestScore = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'description': description,
    'targetScore': targetScore,
    'targetCorrect': targetCorrect,
    'timeLimit': timeLimit,
    'difficulty': difficulty,
    'topics': topics,
    'rewardCoins': rewardCoins,
    'rewardXp': rewardXp,
    'isCompleted': isCompleted,
    'bestScore': bestScore,
  };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
    id: json['id'],
    date: DateTime.parse(json['date']),
    title: json['title'],
    description: json['description'],
    targetScore: json['targetScore'],
    targetCorrect: json['targetCorrect'],
    timeLimit: json['timeLimit'],
    difficulty: json['difficulty'],
    topics: List<String>.from(json['topics']),
    rewardCoins: json['rewardCoins'],
    rewardXp: json['rewardXp'],
    isCompleted: json['isCompleted'] ?? false,
    bestScore: json['bestScore'] ?? 0,
  );
}

/// Şans Çarkı Ödülleri
class SpinWheelReward {
  final String id;
  final String name;
  final String emoji;
  final String type; // 'coins', 'xp', 'powerup', 'hint', 'life'
  final int value;
  final double probability; // 0-1 arası

  const SpinWheelReward({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.value,
    required this.probability,
  });

  static List<SpinWheelReward> get defaultRewards => [
    const SpinWheelReward(
      id: 'coins_50',
      name: '50 Altın',
      emoji: '🪙',
      type: 'coins',
      value: 50,
      probability: 0.25,
    ),
    const SpinWheelReward(
      id: 'coins_100',
      name: '100 Altın',
      emoji: '💰',
      type: 'coins',
      value: 100,
      probability: 0.15,
    ),
    const SpinWheelReward(
      id: 'coins_200',
      name: '200 Altın',
      emoji: '💎',
      type: 'coins',
      value: 200,
      probability: 0.05,
    ),
    const SpinWheelReward(
      id: 'xp_25',
      name: '25 XP',
      emoji: '⭐',
      type: 'xp',
      value: 25,
      probability: 0.20,
    ),
    const SpinWheelReward(
      id: 'xp_50',
      name: '50 XP',
      emoji: '🌟',
      type: 'xp',
      value: 50,
      probability: 0.10,
    ),
    const SpinWheelReward(
      id: 'hint_1',
      name: '1 İpucu',
      emoji: '💡',
      type: 'hint',
      value: 1,
      probability: 0.10,
    ),
    const SpinWheelReward(
      id: 'life_1',
      name: '1 Can',
      emoji: '❤️',
      type: 'life',
      value: 1,
      probability: 0.10,
    ),
    const SpinWheelReward(
      id: 'powerup_random',
      name: 'Rastgele Güç',
      emoji: '🎁',
      type: 'powerup',
      value: 1,
      probability: 0.05,
    ),
  ];
}

/// Sürpriz Kutusu
class SurpriseBox {
  final String id;
  final String name;
  final String emoji;
  final String rarity; // 'common', 'rare', 'epic', 'legendary'
  final int cost;
  final List<BoxReward> possibleRewards;

  const SurpriseBox({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.cost,
    required this.possibleRewards,
  });
}

class BoxReward {
  final String type;
  final int minValue;
  final int maxValue;
  final double probability;

  const BoxReward({
    required this.type,
    required this.minValue,
    required this.maxValue,
    required this.probability,
  });
}

/// Boss Savaşı
class BossBattle {
  final String id;
  final String name;
  final String emoji;
  final int health;
  final int currentHealth;
  final int damagePerCorrect;
  final int damagePerWrong; // Oyuncuya verilen hasar
  final int timePerQuestion;
  final String difficulty;
  final int rewardCoins;
  final int rewardXp;
  final String specialReward;

  BossBattle({
    required this.id,
    required this.name,
    required this.emoji,
    required this.health,
    int? currentHealth,
    required this.damagePerCorrect,
    required this.damagePerWrong,
    required this.timePerQuestion,
    required this.difficulty,
    required this.rewardCoins,
    required this.rewardXp,
    required this.specialReward,
  }) : currentHealth = currentHealth ?? health;

  double get healthPercentage => currentHealth / health;
  bool get isDefeated => currentHealth <= 0;

  static List<BossBattle> get allBosses => [
    BossBattle(
      id: 'count_monster',
      name: 'Sayı Canavarı',
      emoji: '👾',
      health: 100,
      damagePerCorrect: 10,
      damagePerWrong: 15,
      timePerQuestion: 10,
      difficulty: 'easy',
      rewardCoins: 100,
      rewardXp: 50,
      specialReward: 'count_monster_badge',
    ),
    BossBattle(
      id: 'plus_dragon',
      name: 'Toplama Ejderhası',
      emoji: '🐉',
      health: 150,
      damagePerCorrect: 15,
      damagePerWrong: 20,
      timePerQuestion: 12,
      difficulty: 'medium',
      rewardCoins: 200,
      rewardXp: 100,
      specialReward: 'plus_dragon_badge',
    ),
    BossBattle(
      id: 'minus_wizard',
      name: 'Çıkarma Büyücüsü',
      emoji: '🧙',
      health: 200,
      damagePerCorrect: 20,
      damagePerWrong: 25,
      timePerQuestion: 15,
      difficulty: 'hard',
      rewardCoins: 300,
      rewardXp: 150,
      specialReward: 'minus_wizard_badge',
    ),
    BossBattle(
      id: 'multiply_titan',
      name: 'Çarpım Titanı',
      emoji: '🦖',
      health: 300,
      damagePerCorrect: 25,
      damagePerWrong: 30,
      timePerQuestion: 20,
      difficulty: 'expert',
      rewardCoins: 500,
      rewardXp: 250,
      specialReward: 'multiply_titan_badge',
    ),
  ];
}

/// Oyuncu Envanter
class PlayerInventory {
  Map<PowerUpType, int> powerUps;
  int hints;
  int lives;
  int coins;
  int gems;
  List<String> unlockedAvatars;
  List<String> unlockedBackgrounds;
  List<String> unlockedPets;

  PlayerInventory({
    Map<PowerUpType, int>? powerUps,
    this.hints = 3,
    this.lives = 5,
    this.coins = 0,
    this.gems = 0,
    List<String>? unlockedAvatars,
    List<String>? unlockedBackgrounds,
    List<String>? unlockedPets,
  }) : 
    powerUps = powerUps ?? {},
    unlockedAvatars = unlockedAvatars ?? ['default'],
    unlockedBackgrounds = unlockedBackgrounds ?? ['default'],
    unlockedPets = unlockedPets ?? [];

  int getPowerUpCount(PowerUpType type) => powerUps[type] ?? 0;

  void addPowerUp(PowerUpType type, [int count = 1]) {
    powerUps[type] = (powerUps[type] ?? 0) + count;
  }

  bool usePowerUp(PowerUpType type) {
    if (getPowerUpCount(type) > 0) {
      powerUps[type] = powerUps[type]! - 1;
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'powerUps': powerUps.map((k, v) => MapEntry(k.name, v)),
    'hints': hints,
    'lives': lives,
    'coins': coins,
    'gems': gems,
    'unlockedAvatars': unlockedAvatars,
    'unlockedBackgrounds': unlockedBackgrounds,
    'unlockedPets': unlockedPets,
  };

  factory PlayerInventory.fromJson(Map<String, dynamic> json) {
    final powerUpsMap = <PowerUpType, int>{};
    if (json['powerUps'] != null) {
      (json['powerUps'] as Map<String, dynamic>).forEach((key, value) {
        try {
          final type = PowerUpType.values.firstWhere((e) => e.name == key);
          powerUpsMap[type] = value as int;
        } catch (_) {}
      });
    }

    return PlayerInventory(
      powerUps: powerUpsMap,
      hints: json['hints'] ?? 3,
      lives: json['lives'] ?? 5,
      coins: json['coins'] ?? 0,
      gems: json['gems'] ?? 0,
      unlockedAvatars: json['unlockedAvatars'] != null 
          ? List<String>.from(json['unlockedAvatars']) 
          : ['default'],
      unlockedBackgrounds: json['unlockedBackgrounds'] != null 
          ? List<String>.from(json['unlockedBackgrounds']) 
          : ['default'],
      unlockedPets: json['unlockedPets'] != null 
          ? List<String>.from(json['unlockedPets']) 
          : [],
    );
  }
}

