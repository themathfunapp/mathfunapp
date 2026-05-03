import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../models/age_group_selection.dart';

/// Keloğlan'ın Köyü - Dinamik Soru Üretim Sistemi
/// 18 farklı soru tipi, binlerce kombinasyon
class KeloglanVillageScreen extends StatefulWidget {
  final AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const KeloglanVillageScreen({super.key, required this.ageGroup, required this.onBack});

  @override
  State<KeloglanVillageScreen> createState() => _KeloglanVillageScreenState();
}

/// Soru Tipleri Enum - 18 farklı matematik becerisi
enum QuestionType {
  equalSharing,      // Tip 1: Eşit Paylaştırma
  groupDivision,     // Tip 2: Gruplara Ayırma
  remainderDivision, // Tip 3: Kalanlı Bölme
  multiples,         // Tip 4: Kat Kavramı
  fractions,         // Tip 5: Yarım - Çeyrek
  twoStepMix,        // Tip 6: Karıştırma
  comparison,        // Tip 7: Karşılaştırma
  addThenDivide,     // Tip 8: Toplama + Bölme
  multiplyThenDivide, // Tip 9: Çarpma + Bölme
  missingShare,      // Tip 10: Eksik - Fazla Bulmaca
  measurement,       // Tip 11: Ölçme
  time,              // Tip 12: Zaman
  money,             // Tip 13: Para Hesabı
  ratio,             // Tip 14: Kat Sayısı
  pattern,           // Tip 15: Sıralama / Örüntü
  shapeDivision,     // Tip 16: Şekillerle Bölme
  twoStageSharing,   // Tip 17: İki Aşamalı Paylaştırma
  reverseOperation,  // Tip 18: Ters İşlem
}

/// Soru Modeli
class Question {
  final QuestionType type;
  final String questionText;
  final String keloglanMessage;
  final int correctAnswer;
  final List<int> options;
  final String itemEmoji;
  final String itemName;
  final String location;
  final List<String> characters;
  final String explanation;
  final Map<String, dynamic> metadata; // Ek veriler için

  Question({
    required this.type,
    required this.questionText,
    required this.keloglanMessage,
    required this.correctAnswer,
    required this.options,
    required this.itemEmoji,
    required this.itemName,
    required this.location,
    required this.characters,
    required this.explanation,
    this.metadata = const {},
  });
}

class _KeloglanVillageScreenState extends State<KeloglanVillageScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _lives = 5;
  Question? _currentQuestion;
  String? _lastLocale;

  // Renk paleti
  static const Color _villageGreen = Color(0xFF8BC34A);
  static const Color _earthBrown = Color(0xFF795548);
  static const Color _skyBlue = Color(0xFF87CEEB);
  static const Color _cream = Color(0xFFFFF8F0);

  // Karakterler Havuzu
  final List<String> _characters = [
    'Ayşe', 'Ali', 'Fatma', 'Mehmet', 'Zeynep', 'Hasan', 'Hatice', 'Mustafa',
    'Elif', 'Can', 'Merve', 'Emre', 'Duru', 'Efe', 'Asya', 'Kerem', 
    'İrem', 'Burak', 'Cemre', 'Oğuz'
  ];

  // Mekanlar Havuzu (lokalizasyon anahtarları)
  static const List<String> _locationKeys = [
    'keloglan_location_village_square', 'keloglan_location_school_garden',
    'keloglan_location_field', 'keloglan_location_vineyard', 'keloglan_location_garden',
    'keloglan_location_marketplace', 'keloglan_location_house', 'keloglan_location_barn',
    'keloglan_location_coop_place', 'keloglan_location_forest_edge',
    'keloglan_location_stream_edge', 'keloglan_location_aunt_house',
    'keloglan_location_uncle_farm',
  ];

  // Yiyecek ve Nesneler Havuzu (nameKey ile lokalizasyon)
  final List<Map<String, dynamic>> _items = [
    {'emoji': '🍎', 'nameKey': 'keloglan_food_apple', 'type': 'food'},
    {'emoji': '🍐', 'nameKey': 'keloglan_food_pear', 'type': 'food'},
    {'emoji': '🍪', 'nameKey': 'keloglan_food_cookie', 'type': 'food'},
    {'emoji': '🥚', 'nameKey': 'keloglan_food_egg', 'type': 'food'},
    {'emoji': '🥧', 'nameKey': 'keloglan_food_pastry', 'type': 'food'},
    {'emoji': '🥜', 'nameKey': 'keloglan_food_walnut', 'type': 'food'},
    {'emoji': '🍇', 'nameKey': 'keloglan_food_grape', 'type': 'food'},
    {'emoji': '🍉', 'nameKey': 'keloglan_food_watermelon', 'type': 'food'},
    {'emoji': '🍞', 'nameKey': 'keloglan_food_bread', 'type': 'food'},
    {'emoji': '🧀', 'nameKey': 'keloglan_food_cheese', 'type': 'food'},
    {'emoji': '🍯', 'nameKey': 'keloglan_food_honey', 'type': 'food'},
    {'emoji': '🍬', 'nameKey': 'keloglan_food_candy', 'type': 'food'},
    {'emoji': '🥩', 'nameKey': 'keloglan_food_meatball', 'type': 'food'},
    {'emoji': '⚽', 'nameKey': 'keloglan_object_ball', 'type': 'object'},
    {'emoji': '✏️', 'nameKey': 'keloglan_object_pencil', 'type': 'object'},
    {'emoji': '📒', 'nameKey': 'keloglan_object_notebook', 'type': 'object'},
    {'emoji': '🧺', 'nameKey': 'keloglan_object_basket', 'type': 'object'},
    {'emoji': '🌻', 'nameKey': 'keloglan_object_flower', 'type': 'object'},
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    if (_lastLocale != locale.languageCode) {
      _lastLocale = locale.languageCode;
      if (mounted) {
        _generateQuestion(AppLocalizations(locale));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // --- Matematik Bölgeleri yaş kapısına göre sayı aralıkları ---

  int _peopleForSharing(math.Random r) {
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        return 2 + r.nextInt(2);
      case AgeGroupSelection.elementary:
        return 2 + r.nextInt(4);
      case AgeGroupSelection.advanced:
        return 3 + r.nextInt(4);
    }
  }

  int _perPersonItems(math.Random r) {
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        return 2 + r.nextInt(3);
      case AgeGroupSelection.elementary:
        return 2 + r.nextInt(5);
      case AgeGroupSelection.advanced:
        return 3 + r.nextInt(6);
    }
  }

  int _groupSize(math.Random r) {
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        return 2 + r.nextInt(2);
      case AgeGroupSelection.elementary:
        return 2 + r.nextInt(4);
      case AgeGroupSelection.advanced:
        return 3 + r.nextInt(4);
    }
  }

  int _groupCountGroups(math.Random r) {
    switch (widget.ageGroup) {
      case AgeGroupSelection.preschool:
        return 2 + r.nextInt(2);
      case AgeGroupSelection.elementary:
        return 2 + r.nextInt(4);
      case AgeGroupSelection.advanced:
        return 3 + r.nextInt(4);
    }
  }

  // ============================================================================
  // SORU ÜRETİM MOTORU - 18 FARKLI TİP
  // ============================================================================

  void _generateQuestion(AppLocalizations loc) {
    final random = math.Random();
    final type = QuestionType.values[random.nextInt(QuestionType.values.length)];
    
    Question question;
    switch (type) {
      case QuestionType.equalSharing:
        question = _generateEqualSharingQuestion(random, loc);
        break;
      case QuestionType.groupDivision:
        question = _generateGroupDivisionQuestion(random, loc);
        break;
      case QuestionType.remainderDivision:
        question = _generateRemainderQuestion(random, loc);
        break;
      case QuestionType.multiples:
        question = _generateMultiplesQuestion(random, loc);
        break;
      case QuestionType.fractions:
        question = _generateFractionsQuestion(random, loc);
        break;
      case QuestionType.twoStepMix:
        question = _generateTwoStepMixQuestion(random, loc);
        break;
      case QuestionType.comparison:
        question = _generateComparisonQuestion(random, loc);
        break;
      case QuestionType.addThenDivide:
        question = _generateAddThenDivideQuestion(random, loc);
        break;
      case QuestionType.multiplyThenDivide:
        question = _generateMultiplyThenDivideQuestion(random, loc);
        break;
      case QuestionType.missingShare:
        question = _generateMissingShareQuestion(random, loc);
        break;
      case QuestionType.measurement:
        question = _generateMeasurementQuestion(random, loc);
        break;
      case QuestionType.time:
        question = _generateTimeQuestion(random, loc);
        break;
      case QuestionType.money:
        question = _generateMoneyQuestion(random, loc);
        break;
      case QuestionType.ratio:
        question = _generateRatioQuestion(random, loc);
        break;
      case QuestionType.pattern:
        question = _generatePatternQuestion(random, loc);
        break;
      case QuestionType.shapeDivision:
        question = _generateShapeDivisionQuestion(random, loc);
        break;
      case QuestionType.twoStageSharing:
        question = _generateTwoStageSharingQuestion(random, loc);
        break;
      case QuestionType.reverseOperation:
        question = _generateReverseOperationQuestion(random, loc);
        break;
    }

    setState(() {
      _currentQuestion = question;
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  String _itemName(AppLocalizations loc, Map<String, dynamic> item) =>
      loc.get(item['nameKey'] as String);

  // TİP 1: Eşit Paylaştırma
  Question _generateEqualSharingQuestion(math.Random random, AppLocalizations loc) {
    final peopleCount = _peopleForSharing(random);
    final itemPerPerson = _perPersonItems(random);
    final total = peopleCount * itemPerPerson;
    final item = _items[random.nextInt(_items.length)];
    final locationKey = _locationKeys[random.nextInt(_locationKeys.length)];
    final location = loc.get(locationKey);
    final itemName = _itemName(loc, item);
    final friends = _getRandomCharacters(random, peopleCount - 1);

    return Question(
      type: QuestionType.equalSharing,
      questionText: loc.get('keloglan_q_equal_sharing')
          .replaceAll('{0}', '$total').replaceAll('{1}', itemName).replaceAll('{2}', '$peopleCount'),
      keloglanMessage: loc.get('keloglan_s_equal_sharing')
          .replaceAll('{0}', location).replaceAll('{1}', '$total').replaceAll('{2}', itemName).replaceAll('{3}', friends.join(', ')),
      correctAnswer: itemPerPerson,
      options: _generateOptions(itemPerPerson, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: location,
      characters: friends,
      explanation: '$total ÷ $peopleCount = $itemPerPerson',
      metadata: {'total': total, 'people': peopleCount},
    );
  }

  // TİP 2: Gruplara Ayırma
  Question _generateGroupDivisionQuestion(math.Random random, AppLocalizations loc) {
    final groupSize = _groupSize(random);
    final groupCount = _groupCountGroups(random);
    final total = groupSize * groupCount;
    final item = _items[random.nextInt(_items.length)];
    final locationKey = _locationKeys[random.nextInt(_locationKeys.length)];
    final location = loc.get(locationKey);
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.groupDivision,
      questionText: loc.get('keloglan_q_group_division')
          .replaceAll('{0}', '$total').replaceAll('{1}', itemName).replaceAll('{2}', '$groupSize'),
      keloglanMessage: loc.get('keloglan_s_group_division')
          .replaceAll('{0}', location).replaceAll('{1}', '$total').replaceAll('{2}', itemName).replaceAll('{3}', '$groupSize'),
      correctAnswer: groupCount,
      options: _generateOptions(groupCount, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: location,
      characters: [],
      explanation: '$total ÷ $groupSize = $groupCount',
      metadata: {'total': total, 'groupSize': groupSize},
    );
  }

  // TİP 3: Kalanlı Bölme
  Question _generateRemainderQuestion(math.Random random, AppLocalizations loc) {
    final divisor = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 3 + random.nextInt(3),
      AgeGroupSelection.advanced => 3 + random.nextInt(4),
    };
    final quotient = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(4),
      AgeGroupSelection.advanced => 2 + random.nextInt(5),
    };
    final remainder = divisor > 1 ? 1 + random.nextInt(divisor - 1) : 1;
    final total = divisor * quotient + remainder;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);
    final friends = _getRandomCharacters(random, divisor - 1);

    return Question(
      type: QuestionType.remainderDivision,
      questionText: loc.get('keloglan_q_remainder')
          .replaceAll('{0}', '$total').replaceAll('{1}', itemName).replaceAll('{2}', '$divisor'),
      keloglanMessage: loc.get('keloglan_s_remainder')
          .replaceAll('{0}', '$total').replaceAll('{1}', itemName).replaceAll('{2}', friends.join(', ')),
      correctAnswer: remainder,
      options: _generateOptions(remainder, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: friends,
      explanation: '$total = $divisor × $quotient + $remainder, artan: $remainder',
      metadata: {'total': total, 'divisor': divisor, 'remainder': remainder},
    );
  }

  // TİP 4: Kat Kavramı
  Question _generateMultiplesQuestion(math.Random random, AppLocalizations loc) {
    final dailyAmount = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(4),
      AgeGroupSelection.advanced => 2 + random.nextInt(5),
    };
    final days = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 2 + random.nextInt(5),
      AgeGroupSelection.advanced => 3 + random.nextInt(5),
    };
    final total = dailyAmount * days;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.multiples,
      questionText: loc.get('keloglan_q_multiples')
          .replaceAll('{0}', '$dailyAmount').replaceAll('{1}', itemName).replaceAll('{2}', '$days'),
      keloglanMessage: loc.get('keloglan_s_multiples')
          .replaceAll('{0}', '$dailyAmount').replaceAll('{1}', itemName).replaceAll('{2}', '$days'),
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: [],
      explanation: '$dailyAmount × $days = $total',
      metadata: {'daily': dailyAmount, 'days': days},
    );
  }

  // TİP 5: Kesirler (Yarım - Çeyrek)
  Question _generateFractionsQuestion(math.Random random, AppLocalizations loc) {
    final wholeCount = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(1),
      AgeGroupSelection.elementary => 2 + random.nextInt(3),
      AgeGroupSelection.advanced => 2 + random.nextInt(4),
    };
    final isQuarter = random.nextBool();
    final fractionName = isQuarter ? loc.get('keloglan_fraction_quarter') : loc.get('keloglan_fraction_half');
    final multiplier = isQuarter ? 4 : 2;
    final total = wholeCount * multiplier;
    final item = _items.where((i) => i['type'] == 'food').toList()[random.nextInt(6)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.fractions,
      questionText: loc.get('keloglan_q_fractions')
          .replaceAll('{0}', '$wholeCount').replaceAll('{1}', itemName).replaceAll('{2}', fractionName),
      keloglanMessage: loc.get('keloglan_s_fractions')
          .replaceAll('{0}', '$wholeCount').replaceAll('{1}', itemName).replaceAll('{2}', fractionName),
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: [],
      explanation: '$wholeCount × $multiplier = $total $fractionName',
      metadata: {'whole': wholeCount, 'fraction': fractionName},
    );
  }

  // TİP 6: Karıştırma (İki İşlemli)
  Question _generateTwoStepMixQuestion(math.Random random, AppLocalizations loc) {
    final chicken = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 3 + random.nextInt(4),
      AgeGroupSelection.advanced => 4 + random.nextInt(5),
    };
    final eggsPerDay = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2,
      AgeGroupSelection.elementary => 2 + random.nextInt(3),
      AgeGroupSelection.advanced => 2 + random.nextInt(4),
    };
    final days = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 3 + random.nextInt(3),
      AgeGroupSelection.advanced => 3 + random.nextInt(4),
    };
    final total = chicken * eggsPerDay * days;
    final eggName = loc.get('keloglan_food_egg');

    return Question(
      type: QuestionType.twoStepMix,
      questionText: loc.get('keloglan_q_two_step_mix')
          .replaceAll('{0}', '$chicken').replaceAll('{1}', '$eggsPerDay').replaceAll('{2}', '$days'),
      keloglanMessage: loc.get('keloglan_s_two_step_mix')
          .replaceAll('{0}', '$chicken').replaceAll('{1}', '$eggsPerDay').replaceAll('{2}', '$days'),
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: '🥚',
      itemName: eggName,
      location: loc.get('keloglan_location_coop'),
      characters: [],
      explanation: '$chicken × $eggsPerDay × $days = $total',
      metadata: {'chicken': chicken, 'eggsPerDay': eggsPerDay, 'days': days},
    );
  }

  // TİP 7: Karşılaştırma
  Question _generateComparisonQuestion(math.Random random, AppLocalizations loc) {
    final char1 = _characters[random.nextInt(_characters.length)];
    String char2;
    do {
      char2 = _characters[random.nextInt(_characters.length)];
    } while (char1 == char2);

    final count1 = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 3 + random.nextInt(5),
      AgeGroupSelection.elementary => 5 + random.nextInt(10),
      AgeGroupSelection.advanced => 8 + random.nextInt(14),
    };
    final count2 = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 3 + random.nextInt(5),
      AgeGroupSelection.elementary => 5 + random.nextInt(10),
      AgeGroupSelection.advanced => 8 + random.nextInt(14),
    };
    final diff = (count1 - count2).abs();
    final hasMore = count1 > count2 ? char1 : char2;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.comparison,
      questionText: loc.get('keloglan_q_comparison')
          .replaceAll('{0}', char1).replaceAll('{1}', '$count1').replaceAll('{2}', char2).replaceAll('{3}', '$count2').replaceAll('{4}', itemName),
      keloglanMessage: loc.get('keloglan_s_comparison')
          .replaceAll('{0}', char1).replaceAll('{1}', '$count1').replaceAll('{2}', char2).replaceAll('{3}', '$count2').replaceAll('{4}', itemName),
      correctAnswer: diff,
      options: _generateOptions(diff, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: [char1, char2],
      explanation: '$hasMore daha fazla. Fark: $diff',
      metadata: {'count1': count1, 'count2': count2, 'hasMore': hasMore},
    );
  }

  // TİP 8: Toplama + Bölme
  Question _generateAddThenDivideQuestion(math.Random random, AppLocalizations loc) {
    final char1 = loc.get('keloglan_character_name');
    final char2 = _characters[random.nextInt(_characters.length)];
    final char3 = _characters[random.nextInt(_characters.length)];
    
    final count1 = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 3 + random.nextInt(5),
      AgeGroupSelection.advanced => 4 + random.nextInt(6),
    };
    final count2 = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 4 + random.nextInt(5),
      AgeGroupSelection.advanced => 4 + random.nextInt(7),
    };
    final count3 = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 5 + random.nextInt(5),
      AgeGroupSelection.advanced => 5 + random.nextInt(7),
    };
    final total = count1 + count2 + count3;
    final divisor = 3; // Her zaman 3 kişi
    final share = total ~/ divisor;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.addThenDivide,
      questionText: loc.get('keloglan_q_add_then_divide')
          .replaceAll('{0}', '$count1').replaceAll('{1}', char2).replaceAll('{2}', '$count2')
          .replaceAll('{3}', char3).replaceAll('{4}', '$count3').replaceAll('{5}', itemName).replaceAll('{6}', '$divisor'),
      keloglanMessage: loc.get('keloglan_s_add_then_divide')
          .replaceAll('{0}', '$count1').replaceAll('{1}', char2).replaceAll('{2}', '$count2')
          .replaceAll('{3}', char3).replaceAll('{4}', '$count3'),
      correctAnswer: share,
      options: _generateOptions(share, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: [char2, char3],
      explanation: '$count1 + $count2 + $count3 = $total, $total ÷ $divisor = $share',
      metadata: {'total': total, 'share': share},
    );
  }

  // TİP 9: Çarpma + Bölme
  Question _generateMultiplyThenDivideQuestion(math.Random random, AppLocalizations loc) {
    final baskets = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(3),
      AgeGroupSelection.advanced => 2 + random.nextInt(4),
    };
    final itemsPerBasket = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 3 + random.nextInt(4),
      AgeGroupSelection.advanced => 3 + random.nextInt(5),
    };
    final total = baskets * itemsPerBasket;
    final friends = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2,
      AgeGroupSelection.elementary => 2 + random.nextInt(3),
      AgeGroupSelection.advanced => 2 + random.nextInt(4),
    };
    final share = total ~/ friends;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.multiplyThenDivide,
      questionText: loc.get('keloglan_q_multiply_then_divide')
          .replaceAll('{0}', '$baskets').replaceAll('{1}', '$itemsPerBasket').replaceAll('{2}', itemName).replaceAll('{3}', '$friends'),
      keloglanMessage: loc.get('keloglan_s_multiply_then_divide')
          .replaceAll('{0}', '$baskets').replaceAll('{1}', '$itemsPerBasket').replaceAll('{2}', itemName),
      correctAnswer: share,
      options: _generateOptions(share, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: _getRandomCharacters(random, friends - 1),
      explanation: '$baskets × $itemsPerBasket = $total, $total ÷ $friends = $share',
      metadata: {'baskets': baskets, 'itemsPerBasket': itemsPerBasket, 'share': share},
    );
  }

  // TİP 10: Eksik - Fazla Bulmaca
  Question _generateMissingShareQuestion(math.Random random, AppLocalizations loc) {
    final initial = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 8 + random.nextInt(6),
      AgeGroupSelection.elementary => 15 + random.nextInt(10),
      AgeGroupSelection.advanced => 20 + random.nextInt(16),
    };
    final eaten = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(4),
      AgeGroupSelection.elementary => 3 + random.nextInt(8),
      AgeGroupSelection.advanced => 4 + random.nextInt(9),
    };
    final friends = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2,
      AgeGroupSelection.elementary => 2 + random.nextInt(3),
      AgeGroupSelection.advanced => 2 + random.nextInt(4),
    };
    final int remaining = math.max(friends, initial - eaten);
    final share = remaining ~/ friends;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.missingShare,
      questionText: loc.get('keloglan_q_missing_share')
          .replaceAll('{0}', '$initial').replaceAll('{1}', itemName).replaceAll('{2}', '$eaten').replaceAll('{3}', '$friends'),
      keloglanMessage: loc.get('keloglan_s_missing_share')
          .replaceAll('{0}', '$initial').replaceAll('{1}', itemName).replaceAll('{2}', '$eaten'),
      correctAnswer: share,
      options: _generateOptions(share, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: loc.get('keloglan_location_village'),
      characters: _getRandomCharacters(random, friends - 1),
      explanation: '$initial - $eaten = $remaining, $remaining ÷ $friends = $share',
      metadata: {'initial': initial, 'eaten': eaten, 'remaining': remaining},
    );
  }

  // TİP 11: Ölçme
  Question _generateMeasurementQuestion(math.Random random, AppLocalizations loc) {
    final totalLength = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 6 + random.nextInt(7),
      AgeGroupSelection.elementary => 12 + random.nextInt(13),
      AgeGroupSelection.advanced => 15 + random.nextInt(16),
    };
    final pieces = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 2 + random.nextInt(5),
      AgeGroupSelection.advanced => 3 + random.nextInt(5),
    };
    final pieceLength = totalLength ~/ pieces;
    final isRope = random.nextBool();
    final item = isRope ? loc.get('keloglan_object_rope') : loc.get('keloglan_food_watermelon');
    final emoji = isRope ? '🧶' : '🍉';
    final unit = isRope ? loc.get('keloglan_unit_meter') : loc.get('keloglan_unit_kg');

    return Question(
      type: QuestionType.measurement,
      questionText: loc.get('keloglan_q_measurement')
          .replaceAll('{0}', '$totalLength').replaceAll('{1}', unit).replaceAll('{2}', item).replaceAll('{3}', '$pieces'),
      keloglanMessage: loc.get('keloglan_s_measurement')
          .replaceAll('{0}', '$totalLength').replaceAll('{1}', unit).replaceAll('{2}', item).replaceAll('{3}', '$pieces'),
      correctAnswer: pieceLength,
      options: _generateOptions(pieceLength, random),
      itemEmoji: emoji,
      itemName: item,
      location: '',
      characters: [],
      explanation: '$totalLength ÷ $pieces = $pieceLength $unit',
      metadata: {'total': totalLength, 'pieces': pieces},
    );
  }

  // TİP 12: Zaman
  Question _generateTimeQuestion(math.Random random, AppLocalizations loc) {
    final hoursPerDay = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 1 + random.nextInt(3),
      AgeGroupSelection.elementary => 2 + random.nextInt(4),
      AgeGroupSelection.advanced => 2 + random.nextInt(5),
    };
    final days = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 2 + random.nextInt(5),
      AgeGroupSelection.advanced => 3 + random.nextInt(5),
    };
    final total = hoursPerDay * days;
    final hourName = loc.get('keloglan_unit_hour');

    return Question(
      type: QuestionType.time,
      questionText: loc.get('keloglan_q_time')
          .replaceAll('{0}', '$hoursPerDay').replaceAll('{1}', '$days'),
      keloglanMessage: loc.get('keloglan_s_time')
          .replaceAll('{0}', '$hoursPerDay').replaceAll('{1}', '$days'),
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: '⏰',
      itemName: hourName,
      location: '',
      characters: [],
      explanation: '$hoursPerDay × $days = $total $hourName',
      metadata: {'hoursPerDay': hoursPerDay, 'days': days},
    );
  }

  // TİP 13: Para Hesabı
  Question _generateMoneyQuestion(math.Random random, AppLocalizations loc) {
    final items = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 3 + random.nextInt(5),
      AgeGroupSelection.advanced => 4 + random.nextInt(5),
    };
    final price = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 5 + random.nextInt(2) * 5,
      AgeGroupSelection.elementary => 5 + random.nextInt(10) * 5,
      AgeGroupSelection.advanced => 5 + random.nextInt(14) * 5,
    };
    final total = items * price;
    final isBuying = random.nextBool();
    final money = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 20 + random.nextInt(4) * 10,
      AgeGroupSelection.elementary => 50 + random.nextInt(5) * 10,
      AgeGroupSelection.advanced => 60 + random.nextInt(8) * 10,
    };
    final canBuy = money ~/ price;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);
    final marketName = loc.get('keloglan_location_market');

    if (isBuying) {
      return Question(
        type: QuestionType.money,
        questionText: loc.get('keloglan_q_money_buy')
            .replaceAll('{0}', '$money').replaceAll('{1}', '$price').replaceAll('{2}', itemName),
        keloglanMessage: loc.get('keloglan_s_money_buy')
            .replaceAll('{0}', '$money').replaceAll('{1}', '$price').replaceAll('{2}', itemName),
        correctAnswer: canBuy,
        options: _generateOptions(canBuy, random),
        itemEmoji: '💰',
        itemName: itemName,
        location: marketName,
        characters: [],
        explanation: '$money ÷ $price = $canBuy tane',
        metadata: {'money': money, 'price': price},
      );
    } else {
      return Question(
        type: QuestionType.money,
        questionText: loc.get('keloglan_q_money_sell')
            .replaceAll('{0}', '$items').replaceAll('{1}', itemName).replaceAll('{2}', '$price'),
        keloglanMessage: loc.get('keloglan_s_money_sell')
            .replaceAll('{0}', '$items').replaceAll('{1}', itemName).replaceAll('{2}', '$price'),
        correctAnswer: total,
        options: _generateOptions(total, random),
        itemEmoji: '💵',
        itemName: 'lira',
        location: marketName,
        characters: [],
        explanation: '$items × $price = $total lira',
        metadata: {'items': items, 'price': price},
      );
    }
  }

  // TİP 14: Kat Sayısı
  Question _generateRatioQuestion(math.Random random, AppLocalizations loc) {
    final keloglanCount = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 3 + random.nextInt(5),
      AgeGroupSelection.advanced => 4 + random.nextInt(6),
    };
    final multiplier = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2,
      AgeGroupSelection.elementary => 2 + random.nextInt(3),
      AgeGroupSelection.advanced => 2 + random.nextInt(4),
    };
    final aliCount = keloglanCount * multiplier;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.ratio,
      questionText: loc.get('keloglan_q_ratio')
          .replaceAll('{0}', '$keloglanCount').replaceAll('{1}', '$aliCount').replaceAll('{2}', itemName),
      keloglanMessage: loc.get('keloglan_s_ratio')
          .replaceAll('{0}', '$keloglanCount').replaceAll('{1}', '$aliCount').replaceAll('{2}', itemName),
      correctAnswer: multiplier,
      options: _generateOptions(multiplier, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: ['Ali'],
      explanation: '$aliCount ÷ $keloglanCount = $multiplier katı',
      metadata: {'keloglan': keloglanCount, 'ali': aliCount},
    );
  }

  // TİP 15: Sıralama / Örüntü
  Question _generatePatternQuestion(math.Random random, AppLocalizations loc) {
    final start = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(4),
      AgeGroupSelection.advanced => 2 + random.nextInt(5),
    };
    final increment = 2; // Her gün +2
    final targetDay = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 3 + random.nextInt(2),
      AgeGroupSelection.elementary => 4 + random.nextInt(3),
      AgeGroupSelection.advanced => 4 + random.nextInt(4),
    };
    final result = start + (targetDay - 1) * increment;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);

    return Question(
      type: QuestionType.pattern,
      questionText: loc.get('keloglan_q_pattern')
          .replaceAll('{0}', '$increment').replaceAll('{1}', itemName).replaceAll('{2}', '$start').replaceAll('{3}', '$targetDay'),
      keloglanMessage: loc.get('keloglan_s_pattern')
          .replaceAll('{0}', '$increment').replaceAll('{1}', itemName).replaceAll('{2}', '$start').replaceAll('{3}', '$targetDay'),
      correctAnswer: result,
      options: _generateOptions(result, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: [],
      explanation: '$start, ${start + increment}, ${start + 2 * increment}, ..., $targetDay. gün: $result',
      metadata: {'start': start, 'increment': increment, 'targetDay': targetDay},
    );
  }

  // TİP 16: Şekillerle Bölme
  Question _generateShapeDivisionQuestion(math.Random random, AppLocalizations loc) {
    final people = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(6),
      AgeGroupSelection.advanced => 3 + random.nextInt(6),
    };
    final cuts = people; // Kesim sayısı = kişi sayısı
    final isCake = random.nextBool();
    final item = isCake ? loc.get('keloglan_object_cake') : loc.get('keloglan_object_field');
    final emoji = isCake ? '🎂' : '🌾';

    return Question(
      type: QuestionType.shapeDivision,
      questionText: loc.get('keloglan_q_shape_division')
          .replaceAll('{0}', '$people').replaceAll('{1}', item),
      keloglanMessage: loc.get('keloglan_s_shape_division')
          .replaceAll('{0}', '$people').replaceAll('{1}', item),
      correctAnswer: cuts,
      options: _generateOptions(cuts, random),
      itemEmoji: emoji,
      itemName: item,
      location: '',
      characters: _getRandomCharacters(random, people - 1),
      explanation: '$people kişi = $cuts kesim',
      metadata: {'people': people},
    );
  }

  // TİP 17: İki Aşamalı Paylaştırma
  Question _generateTwoStageSharingQuestion(math.Random random, AppLocalizations loc) {
    final total = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 12 + random.nextInt(8),
      AgeGroupSelection.elementary => 24 + random.nextInt(12),
      AgeGroupSelection.advanced => 30 + random.nextInt(18),
    };
    final firstFriends = 2; // İlk aşamada 2 kişi
    final secondFriends = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 1 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(2),
      AgeGroupSelection.advanced => 2 + random.nextInt(3),
    };
    final totalFriends = firstFriends + secondFriends;
    final finalShare = total ~/ totalFriends;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);
    final firstChar = _characters[random.nextInt(_characters.length)];

    return Question(
      type: QuestionType.twoStageSharing,
      questionText: loc.get('keloglan_q_two_stage')
          .replaceAll('{0}', '$total').replaceAll('{1}', itemName).replaceAll('{2}', '$totalFriends'),
      keloglanMessage: loc.get('keloglan_s_two_stage')
          .replaceAll('{0}', '$total').replaceAll('{1}', itemName).replaceAll('{2}', '$totalFriends')
          .replaceAll('{3}', firstChar).replaceAll('{4}', '$secondFriends'),
      correctAnswer: finalShare,
      options: _generateOptions(finalShare, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: [firstChar],
      explanation: '$total ÷ $totalFriends = $finalShare',
      metadata: {'total': total, 'friends': totalFriends},
    );
  }

  // TİP 18: Ters İşlem
  Question _generateReverseOperationQuestion(math.Random random, AppLocalizations loc) {
    final share = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(3),
      AgeGroupSelection.elementary => 3 + random.nextInt(5),
      AgeGroupSelection.advanced => 3 + random.nextInt(6),
    };
    final friends = switch (widget.ageGroup) {
      AgeGroupSelection.preschool => 2 + random.nextInt(2),
      AgeGroupSelection.elementary => 2 + random.nextInt(4),
      AgeGroupSelection.advanced => 2 + random.nextInt(5),
    };
    final total = share * friends;
    final item = _items[random.nextInt(_items.length)];
    final itemName = _itemName(loc, item);
    final chars = _getRandomCharacters(random, friends - 1);

    return Question(
      type: QuestionType.reverseOperation,
      questionText: loc.get('keloglan_q_reverse')
          .replaceAll('{0}', '$share').replaceAll('{1}', itemName).replaceAll('{2}', '$friends'),
      keloglanMessage: loc.get('keloglan_s_reverse')
          .replaceAll('{0}', chars.join(', ')).replaceAll('{1}', itemName).replaceAll('{2}', '$share'),
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: item['emoji'] as String,
      itemName: itemName,
      location: '',
      characters: chars,
      explanation: '$share × $friends = $total',
      metadata: {'share': share, 'friends': friends},
    );
  }

  // Yardımcı Fonksiyonlar

  List<String> _getRandomCharacters(math.Random random, int count) {
    final shuffled = [..._characters]..shuffle(random);
    return shuffled.take(count).toList();
  }

  List<int> _generateOptions(int correctAnswer, math.Random random) {
    final Set<int> options = {correctAnswer};
    
    // Yanlış cevaplar üret (doğruya yakın)
    while (options.length < 3) {
      int variation = random.nextInt(5) - 2; // -2, -1, 0, 1, 2
      if (variation == 0) variation = random.nextBool() ? 1 : -1;
      
      int wrong = correctAnswer + variation;
      if (wrong > 0 && wrong != correctAnswer) {
        options.add(wrong);
      }
    }
    
    // Eğer hala 3 değilse rastgele ekle
    while (options.length < 3) {
      int wrong = correctAnswer + random.nextInt(8) + 1;
      options.add(wrong);
    }
    
    return options.toList()..shuffle(random);
  }

  // ============================================================================
  // UI FONKSİYONLARI
  // ============================================================================

  void _checkAnswer(int answer) {
    if (_isAnswered || _currentQuestion == null) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = answer == _currentQuestion!.correctAnswer;

      if (_isCorrect) {
        _score += 10;
        _stars++;
        _celebrationController.forward(from: 0);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
            _generateQuestion(loc);
          }
        });
      } else {
        _lives = (_lives - 1).clamp(0, 5);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
            _generateQuestion(loc);
          }
        });
      }
    });
  }

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    
    if (_currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _currentQuestion!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_skyBlue, _cream, _villageGreen],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              ..._buildVillageBackground(),
              Column(
                children: [
                  _buildTopBar(loc),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 36,
                      ),
                      child: Column(
                        children: [
                          _buildLevelInfo(loc),
                          const SizedBox(height: 16),
                          _buildCharacterMessage(loc, q),
                          const SizedBox(height: 24),
                          _buildQuestionArea(loc, q),
                          const SizedBox(height: 20),
                          _buildAnswerOptions(loc, q),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isCorrect && _isAnswered) _buildCelebration(q),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _cream.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: _earthBrown.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: _earthBrown.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.arrow_back, color: _earthBrown),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '🧑‍🌾 ${loc.get('keloglan_village')}',
                maxLines: 1,
                style: _textStyle(_earthBrown, size: 18, bold: true),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final hasLife = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(left: 1),
                child: hasLife
                    ? const Text('🧺', style: TextStyle(fontSize: 15))
                    : const Text('🪹', style: TextStyle(fontSize: 15, color: Colors.grey)),
              );
            }),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _villageGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _villageGreen.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('$_stars', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _earthBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterMessage(AppLocalizations loc, Question q) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _villageGreen.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: _earthBrown.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Kel Keloğlan Avatar - saçsız/kel görünüm
          _buildKelKeloglanAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.get('keloglan_character_name'), style: _textStyle(_earthBrown, size: 18, bold: true)),
                const SizedBox(height: 4),
                Text(q.keloglanMessage, style: _textStyle(_earthBrown.withOpacity(0.9), size: 14), maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kel Keloğlan Avatar - saçsız/kel kafa görünümü (BÜYÜK BOY)
  Widget _buildKelKeloglanAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF5D0A9), // Ten rengi
        shape: BoxShape.circle,
        border: Border.all(color: _earthBrown, width: 2),
        boxShadow: [
          BoxShadow(color: _earthBrown.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Center(
          child: Transform.scale(
            scale: 1.4,
            child: const Text('👨‍🦲', style: TextStyle(fontSize: 44)),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelInfo(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _villageGreen.withOpacity(0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(loc.get('level'), '$_currentLevel', '🎯'),
              Container(
                width: 1,
                height: 36,
                color: _earthBrown.withOpacity(0.15),
              ),
              _buildStatItem(loc.get('score'), '$_score', '⭐'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentLevel % 5) / 5,
              minHeight: 10,
              backgroundColor: _cream.withOpacity(0.9),
              valueColor: const AlwaysStoppedAnimation<Color>(_villageGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: _textStyle(_earthBrown, size: 18, bold: true).copyWith(height: 1.05),
            ),
            Text(
              label,
              style: _textStyle(_earthBrown.withOpacity(0.85), size: 10).copyWith(height: 1.1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionArea(AppLocalizations loc, Question q) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _villageGreen.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: _earthBrown.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          // Soru metni
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _villageGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(q.questionText, style: _textStyle(_earthBrown, size: 18, bold: true), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          // Sadece sembolik olarak 1 emoji + soru işareti göster (cevap vermeden)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(q.itemEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Text('❓', style: const TextStyle(fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(AppLocalizations loc, Question q) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Text(loc.get('choose_answer'), style: _textStyle(_earthBrown, size: 16, bold: true)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: q.options.map((option) => _buildAnswerButton(option, q)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int value, Question q) {
    final isCorrectAnswer = value == q.correctAnswer;
    final isSelected = _isAnswered && value == q.correctAnswer;

    Color buttonColor;
    if (_isAnswered) {
      buttonColor = isCorrectAnswer ? _villageGreen.withOpacity(0.8) : Colors.red.withOpacity(0.3);
    } else {
      buttonColor = _cream.withOpacity(0.9);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _villageGreen : _earthBrown.withOpacity(0.5), width: isSelected ? 3 : 2),
          boxShadow: [BoxShadow(color: _earthBrown.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: GoogleFonts.quicksand(color: _earthBrown, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration(Question q) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(20, (index) {
                final random = math.Random(index);
                final startX = random.nextDouble();
                final delay = random.nextDouble() * 0.5;
                final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);

                return Positioned(
                  left: MediaQuery.of(context).size.width * startX,
                  top: -50 + (MediaQuery.of(context).size.height * progress * 1.2),
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Transform.rotate(
                      angle: progress * 4 * math.pi,
                      child: Text([q.itemEmoji, '🎉', '⭐'][random.nextInt(3)], style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildVillageBackground() {
    return [
      Positioned(top: 40, right: 40, child: Opacity(opacity: 0.6, child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.yellow.withOpacity(0.8), shape: BoxShape.circle),
        child: const Center(child: Text('☀️', style: TextStyle(fontSize: 32))),
      ))),
      Positioned(top: 80, left: 20, child: Opacity(opacity: 0.4, child: Text('☁️', style: TextStyle(fontSize: 48)))),
      ...List.generate(5, (i) {
        final random = math.Random(i);
        return Positioned(
          bottom: 100 + random.nextDouble() * 50, left: random.nextDouble() * 300,
          child: Opacity(opacity: 0.2, child: Text(['🌳', '🌲', '🌴'][random.nextInt(3)], style: TextStyle(fontSize: 40 + random.nextDouble() * 20))),
        );
      }),
    ];
  }
}
