import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import 'topic_selection_screen.dart';
import 'math_regions_screen.dart';
import 'quick_math_screen.dart';
import 'endless_mode_screen.dart';
import 'daily_challenge_screen.dart';
import 'boss_battle_screen.dart';
import 'live_duel_screen.dart';
import '../models/game_mechanics.dart';
import 'discover_screen.dart'; // YENİ EKLENDİ

/// Yaş grupları enum
enum AgeGroupSelection {
  preschool, // 3-5
  elementary, // 6-8
  advanced, // 9-11
}

/// Oyun Başlangıç Ekranı
/// Yaş seçimi, hızlı başlangıç ve konu seçimi içerir
class GameStartScreen extends StatefulWidget {
  final VoidCallback onBack;

  const GameStartScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<GameStartScreen> createState() => _GameStartScreenState();
}

class _GameStartScreenState extends State<GameStartScreen>
    with TickerProviderStateMixin {
  // Animasyon kontrolcüleri
  late AnimationController _doorController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _characterController;

  // Animasyonlar
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  // Seçili yaş grubu
  AgeGroupSelection? _selectedAgeGroup;
  bool _showContent = false;

  // Günlük karşılama mesajları
  final List<String> _dailyMessages = [
    "Bugün matematikle neler keşfedeceğiz? 🔍",
    "Matematik süper kahramanı hazır mısın? 🦸",
    "Sayı canavarları seni bekliyor! 👾",
    "Geometri diyarında macera başlıyor! 🔺",
    "Matematiğin sihirli dünyasına hoş geldin! ✨",
    "Bugün yıldızlar toplamaya hazır mısın? ⭐",
    "Yeni matematik maceraları seni bekliyor! 🚀",
  ];

  String _currentMessage = "";

  @override
  void initState() {
    super.initState();

    // Rastgele karşılama mesajı
    _currentMessage =
    _dailyMessages[math.Random().nextInt(_dailyMessages.length)];

    // Kapı animasyonu
    _doorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Yüzen animasyon (karakterler için)
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Nabız animasyonu (butonlar için)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Karakter animasyonu
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _doorController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _selectAgeGroup(AgeGroupSelection age) {
    setState(() {
      _selectedAgeGroup = age;
    });

    // Kapı animasyonunu başlat
    _doorController.forward().then((_) {
      _characterController.forward().then((_) {
        setState(() {
          _showContent = true;
        });
      });
    });
  }

  void _resetSelection() {
    setState(() {
      _showContent = false;
      _selectedAgeGroup = null;
    });
    _doorController.reverse();
    _characterController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B8DD6),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Arka plan parçacıkları
              ..._buildBackgroundParticles(),

              // Ana içerik
              Column(
                children: [
                  // Üst bar
                  _buildTopBar(localizations),

                  // İçerik
                  Expanded(
                    child: _showContent
                        ? _buildGameModeContent(localizations)
                        : _buildAgeSelection(localizations),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Arka plan parçacıkları
  List<Widget> _buildBackgroundParticles() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      final size = random.nextDouble() * 30 + 10;
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;
      final opacity = random.nextDouble() * 0.3 + 0.1;
      final symbols = ['➕', '➖', '✖️', '➗', '🔢', '⭐', '💫'];
      final symbol = symbols[random.nextInt(symbols.length)];

      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value * (index % 3 + 1)),
              child: Opacity(
                opacity: opacity,
                child: Text(
                  symbol,
                  style: TextStyle(fontSize: size),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // Üst bar
  Widget _buildTopBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: _showContent ? _resetSelection : widget.onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const Spacer(),

          // Başlık
          Column(
            children: [
              Text(
                _showContent
                    ? _getAgeGroupTitle(localizations)
                    : localizations.get('select_age_group'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_showContent)
                Text(
                  _getAgeGroupSubtitle(localizations),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Boşluk için
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Yaş seçimi ekranı
  Widget _buildAgeSelection(AppLocalizations localizations) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Karşılama mesajı
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🧙‍♂️', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        // Yaş grupları kapıları
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 3-5 Yaş
                Expanded(
                  child: _buildAgeDoor(
                    emoji: '🐣',
                    title: localizations.get('age_3_5'),
                    subtitle: localizations.get('age_preschool'),
                    color: const Color(0xFFFF6B6B),
                    age: AgeGroupSelection.preschool,
                  ),
                ),
                const SizedBox(width: 12),

                // 6-8 Yaş
                Expanded(
                  child: _buildAgeDoor(
                    emoji: '🚀',
                    title: localizations.get('age_6_8'),
                    subtitle: localizations.get('age_elementary'),
                    color: const Color(0xFF4ECDC4),
                    age: AgeGroupSelection.elementary,
                  ),
                ),
                const SizedBox(width: 12),

                // 9-11 Yaş
                Expanded(
                  child: _buildAgeDoor(
                    emoji: '🏰',
                    title: localizations.get('age_9_11'),
                    subtitle: localizations.get('age_advanced'),
                    color: const Color(0xFF9B59B6),
                    age: AgeGroupSelection.advanced,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Alt bilgi
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            localizations.get('tap_door_to_enter'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Yaş kapısı widget'ı
  Widget _buildAgeDoor({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required AgeGroupSelection age,
  }) {
    final isSelected = _selectedAgeGroup == age;

    return GestureDetector(
      onTap: () => _selectAgeGroup(age),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? 1.0 : _pulseAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.9),
                    color.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kapı simgesi
                  Container(
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 4),
                        // Kapı kolu
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Yaş başlığı
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Alt başlık
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Yıldızlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      age == AgeGroupSelection.preschool
                          ? 1
                          : age == AgeGroupSelection.elementary
                          ? 2
                          : 3,
                          (index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.star, color: Colors.amber, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Oyun modu içeriği (yaş seçildikten sonra)
  Widget _buildGameModeContent(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Karakter karşılama
        _buildCharacterGreeting(localizations),

        const SizedBox(height: 24),

        // Hızlı Başlangıç bölümü
        _buildQuickStartSection(localizations),

        const SizedBox(height: 24),

        // Konu Seçimi bölümü
        _buildTopicSelectionSection(localizations),

        const SizedBox(height: 24),

        // Matematik Bölgeleri
        _buildMathRegionsSection(localizations),

        const SizedBox(height: 24),

        // YENİ GELİŞTİR/KEŞFET BÖLÜMÜ
        _buildDiscoverSection(localizations),

        const SizedBox(height: 24),

        // Öğrenme Hedefi Seçimi
        _buildLearningGoalSection(localizations),

        const SizedBox(height: 40),
      ],
    );
  }

  // Karakter karşılama
  Widget _buildCharacterGreeting(AppLocalizations localizations) {
    final characters = {
      AgeGroupSelection.preschool: {
        'emoji': '🧚',
        'name': localizations.get('char_fairy'),
        'message': localizations.get('char_fairy_msg'),
      },
      AgeGroupSelection.elementary: {
        'emoji': '🦸',
        'name': localizations.get('char_hero'),
        'message': localizations.get('char_hero_msg'),
      },
      AgeGroupSelection.advanced: {
        'emoji': '🧙‍♂️',
        'name': localizations.get('char_wizard'),
        'message': localizations.get('char_wizard_msg'),
      },
    };

    final char = characters[_selectedAgeGroup]!;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Karakter
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      char['emoji']!,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        char['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        char['message']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hızlı Başlangıç bölümü
  Widget _buildQuickStartSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              localizations.get('quick_start'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // İlk satır
        Row(
          children: [
            // Anında Matematik
            Expanded(
              child: _buildQuickStartCard(
                emoji: '⚡',
                title: localizations.get('instant_math'),
                subtitle: localizations.get('random_5_questions'),
                color: const Color(0xFFFF6B6B),
                onTap: () => _startQuickGame('instant'),
              ),
            ),
            const SizedBox(width: 12),
            // Günün Görevi
            Expanded(
              child: _buildQuickStartCard(
                emoji: '🎯',
                title: localizations.get('daily_challenge'),
                subtitle: localizations.get('surprise_reward'),
                color: const Color(0xFF4ECDC4),
                onTap: () => _startQuickGame('daily'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // İkinci satır - Yeni modlar
        Row(
          children: [
            // Sonsuz Mod
            Expanded(
              child: _buildQuickStartCard(
                emoji: '♾️',
                title: 'Sonsuz Mod',
                subtitle: 'Yanlış yapana kadar',
                color: const Color(0xFF8E44AD),
                onTap: () => _startQuickGame('endless'),
              ),
            ),
            const SizedBox(width: 12),
            // Boss Savaşı
            Expanded(
              child: _buildQuickStartCard(
                emoji: '👾',
                title: 'Boss Savaşı',
                subtitle: 'Canavarları yen',
                color: const Color(0xFFE74C3C),
                onTap: () => _startQuickGame('boss'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Arkadaşlı Yarış (tam genişlik)
        _buildQuickStartCard(
          emoji: '👥',
          title: localizations.get('friend_race'),
          subtitle: localizations.get('math_duel'),
          color: const Color(0xFF9B59B6),
          onTap: () => _startQuickGame('friend'),
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildQuickStartCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              height: isWide ? 70 : 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Konu Seçimi bölümü
  Widget _buildTopicSelectionSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  localizations.get('topic_selection'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _openTopicSelection(),
              child: Text(
                localizations.get('see_all'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTopicCard(
                emoji: '➕',
                title: localizations.get('addition'),
                stars: 1,
                color: const Color(0xFF2ECC71),
              ),
              _buildTopicCard(
                emoji: '➖',
                title: localizations.get('subtraction'),
                stars: 1,
                color: const Color(0xFFE74C3C),
              ),
              _buildTopicCard(
                emoji: '✖️',
                title: localizations.get('multiplication'),
                stars: 2,
                color: const Color(0xFF3498DB),
              ),
              _buildTopicCard(
                emoji: '➗',
                title: localizations.get('division'),
                stars: 2,
                color: const Color(0xFF9B59B6),
              ),
              _buildTopicCard(
                emoji: '🔺',
                title: localizations.get('geometry'),
                stars: 2,
                color: const Color(0xFFE67E22),
              ),
              _buildTopicCard(
                emoji: '½',
                title: localizations.get('fractions'),
                stars: 3,
                color: const Color(0xFF1ABC9C),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard({
    required String emoji,
    required String title,
    required int stars,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _startTopicGame(title),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                    (index) => Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Matematik Bölgeleri
  Widget _buildMathRegionsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.map, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  localizations.get('math_regions'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _openMathRegions(),
              child: Text(
                localizations.get('explore'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.blue.shade400,
                Colors.purple.shade400,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Arka plan deseni
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                  ),
                ),
              ),

              // Bölge ikonları
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRegionIcon('🌲', localizations.get('number_forest')),
                    _buildRegionIcon('🔢', localizations.get('digit_river')),
                    _buildRegionIcon('🔺', localizations.get('geometry_mountain')),
                    _buildRegionIcon('🕰', localizations.get('time_island')),
                  ],
                ),
              ),

              // Keşfet butonu
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _openMathRegions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          localizations.get('explore_map'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF764ba2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Color(0xFF764ba2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // YENİ GELİŞTİR/KEŞFET BÖLÜMÜ
  Widget _buildDiscoverSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Yeni Geliştir',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _openDiscoverScreen,
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // İlk satır - 3 öğe
        Row(
          children: [
            _buildDiscoverCard(
              emoji: '🧩',
              title: 'Zeka Oyunları',
              subtitle: 'Akıl oyunları',
              color: const Color(0xFF00CEC9),
              onTap: () => _openDiscoverItem('Zeka Oyunları'),
            ),
            const SizedBox(width: 12),
            _buildDiscoverCard(
              emoji: '🎭',
              title: 'Zaman Atölyesi',
              subtitle: 'Zaman kavramı',
              color: const Color(0xFFA29BFE),
              onTap: () => _openDiscoverItem('Zaman Atölyesi'),
            ),
            const SizedBox(width: 12),
            _buildDiscoverCard(
              emoji: '🧮',
              title: 'Hesap Makinesi',
              subtitle: 'Pratik yap',
              color: const Color(0xFFFD79A8),
              onTap: () => _openDiscoverItem('Hesap Makinesi'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // İkinci satır - 3 öğe
        Row(
          children: [
            _buildDiscoverCard(
              emoji: '📊',
              title: 'İstatistik',
              subtitle: 'Gelişim grafiği',
              color: const Color(0xFFFDCB6E),
              onTap: () => _openDiscoverItem('İstatistik'),
            ),
            const SizedBox(width: 12),
            _buildDiscoverCard(
              emoji: '🎨',
              title: 'Renkli Matematik',
              subtitle: 'Eğlenceli tasarım',
              color: const Color(0xFF74B9FF),
              onTap: () => _openDiscoverItem('Renkli Matematik'),
            ),
            const SizedBox(width: 12),
            _buildDiscoverCard(
              emoji: '🏆',
              title: 'Başarılar',
              subtitle: 'Rozet koleksiyonu',
              color: const Color(0xFF55EFC4),
              onTap: () => _openDiscoverItem('Başarılar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscoverCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionIcon(String emoji, String name) {
    return GestureDetector(
      onTap: () => _openRegion(name),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Öğrenme Hedefi Seçimi
  Widget _buildLearningGoalSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              localizations.get('learning_goal'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGoalCard(
                emoji: '🎯',
                title: localizations.get('school_support'),
                color: const Color(0xFF3498DB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGoalCard(
                emoji: '🌟',
                title: localizations.get('skill_develop'),
                color: const Color(0xFFE67E22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGoalCard(
                emoji: '😊',
                title: localizations.get('fun_mode'),
                color: const Color(0xFF2ECC71),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalCard({
    required String emoji,
    required String title,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _selectGoal(title),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Yardımcı methodlar
  String _getAgeGroupTitle(AppLocalizations localizations) {
    switch (_selectedAgeGroup) {
      case AgeGroupSelection.preschool:
        return localizations.get('age_3_5');
      case AgeGroupSelection.elementary:
        return localizations.get('age_6_8');
      case AgeGroupSelection.advanced:
        return localizations.get('age_9_11');
      default:
        return '';
    }
  }

  String _getAgeGroupSubtitle(AppLocalizations localizations) {
    switch (_selectedAgeGroup) {
      case AgeGroupSelection.preschool:
        return localizations.get('age_preschool');
      case AgeGroupSelection.elementary:
        return localizations.get('age_elementary');
      case AgeGroupSelection.advanced:
        return localizations.get('age_advanced');
      default:
        return '';
    }
  }

  void _startQuickGame(String type) {
    debugPrint('Starting quick game: $type');

    switch (type) {
      case 'instant':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuickMathScreen(
              gameType: type,
              ageGroup: _selectedAgeGroup!,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
        break;
      case 'daily':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyChallengeScreen(
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
        break;
      case 'endless':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EndlessModeScreen(
              ageGroup: _selectedAgeGroup!,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
        break;
      case 'boss':
        _showBossSelection();
        break;
      case 'friend':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveDuelScreen(
              ageGroup: _selectedAgeGroup!,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuickMathScreen(
              gameType: type,
              ageGroup: _selectedAgeGroup!,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
    }
  }

  void _showBossSelection() {
    final bosses = BossBattle.allBosses;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '👾 BOSS SEÇ 👾',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ...bosses.map((boss) => _buildBossItem(boss)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBossItem(BossBattle boss) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BossBattleScreen(
              boss: boss,
              ageGroup: _selectedAgeGroup!,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Text(boss.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boss.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Zorluk: ${boss.difficulty.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${boss.health}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${boss.rewardCoins}',
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // DÜZELTİLDİ: Artık TopicSelectionScreen'e gidiyor
  void _startTopicGame(String topic) {
    debugPrint('Starting topic game: $topic');

    // TopicSelectionScreen'e git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicSelectionScreen(
          ageGroup: _selectedAgeGroup!,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openTopicSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicSelectionScreen(
          ageGroup: _selectedAgeGroup!,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openMathRegions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathRegionsScreen(
          ageGroup: _selectedAgeGroup!,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // YENİ EKLENDİ: Keşfet ekranını aç
  void _openDiscoverScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscoverScreen(
          ageGroup: _selectedAgeGroup!,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // YENİ EKLENDİ: Keşfet öğesini aç
  void _openDiscoverItem(String itemName) {
    debugPrint('Opening discover item: $itemName');

    // Şimdilik snackbar göster, daha sonra gerçek ekranlar eklenebilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName özelliği yakında eklenecek!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Veya direkt DiscoverScreen'e git
    // _openDiscoverScreen();
  }

  // DÜZELTİLDİ: Artık MathRegionsScreen'e gidiyor
  void _openRegion(String region) {
    debugPrint('Opening region: $region');

    // Bölgeye özel bir ekran yoksa, genel MathRegionsScreen'e git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathRegionsScreen(
          ageGroup: _selectedAgeGroup!,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _selectGoal(String goal) {
    debugPrint('Selected goal: $goal');
    // TODO: Implement goal selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$goal hedefi seçildi!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Harita deseni painter
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Yatay çizgiler
    for (int i = 0; i < 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dikey çizgiler
    for (int i = 0; i < 15; i++) {
      final x = size.width * i / 15;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Dalgalı yol
    final pathPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(0, size.height / 2);
    for (int i = 0; i < 5; i++) {
      final x1 = size.width * (i * 2 + 1) / 10;
      final x2 = size.width * (i * 2 + 2) / 10;
      final y1 = size.height * (i % 2 == 0 ? 0.3 : 0.7);
      final y2 = size.height * (i % 2 == 0 ? 0.7 : 0.3);
      path.quadraticBezierTo(x1, y1, x2, y2);
    }
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}