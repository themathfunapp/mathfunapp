// models/game_mechanics.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../screens/game_start_screen.dart';



// === KONU TÜRLERİ ===
enum TopicType {
  counting,        // Sayma
  addition,        // Toplama
  subtraction,     // Çıkarma
  multiplication,  // Çarpma
  division,        // Bölme
  geometry,        // Geometri
  fractions,       // Kesirler
  decimals,        // Ondalıklar
  time,            // Zaman
  measurements,    // Ölçümler
  patterns,        // Örüntüler
  algebra,         // Cebir
  statistics,      // İstatistik
}

// === GÜÇ-UP TÜRLERİ ===
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

// === GÜÇ-UP MODELİ ===
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

// === CAN SİSTEMİ ===
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

// === COMBO SİSTEMİ ===
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

// === İPUCU SİSTEMİ ===
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

// === KONU OYUN AYARLARI ===
class TopicGameSettings {
  final TopicType topicType;
  final String title;
  final String emoji;
  final Color color;
  final int ageGroupMin;
  final int ageGroupMax;
  final List<String> questionTypes;
  final Map<String, dynamic> customRules;

  TopicGameSettings({
    required this.topicType,
    required this.title,
    required this.emoji,
    required this.color,
    required this.ageGroupMin,
    required this.ageGroupMax,
    required this.questionTypes,
    this.customRules = const {},
  });
}

// === KONU OYUN YÖNETİCİSİ ===
class TopicGameManager {
  static Map<TopicType, TopicGameSettings> getTopicSettings() {
    return {
      TopicType.counting: TopicGameSettings(
        topicType: TopicType.counting,
        title: 'Sayma',
        emoji: '🔢',
        color: Colors.blue,
        ageGroupMin: 3,
        ageGroupMax: 6,
        questionTypes: ['count_objects', 'find_missing', 'whats_next'],
        customRules: {
          'visual_elements': true,
          'sound_effects': true,
          'max_number': 20,
        },
      ),

      TopicType.addition: TopicGameSettings(
        topicType: TopicType.addition,
        title: 'Toplama',
        emoji: '➕',
        color: Colors.green,
        ageGroupMin: 5,
        ageGroupMax: 11,
        questionTypes: ['basic_addition', 'word_problems', 'visual_addition'],
        customRules: {
          'carry_over': true,
          'max_sum': 100,
        },
      ),

      TopicType.subtraction: TopicGameSettings(
        topicType: TopicType.subtraction,
        title: 'Çıkarma',
        emoji: '➖',
        color: Colors.red,
        ageGroupMin: 5,
        ageGroupMax: 11,
        questionTypes: ['basic_subtraction', 'word_problems', 'visual_subtraction'],
        customRules: {
          'allow_negative': false,
          'max_difference': 50,
        },
      ),

      TopicType.multiplication: TopicGameSettings(
        topicType: TopicType.multiplication,
        title: 'Çarpma',
        emoji: '✖️',
        color: Colors.purple,
        ageGroupMin: 7,
        ageGroupMax: 11,
        questionTypes: ['basic_multiplication', 'array_visualization', 'word_problems'],
        customRules: {
          'max_factor': 12,
          'times_table': true,
        },
      ),

      TopicType.division: TopicGameSettings(
        topicType: TopicType.division,
        title: 'Bölme',
        emoji: '➗',
        color: Colors.orange,
        ageGroupMin: 8,
        ageGroupMax: 11,
        questionTypes: ['basic_division', 'equal_groups', 'word_problems'],
        customRules: {
          'max_dividend': 144,
          'remainder': false,
        },
      ),

      TopicType.geometry: TopicGameSettings(
        topicType: TopicType.geometry,
        title: 'Geometri',
        emoji: '🔺',
        color: Colors.orange,
        ageGroupMin: 4,
        ageGroupMax: 11,
        questionTypes: ['identify_shapes', 'count_sides', 'area_perimeter', 'symmetry'],
        customRules: {
          'shapes': ['daire', 'kare', 'üçgen', 'dikdörtgen', 'beşgen'],
          'interactive_drawing': true,
        },
      ),

      TopicType.fractions: TopicGameSettings(
        topicType: TopicType.fractions,
        title: 'Kesirler',
        emoji: '½',
        color: Colors.purple,
        ageGroupMin: 7,
        ageGroupMax: 11,
        questionTypes: ['identify_fraction', 'compare_fractions', 'add_fractions', 'simplify'],
        customRules: {
          'visual_fractions': true,
          'pizza_slices': true,
          'max_denominator': 12,
        },
      ),

      TopicType.decimals: TopicGameSettings(
        topicType: TopicType.decimals,
        title: 'Ondalıklar',
        emoji: '0️⃣',
        color: const Color(0xFF8E44AD),
        ageGroupMin: 8,
        ageGroupMax: 11,
        questionTypes: ['addition', 'subtraction', 'compare', 'round'],
        customRules: {
          'max_decimal_places': 1,
          'max_value': 10,
        },
      ),

      TopicType.time: TopicGameSettings(
        topicType: TopicType.time,
        title: 'Zaman',
        emoji: '🕰️',
        color: Colors.teal,
        ageGroupMin: 6,
        ageGroupMax: 11,
        questionTypes: ['read_clock', 'elapsed_time', 'time_conversion', 'schedule'],
        customRules: {
          'analog_clock': true,
          'digital_clock': true,
          'word_problems': true,
        },
      ),

      TopicType.measurements: TopicGameSettings(
        topicType: TopicType.measurements,
        title: 'Ölçümler',
        emoji: '📏',
        color: Colors.brown,
        ageGroupMin: 6,
        ageGroupMax: 11,
        questionTypes: ['length_comparison', 'weight_estimation', 'volume_conversion'],
        customRules: {
          'units': ['cm', 'm', 'kg', 'g', 'L', 'mL'],
          'visual_comparison': true,
        },
      ),

      TopicType.patterns: TopicGameSettings(
        topicType: TopicType.patterns,
        title: 'Örüntüler',
        emoji: '🔁',
        color: Colors.pink,
        ageGroupMin: 5,
        ageGroupMax: 11,
        questionTypes: ['complete_pattern', 'create_pattern', 'pattern_rule'],
        customRules: {
          'pattern_types': ['color', 'shape', 'number', 'size'],
          'max_pattern_length': 5,
        },
      ),

      TopicType.algebra: TopicGameSettings(
        topicType: TopicType.algebra,
        title: 'Cebir',
        emoji: '🔤',
        color: Colors.indigo,
        ageGroupMin: 9,
        ageGroupMax: 11,
        questionTypes: ['solve_equation', 'find_variable', 'word_problems'],
        customRules: {
          'max_variable': 20,
          'simple_equations': true,
        },
      ),

      TopicType.statistics: TopicGameSettings(
        topicType: TopicType.statistics,
        title: 'İstatistik',
        emoji: '📊',
        color: Colors.cyan,
        ageGroupMin: 8,
        ageGroupMax: 11,
        questionTypes: ['read_graph', 'calculate_mean', 'find_mode', 'probability'],
        customRules: {
          'graph_types': ['bar', 'pie', 'line'],
          'max_data_points': 10,
        },
      ),
    };
  }

  // Konuya özel soru üret
  static Map<String, dynamic> generateTopicQuestion(
      TopicType topic,
      AgeGroupSelection ageGroup,
      math.Random random,
      ) {
    final settings = getTopicSettings()[topic]!;

    switch (topic) {
      case TopicType.counting:
        return _generateCountingQuestion(ageGroup, random, settings);

      case TopicType.geometry:
        return _generateGeometryQuestion(ageGroup, random, settings);

      case TopicType.fractions:
        return _generateFractionQuestion(ageGroup, random, settings);

      case TopicType.time:
        return _generateTimeQuestion(ageGroup, random, settings);

      case TopicType.measurements:
        return _generateMeasurementQuestion(ageGroup, random, settings);

      case TopicType.patterns:
        return _generatePatternQuestion(ageGroup, random, settings);

      case TopicType.decimals:
        return _generateDecimalsQuestion(ageGroup, random, settings);

      case TopicType.algebra:
        return _generateAlgebraQuestion(ageGroup, random, settings);

      default:
        return _generateBasicMathQuestion(topic, ageGroup, random);
    }
  }

  static Map<String, dynamic> _generateCountingQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final questionTypes = ['count_objects', 'find_missing', 'whats_next', 'before_after'];
    final type = questionTypes[random.nextInt(questionTypes.length)];
    final maxNumber = settings.customRules['max_number'] as int;

    switch (type) {
      case 'count_objects':
        // "Kaç tane ... var?" sorusu
        final count = random.nextInt(maxNumber - 5) + 3; // 3-17 arası
        final emojis = ['🍎', '⭐', '🎈', '🌸', '🐝', '🎁', '🍕', '🚗', '⚽'];
        final emoji = emojis[random.nextInt(emojis.length)];
        
        return {
          'type': 'count_objects',
          'question': 'Kaç tane var?',
          'emoji': emoji,
          'count': count,
          'correctAnswer': count,
          'options': _generateOptions(count, random),
        };

      case 'find_missing':
        // "Hangi sayı eksik: 1, 2, __, 4" sorusu
        final start = random.nextInt(maxNumber - 5) + 1;
        final missing = start + 2;
        
        return {
          'type': 'find_missing',
          'question': 'Hangi sayı eksik?',
          'sequence': '$start, ${start + 1}, __, ${start + 3}',
          'correctAnswer': missing,
          'options': [missing, missing - 1, missing + 1, missing + 2]..shuffle(),
        };

      case 'whats_next':
        // "Sonraki sayı: 5, 6, 7, __" sorusu
        final start = random.nextInt(maxNumber - 4) + 1;
        final next = start + 3;
        
        return {
          'type': 'whats_next',
          'question': 'Sonraki sayı kaç?',
          'sequence': '$start, ${start + 1}, ${start + 2}, __',
          'correctAnswer': next,
          'options': [next, next - 1, next + 1, next + 2]..shuffle(),
        };

      case 'before_after':
        // "7'den önce/sonra hangi sayı gelir?" sorusu
        final number = random.nextInt(maxNumber - 2) + 2;
        final isBefore = random.nextBool();
        final correctAnswer = isBefore ? number - 1 : number + 1;
        
        return {
          'type': 'before_after',
          'question': isBefore 
              ? '$number\'den önce hangi sayı gelir?'
              : '$number\'den sonra hangi sayı gelir?',
          'correctAnswer': correctAnswer,
          'options': [correctAnswer, number, correctAnswer + 1, correctAnswer - 1]..shuffle(),
        };

      default:
        return _generateBasicMathQuestion(TopicType.addition, ageGroup, random);
    }
  }

  static Map<String, dynamic> _generateDecimalsQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final questionTypes = ['addition', 'subtraction', 'compare', 'round'];
    final type = questionTypes[random.nextInt(questionTypes.length)];

    switch (type) {
      case 'addition':
        // Ondalıklı toplama
        final num1 = (random.nextInt(90) + 10) / 10; // 1.0-10.0 arası
        final num2 = (random.nextInt(90) + 10) / 10;
        final answer = (num1 + num2).toStringAsFixed(1);
        
        return {
          'type': 'decimal_addition',
          'question': '$num1 + $num2 = ?',
          'correctAnswer': answer,
          'options': _generateDecimalOptions(double.parse(answer), random),
        };

      case 'subtraction':
        // Ondalıklı çıkarma
        final num1 = (random.nextInt(90) + 10) / 10; // 1.0-10.0 arası
        final num2 = (random.nextInt((num1 * 10).toInt() - 5) + 5) / 10;
        final answer = (num1 - num2).toStringAsFixed(1);
        
        return {
          'type': 'decimal_subtraction',
          'question': '$num1 - $num2 = ?',
          'correctAnswer': answer,
          'options': _generateDecimalOptions(double.parse(answer), random),
        };

      case 'compare':
        // Ondalıklı karşılaştırma
        final num1 = (random.nextInt(90) + 10) / 10;
        final num2 = (random.nextInt(90) + 10) / 10;
        final correctAnswer = num1 > num2 ? '>' : num1 < num2 ? '<' : '=';
        
        return {
          'type': 'decimal_compare',
          'question': '$num1 __ $num2',
          'correctAnswer': correctAnswer,
          'options': ['>', '<', '=', '≠'],
        };

      case 'round':
        // Yuvarlama
        final decimal = (random.nextInt(95) + 5) / 10; // 0.5-10.0 arası
        final rounded = decimal.round();
        
        return {
          'type': 'decimal_round',
          'question': '$decimal sayısını yuvarla:',
          'correctAnswer': rounded,
          'options': [rounded, rounded + 1, rounded - 1, rounded + 2]..shuffle(),
        };

      default:
        return _generateBasicMathQuestion(TopicType.addition, ageGroup, random);
    }
  }

  static Map<String, dynamic> _generateAlgebraQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final questionTypes = ['solve_for_x', 'simple_equation', 'missing_number'];
    final type = questionTypes[random.nextInt(questionTypes.length)];

    switch (type) {
      case 'solve_for_x':
        // x + a = b tarzı denklemler
        final a = random.nextInt(10) + 1;
        final b = random.nextInt(10) + a + 1;
        final x = b - a;
        
        return {
          'type': 'solve_for_x',
          'question': 'x + $a = $b\nx = ?',
          'correctAnswer': x,
          'options': _generateOptions(x, random),
        };

      case 'simple_equation':
        // a × x = b tarzı denklemler
        final x = random.nextInt(5) + 2;
        final a = random.nextInt(5) + 2;
        final b = a * x;
        
        return {
          'type': 'simple_equation',
          'question': '$a × x = $b\nx = ?',
          'correctAnswer': x,
          'options': _generateOptions(x, random),
        };

      case 'missing_number':
        // __ + 5 = 12 tarzı sorular
        final answer = random.nextInt(10) + 1;
        final addend = random.nextInt(10) + 1;
        final sum = answer + addend;
        
        return {
          'type': 'missing_number',
          'question': '__ + $addend = $sum\nEksik sayı?',
          'correctAnswer': answer,
          'options': _generateOptions(answer, random),
        };

      default:
        return _generateBasicMathQuestion(TopicType.addition, ageGroup, random);
    }
  }

  static Map<String, dynamic> _generateGeometryQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final questionTypes = ['identify_shapes', 'count_sides', 'find_area'];
    final type = questionTypes[random.nextInt(questionTypes.length)];

    switch (type) {
      case 'identify_shapes':
        final shapes = settings.customRules['shapes'] as List<String>;
        final shape = shapes[random.nextInt(shapes.length)];
        final options = List.from(shapes)..shuffle();

        return {
          'type': 'identify_shapes',
          'question': 'Hangi şekil bir $shape?',
          'correctAnswer': shape,
          'shapeToShow': shape, // Gösterilecek şekil
          'options': options.take(4).toList(),
          'explanation': 'Bir $shape, ${_getShapeDescription(shape)}.',
        };

      case 'count_sides':
        final shapeData = [
          {'name': 'üçgen', 'sides': 3},
          {'name': 'kare', 'sides': 4},
          {'name': 'beşgen', 'sides': 5},
        ];
        final selected = shapeData[random.nextInt(shapeData.length)];
        final shapeName = selected['name'] as String;
        final sides = selected['sides'] as int;

        return {
          'type': 'count_sides',
          'question': 'Bir $shapeName kaç kenara sahiptir?',
          'correctAnswer': sides,
          'shapeToShow': shapeName, // Gösterilecek şekil
          'options': [sides, sides + 1, sides - 1, sides + 2]..shuffle(),
        };

      case 'find_area':
        final side = random.nextInt(5) + 2;
        final area = side * side;

        return {
          'type': 'find_area',
          'question': 'Bir kenarı $side cm olan karenin alanı kaç cm²?',
          'correctAnswer': area,
          'shapeToShow': 'kare', // Gösterilecek şekil
          'options': _generateOptions(area, random),
          'explanation': 'Karenin alanı = kenar × kenar = $side × $side = $area',
        };

      default:
        return _generateBasicMathQuestion(TopicType.addition, ageGroup, random);
    }
  }

  static Map<String, dynamic> _generateFractionQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final questionTypes = ['identify_fraction', 'compare_fractions', 'add_fractions'];
    final type = questionTypes[random.nextInt(questionTypes.length)];

    switch (type) {
      case 'identify_fraction':
        final numerator = random.nextInt(3) + 1;
        final denominator = random.nextInt(4) + 2;

        return {
          'type': 'identify_fraction',
          'question': 'Görseldeki kesri seçin:',
          'correctAnswer': '$numerator/$denominator',
          'options': [
            '$numerator/$denominator',
            '${numerator + 1}/$denominator',
            '$numerator/${denominator + 1}',
            '${numerator - 1}/${denominator - 1}',
          ],
          'image': 'fraction_${numerator}_$denominator',
        };

      case 'compare_fractions':
        final frac1 = '${random.nextInt(2) + 1}/${random.nextInt(3) + 2}';
        final frac2 = '${random.nextInt(2) + 1}/${random.nextInt(3) + 2}';
        final value1 = _fractionToDecimal(frac1);
        final value2 = _fractionToDecimal(frac2);
        final correct = value1 > value2 ? '>' : value1 < value2 ? '<' : '=';

        return {
          'type': 'compare_fractions',
          'question': '$frac1 ? $frac2',
          'correctAnswer': correct,
          'options': ['>', '<', '=', '?'],
        };

      case 'add_fractions':
        final denom = random.nextInt(4) + 2;
        final num1 = random.nextInt(denom - 1) + 1;
        final num2 = random.nextInt(denom - 1) + 1;
        final sumNum = num1 + num2;

        return {
          'type': 'add_fractions',
          'question': '$num1/$denom + $num2/$denom = ?',
          'correctAnswer': sumNum <= denom ? '$sumNum/$denom' : '1 ${sumNum - denom}/$denom',
          'options': _generateFractionOptions(num1, num2, denom, random),
        };

      default:
        return _generateBasicMathQuestion(TopicType.addition, ageGroup, random);
    }
  }

  static Map<String, dynamic> _generateTimeQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final hour = random.nextInt(12) + 1;
    final minute = [0, 15, 30, 45][random.nextInt(4)];

    return {
      'type': 'read_clock',
      'question': 'Saat kaçı gösteriyor?',
      'correctAnswer': '$hour:${minute.toString().padLeft(2, '0')}',
      'options': [
        '$hour:${minute.toString().padLeft(2, '0')}',
        '${(hour % 12) + 1}:${minute.toString().padLeft(2, '0')}',
        '$hour:${((minute + 15) % 60).toString().padLeft(2, '0')}',
        '${hour}:${((minute + 30) % 60).toString().padLeft(2, '0')}',
      ],
      'image': 'clock_${hour}_$minute',
    };
  }

  static Map<String, dynamic> _generateMeasurementQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final units = ['cm', 'm', 'kg', 'g', 'L', 'mL'];
    final unit = units[random.nextInt(units.length)];
    final value = random.nextInt(10) + 1;
    final convertedValue = _convertMeasurement(value, unit);

    return {
      'type': 'measurement_conversion',
      'question': '$value $unit = ?',
      'correctAnswer': convertedValue,
      'options': _generateOptions(convertedValue, random),
      'explanation': '1 $unit = ${convertedValue ~/ value} ${_getConvertedUnit(unit)}',
    };
  }

  static Map<String, dynamic> _generatePatternQuestion(
      AgeGroupSelection ageGroup,
      math.Random random,
      TopicGameSettings settings,
      ) {
    final pattern = [1, 2, 3, 4, 5];
    final missingIndex = random.nextInt(5);
    final missingValue = pattern[missingIndex];

    final displayPattern = List.from(pattern);
    displayPattern[missingIndex] = '?';

    return {
      'type': 'complete_pattern',
      'question': 'Örüntü: ${displayPattern.join(", ")}\nEksik sayı nedir?',
      'correctAnswer': missingValue,
      'options': [missingValue, missingValue + 1, missingValue - 1, missingValue + 2],
      'explanation': 'Örüntü her adımda 1 artıyor: ${pattern.join(" → ")}',
    };
  }

  static Map<String, dynamic> _generateBasicMathQuestion(
      TopicType topic,
      AgeGroupSelection ageGroup,
      math.Random random,
      ) {
    int num1, num2, answer;
    String operator;

    switch (topic) {
      case TopicType.addition:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        answer = num1 + num2;
        operator = '+';
        break;

      case TopicType.subtraction:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(num1) + 1;
        answer = num1 - num2;
        operator = '-';
        break;

      case TopicType.multiplication:
        num1 = random.nextInt(5) + 1;
        num2 = random.nextInt(5) + 1;
        answer = num1 * num2;
        operator = '×';
        break;

      case TopicType.division:
        num2 = random.nextInt(5) + 1;
        answer = random.nextInt(5) + 1;
        num1 = num2 * answer;
        operator = '÷';
        break;

      default:
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        answer = num1 + num2;
        operator = '+';
    }

    return {
      'type': 'basic_math',
      'question': '$num1 $operator $num2 = ?',
      'correctAnswer': answer,
      'options': _generateOptions(answer, random),
      'num1': num1,
      'num2': num2,
      'operator': operator,
    };
  }

  // Yardımcı fonksiyonlar
  static String _getShapeDescription(String shape) {
    switch (shape) {
      case 'daire': return 'etrafında hiç köşe olmayan yuvarlak bir şekildir';
      case 'kare': return 'dört eşit kenarı ve dört dik açısı olan bir şekildir';
      case 'üçgen': return 'üç kenarı ve üç köşesi olan bir şekildir';
      case 'dikdörtgen': return 'karşılıklı kenarları eşit ve dik açılı bir şekildir';
      case 'beşgen': return 'beş kenarı ve beş köşesi olan bir şekildir';
      default: return 'geometrik bir şekildir';
    }
  }

  static double _fractionToDecimal(String fraction) {
    final parts = fraction.split('/');
    return int.parse(parts[0]) / int.parse(parts[1]);
  }

  static List<int> _generateOptions(int correctAnswer, math.Random random) {
    final options = <int>[correctAnswer];

    while (options.length < 4) {
      int wrongAnswer;
      if (random.nextBool()) {
        wrongAnswer = correctAnswer + random.nextInt(5) + 1;
      } else {
        wrongAnswer = correctAnswer - random.nextInt(5) - 1;
      }
      if (wrongAnswer > 0 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }

    return options..shuffle();
  }

  static List<String> _generateFractionOptions(int num1, int num2, int denom, math.Random random) {
    final sum = num1 + num2;
    final options = <String>[];

    options.add(sum <= denom ? '$sum/$denom' : '1 ${sum - denom}/$denom');

    while (options.length < 4) {
      final wrongNum = sum + random.nextInt(3) - 1;
      final wrongDenom = denom + random.nextInt(3) - 1;
      if (wrongNum > 0 && wrongDenom > 0) {
        final option = wrongNum <= wrongDenom
            ? '$wrongNum/$wrongDenom'
            : '1 ${wrongNum - wrongDenom}/$wrongDenom';
        if (!options.contains(option)) {
          options.add(option);
        }
      }
    }

    return options..shuffle();
  }

  static List<String> _generateDecimalOptions(double correctAnswer, math.Random random) {
    final options = <String>[correctAnswer.toStringAsFixed(1)];

    while (options.length < 4) {
      double wrongAnswer;
      if (random.nextBool()) {
        wrongAnswer = correctAnswer + (random.nextInt(10) + 1) / 10;
      } else {
        wrongAnswer = correctAnswer - (random.nextInt(10) + 1) / 10;
      }
      
      if (wrongAnswer > 0) {
        final wrongStr = wrongAnswer.toStringAsFixed(1);
        if (!options.contains(wrongStr)) {
          options.add(wrongStr);
        }
      }
    }

    return options..shuffle();
  }

  static int _convertMeasurement(int value, String unit) {
    switch (unit) {
      case 'cm': return value * 10; // cm -> mm
      case 'm': return value * 100; // m -> cm
      case 'kg': return value * 1000; // kg -> g
      case 'g': return value ~/ 1000; // g -> kg
      case 'L': return value * 1000; // L -> mL
      case 'mL': return value ~/ 1000; // mL -> L
      default: return value;
    }
  }

  static String _getConvertedUnit(String unit) {
    switch (unit) {
      case 'cm': return 'mm';
      case 'm': return 'cm';
      case 'kg': return 'g';
      case 'g': return 'kg';
      case 'L': return 'mL';
      case 'mL': return 'L';
      default: return unit;
    }
  }
}

// === GÜNLÜK CHALLENGE ===
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

// === ŞANS ÇARKI ÖDÜLLERİ ===
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

// === SÜRPRİZ KUTUSU ===
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

// === BOSS SAVAŞI ===
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

// === OYUNCU ENVANTERİ ===
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

// === MATEMATİK SORUSU MODELİ ===
class MathQuestion {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;
  final String? questionText; // Konuya özel soru metni
  final String? questionImage; // Konuya özel görsel

  MathQuestion({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
    this.questionText,
    this.questionImage,
  });
}

// === SORU ZORLUK SEVİYELERİ ===
class DifficultyLevel {
  final String id;
  final String name;
  final String emoji;
  final int baseTime;
  final int questionCount;
  final double scoreMultiplier;
  final int coinReward;
  final int xpReward;

  const DifficultyLevel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.baseTime,
    required this.questionCount,
    required this.scoreMultiplier,
    required this.coinReward,
    required this.xpReward,
  });

  static List<DifficultyLevel> get allLevels => [
    const DifficultyLevel(
      id: 'easy',
      name: 'Kolay',
      emoji: '😊',
      baseTime: 30,
      questionCount: 5,
      scoreMultiplier: 1.0,
      coinReward: 50,
      xpReward: 25,
    ),
    const DifficultyLevel(
      id: 'medium',
      name: 'Orta',
      emoji: '😐',
      baseTime: 25,
      questionCount: 10,
      scoreMultiplier: 1.5,
      coinReward: 100,
      xpReward: 50,
    ),
    const DifficultyLevel(
      id: 'hard',
      name: 'Zor',
      emoji: '😰',
      baseTime: 20,
      questionCount: 15,
      scoreMultiplier: 2.0,
      coinReward: 150,
      xpReward: 75,
    ),
    const DifficultyLevel(
      id: 'expert',
      name: 'Uzman',
      emoji: '🤯',
      baseTime: 15,
      questionCount: 20,
      scoreMultiplier: 3.0,
      coinReward: 200,
      xpReward: 100,
    ),
  ];
}

// === OYUN MODU TÜRLERİ ===
enum GameMode {
  quickPlay,      // Hızlı oyun
  topicPractice,  // Konu pratiği
  dailyChallenge, // Günlük challenge
  bossBattle,     // Boss savaşı
  endlessMode,    // Sonsuz mod
  friendDuel,     // Arkadaş düellosu
  tournament,     // Turnuva
}