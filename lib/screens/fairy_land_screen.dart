import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

// ============================================================================
// NESNE TANIMLARI (GameObject Sistemi)
// ============================================================================

enum ObjectType {
  // Çiçekler - Toprak Zemin
  daisy,      // Papatya
  tulip,      // Lale
  rose,       // Gül
  sunflower,  // Ayçiçeği
  hibiscus,   // Hibiskus
  cherry,     // Kiraz çiçeği
  
  // Sihirli Nesneler - Kristal/Mağara Zemin
  crystal,    // Kristal
  diamond,    // Elmas
  orb,        // Küre
  mushroom,   // Mantar
  star,       // Yıldız
}

enum GroundType {
  grass,    // Çimen/Toprak - Çiçekler için
  crystal,  // Kristal zemin - Sihirli nesneler için
}

enum QuestionType {
  sameTypeCounting,      // Tek tür sayma (sadece papatyalar)
  filteredCounting,      // Filtreli sayma (karışık içinden sadece laleler)
  generalCounting,       // Genel sayma (hepsi)
  additionSameType,      // Aynı tür toplama
  subtractionSameType,   // Aynı tür eksiltme
}

class GameObject {
  final ObjectType type;
  final String emoji;
  final String name;
  final Color color;
  final int id;
  bool isCounted;
  bool isWrong;

  GameObject({
    required this.type,
    required this.emoji,
    required this.name,
    required this.color,
    required this.id,
    this.isCounted = false,
    this.isWrong = false,
  });

  bool get isFlower {
    return type == ObjectType.daisy ||
           type == ObjectType.tulip ||
           type == ObjectType.rose ||
           type == ObjectType.sunflower ||
           type == ObjectType.hibiscus ||
           type == ObjectType.cherry;
  }

  bool get isCrystal {
    return type == ObjectType.crystal ||
           type == ObjectType.diamond ||
           type == ObjectType.orb ||
           type == ObjectType.star;
  }
}

class FairyLandQuestion {
  final QuestionType type;
  final String questionText;
  final String targetTypeName; // "papatya", "lale" vb.
  final ObjectType? targetType;
  final int correctAnswer;
  final List<int> options;
  final GroundType groundType;
  final String feedbackMessage;

  FairyLandQuestion({
    required this.type,
    required this.questionText,
    required this.targetTypeName,
    this.targetType,
    required this.correctAnswer,
    required this.options,
    required this.groundType,
    required this.feedbackMessage,
  });
}

// ============================================================================
// ANA EKRAN
// ============================================================================

class FairyLandScreen extends StatefulWidget {
  final VoidCallback onBack;

  const FairyLandScreen({super.key, required this.onBack});

  @override
  State<FairyLandScreen> createState() => _FairyLandScreenState();
}

class _FairyLandScreenState extends State<FairyLandScreen>
    with TickerProviderStateMixin {
  
  // Animasyon kontrolcüleri
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;

  // Oyun durumu
  int _currentLevel = 1;
  int _score = 0;
  int _stars = 0;
  int _lives = 5;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _currentCount = 0; // Şu ana kadar sayılan

  // Nesne ve soru verileri
  List<GameObject> _objects = [];
  FairyLandQuestion? _currentQuestion;

  // Renkler
  static const Color _fairyPurple = Color(0xFF9C27B0);
  static const Color _fairyPink = Color(0xFFE1BEE7);
  static const Color _magicBlue = Color(0xFF81D4FA);
  static const Color _grassGreen = Color(0xFF8BC34A);
  static const Color _crystalCyan = Color(0xFF00E5FF);
  static const Color _earthBrown = Color(0xFF795548);

  // Nesne tanımları
  final Map<ObjectType, Map<String, dynamic>> _objectDefinitions = {
    // Çiçekler - Çimen Zemin
    ObjectType.daisy: {'emoji': '🌼', 'name': 'papatya', 'color': Color(0xFFFFEB3B)},
    ObjectType.tulip: {'emoji': '🌷', 'name': 'lale', 'color': Color(0xFFE91E63)},
    ObjectType.rose: {'emoji': '🌹', 'name': 'gül', 'color': Color(0xFFF44336)},
    ObjectType.sunflower: {'emoji': '🌻', 'name': 'ayçiçeği', 'color': Color(0xFFFFC107)},
    ObjectType.hibiscus: {'emoji': '🌺', 'name': 'hibiskus', 'color': Color(0xFFFF4081)},
    ObjectType.cherry: {'emoji': '🌸', 'name': 'kiraz çiçeği', 'color': Color(0xFFFFCDD2)},
    
    // Sihirli Nesneler - Kristal Zemin
    ObjectType.crystal: {'emoji': '💎', 'name': 'kristal', 'color': Color(0xFF00E5FF)},
    ObjectType.diamond: {'emoji': '💎', 'name': 'elmas', 'color': Color(0xFF2979FF)},
    ObjectType.orb: {'emoji': '🔮', 'name': 'sihirli küre', 'color': Color(0xFF9C27B0)},
    ObjectType.mushroom: {'emoji': '🍄', 'name': 'sihirli mantar', 'color': Color(0xFFFF5722)},
    ObjectType.star: {'emoji': '⭐', 'name': 'yıldız', 'color': Color(0xFFFFD700)},
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2), vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500), vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300), vsync: this,
    );

    _generateNewQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ============================================================================
  // SORU ÜRETİM MOTORU (QuestionGenerator)
  // ============================================================================

  void _generateNewQuestion() {
    final random = math.Random();
    final questionTypes = QuestionType.values;
    final selectedType = questionTypes[random.nextInt(questionTypes.length)];

    switch (selectedType) {
      case QuestionType.sameTypeCounting:
        _generateSameTypeCounting(random);
        break;
      case QuestionType.filteredCounting:
        _generateFilteredCounting(random);
        break;
      case QuestionType.generalCounting:
        _generateGeneralCounting(random);
        break;
      case QuestionType.additionSameType:
        _generateAdditionSameType(random);
        break;
      case QuestionType.subtractionSameType:
        _generateSubtractionSameType(random);
        break;
    }

    setState(() {
      _isAnswered = false;
      _isCorrect = false;
      _currentCount = 0;
      for (var obj in _objects) {
        obj.isCounted = false;
        obj.isWrong = false;
      }
    });
  }

  // SORU TİPİ 1: Tek Tür Sayma (Sadece aynı tür nesneler)
  void _generateSameTypeCounting(math.Random random) {
    // Rastgele bir tür seç
    final allTypes = ObjectType.values;
    final targetType = allTypes[random.nextInt(allTypes.length)];
    final count = 4 + random.nextInt(5); // 4-8 arası (daha kompakt)

    // Sadece bu türden nesneler oluştur
    _objects = [];
    for (int i = 0; i < count; i++) {
      final def = _objectDefinitions[targetType]!;
      _objects.add(GameObject(
        type: targetType,
        emoji: def['emoji'],
        name: def['name'],
        color: def['color'],
        id: i,
      ));
    }

    final def = _objectDefinitions[targetType]!;
    final isFlower = targetType == ObjectType.daisy || 
                     targetType == ObjectType.tulip || 
                     targetType == ObjectType.rose ||
                     targetType == ObjectType.sunflower ||
                     targetType == ObjectType.hibiscus ||
                     targetType == ObjectType.cherry;

    _currentQuestion = FairyLandQuestion(
      type: QuestionType.sameTypeCounting,
      questionText: 'Bahçede kaç tane ${def['name']} var? Say bakalım!',
      targetTypeName: def['name'],
      targetType: targetType,
      correctAnswer: count,
      options: _generateOptions(count, random),
      groundType: isFlower ? GroundType.grass : GroundType.crystal,
      feedbackMessage: 'Harika! Hepsini doğru saydın.',
    );
  }

  // SORU TİPİ 2: Filtreli Sayma (Karışık içinden spesifik)
  void _generateFilteredCounting(math.Random random) {
    // Hedef tür ve diğer türleri karıştır
    final allTypes = ObjectType.values.toList();
    final targetType = allTypes[random.nextInt(allTypes.length)];
    final targetCount = 3 + random.nextInt(3); // 3-5 hedef (daha kompakt)
    final otherCount = 3 + random.nextInt(3); // 3-5 diğer (daha kompakt)

    _objects = [];
    int id = 0;

    // Hedef türden nesneler
    for (int i = 0; i < targetCount; i++) {
      final def = _objectDefinitions[targetType]!;
      _objects.add(GameObject(
        type: targetType,
        emoji: def['emoji'],
        name: def['name'],
        color: def['color'],
        id: id++,
      ));
    }

    // Diğer türlerden nesneler (farklı türler)
    for (int i = 0; i < otherCount; i++) {
      ObjectType otherType;
      do {
        otherType = allTypes[random.nextInt(allTypes.length)];
      } while (otherType == targetType);

      final def = _objectDefinitions[otherType]!;
      _objects.add(GameObject(
        type: otherType,
        emoji: def['emoji'],
        name: def['name'],
        color: def['color'],
        id: id++,
      ));
    }

    // Karıştır
    _objects.shuffle(random);

    final def = _objectDefinitions[targetType]!;
    final isFlower = targetType == ObjectType.daisy || 
                     targetType == ObjectType.tulip || 
                     targetType == ObjectType.rose ||
                     targetType == ObjectType.sunflower ||
                     targetType == ObjectType.hibiscus ||
                     targetType == ObjectType.cherry;

    _currentQuestion = FairyLandQuestion(
      type: QuestionType.filteredCounting,
      questionText: 'Sadece ${def['name']} olanları say! Diğerlerine dokunma.',
      targetTypeName: def['name'],
      targetType: targetType,
      correctAnswer: targetCount,
      options: _generateOptions(targetCount, random),
      groundType: isFlower ? GroundType.grass : GroundType.crystal,
      feedbackMessage: 'Çok dikkatlisin! Sadece ${def['name']} olanları saydın.',
    );
  }

  // SORU TİPİ 3: Genel Sayma (Tümü)
  void _generateGeneralCounting(math.Random random) {
    final count = 6 + random.nextInt(5); // 6-10 arası (kompakt)
    final allTypes = ObjectType.values.toList();

    _objects = [];
    for (int i = 0; i < count; i++) {
      final type = allTypes[random.nextInt(allTypes.length)];
      final def = _objectDefinitions[type]!;
      _objects.add(GameObject(
        type: type,
        emoji: def['emoji'],
        name: def['name'],
        color: def['color'],
        id: i,
      ));
    }

    // Çoğunluk çiçek mi kristal mi kontrol et
    int flowerCount = _objects.where((o) => o.isFlower).length;
    final groundType = flowerCount > _objects.length / 2 ? GroundType.grass : GroundType.crystal;

    _currentQuestion = FairyLandQuestion(
      type: QuestionType.generalCounting,
      questionText: 'Bahçedeki tüm sihirli nesnelerin sayısı kaç?',
      targetTypeName: 'tüm nesneler',
      correctAnswer: count,
      options: _generateOptions(count, random),
      groundType: groundType,
      feedbackMessage: 'Harika! Hepsini saydın.',
    );
  }

  // SORU TİPİ 4: Toplama (Aynı tür)
  void _generateAdditionSameType(math.Random random) {
    final allTypes = ObjectType.values.toList();
    final targetType = allTypes[random.nextInt(allTypes.length)];
    final initialCount = 4 + random.nextInt(6); // 4-9
    final additionalCount = 2 + random.nextInt(4); // 2-5
    final totalCount = initialCount + additionalCount;

    // Sembolik gösterim: 1 nesne + ? (cevabı vermemek için)
    _objects = [];
    final def = _objectDefinitions[targetType]!;
    _objects.add(GameObject(
      type: targetType,
      emoji: def['emoji'],
      name: def['name'],
      color: def['color'],
      id: 0,
    ));

    final isFlower = targetType == ObjectType.daisy || 
                     targetType == ObjectType.tulip || 
                     targetType == ObjectType.rose ||
                     targetType == ObjectType.sunflower ||
                     targetType == ObjectType.hibiscus ||
                     targetType == ObjectType.cherry;

    _currentQuestion = FairyLandQuestion(
      type: QuestionType.additionSameType,
      questionText: 'Bahçede $initialCount tane ${def['name']} var. $additionalCount tane daha ekersek toplam kaç ${def['name']} olur?',
      targetTypeName: def['name'],
      targetType: targetType,
      correctAnswer: totalCount,
      options: _generateOptions(totalCount, random),
      groundType: isFlower ? GroundType.grass : GroundType.crystal,
      feedbackMessage: 'Süper! Toplam ${def['name']} sayısını buldun.',
    );
  }

  // SORU TİPİ 5: Eksiltme (Aynı tür)
  void _generateSubtractionSameType(math.Random random) {
    final allTypes = ObjectType.values.toList();
    final targetType = allTypes[random.nextInt(allTypes.length)];
    final initialCount = 6 + random.nextInt(6); // 6-11
    final removeCount = 2 + random.nextInt(4); // 2-5
    final remainingCount = initialCount - removeCount;

    // Sembolik gösterim: 1 nesne + ? (cevabı vermemek için)
    _objects = [];
    final def = _objectDefinitions[targetType]!;
    _objects.add(GameObject(
      type: targetType,
      emoji: def['emoji'],
      name: def['name'],
      color: def['color'],
      id: 0,
    ));
    final isFlower = targetType == ObjectType.daisy || 
                     targetType == ObjectType.tulip || 
                     targetType == ObjectType.rose ||
                     targetType == ObjectType.sunflower ||
                     targetType == ObjectType.hibiscus ||
                     targetType == ObjectType.cherry;

    _currentQuestion = FairyLandQuestion(
      type: QuestionType.subtractionSameType,
      questionText: '$initialCount tane ${def['name']} vardı. Periler $removeCount tanesini tozuna dönüştürdü. Geriye kaç ${def['name']} kaldı?',
      targetTypeName: def['name'],
      targetType: targetType,
      correctAnswer: remainingCount,
      options: _generateOptions(remainingCount, random),
      groundType: isFlower ? GroundType.grass : GroundType.crystal,
      feedbackMessage: 'Doğru! Perilerin tozuna dönüştürdükten sonra kalanları saydın.',
    );
  }

  List<int> _generateOptions(int correct, math.Random random) {
    final Set<int> opts = {correct};
    while (opts.length < 4) {
      int diff = random.nextInt(4) + 1;
      int opt = random.nextBool() ? correct + diff : correct - diff;
      if (opt >= 1 && opt <= 20 && opt != correct) {
        opts.add(opt);
      }
    }
    return opts.toList()..shuffle(random);
  }

  // ============================================================================
  // ETKİLEŞİM VE GERİ BİLDİRİM
  // ============================================================================

  void _onObjectTap(GameObject obj) {
    if (_isAnswered) return;

    final question = _currentQuestion!;

    // Filtreli sayma veya tek tür saymada yanlış türe dokunuldu mu?
    if ((question.type == QuestionType.filteredCounting ||
         question.type == QuestionType.sameTypeCounting) &&
        question.targetType != null &&
        obj.type != question.targetType) {
      // Yanlış tür! X göster
      setState(() {
        obj.isWrong = true;
        _shakeController.forward(from: 0).then((_) {
          setState(() => obj.isWrong = false);
        });
      });
      return;
    }

    // Doğru türden bir nesne - sadece say, cevap şıklardan seçilecek
    if (!obj.isCounted) {
      setState(() {
        obj.isCounted = true;
        _currentCount++;
      });
    }
  }

  void _checkAnswer(int answer) {
    if (_isAnswered) return;

    final isCorrect = answer == _currentQuestion!.correctAnswer;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;

      if (isCorrect) {
        _score += 10;
        _stars++;
        _celebrationController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _currentLevel++;
            _generateNewQuestion();
          }
        });
      } else {
        _lives = (_lives - 1).clamp(0, 5);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _generateNewQuestion();
        });
      }
    });
  }

  // ============================================================================
  // UI FONKSİYONLARI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Provider.of<LocaleProvider>(context, listen: true).locale);
    
    if (_currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Stack(
            children: [
              _buildAmbientEffects(),
              Column(
                children: [
                  _buildTopBar(loc),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCharacterMessage(loc),
                          const SizedBox(height: 8),
                          _buildLevelInfo(loc),
                          const SizedBox(height: 12),
                          _buildCentralPlayArea(),
                          const SizedBox(height: 12),
                          _buildAnswerSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isCorrect) _buildCelebration(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    final groundType = _currentQuestion!.groundType;
    
    if (groundType == GroundType.grass) {
      // Çimen/Toprak zemin - Çiçekler için
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _magicBlue,
            _grassGreen.withOpacity(0.7),
            _earthBrown.withOpacity(0.5),
          ],
        ),
      );
    } else {
      // Kristal/Mağara zemin - Sihirli nesneler için
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _magicBlue,
            _fairyPurple.withOpacity(0.6),
            _crystalCyan.withOpacity(0.4),
          ],
        ),
      );
    }
  }

  Widget _buildAmbientEffects() {
    return Stack(
      children: [
        // Uçan peri
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Positioned(
              top: 80 + math.sin(_pulseController.value * 2 * math.pi) * 20,
              right: 30,
              child: Opacity(
                opacity: 0.5,
                child: Text('🧚‍♀️', style: TextStyle(fontSize: 36 + _pulseAnimation.value * 4)),
              ),
            );
          },
        ),
        // Parıltılar
        ...List.generate(8, (index) {
          final random = math.Random(index);
          return Positioned(
            top: random.nextDouble() * 400,
            left: random.nextDouble() * 350,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + _pulseAnimation.value * 0.3,
                  child: const Text('✨', style: TextStyle(fontSize: 18)),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: _fairyPurple.withOpacity(0.5)),
              ),
              child: Icon(Icons.arrow_back, color: _fairyPurple, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧚 Periler Diyarı', style: _textStyle(_fairyPurple, size: 18, bold: true)),
                Text(_getGroundLabel(), style: _textStyle(Colors.white, size: 11)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Text(i < _lives ? '🧚' : '💨', style: const TextStyle(fontSize: 18)),
              );
            }),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('⭐ $_stars', style: _textStyle(Colors.white, size: 16, bold: true)),
          ),
        ],
      ),
    );
  }

  String _getGroundLabel() {
    final groundType = _currentQuestion!.groundType;
    return groundType == GroundType.grass ? '🌱 Sihirli Bahçe' : '💎 Kristal Mağara';
  }

  Widget _buildCharacterMessage(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _fairyPink.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: _fairyPurple, width: 2),
            ),
            child: const Center(child: Text('🧚‍♀️', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peri Prenses', style: _textStyle(_fairyPurple, size: 16, bold: true)),
                const SizedBox(height: 6),
                Text(
                  _currentQuestion!.questionText,
                  style: _textStyle(Colors.black87, size: 17),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Seviye', '$_currentLevel', '🎯'),
          _buildStatItem('Puan', '$_score', '⭐'),
          if (_currentQuestion!.type == QuestionType.filteredCounting ||
              _currentQuestion!.type == QuestionType.sameTypeCounting)
            _buildStatItem('Sayılan', '$_currentCount', '🔢'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        Text(value, style: _textStyle(_fairyPurple, size: 16, bold: true)),
        Text(label, style: _textStyle(_fairyPurple.withOpacity(0.8), size: 10)),
      ],
    );
  }

  // ============================================================================
  // MERKEZİ OYUN ALANI (Central Play Area)
  // ============================================================================

  Widget _buildCentralPlayArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = (constraints.maxWidth.isFinite && constraints.maxWidth > 0) 
            ? constraints.maxWidth - 8 
            : screenWidth - 56;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentQuestion!.groundType == GroundType.grass 
                      ? _grassGreen.withOpacity(0.3) 
                      : _crystalCyan.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentQuestion!.groundType == GroundType.grass ? '🌱 Çimen Zemin' : '💎 Kristal Zemin',
                  style: _textStyle(_fairyPurple, size: 11, bold: true),
                ),
              ),
              const SizedBox(height: 12),
              _buildObjectGrid(availableWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildObjectGrid(double availableWidth) {
    if (_objects.isEmpty) {
      return const SizedBox(height: 60, child: Center(child: Text('Yükleniyor...')));
    }
    const cellSize = 44.0;
    const spacing = 6.0;

    final isMathQuestion = _currentQuestion!.type == QuestionType.additionSameType ||
        _currentQuestion!.type == QuestionType.subtractionSameType;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: [
        ..._objects.map((obj) => SizedBox(
          width: cellSize,
          height: cellSize,
          child: _buildObjectItem(obj, isMathQuestion),
        )),
        if (isMathQuestion) SizedBox(
          width: cellSize,
          height: cellSize,
          child: _buildQuestionMarkCell(),
        ),
      ],
    );
  }

  Widget _buildQuestionMarkCell() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fairyPurple.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Text('?', style: _textStyle(_fairyPurple, size: 28, bold: true)),
      ),
    );
  }

  Widget _buildObjectItem(GameObject obj, [bool disableTap = false]) {
    return GestureDetector(
      onTap: disableTap ? null : () => _onObjectTap(obj),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: obj.isCounted 
              ? obj.color.withOpacity(0.35)
              : obj.isWrong
                  ? Colors.red.withOpacity(0.25)
                  : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: obj.isCounted
                ? obj.color
                : obj.isWrong
                    ? Colors.red
                    : Colors.grey.withOpacity(0.4),
            width: obj.isCounted || obj.isWrong ? 2.5 : 1,
          ),
          boxShadow: obj.isCounted
              ? [BoxShadow(color: obj.color.withOpacity(0.3), blurRadius: 4)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(obj.emoji, style: const TextStyle(fontSize: 24)),
            if (obj.isWrong)
              Positioned(
                top: 0,
                right: 0,
                child: Text('❌', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            if (obj.isCounted)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('✓', style: TextStyle(fontSize: 9, color: Colors.white))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CEVAP BÖLMESİ
  // ============================================================================

  Widget _buildAnswerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cevabını seç:',
            style: _textStyle(_fairyPurple, size: 13, bold: true),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _currentQuestion!.options.map((opt) => _buildOptionButton(opt)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int value) {
    final isCorrect = value == _currentQuestion!.correctAnswer;
    final isSelected = _isAnswered && isCorrect;

    Color buttonColor;
    if (_isAnswered) {
      buttonColor = isCorrect ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.2);
    } else {
      buttonColor = Colors.white.withOpacity(0.9);
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _checkAnswer(value),
      child: Container(
        width: 70,
        height: 52,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : _fairyPurple.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
        ),
        child: Center(
          child: Text('$value', style: _textStyle(_fairyPurple, size: 22, bold: true)),
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final centerX = screenWidth / 2;
        final centerY = screenHeight / 2;

        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(50, (index) {
                final random = math.Random(index);
                final angle = random.nextDouble() * 2 * math.pi;
                final speed = 0.3 + random.nextDouble() * 0.5;
                final progress = (_celebrationController.value * 1.2 - random.nextDouble() * 0.2).clamp(0.0, 1.0);
                final distance = progress * screenHeight * speed;
                final x = centerX + math.cos(angle) * distance;
                final y = centerY + math.sin(angle) * distance - progress * 100;

                return Positioned(
                  left: x - 20,
                  top: y - 20,
                  child: Opacity(
                    opacity: (1.0 - progress).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: progress * 8 * math.pi,
                      child: Transform.scale(
                        scale: 0.8 + random.nextDouble() * 0.6,
                        child: Text(
                          ['🧚‍♀️', '🧚', '✨', '⭐', '🌸', '💫', '🦋', '💎'][random.nextInt(8)],
                          style: TextStyle(fontSize: 22.0 + random.nextDouble() * 16),
                        ),
                      ),
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

  static TextStyle _textStyle(Color color, {double size = 16, bool bold = false}) =>
      GoogleFonts.quicksand(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.w500);
}
