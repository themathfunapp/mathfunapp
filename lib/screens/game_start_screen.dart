import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import 'topic_selection_screen.dart';
import 'math_regions_screen.dart';
import 'quick_math_screen.dart';
import 'endless_mode_screen.dart';
import 'daily_challenge_screen.dart';
import 'boss_battle_screen.dart';
import 'live_duel_screen.dart';
import '../models/game_mechanics.dart';
import 'discover_screen.dart';
import 'colorful_math_screen.dart';
import 'intelligence_games_screen.dart';
import 'package:mathfun/services/game_mechanics_service.dart';

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

  // Varsayılan yaş grubu (arka planda kullanılır, seçim ekranı yok)
  AgeGroupSelection _selectedAgeGroup = AgeGroupSelection.elementary;
  bool _showContent = true;

  // Game Mechanics Service
  late GameMechanicsService _mechanicsService;
  bool _isLoading = true;

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

    // GameMechanicsService başlat
    _mechanicsService = GameMechanicsService();
    _initializeMechanics();

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

  Future<void> _initializeMechanics() async {
    // Gerçek uygulamada kullanıcı ID'si authentication'dan alınacak
    await _mechanicsService.initialize('current_user_id');
    setState(() {
      _isLoading = false;
    });
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

  // Can bilgisini formatlamak için yardımcı metod
  String _getLivesDisplay() {
    final lives = _mechanicsService.livesSystem.currentLives;
    return '❤️' * lives + '🖤' * (3 - lives);
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Stack(
                  children: [
                    // Arka plan parçacıkları
                    ..._buildBackgroundParticles(),

                    // Ana içerik
                    Column(
                      children: [
                        // Üst bar
                        _buildTopBar(localizations),

                        // İçerik (yaş grubu seçimi olmadan doğrudan ana sayfa)
                        Expanded(
                          child: _buildGameModeContent(localizations),
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
            onTap: widget.onBack,
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
          Text(
            localizations.get('app_name'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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

        // TODO: Yayın sonrası güncellemede eklenecek (6-7 ay sonra)
        // Öğrenme Hedefi Seçimi
        // - Okul Destek (🎯)
        // - Yetenek Geliştir (🌟)
        // - Eğlence Modu (😊)
        // _buildLearningGoalSection(localizations),

        const SizedBox(height: 20),
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

  // Hızlı Başlangıç bölümü - CAN EKLENDİ
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
            // Günün Görevi - 3 CAN EKLENDİ
            // Günün Görevi kartı (can göstergesi olmadan)
            Expanded(
              child: _buildQuickStartCard(
                emoji: '🎯',
                title: localizations.get('daily_challenge'),
                subtitle: localizations.get('surprise_reward'),
                color: const Color(0xFF4ECDC4),
                onTap: () => _startQuickGame('daily'),
                // showLives: true,    → kaldırıldı
                // livesCount: _mechanicsService.livesSystem.currentLives,  → kaldırıldı
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
                title: localizations.get('endless_mode'),
                subtitle: localizations.get('endless_mode_subtitle'),
                color: const Color(0xFF8E44AD),
                onTap: () => _startQuickGame('endless'),
              ),
            ),
            const SizedBox(width: 12),
            // Boss Savaşı
            Expanded(
              child: _buildQuickStartCard(
                emoji: '👾',
                title: localizations.get('boss_battle'),
                subtitle: localizations.get('boss_battle_subtitle'),
                color: const Color(0xFFE74C3C),
                onTap: () => _startQuickGame('boss'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Arkadaşla Yarış (tam genişlik)
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

  // Hızlı Başlangıç Kartı - CAN GÖSTERGESİ EKLENDİ
  Widget _buildQuickStartCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isWide = false,
    // showLives ve livesCount parametreleri artık kullanılmıyor, kaldırılabilir
    // bool showLives = false,
    // int livesCount = 3,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              height: isWide ? 80 : 118,
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
                  // Emoji
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),

                  // Başlık ve alt başlık (can kısmı tamamen kaldırıldı)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Play butonu
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
                    _buildRegionIcon('🧑‍🌾', localizations.get('keloglan_village')),
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
                  localizations.get('newly_developed'),
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

        // Keşfet kartları - sadece aktif özellikler
        Row(
          children: [
            _buildDiscoverCard(
              emoji: '🧩',
              title: localizations.get('intelligence_games'),
              subtitle: localizations.get('brain_games'),
              color: const Color(0xFF00CEC9),
              onTap: () => _openDiscoverItem('intelligence_games'),
              isPremium: true,
            ),
            const SizedBox(width: 12),
            _buildDiscoverCard(
              emoji: '🎨',
              title: localizations.get('colorful_math'),
              subtitle: localizations.get('fun_design'),
              color: const Color(0xFF74B9FF),
              onTap: () => _openDiscoverItem('colorful_math'),
              isPremium: true,
            ),
          ],
        ),

        // TODO: Yayın sonrası güncellemede eklenecek özellikler (6-7 ay sonra)
        // - Zaman Atölyesi (🎭)
        // - Hesap Makinesi (🧮)
        // - İstatistik (📊)
        // - Başarılar (🏆)
      ],
    );
  }

  Widget _buildDiscoverCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLocked = isPremium && !authService.isPremium;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Premium badge - sağ üst köşe
            if (isLocked)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('👑', style: TextStyle(fontSize: 10)),
                      SizedBox(width: 2),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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

    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: false);
    if (!mechanicsService.hasLives) {
      _showNoLivesDialog();
      return;
    }

    switch (type) {
      case 'instant':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuickMathScreen(
              gameType: type,
              ageGroup: _selectedAgeGroup,
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
              // initialLives parametresini KALDIRDIM
            ),
          ),
        );
        break;
      case 'endless':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EndlessModeScreen(
              ageGroup: _selectedAgeGroup,
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
              ageGroup: _selectedAgeGroup,
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
              ageGroup: _selectedAgeGroup,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
    }
  }

  void _showNoLivesDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.favorite_border, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Text(loc.get('lives_finished')),
          ],
        ),
        content: Text(
          '${loc.get('no_lives_play')}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('ok')),
          ),
        ],
      ),
    );
  }

  void _showBossSelection() {
    final bosses = BossBattle.allBosses;
    final loc = AppLocalizations.of(context);

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
            Text(
              '👾 ${loc.get('select_boss')} 👾',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: bosses.map((boss) => _buildBossItem(boss, loc)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBossItem(BossBattle boss, AppLocalizations loc) {
    final bossNameKey = 'boss_${boss.id}';
    final difficultyKey = 'difficulty_${boss.difficulty}';
    final bossName = loc.get(bossNameKey);
    final difficultyLabel = loc.get(difficultyKey);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BossBattleScreen(
              boss: boss,
              ageGroup: _selectedAgeGroup,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Text(boss.emoji, style: const TextStyle(fontSize: 35)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bossName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${loc.get('difficulty')}: $difficultyLabel',
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

  void _startTopicGame(String topic) {
    debugPrint('Starting topic game: $topic');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicSelectionScreen(
          ageGroup: _selectedAgeGroup,
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
          ageGroup: _selectedAgeGroup,
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
          ageGroup: _selectedAgeGroup,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openDiscoverScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscoverScreen(
          ageGroup: _selectedAgeGroup,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openDiscoverItem(String itemKey) {
    debugPrint('Opening discover item: $itemKey');

    final authService = Provider.of<AuthService>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations(localeProvider.locale);
    
    // Premium kontrol gerektiren özellikler
    const premiumFeatures = ['intelligence_games', 'colorful_math'];
    
    if (premiumFeatures.contains(itemKey) && !authService.isPremium) {
      _showPremiumRequiredDialog(localizations.get(itemKey));
      return;
    }

    if (itemKey == 'colorful_math') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ColorfulMathScreen(
            ageGroup: _selectedAgeGroup.toString().split('.').last,
          ),
        ),
      );
      return;
    }

    if (itemKey == 'intelligence_games') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IntelligenceGamesScreen(
            ageGroup: _selectedAgeGroup.toString().split('.').last,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.get('feature_coming_soon').replaceAll('{name}', localizations.get(itemKey))),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Premium gerektiren özellik için dialog
  void _showPremiumRequiredDialog(String featureName) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations(localeProvider.locale);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.get('premium_feature'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    featureName,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.get('premium_exclusive_message'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '✨ ${localizations.get('premium_access_message')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.get('close'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPremiumScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF8B4513),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👑', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  localizations.get('upgrade_to_premium'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Premium ekranına yönlendir
  void _navigateToPremiumScreen() {
    // TODO: Premium satın alma ekranına yönlendir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Premium üyelik yakında aktif olacak! 👑'),
        backgroundColor: Colors.amber.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openRegion(String region) {
    debugPrint('Opening region: $region');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathRegionsScreen(
          ageGroup: _selectedAgeGroup,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _selectGoal(String goal) {
    debugPrint('Selected goal: $goal');
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