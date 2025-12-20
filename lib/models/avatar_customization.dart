/// Avatar Özelleştirme Modelleri
/// Karakter, aksesuar, evcil hayvan sistemleri

/// Avatar parça türleri
enum AvatarPartType {
  skin,
  hair,
  eyes,
  outfit,
  accessory,
  background,
}

/// Avatar parçası
class AvatarPart {
  final String id;
  final String name;
  final AvatarPartType type;
  final String emoji;
  final int cost;
  final bool isPremium;
  final bool isUnlocked;

  const AvatarPart({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    this.cost = 0,
    this.isPremium = false,
    this.isUnlocked = false,
  });

  static List<AvatarPart> get allParts => [
    // Skin Colors
    const AvatarPart(id: 'skin_default', name: 'Normal', type: AvatarPartType.skin, emoji: '👦', isUnlocked: true),
    const AvatarPart(id: 'skin_light', name: 'Açık', type: AvatarPartType.skin, emoji: '👦🏻', isUnlocked: true),
    const AvatarPart(id: 'skin_medium', name: 'Orta', type: AvatarPartType.skin, emoji: '👦🏽', isUnlocked: true),
    const AvatarPart(id: 'skin_dark', name: 'Koyu', type: AvatarPartType.skin, emoji: '👦🏿', isUnlocked: true),
    
    // Hair Styles
    const AvatarPart(id: 'hair_short', name: 'Kısa', type: AvatarPartType.hair, emoji: '💇', isUnlocked: true),
    const AvatarPart(id: 'hair_long', name: 'Uzun', type: AvatarPartType.hair, emoji: '💇‍♀️', isUnlocked: true),
    const AvatarPart(id: 'hair_curly', name: 'Kıvırcık', type: AvatarPartType.hair, emoji: '🦱', cost: 50),
    const AvatarPart(id: 'hair_spiky', name: 'Dikili', type: AvatarPartType.hair, emoji: '🦔', cost: 75),
    const AvatarPart(id: 'hair_rainbow', name: 'Gökkuşağı', type: AvatarPartType.hair, emoji: '🌈', cost: 200, isPremium: true),
    
    // Eye Styles
    const AvatarPart(id: 'eyes_normal', name: 'Normal', type: AvatarPartType.eyes, emoji: '👀', isUnlocked: true),
    const AvatarPart(id: 'eyes_cool', name: 'Havalı', type: AvatarPartType.eyes, emoji: '😎', cost: 100),
    const AvatarPart(id: 'eyes_star', name: 'Yıldız', type: AvatarPartType.eyes, emoji: '🤩', cost: 150),
    const AvatarPart(id: 'eyes_heart', name: 'Kalp', type: AvatarPartType.eyes, emoji: '😍', cost: 150),
    
    // Outfits
    const AvatarPart(id: 'outfit_casual', name: 'Günlük', type: AvatarPartType.outfit, emoji: '👕', isUnlocked: true),
    const AvatarPart(id: 'outfit_superhero', name: 'Süper Kahraman', type: AvatarPartType.outfit, emoji: '🦸', cost: 200),
    const AvatarPart(id: 'outfit_astronaut', name: 'Astronot', type: AvatarPartType.outfit, emoji: '👨‍🚀', cost: 300),
    const AvatarPart(id: 'outfit_wizard', name: 'Büyücü', type: AvatarPartType.outfit, emoji: '🧙', cost: 250),
    const AvatarPart(id: 'outfit_princess', name: 'Prenses', type: AvatarPartType.outfit, emoji: '👸', cost: 300),
    const AvatarPart(id: 'outfit_pirate', name: 'Korsan', type: AvatarPartType.outfit, emoji: '🏴‍☠️', cost: 200),
    const AvatarPart(id: 'outfit_ninja', name: 'Ninja', type: AvatarPartType.outfit, emoji: '🥷', cost: 350),
    const AvatarPart(id: 'outfit_robot', name: 'Robot', type: AvatarPartType.outfit, emoji: '🤖', cost: 400, isPremium: true),
    
    // Accessories
    const AvatarPart(id: 'acc_none', name: 'Yok', type: AvatarPartType.accessory, emoji: '❌', isUnlocked: true),
    const AvatarPart(id: 'acc_glasses', name: 'Gözlük', type: AvatarPartType.accessory, emoji: '👓', cost: 50),
    const AvatarPart(id: 'acc_crown', name: 'Taç', type: AvatarPartType.accessory, emoji: '👑', cost: 500),
    const AvatarPart(id: 'acc_hat', name: 'Şapka', type: AvatarPartType.accessory, emoji: '🎩', cost: 100),
    const AvatarPart(id: 'acc_cap', name: 'Kep', type: AvatarPartType.accessory, emoji: '🧢', cost: 75),
    const AvatarPart(id: 'acc_headphones', name: 'Kulaklık', type: AvatarPartType.accessory, emoji: '🎧', cost: 150),
    const AvatarPart(id: 'acc_mask', name: 'Maske', type: AvatarPartType.accessory, emoji: '🎭', cost: 200),
    
    // Backgrounds
    const AvatarPart(id: 'bg_default', name: 'Varsayılan', type: AvatarPartType.background, emoji: '🟦', isUnlocked: true),
    const AvatarPart(id: 'bg_space', name: 'Uzay', type: AvatarPartType.background, emoji: '🌌', cost: 300),
    const AvatarPart(id: 'bg_forest', name: 'Orman', type: AvatarPartType.background, emoji: '🌲', cost: 200),
    const AvatarPart(id: 'bg_beach', name: 'Plaj', type: AvatarPartType.background, emoji: '🏖️', cost: 250),
    const AvatarPart(id: 'bg_castle', name: 'Şato', type: AvatarPartType.background, emoji: '🏰', cost: 350),
    const AvatarPart(id: 'bg_rainbow', name: 'Gökkuşağı', type: AvatarPartType.background, emoji: '🌈', cost: 400, isPremium: true),
  ];
}

/// Evcil Hayvan Türleri
enum PetType {
  cat,
  dog,
  bunny,
  bird,
  dragon,
  unicorn,
  robot,
  alien,
}

/// Evcil Hayvan
class Pet {
  final String id;
  final String name;
  final PetType type;
  final String emoji;
  final int cost;
  final bool isPremium;
  int level;
  int experience;
  int happiness;
  DateTime? lastFed;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    this.cost = 0,
    this.isPremium = false,
    this.level = 1,
    this.experience = 0,
    this.happiness = 100,
    this.lastFed,
  });

  int get experienceToNextLevel => level * 100;
  double get experienceProgress => experience / experienceToNextLevel;

  bool get isHungry {
    if (lastFed == null) return true;
    return DateTime.now().difference(lastFed!).inHours >= 4;
  }

  void feed() {
    lastFed = DateTime.now();
    happiness = (happiness + 20).clamp(0, 100);
    experience += 10;
    if (experience >= experienceToNextLevel) {
      experience = 0;
      level++;
    }
  }

  void play() {
    happiness = (happiness + 10).clamp(0, 100);
    experience += 5;
    if (experience >= experienceToNextLevel) {
      experience = 0;
      level++;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'level': level,
    'experience': experience,
    'happiness': happiness,
    'lastFed': lastFed?.toIso8601String(),
  };

  factory Pet.fromJson(Map<String, dynamic> json) {
    final allPets = Pet.allPets;
    final template = allPets.firstWhere(
      (p) => p.id == json['id'],
      orElse: () => allPets.first,
    );
    
    return Pet(
      id: json['id'] ?? template.id,
      name: json['name'] ?? template.name,
      type: PetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => template.type,
      ),
      emoji: template.emoji,
      cost: template.cost,
      isPremium: template.isPremium,
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      happiness: json['happiness'] ?? 100,
      lastFed: json['lastFed'] != null ? DateTime.parse(json['lastFed']) : null,
    );
  }

  static List<Pet> get allPets => [
    Pet(id: 'pet_cat', name: 'Mırmır', type: PetType.cat, emoji: '🐱', cost: 200),
    Pet(id: 'pet_dog', name: 'Karabaş', type: PetType.dog, emoji: '🐶', cost: 200),
    Pet(id: 'pet_bunny', name: 'Pamuk', type: PetType.bunny, emoji: '🐰', cost: 250),
    Pet(id: 'pet_bird', name: 'Cıvıl', type: PetType.bird, emoji: '🐦', cost: 150),
    Pet(id: 'pet_dragon', name: 'Ateş', type: PetType.dragon, emoji: '🐉', cost: 500),
    Pet(id: 'pet_unicorn', name: 'Gökkuşağı', type: PetType.unicorn, emoji: '🦄', cost: 750, isPremium: true),
    Pet(id: 'pet_robot', name: 'Bibi', type: PetType.robot, emoji: '🤖', cost: 400),
    Pet(id: 'pet_alien', name: 'Uzaylı', type: PetType.alien, emoji: '👽', cost: 600),
  ];
}

/// Kullanıcı Avatar Verisi
class UserAvatar {
  String oderId;
  String selectedSkin;
  String selectedHair;
  String selectedEyes;
  String selectedOutfit;
  String selectedAccessory;
  String selectedBackground;
  List<String> unlockedParts;
  Pet? activePet;
  List<Pet> ownedPets;

  UserAvatar({
    required this.oderId,
    this.selectedSkin = 'skin_default',
    this.selectedHair = 'hair_short',
    this.selectedEyes = 'eyes_normal',
    this.selectedOutfit = 'outfit_casual',
    this.selectedAccessory = 'acc_none',
    this.selectedBackground = 'bg_default',
    List<String>? unlockedParts,
    this.activePet,
    List<Pet>? ownedPets,
  }) : unlockedParts = unlockedParts ?? [], ownedPets = ownedPets ?? [];

  Map<String, dynamic> toJson() => {
    'oderId': oderId,
    'selectedSkin': selectedSkin,
    'selectedHair': selectedHair,
    'selectedEyes': selectedEyes,
    'selectedOutfit': selectedOutfit,
    'selectedAccessory': selectedAccessory,
    'selectedBackground': selectedBackground,
    'unlockedParts': unlockedParts,
    'activePet': activePet?.toJson(),
    'ownedPets': ownedPets.map((p) => p.toJson()).toList(),
  };

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      oderId: json['oderId'] ?? '',
      selectedSkin: json['selectedSkin'] ?? 'skin_default',
      selectedHair: json['selectedHair'] ?? 'hair_short',
      selectedEyes: json['selectedEyes'] ?? 'eyes_normal',
      selectedOutfit: json['selectedOutfit'] ?? 'outfit_casual',
      selectedAccessory: json['selectedAccessory'] ?? 'acc_none',
      selectedBackground: json['selectedBackground'] ?? 'bg_default',
      unlockedParts: json['unlockedParts'] != null 
          ? List<String>.from(json['unlockedParts']) 
          : [],
      activePet: json['activePet'] != null ? Pet.fromJson(json['activePet']) : null,
      ownedPets: json['ownedPets'] != null
          ? (json['ownedPets'] as List).map((p) => Pet.fromJson(p)).toList()
          : [],
    );
  }
}

/// Oda Dekorasyonu
class RoomDecoration {
  final String id;
  final String name;
  final String emoji;
  final String category; // 'furniture', 'wall', 'floor', 'accessory'
  final int cost;
  final bool isPremium;

  const RoomDecoration({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.cost = 0,
    this.isPremium = false,
  });

  static List<RoomDecoration> get allDecorations => [
    // Furniture
    const RoomDecoration(id: 'bed_basic', name: 'Temel Yatak', emoji: '🛏️', category: 'furniture'),
    const RoomDecoration(id: 'bed_fancy', name: 'Süslü Yatak', emoji: '🛋️', category: 'furniture', cost: 200),
    const RoomDecoration(id: 'desk', name: 'Çalışma Masası', emoji: '🪑', category: 'furniture', cost: 150),
    const RoomDecoration(id: 'bookshelf', name: 'Kitaplık', emoji: '📚', category: 'furniture', cost: 100),
    const RoomDecoration(id: 'lamp', name: 'Lamba', emoji: '💡', category: 'furniture', cost: 50),
    const RoomDecoration(id: 'plant', name: 'Bitki', emoji: '🪴', category: 'furniture', cost: 75),
    const RoomDecoration(id: 'tv', name: 'Televizyon', emoji: '📺', category: 'furniture', cost: 300),
    const RoomDecoration(id: 'computer', name: 'Bilgisayar', emoji: '💻', category: 'furniture', cost: 400),
    
    // Wall
    const RoomDecoration(id: 'poster_math', name: 'Matematik Posteri', emoji: '🔢', category: 'wall', cost: 50),
    const RoomDecoration(id: 'poster_space', name: 'Uzay Posteri', emoji: '🚀', category: 'wall', cost: 75),
    const RoomDecoration(id: 'clock', name: 'Saat', emoji: '🕰️', category: 'wall', cost: 100),
    const RoomDecoration(id: 'painting', name: 'Tablo', emoji: '🖼️', category: 'wall', cost: 200),
    
    // Floor
    const RoomDecoration(id: 'rug_basic', name: 'Temel Halı', emoji: '🟫', category: 'floor', cost: 50),
    const RoomDecoration(id: 'rug_colorful', name: 'Renkli Halı', emoji: '🌈', category: 'floor', cost: 150),
    
    // Accessories
    const RoomDecoration(id: 'trophy', name: 'Kupa', emoji: '🏆', category: 'accessory', cost: 100),
    const RoomDecoration(id: 'globe', name: 'Küre', emoji: '🌍', category: 'accessory', cost: 150),
    const RoomDecoration(id: 'telescope', name: 'Teleskop', emoji: '🔭', category: 'accessory', cost: 250),
    const RoomDecoration(id: 'robot_toy', name: 'Robot Oyuncak', emoji: '🤖', category: 'accessory', cost: 200),
  ];
}

/// Kullanıcı Odası
class UserRoom {
  String oderId;
  List<String> placedDecorations;
  String wallColor;
  String floorColor;

  UserRoom({
    required this.oderId,
    List<String>? placedDecorations,
    this.wallColor = 'blue',
    this.floorColor = 'wood',
  }) : placedDecorations = placedDecorations ?? [];

  Map<String, dynamic> toJson() => {
    'oderId': oderId,
    'placedDecorations': placedDecorations,
    'wallColor': wallColor,
    'floorColor': floorColor,
  };

  factory UserRoom.fromJson(Map<String, dynamic> json) {
    return UserRoom(
      oderId: json['oderId'] ?? '',
      placedDecorations: json['placedDecorations'] != null 
          ? List<String>.from(json['placedDecorations']) 
          : [],
      wallColor: json['wallColor'] ?? 'blue',
      floorColor: json['floorColor'] ?? 'wood',
    );
  }
}

