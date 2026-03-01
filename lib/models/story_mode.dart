import 'package:cloud_firestore/cloud_firestore.dart';


/// Yaş grupları
enum AgeGroup {
  preschool, // 3-5 yaş - Sayı Maceracıları
  earlyElementary, // 6-8 yaş - Matematik Gezginleri
  lateElementary, // 9-11 yaş - Matematik Krallığı
}

/// Dünya temaları
enum WorldTheme {
  numberForest, // Sayı Ormanı - Toplama/Çıkarma
  geometryCastle, // Geometri Şatosu - Şekiller
  fractionBakery, // Kesir Pastanesi - Kesirler
  timeAdventure, // Zaman Macerası - Saat
  moneyMarket, // Para Pazarı - Para kavramı
  measurementLand, // Ölçüm Diyarı - Ölçme/Boyut
}

/// Matematik konuları
enum MathTopic {
  counting, // Sayma (1-10, 1-20, 1-100)
  addition, // Toplama
  subtraction, // Çıkarma
  multiplication, // Çarpma
  division, // Bölme
  fractions, // Kesirler
  decimals, // Ondalıklar
  shapes, // Şekiller
  angles, // Açılar
  time, // Saat
  money, // Para
  measurement, // Ölçme
  patterns, // Örüntüler
  algebra, // Basit cebir
}

/// Yardımcı karakterler
enum HelperCharacter {
  calculationSquirrel, // Hesaplama Sincabı - Hızlı matematik
  shapeOwl, // Şekil Ustası Baykuş - Geometri
  logicFox, // Mantık Tilki - Problem çözme
  timeTurtle, // Zaman Kaplumbağası - Saat
  fractionFrog, // Kesir Kurbağası - Kesirler
}

/// Oyuncu avatarı
class PlayerAvatar {
  final String oderId;
  final String odername;

  final int skinIndex;
  final int faceIndex;

  final int hairStyleIndex;
  final String hairColorName;

  final int shirtIndex;

  final int pantsIndex;
  final String pantsColorName;

  final int shoesIndex;
  final String shoesColorName;

  final int accessoryIndex;

  final int level;
  final int experience;

  PlayerAvatar({
    required this.oderId,
    required this.odername,

    this.skinIndex = 0,
    this.faceIndex = 0,

    this.hairStyleIndex = 0,
    this.hairColorName = 'Black',

    this.shirtIndex = 0,

    this.pantsIndex = 0,
    this.pantsColorName = 'Blue 1',

    this.shoesIndex = 0,
    this.shoesColorName = 'Black',

    this.accessoryIndex = 0,

    this.level = 1,
    this.experience = 0,

  });

  factory PlayerAvatar.fromMap(Map<String, dynamic> map) {
    return PlayerAvatar(
      oderId: map['oderId'] ?? '',
      odername: map['odername'] ?? 'Kahraman',

      skinIndex: map['skinIndex'] ?? 0,
      faceIndex: map['faceIndex'] ?? 0,

      hairStyleIndex: map['hairStyleIndex'] ?? 0,
      hairColorName: map['hairColorName'] ?? 'Black',

      shirtIndex: map['shirtIndex'] ?? 0,

      pantsIndex: map['pantsIndex'] ?? 0,
      pantsColorName: map['pantsColorName'] ?? 'Blue 1',

      shoesIndex: map['shoesIndex'] ?? 0,
      shoesColorName: map['shoesColorName'] ?? 'Black',

      accessoryIndex: map['accessoryIndex'] ?? 0,

      level: map['level'] ?? 1,
      experience: map['experience'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oderId': oderId,
      'odername': odername,

      'skinIndex': skinIndex,
      'faceIndex': faceIndex,

      'hairStyleIndex': hairStyleIndex,
      'hairColorName': hairColorName,

      'shirtIndex': shirtIndex,

      'pantsIndex': pantsIndex,
      'pantsColorName': pantsColorName,

      'shoesIndex': shoesIndex,
      'shoesColorName': shoesColorName,

      'accessoryIndex': accessoryIndex,

      'level': level,
      'experience': experience,
    };
  }

  PlayerAvatar copyWith({
    String? oderId,
    String? odername,

    int? skinIndex,
    int? faceIndex,

    int? hairStyleIndex,
    String? hairColorName,

    int? shirtIndex,

    int? pantsIndex,
    String? pantsColorName,

    int? shoesIndex,
    String? shoesColorName,

    int? accessoryIndex,

    int? level,
    int? experience,

  }) {
    return PlayerAvatar(
      oderId: oderId ?? this.oderId,
      odername: odername ?? this.odername,

      skinIndex: skinIndex ?? this.skinIndex,
      faceIndex: faceIndex ?? this.faceIndex,

      hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
      hairColorName: hairColorName ?? this.hairColorName,

      shirtIndex: shirtIndex ?? this.shirtIndex,

      pantsIndex: pantsIndex ?? this.pantsIndex,
      pantsColorName: pantsColorName ?? this.pantsColorName,

      shoesIndex: shoesIndex ?? this.shoesIndex,
      shoesColorName: shoesColorName ?? this.shoesColorName,

      accessoryIndex: accessoryIndex ?? this.accessoryIndex,

      level: level ?? this.level,
      experience: experience ?? this.experience,
    );
  }
}


/// Dünya (World) - Ana tema
class StoryWorld {
  final String id;
  final WorldTheme theme;
  final String nameKey; // Localization key
  final String descriptionKey;
  final String iconEmoji;
  final List<String> colors; // Gradient colors
  final List<MathTopic> topics;
  final AgeGroup targetAge;
  final List<StoryChapter> chapters;
  final bool isLocked;
  final int requiredStars;

  StoryWorld({
    required this.id,
    required this.theme,
    required this.nameKey,
    required this.descriptionKey,
    required this.iconEmoji,
    required this.colors,
    required this.topics,
    required this.targetAge,
    required this.chapters,
    this.isLocked = false,
    this.requiredStars = 0,
  });
}

/// Bölüm (Chapter) - Dünya içindeki ana hikaye bölümü
class StoryChapter {
  final String id;
  final String worldId;
  final int orderIndex;
  final String nameKey;
  final String descriptionKey;
  final String storyIntroKey; // Hikaye girişi
  final List<StoryLevel> levels;
  final HelperCharacter helper;
  final bool isLocked;
  final int requiredStars;

  StoryChapter({
    required this.id,
    required this.worldId,
    required this.orderIndex,
    required this.nameKey,
    required this.descriptionKey,
    required this.storyIntroKey,
    required this.levels,
    required this.helper,
    this.isLocked = false,
    this.requiredStars = 0,
  });
}

/// Seviye (Level) - Oynanabilir bölüm
class StoryLevel {
  final String id;
  final String chapterId;
  final int orderIndex;
  final String nameKey;
  final LevelType type;
  final MathTopic topic;
  final int difficulty; // 1-5
  final List<MathQuestion> questions;
  final int starThresholds1; // 1 yıldız için gereken puan
  final int starThresholds2; // 2 yıldız için gereken puan
  final int starThresholds3; // 3 yıldız için gereken puan
  final int timeLimit; // saniye (0 = süresiz)
  final List<String> rewards; // Ödül ID'leri
  final bool isBossLevel;

  StoryLevel({
    required this.id,
    required this.chapterId,
    required this.orderIndex,
    required this.nameKey,
    required this.type,
    required this.topic,
    required this.difficulty,
    required this.questions,
    this.starThresholds1 = 50,
    this.starThresholds2 = 75,
    this.starThresholds3 = 100,
    this.timeLimit = 0,
    this.rewards = const [],
    this.isBossLevel = false,
  });
}

/// Seviye türleri
enum LevelType {
  discovery, // Keşif Anı - Yeni kavram tanıtımı
  practice, // Pratik Zamanı - Mini oyunlarla deneme
  challenge, // Meydan Okuma - Hafif zorlayıcı bulmaca
  creative, // Yaratıcı Uygulama - Farklı kullanım
  boss, // Boss seviyesi - Bölüm sonu
}

/// Matematik sorusu
class MathQuestion {
  final String id;
  final String questionKey; // Localization key veya dinamik soru
  final String? imageUrl;
  final MathTopic topic;
  final QuestionType type;
  final List<String> options; // Çoktan seçmeli için
  final String correctAnswer;
  final List<String>? alternativeAnswers; // Birden fazla doğru cevap
  final String? hintKey;
  final String? explanationKey;
  final int points;
  final int difficulty;

  MathQuestion({
    required this.id,
    required this.questionKey,
    this.imageUrl,
    required this.topic,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    this.alternativeAnswers,
    this.hintKey,
    this.explanationKey,
    this.points = 10,
    this.difficulty = 1,
  });
}

/// Soru türleri
enum QuestionType {
  multipleChoice, // Çoktan seçmeli
  dragDrop, // Sürükle bırak
  fillBlank, // Boşluk doldurma
  matching, // Eşleştirme
  ordering, // Sıralama
  drawing, // Çizim (şekiller için)
  counting, // Sayma (nesneleri say)
  trueForze, // Doğru/Yanlış
}

/// Görev (Quest) - Günlük/haftalık görevler
class StoryQuest {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final QuestType type;
  final int targetValue; // Hedef değer (örn: 5 seviye tamamla)
  final int currentValue; // Mevcut ilerleme
  final List<QuestReward> rewards;
  final DateTime? expiresAt;
  final bool isCompleted;

  StoryQuest({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.rewards,
    this.expiresAt,
    this.isCompleted = false,
  });

  double get progress => currentValue / targetValue;

  factory StoryQuest.fromMap(Map<String, dynamic> map) {
    return StoryQuest(
      id: map['id'] ?? '',
      nameKey: map['nameKey'] ?? '',
      descriptionKey: map['descriptionKey'] ?? '',
      type: QuestType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestType.daily,
      ),
      targetValue: map['targetValue'] ?? 1,
      currentValue: map['currentValue'] ?? 0,
      rewards: (map['rewards'] as List<dynamic>?)
              ?.map((r) => QuestReward.fromMap(r))
              .toList() ??
          [],
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameKey': nameKey,
      'descriptionKey': descriptionKey,
      'type': type.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'rewards': rewards.map((r) => r.toMap()).toList(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isCompleted': isCompleted,
    };
  }
}

enum QuestType {
  daily, // Günlük görev
  weekly, // Haftalık görev
  story, // Hikaye görevi
  special, // Özel etkinlik görevi
}

/// Görev ödülü
class QuestReward {
  final RewardType type;
  final int amount;
  final String? itemId; // Özel item için

  QuestReward({
    required this.type,
    required this.amount,
    this.itemId,
  });

  factory QuestReward.fromMap(Map<String, dynamic> map) {
    return QuestReward(
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.coins,
      ),
      amount: map['amount'] ?? 0,
      itemId: map['itemId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'amount': amount,
      'itemId': itemId,
    };
  }
}

enum RewardType {
  coins, // Altın
  gems, // Elmas
  experience, // Deneyim puanı
  badge, // Rozet
  avatar, // Avatar parçası
  sticker, // Çıkartma
  booster, // Güçlendirici
}

/// Oyuncu hikaye ilerlemesi
class StoryProgress {
  final String oderId;
  final AgeGroup selectedAgeGroup;
  final PlayerAvatar avatar;
  final Map<String, WorldProgress> worldProgress;
  final List<String> completedQuests;
  final List<String> earnedBadges;
  final List<String> unlockedAvatarItems;
  final int totalStars;
  final int totalCoins;
  final int totalGems;
  final int currentStreak;
  final DateTime? lastPlayedAt;

  StoryProgress({
    required this.oderId,
    required this.selectedAgeGroup,
    required this.avatar,
    this.worldProgress = const {},
    this.completedQuests = const [],
    this.earnedBadges = const [],
    this.unlockedAvatarItems = const [],
    this.totalStars = 0,
    this.totalCoins = 0,
    this.totalGems = 0,
    this.currentStreak = 0,
    this.lastPlayedAt,
  });

  factory StoryProgress.fromMap(Map<String, dynamic> map) {
    return StoryProgress(
      oderId: map['userId'] ?? '',
      selectedAgeGroup: AgeGroup.values.firstWhere(
        (e) => e.name == map['selectedAgeGroup'],
        orElse: () => AgeGroup.preschool,
      ),
      avatar: PlayerAvatar.fromMap(map['avatar'] ?? {}),
      worldProgress: (map['worldProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, WorldProgress.fromMap(value)),
          ) ??
          {},
      completedQuests: List<String>.from(map['completedQuests'] ?? []),
      earnedBadges: List<String>.from(map['earnedBadges'] ?? []),
      unlockedAvatarItems: List<String>.from(map['unlockedAvatarItems'] ?? []),
      totalStars: map['totalStars'] ?? 0,
      totalCoins: map['totalCoins'] ?? 0,
      totalGems: map['totalGems'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      lastPlayedAt: map['lastPlayedAt'] != null
          ? (map['lastPlayedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': oderId,
      'selectedAgeGroup': selectedAgeGroup.name,
      'avatar': avatar.toMap(),
      'worldProgress': worldProgress.map((key, value) => MapEntry(key, value.toMap())),
      'completedQuests': completedQuests,
      'earnedBadges': earnedBadges,
      'unlockedAvatarItems': unlockedAvatarItems,
      'totalStars': totalStars,
      'totalCoins': totalCoins,
      'totalGems': totalGems,
      'currentStreak': currentStreak,
      'lastPlayedAt': lastPlayedAt != null ? Timestamp.fromDate(lastPlayedAt!) : null,
    };
  }
}

/// Dünya ilerlemesi
class WorldProgress {
  final String worldId;
  final Map<String, ChapterProgress> chapterProgress;
  final bool isUnlocked;
  final int totalStars;

  WorldProgress({
    required this.worldId,
    this.chapterProgress = const {},
    this.isUnlocked = false,
    this.totalStars = 0,
  });

  factory WorldProgress.fromMap(Map<String, dynamic> map) {
    return WorldProgress(
      worldId: map['worldId'] ?? '',
      chapterProgress: (map['chapterProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ChapterProgress.fromMap(value)),
          ) ??
          {},
      isUnlocked: map['isUnlocked'] ?? false,
      totalStars: map['totalStars'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'worldId': worldId,
      'chapterProgress': chapterProgress.map((key, value) => MapEntry(key, value.toMap())),
      'isUnlocked': isUnlocked,
      'totalStars': totalStars,
    };
  }
}

/// Bölüm ilerlemesi
class ChapterProgress {
  final String chapterId;
  final Map<String, LevelProgress> levelProgress;
  final bool isUnlocked;
  final int totalStars;

  ChapterProgress({
    required this.chapterId,
    this.levelProgress = const {},
    this.isUnlocked = false,
    this.totalStars = 0,
  });

  factory ChapterProgress.fromMap(Map<String, dynamic> map) {
    return ChapterProgress(
      chapterId: map['chapterId'] ?? '',
      levelProgress: (map['levelProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, LevelProgress.fromMap(value)),
          ) ??
          {},
      isUnlocked: map['isUnlocked'] ?? false,
      totalStars: map['totalStars'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterId': chapterId,
      'levelProgress': levelProgress.map((key, value) => MapEntry(key, value.toMap())),
      'isUnlocked': isUnlocked,
      'totalStars': totalStars,
    };
  }
}

/// Seviye ilerlemesi
class LevelProgress {
  final String levelId;
  final bool isCompleted;
  final int stars; // 0-3
  final int bestScore;
  final int attempts;
  final DateTime? completedAt;

  LevelProgress({
    required this.levelId,
    this.isCompleted = false,
    this.stars = 0,
    this.bestScore = 0,
    this.attempts = 0,
    this.completedAt,
  });

  factory LevelProgress.fromMap(Map<String, dynamic> map) {
    return LevelProgress(
      levelId: map['levelId'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      stars: map['stars'] ?? 0,
      bestScore: map['bestScore'] ?? 0,
      attempts: map['attempts'] ?? 0,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'isCompleted': isCompleted,
      'stars': stars,
      'bestScore': bestScore,
      'attempts': attempts,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

/// Koleksiyon kartı
class CollectionCard {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final String imageUrl;
  final CardRarity rarity;
  final MathTopic topic;
  final bool isUnlocked;

  CollectionCard({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.imageUrl,
    required this.rarity,
    required this.topic,
    this.isUnlocked = false,
  });
}

enum CardRarity {
  common, // Yaygın
  rare, // Nadir
  epic, // Epik
  legendary, // Efsanevi
}

