import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Keloğlan'ın Köyü - Dinamik Soru Üretim Sistemi
/// 18 farklı soru tipi, binlerce kombinasyon
class KeloglanVillageScreen extends StatefulWidget {
  final VoidCallback onBack;

  const KeloglanVillageScreen({super.key, required this.onBack});

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

  // Mekanlar Havuzu
  final List<String> _locations = [
    'Köy meydanı', 'Okul bahçesi', 'Tarla', 'Bağ', 'Bahçe', 'Pazar yeri',
    'Ev', 'Ahır', 'Kümes', 'Orman kenarı', 'Dere kenarı', 'Teyze evi',
    'Amca çiftliği'
  ];

  // Yiyecek ve Nesneler Havuzu
  final List<Map<String, dynamic>> _items = [
    {'emoji': '🍎', 'name': 'elma', 'type': 'food'},
    {'emoji': '🍐', 'name': 'armut', 'type': 'food'},
    {'emoji': '🍪', 'name': 'kurabiye', 'type': 'food'},
    {'emoji': '🥚', 'name': 'yumurta', 'type': 'food'},
    {'emoji': '🥧', 'name': 'börek', 'type': 'food'},
    {'emoji': '🥜', 'name': 'ceviz', 'type': 'food'},
    {'emoji': '🍇', 'name': 'üzüm', 'type': 'food'},
    {'emoji': '🍉', 'name': 'karpuz', 'type': 'food'},
    {'emoji': '🍞', 'name': 'ekmek', 'type': 'food'},
    {'emoji': '🧀', 'name': 'peynir', 'type': 'food'},
    {'emoji': '🍯', 'name': 'bal', 'type': 'food'},
    {'emoji': '🍬', 'name': 'şeker', 'type': 'food'},
    {'emoji': '🥩', 'name': 'köfte', 'type': 'food'},
    {'emoji': '⚽', 'name': 'top', 'type': 'object'},
    {'emoji': '✏️', 'name': 'kalem', 'type': 'object'},
    {'emoji': '📒', 'name': 'defter', 'type': 'object'},
    {'emoji': '🧺', 'name': 'sepet', 'type': 'object'},
    {'emoji': '🌻', 'name': 'çiçek', 'type': 'object'},
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

    _generateQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // ============================================================================
  // SORU ÜRETİM MOTORU - 18 FARKLI TİP
  // ============================================================================

  void _generateQuestion() {
    final random = math.Random();
    final type = QuestionType.values[random.nextInt(QuestionType.values.length)];
    
    Question question;
    switch (type) {
      case QuestionType.equalSharing:
        question = _generateEqualSharingQuestion(random);
        break;
      case QuestionType.groupDivision:
        question = _generateGroupDivisionQuestion(random);
        break;
      case QuestionType.remainderDivision:
        question = _generateRemainderQuestion(random);
        break;
      case QuestionType.multiples:
        question = _generateMultiplesQuestion(random);
        break;
      case QuestionType.fractions:
        question = _generateFractionsQuestion(random);
        break;
      case QuestionType.twoStepMix:
        question = _generateTwoStepMixQuestion(random);
        break;
      case QuestionType.comparison:
        question = _generateComparisonQuestion(random);
        break;
      case QuestionType.addThenDivide:
        question = _generateAddThenDivideQuestion(random);
        break;
      case QuestionType.multiplyThenDivide:
        question = _generateMultiplyThenDivideQuestion(random);
        break;
      case QuestionType.missingShare:
        question = _generateMissingShareQuestion(random);
        break;
      case QuestionType.measurement:
        question = _generateMeasurementQuestion(random);
        break;
      case QuestionType.time:
        question = _generateTimeQuestion(random);
        break;
      case QuestionType.money:
        question = _generateMoneyQuestion(random);
        break;
      case QuestionType.ratio:
        question = _generateRatioQuestion(random);
        break;
      case QuestionType.pattern:
        question = _generatePatternQuestion(random);
        break;
      case QuestionType.shapeDivision:
        question = _generateShapeDivisionQuestion(random);
        break;
      case QuestionType.twoStageSharing:
        question = _generateTwoStageSharingQuestion(random);
        break;
      case QuestionType.reverseOperation:
        question = _generateReverseOperationQuestion(random);
        break;
    }

    setState(() {
      _currentQuestion = question;
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  // TİP 1: Eşit Paylaştırma
  Question _generateEqualSharingQuestion(math.Random random) {
    final peopleCount = 2 + random.nextInt(4); // 2-5 kişi
    final itemPerPerson = 2 + random.nextInt(5); // Kişi başı 2-6
    final total = peopleCount * itemPerPerson;
    final item = _items[random.nextInt(_items.length)];
    final location = _locations[random.nextInt(_locations.length)];
    final friends = _getRandomCharacters(random, peopleCount - 1);

    return Question(
      type: QuestionType.equalSharing,
      questionText: '$total tane ${item['name']} var. $peopleCount kişi eşit paylaştırsa herkese kaç ${item['name']} düşer?',
      keloglanMessage: '$location\'nde $total tane ${item['name']} topladım. ${friends.join(', ')} ve ben paylaşacağız. Bakalım her birimize kaç düşecek!',
      correctAnswer: itemPerPerson,
      options: _generateOptions(itemPerPerson, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: location,
      characters: friends,
      explanation: '$total ÷ $peopleCount = $itemPerPerson',
      metadata: {'total': total, 'people': peopleCount},
    );
  }

  // TİP 2: Gruplara Ayırma
  Question _generateGroupDivisionQuestion(math.Random random) {
    final groupSize = 2 + random.nextInt(4); // Her grupta 2-5
    final groupCount = 2 + random.nextInt(4); // 2-5 grup
    final total = groupSize * groupCount;
    final item = _items[random.nextInt(_items.length)];
    final location = _locations[random.nextInt(_locations.length)];

    return Question(
      type: QuestionType.groupDivision,
      questionText: '$total tane ${item['name']}\'yi ${groupSize}\'şerli gruplara ayırırsak kaç grup olur?',
      keloglanMessage: '$location\'nde $total tane ${item['name']} birikti. Bunları ${groupSize}\'şerli kolilere koymam gerekiyor.',
      correctAnswer: groupCount,
      options: _generateOptions(groupCount, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: location,
      characters: [],
      explanation: '$total ÷ $groupSize = $groupCount',
      metadata: {'total': total, 'groupSize': groupSize},
    );
  }

  // TİP 3: Kalanlı Bölme
  Question _generateRemainderQuestion(math.Random random) {
    final divisor = 3 + random.nextInt(3); // 3-5
    final quotient = 2 + random.nextInt(4); // 2-5
    final remainder = 1 + random.nextInt(divisor - 1); // 1'den büyük, bölene eşit değil
    final total = divisor * quotient + remainder;
    final item = _items[random.nextInt(_items.length)];
    final friends = _getRandomCharacters(random, divisor - 1);

    return Question(
      type: QuestionType.remainderDivision,
      questionText: '$total tane ${item['name']} $divisor kişiye eşit paylaştırılınca kaç ${item['name']} artar?',
      keloglanMessage: '$total tane ${item['name']} topladım. ${friends.join(', ')} ve ben paylaşacağız. Eşit bölününce kaç tane artacak acaba?',
      correctAnswer: remainder,
      options: _generateOptions(remainder, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: friends,
      explanation: '$total = $divisor × $quotient + $remainder, artan: $remainder',
      metadata: {'total': total, 'divisor': divisor, 'remainder': remainder},
    );
  }

  // TİP 4: Kat Kavramı
  Question _generateMultiplesQuestion(math.Random random) {
    final dailyAmount = 2 + random.nextInt(4); // Günde 2-5
    final days = 2 + random.nextInt(5); // 2-6 gün
    final total = dailyAmount * days;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.multiples,
      questionText: 'Her gün $dailyAmount tane ${item['name']} yenilirse $days günde toplam kaç ${item['name']} yenilir?',
      keloglanMessage: 'Her gün $dailyAmount tane ${item['name']} yiyorum. $days gün sonra toplam kaç yemiş olacağımı hesaplamam gerekiyor.',
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: [],
      explanation: '$dailyAmount × $days = $total',
      metadata: {'daily': dailyAmount, 'days': days},
    );
  }

  // TİP 5: Kesirler (Yarım - Çeyrek)
  Question _generateFractionsQuestion(math.Random random) {
    final wholeCount = 2 + random.nextInt(3); // 2-4 bütün
    final isQuarter = random.nextBool();
    final fractionName = isQuarter ? 'çeyrek' : 'yarım';
    final multiplier = isQuarter ? 4 : 2;
    final total = wholeCount * multiplier;
    final item = _items.where((i) => i['type'] == 'food').toList()[random.nextInt(6)];

    return Question(
      type: QuestionType.fractions,
      questionText: '$wholeCount bütün ${item['name']} kaç $fractionName ${item['name']} eder?',
      keloglanMessage: 'Annem ${item['name']}yi $fractionName dilimlere bölmek istiyor. Elimizde $wholeCount bütün var.',
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: [],
      explanation: '$wholeCount × $multiplier = $total $fractionName',
      metadata: {'whole': wholeCount, 'fraction': fractionName},
    );
  }

  // TİP 6: Karıştırma (İki İşlemli)
  Question _generateTwoStepMixQuestion(math.Random random) {
    final chicken = 3 + random.nextInt(4); // 3-6 tavuk
    final eggsPerDay = 2 + random.nextInt(3); // Günde 2-4 yumurta
    final days = 3 + random.nextInt(3); // 3-5 gün
    final total = chicken * eggsPerDay * days;

    return Question(
      type: QuestionType.twoStepMix,
      questionText: '$chicken tane tavuk her gün $eggsPerDay\'şer yumurta veriyorsa $days günde toplam kaç yumurta olur?',
      keloglanMessage: 'Kümesimizde $chicken tane tavuk var. Her gün $eggsPerDay\'şer yumurta veriyorlar. $days gün sonunda toplam kaç yumurta toplamış olurum?',
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: '🥚',
      itemName: 'yumurta',
      location: 'Kümes',
      characters: [],
      explanation: '$chicken × $eggsPerDay × $days = $total',
      metadata: {'chicken': chicken, 'eggsPerDay': eggsPerDay, 'days': days},
    );
  }

  // TİP 7: Karşılaştırma
  Question _generateComparisonQuestion(math.Random random) {
    final char1 = _characters[random.nextInt(_characters.length)];
    String char2;
    do {
      char2 = _characters[random.nextInt(_characters.length)];
    } while (char1 == char2);

    final count1 = 5 + random.nextInt(10);
    final count2 = 5 + random.nextInt(10);
    final diff = (count1 - count2).abs();
    final hasMore = count1 > count2 ? char1 : char2;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.comparison,
      questionText: '$char1\'nin $count1, $char2\'nin $count2 tane ${item['name']} var. Aradaki fark kaç?',
      keloglanMessage: '$char1 $count1 tane, $char2 ise $count2 tane ${item['name']} topladı. İkisinin topladığı arasındaki farkı bulmam lazım.',
      correctAnswer: diff,
      options: _generateOptions(diff, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: [char1, char2],
      explanation: '$hasMore daha fazla. Fark: $diff',
      metadata: {'count1': count1, 'count2': count2, 'hasMore': hasMore},
    );
  }

  // TİP 8: Toplama + Bölme
  Question _generateAddThenDivideQuestion(math.Random random) {
    final char1 = 'Keloğlan';
    final char2 = _characters[random.nextInt(_characters.length)];
    final char3 = _characters[random.nextInt(_characters.length)];
    
    final count1 = 3 + random.nextInt(5);
    final count2 = 4 + random.nextInt(5);
    final count3 = 5 + random.nextInt(5);
    final total = count1 + count2 + count3;
    final divisor = 3; // Her zaman 3 kişi
    final share = total ~/ divisor;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.addThenDivide,
      questionText: '$char1\'ın $count1, $char2\'nin $count2, $char3\'nin $count3 tane ${item['name']} var. Hepsini birleştirip $divisor kişiye eşit paylaştırırsak herkese kaç ${item['name']} düşer?',
      keloglanMessage: '$char2 $count2 tane, $char3 ise $count3 tane topladı. Ben de $count1 tane topladım. Hepsini birleştirip paylaşacağız.',
      correctAnswer: share,
      options: _generateOptions(share, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: [char2, char3],
      explanation: '$count1 + $count2 + $count3 = $total, $total ÷ $divisor = $share',
      metadata: {'total': total, 'share': share},
    );
  }

  // TİP 9: Çarpma + Bölme
  Question _generateMultiplyThenDivideQuestion(math.Random random) {
    final baskets = 2 + random.nextInt(3); // 2-4 sepet
    final itemsPerBasket = 3 + random.nextInt(4); // Sepette 3-6
    final total = baskets * itemsPerBasket;
    final friends = 2 + random.nextInt(3); // 2-4 arkadaş
    final share = total ~/ friends;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.multiplyThenDivide,
      questionText: '$baskets sepette $itemsPerBasket\'şer ${item['name']} var. Bunları $friends kişiye eşit paylaştırırsak herkese kaç ${item['name']} düşer?',
      keloglanMessage: '$baskets sepet ${item['name']} dolu. Her sepette $itemsPerBasket tane var. Arkadaşlarımla paylaşacağız.',
      correctAnswer: share,
      options: _generateOptions(share, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: _getRandomCharacters(random, friends - 1),
      explanation: '$baskets × $itemsPerBasket = $total, $total ÷ $friends = $share',
      metadata: {'baskets': baskets, 'itemsPerBasket': itemsPerBasket, 'share': share},
    );
  }

  // TİP 10: Eksik - Fazla Bulmaca
  Question _generateMissingShareQuestion(math.Random random) {
    final initial = 15 + random.nextInt(10); // Başlangıç 15-24
    final eaten = 3 + random.nextInt(8); // Yenen 3-10
    final remaining = initial - eaten;
    final friends = 2 + random.nextInt(3); // 2-4 kişi
    final share = remaining ~/ friends;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.missingShare,
      questionText: '$initial tane ${item['name']} vardı. $eaten tane yenildi. Kalan $friends kişiye eşit paylaştırılırsa herkese kaç ${item['name']} düşer?',
      keloglanMessage: 'Elimizde $initial tane ${item['name']} var. $eaten tanesi yendi. Kalanı arkadaşlarımla paylaşacağız.',
      correctAnswer: share,
      options: _generateOptions(share, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: 'Köy',
      characters: _getRandomCharacters(random, friends - 1),
      explanation: '$initial - $eaten = $remaining, $remaining ÷ $friends = $share',
      metadata: {'initial': initial, 'eaten': eaten, 'remaining': remaining},
    );
  }

  // TİP 11: Ölçme
  Question _generateMeasurementQuestion(math.Random random) {
    final totalLength = 12 + random.nextInt(13); // 12-24 metre
    final pieces = 2 + random.nextInt(5); // 2-6 parça
    final pieceLength = totalLength ~/ pieces;
    final isRope = random.nextBool();
    final item = isRope ? 'ip' : 'karpuz';
    final emoji = isRope ? '🧶' : '🍉';
    final unit = isRope ? 'metre' : 'kg';

    return Question(
      type: QuestionType.measurement,
      questionText: '$totalLength $unit uzunluğundaki $item $pieces eşit parçaya bölünürse her parça kaç $unit olur?',
      keloglanMessage: 'Annem $totalLength $unit\'lik $item\'yi $pieces parçaya bölmek istiyor. Her parça ne kadar olacak?',
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
  Question _generateTimeQuestion(math.Random random) {
    final hoursPerDay = 2 + random.nextInt(4); // Günde 2-5 saat
    final days = 2 + random.nextInt(5); // 2-6 gün
    final total = hoursPerDay * days;

    return Question(
      type: QuestionType.time,
      questionText: 'Günde $hoursPerDay saat çalışılırsa $days günde toplam kaç saat çalışılmış olur?',
      keloglanMessage: 'Her gün $hoursPerDay saat matematik çalışıyorum. $days gün sonunda toplam kaç saat ettiğini hesaplamam lazım.',
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: '⏰',
      itemName: 'saat',
      location: '',
      characters: [],
      explanation: '$hoursPerDay × $days = $total saat',
      metadata: {'hoursPerDay': hoursPerDay, 'days': days},
    );
  }

  // TİP 13: Para Hesabı
  Question _generateMoneyQuestion(math.Random random) {
    final items = 3 + random.nextInt(5); // 3-7 tane
    final price = 5 + random.nextInt(10) * 5; // 5, 10, 15... kuruş
    final total = items * price;
    final isBuying = random.nextBool();
    final money = 50 + random.nextInt(5) * 10; // 50-90 lira
    final canBuy = money ~/ price;
    final item = _items[random.nextInt(_items.length)];

    if (isBuying) {
      return Question(
        type: QuestionType.money,
        questionText: '$money lira ile tanesi $price lira olan ${item['name']}\'lerden kaç tane alınabilir?',
        keloglanMessage: 'Pazara $money lira ile gittim. ${item['name']} tanesi $price lira. Kaç tane alabileceğimi hesaplıyorum.',
        correctAnswer: canBuy,
        options: _generateOptions(canBuy, random),
        itemEmoji: '💰',
        itemName: item['name'] as String,
        location: 'Pazar',
        characters: [],
        explanation: '$money ÷ $price = $canBuy tane',
        metadata: {'money': money, 'price': price},
      );
    } else {
      return Question(
        type: QuestionType.money,
        questionText: '$items tane ${item['name']} tanesi $price liradan satılırsa toplam kaç lira kazanılır?',
        keloglanMessage: '$items tane ${item['name']} satacağım. Tanesini $price liradan satarsam toplam ne kadar kazanırım?',
        correctAnswer: total,
        options: _generateOptions(total, random),
        itemEmoji: '💵',
        itemName: 'lira',
        location: 'Pazar',
        characters: [],
        explanation: '$items × $price = $total lira',
        metadata: {'items': items, 'price': price},
      );
    }
  }

  // TİP 14: Kat Sayısı
  Question _generateRatioQuestion(math.Random random) {
    final keloglanCount = 3 + random.nextInt(5); // Keloğlan'ın 3-7
    final multiplier = 2 + random.nextInt(3); // 2-4 katı
    final aliCount = keloglanCount * multiplier;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.ratio,
      questionText: 'Keloğlan\'ın $keloglanCount, Ali\'nin $aliCount tane ${item['name']} var. Ali\'nin topladığı Keloğlan\'ınkinin kaç katıdır?',
      keloglanMessage: 'Ben $keloglanCount tane ${item['name']} topladım. Ali ise $aliCount tane topladı. Kaç kat fazla toplamış hesaplıyorum.',
      correctAnswer: multiplier,
      options: _generateOptions(multiplier, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: ['Ali'],
      explanation: '$aliCount ÷ $keloglanCount = $multiplier katı',
      metadata: {'keloglan': keloglanCount, 'ali': aliCount},
    );
  }

  // TİP 15: Sıralama / Örüntü
  Question _generatePatternQuestion(math.Random random) {
    final start = 2 + random.nextInt(4); // İlk gün 2-5
    final increment = 2; // Her gün +2
    final targetDay = 4 + random.nextInt(3); // 4-6. gün
    final result = start + (targetDay - 1) * increment;
    final item = _items[random.nextInt(_items.length)];

    return Question(
      type: QuestionType.pattern,
      questionText: 'Her gün bir önceki günden $increment fazla ${item['name']} yeniyor. İlk gün $start ise $targetDay. gün kaç ${item['name']} yenilir?',
      keloglanMessage: 'Her gün bir önceki günden $increment fazla ${item['name']} yiyorum. İlk gün $start yedim. $targetDay. gün kaç yemiş olurum acaba?',
      correctAnswer: result,
      options: _generateOptions(result, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: [],
      explanation: '$start, ${start + increment}, ${start + 2 * increment}, ..., $targetDay. gün: $result',
      metadata: {'start': start, 'increment': increment, 'targetDay': targetDay},
    );
  }

  // TİP 16: Şekillerle Bölme
  Question _generateShapeDivisionQuestion(math.Random random) {
    final people = 2 + random.nextInt(6); // 2-7 kişi
    final cuts = people; // Kesim sayısı = kişi sayısı
    final item = random.nextBool() ? 'pasta' : 'tarla';
    final emoji = item == 'pasta' ? '🎂' : '🌾';

    return Question(
      type: QuestionType.shapeDivision,
      questionText: '$people kişiye eşit paylaştırmak için bir $item kaç parçaya bölünmeli?',
      keloglanMessage: 'Annem ${item} yaptı. $people arkadaşla paylaşacağız. Kaç eşit parça yapmamız gerekiyor?',
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
  Question _generateTwoStageSharingQuestion(math.Random random) {
    final total = 24 + random.nextInt(12); // 24-35
    final firstFriends = 2; // İlk aşamada 2 kişi
    final secondFriends = 2 + random.nextInt(2); // 2-3 yeni misafir
    final totalFriends = firstFriends + secondFriends;
    final finalShare = total ~/ totalFriends;
    final item = _items[random.nextInt(_items.length)];
    final firstChar = _characters[random.nextInt(_characters.length)];

    return Question(
      type: QuestionType.twoStageSharing,
      questionText: '$total tane ${item['name']} $totalFriends kişiye eşit paylaştırılırsa herkese kaç ${item['name']} düşer?',
      keloglanMessage: '$total tane ${item['name']} ve $firstChar ile paylaşacaktık. Sonra $secondFriends misafir daha geldi. Şimdi toplam $totalFriends kişi olduk.',
      correctAnswer: finalShare,
      options: _generateOptions(finalShare, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
      location: '',
      characters: [firstChar],
      explanation: '$total ÷ $totalFriends = $finalShare',
      metadata: {'total': total, 'friends': totalFriends},
    );
  }

  // TİP 18: Ters İşlem
  Question _generateReverseOperationQuestion(math.Random random) {
    final share = 3 + random.nextInt(5); // Kişi başı 3-7
    final friends = 2 + random.nextInt(4); // 2-5 kişi
    final total = share * friends;
    final item = _items[random.nextInt(_items.length)];
    final chars = _getRandomCharacters(random, friends - 1);

    return Question(
      type: QuestionType.reverseOperation,
      questionText: 'Her kişiye $share tane ${item['name']} düşüyorsa ve $friends kişi varsa toplam kaç ${item['name']} vardı?',
      keloglanMessage: '${chars.join(', ')} ve ben ${item['name']} paylaştık. Her birimize $share tane düştüğünü söylediler. Başlangıçta kaç vardı acaba?',
      correctAnswer: total,
      options: _generateOptions(total, random),
      itemEmoji: item['emoji'] as String,
      itemName: item['name'] as String,
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
            _generateQuestion();
          }
        });
      } else {
        _lives = (_lives - 1).clamp(0, 5);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _generateQuestion();
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
                  _buildTopBar(loc, q),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCharacterMessage(loc, q),
                          const SizedBox(height: 16),
                          _buildLevelInfo(loc),
                          const SizedBox(height: 24),
                          _buildQuestionArea(loc, q),
                          const SizedBox(height: 32),
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

  Widget _buildTopBar(AppLocalizations loc, Question q) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧑‍🌾 ${loc.get('keloglan_village')}', style: _textStyle(_earthBrown, size: 22, bold: true)),
                Text(q.location.isNotEmpty ? '📍 ${q.location}' : 'Soru ${_currentLevel}', 
                  style: _textStyle(_earthBrown.withOpacity(0.8), size: 12)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              final hasLife = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(left: 2),
                child: hasLife ? const Text('🧺', style: TextStyle(fontSize: 24)) : const Text('🪹', style: TextStyle(fontSize: 24, color: Colors.grey)),
              );
            }),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _villageGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _villageGreen.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text('$_stars', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _earthBrown)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _villageGreen.withOpacity(0.4), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Seviye', '$_currentLevel', '🎯'),
              _buildStatItem('Puan', '$_score', '⭐'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: (_currentLevel % 5) / 5,
              minHeight: 14,
              backgroundColor: _cream.withOpacity(0.9),
              valueColor: const AlwaysStoppedAnimation<Color>(_villageGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: _textStyle(_earthBrown, size: 24, bold: true)),
        Text(label, style: _textStyle(_earthBrown.withOpacity(0.8), size: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(loc.get('choose_answer'), style: _textStyle(_earthBrown, size: 16, bold: true)),
          const SizedBox(height: 12),
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
