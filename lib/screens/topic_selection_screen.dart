import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../localization/app_localizations.dart';
import '../models/game_mechanics.dart' as GameMechanics;
import 'game_start_screen.dart' as GameMechanics;
import 'specialized_game_screen.dart';
import 'game_start_screen.dart';

/// Konu Seçimi Ekranı - Çocuklara Özel Tasarım
class TopicSelectionScreen extends StatefulWidget {
  final GameMechanics.AgeGroupSelection ageGroup;
  final VoidCallback onBack;

  const TopicSelectionScreen({
    super.key,
    required this.ageGroup,
    required this.onBack,
  });

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _characterController;
  late AnimationController _floatController;
  late AnimationController _particleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _particleAnimation;

  GameMechanics.PlayerInventory _inventory = GameMechanics.PlayerInventory();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  // Yaşa göre karakter ve tema
  Map<String, dynamic> get _ageTheme {
    switch (widget.ageGroup) {
      case GameMechanics.AgeGroupSelection.preschool:
        return {
          'character': '🐣',
          'characterName': 'Sayı Civciv',
          'bgColor': const Color(0xFFFFF9C4),
          'accentColor': const Color(0xFFFF9800),
          'particleColor': const Color(0xFFFFB74D),
        };
      case GameMechanics.AgeGroupSelection.elementary:
        return {
          'character': '🚀',
          'characterName': 'Roket Uzmanı',
          'bgColor': const Color(0xFFE3F2FD),
          'accentColor': const Color(0xFF2196F3),
          'particleColor': const Color(0xFF64B5F6),
        };
      case GameMechanics.AgeGroupSelection.advanced:
        return {
          'character': '🧙‍♂️',
          'characterName': 'Matematik Büyücüsü',
          'bgColor': const Color(0xFFEDE7F6),
          'accentColor': const Color(0xFF673AB7),
          'particleColor': const Color(0xFF9575CD),
        };
      default:
        return {
          'character': '🌟',
          'characterName': 'Matematik Yıldızı',
          'bgColor': const Color(0xFFF3E5F5),
          'accentColor': const Color(0xFF9C27B0),
          'particleColor': const Color(0xFFCE93D8),
        };
    }
  }

  @override
  void initState() {
    super.initState();

    // Arka plan animasyonu
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Karakter animasyonu
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Yüzen animasyon
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Parçacık animasyonu
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _particleAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Sayfa değişimini dinle
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _characterController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final topics = _getTopicsForAge(widget.ageGroup, localizations);
    final theme = _ageTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme['bgColor'] as Color,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar - Çocuk dostu
              _buildKidFriendlyTopBar(localizations, theme),

              // Karakter ve başlık
              _buildCharacterSection(localizations, theme),

              // Kaydırılabilir konu kartları
              Expanded(
                child: _buildTopicCarousel(topics, theme),
              ),

              // Alt navigasyon
              _buildBottomNavigation(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKidFriendlyTopBar(AppLocalizations localizations, Map<String, dynamic> theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme['accentColor'] as Color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: (theme['accentColor'] as Color).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Geri butonu - Çocuk dostu tasarım
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.orange,
                size: 24,
              ),
            ),
          ),

          const Spacer(),

          // Ana başlık - Büyük ve renkli
          Column(
            children: [
              Text(
                localizations.get('choose_topic'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              Text(
                localizations.get('select_topic_to_practice'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Envanter gösterimi
          Row(
            children: [
              _buildInventoryBubble(
                icon: Icons.favorite,
                count: _inventory.lives,
                color: Colors.red,
                theme: theme,
              ),
              const SizedBox(width: 6),
              _buildInventoryBubble(
                icon: Icons.attach_money,
                count: _inventory.coins,
                color: Colors.amber,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryBubble({
    required IconData icon,
    required int count,
    required Color color,
    required Map<String, dynamic> theme,
  }) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (theme['accentColor'] as Color).withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSection(AppLocalizations localizations, Map<String, dynamic> theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          // Karakter animasyonu
          AnimatedBuilder(
            animation: _characterController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _characterController.value * 5),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (theme['accentColor'] as Color).withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      theme['character'] as String,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 15),

          // Karakter konuşması
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme['characterName'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme['accentColor'] as Color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hangi konuda pratik yapmak istiyorsun?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCarousel(List<Map<String, dynamic>> topics, Map<String, dynamic> theme) {
    return Column(
      children: [
        // Parçacık efekti
        SizedBox(
          height: 30,
          child: AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  animationValue: _particleAnimation.value,
                  color: theme['particleColor'] as Color,
                ),
              );
            },
          ),
        ),

        // Konu kartları
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: topics.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return _buildTopicCard(topic: topic, index: index, theme: theme);
                },
              ),
              
              // Sol ok butonu
              if (_currentPage > 0)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: theme['accentColor'] as Color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Sağ ok butonu
              if (_currentPage < topics.length - 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: theme['accentColor'] as Color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Sayfa göstergesi
        _buildPageIndicator(topics.length),
      ],
    );
  }

  Widget _buildTopicCard({
    required Map<String, dynamic> topic,
    required int index,
    required Map<String, dynamic> theme,
  }) {
    final isLocked = topic['locked'] == true;

    return GestureDetector(
      onTap: () {}, // Boş onTap - kartı tıklanabilir yap ama hiçbir şey yapma
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: (topic['color'] as Color).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Arka plan deseni
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: CustomPaint(
                    painter: _PatternPainter(color: (topic['color'] as Color).withOpacity(0.1)),
                  ),
                ),
              ),
            ),

            // İçerik
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Emoji ve başlık
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              topic['color'] as Color,
                              (topic['color'] as Color).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (topic['color'] as Color).withOpacity(0.4),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            topic['emoji'] as String,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        topic['title'] as String,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: topic['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Zorluk yıldızları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                          (starIndex) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          starIndex < (topic['stars'] as int)
                              ? Icons.star
                              : Icons.star_border,
                          color: starIndex < (topic['stars'] as int)
                              ? Colors.amber
                              : Colors.grey[300],
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Başla butonu
                  if (!isLocked)
                    Container(
                      width: double.infinity,
                      height: 50,
                      margin: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: () => _selectTopic(topic),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: topic['color'] as Color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: (topic['color'] as Color).withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'OYNA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.play_arrow, size: 20),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Kilit ikonu
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'KİLİTLİ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${topic['unlockLevel'] ?? 5}. seviyede açılacak',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Container(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: index == _currentPage ? 30 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == _currentPage
                  ? _ageTheme['accentColor'] as Color
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigation(Map<String, dynamic> theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Yardım butonu
          _buildBottomButton(
            icon: Icons.help_outline,
            label: 'Yardım',
            color: Colors.blue,
            onTap: () => _showHelpDialog(),
          ),

          // Güçlendirme butonu
          _buildBottomButton(
            icon: Icons.flash_on,
            label: 'Güçler',
            color: Colors.purple,
            onTap: () => _showPowerUps(),
          ),

          // Seviye seçimi butonu
          _buildBottomButton(
            icon: Icons.school,
            label: 'Seviye',
            color: Colors.green,
            onTap: () => _showLevelSelection(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTopicsForAge(
      GameMechanics.AgeGroupSelection age,
      AppLocalizations localizations,
      ) {
    final baseTopics = [
      {
        'id': 'counting',
        'emoji': '🔢',
        'title': localizations.get('counting'),
        'subtitle': localizations.get('learn_numbers'),
        'color': const Color(0xFF2ECC71),
        'stars': 1,
        'locked': false,
      },
      {
        'id': 'addition',
        'emoji': '➕',
        'title': localizations.get('addition'),
        'subtitle': localizations.get('add_numbers'),
        'color': const Color(0xFF3498DB),
        'stars': 1,
        'locked': false,
      },
      {
        'id': 'subtraction',
        'emoji': '➖',
        'title': localizations.get('subtraction'),
        'subtitle': localizations.get('subtract_numbers'),
        'color': const Color(0xFFE74C3C),
        'stars': 1,
        'locked': false,
      },
      {
        'id': 'shapes',
        'emoji': '🔺',
        'title': 'Geometri',
        'subtitle': 'Şekilleri öğren',
        'color': const Color(0xFFE67E22),
        'stars': 1,
        'locked': false,
      },
    ];

    if (age == GameMechanics.AgeGroupSelection.preschool) {
      return baseTopics;
    }

    final elementaryTopics = [
      ...baseTopics,
      {
        'id': 'multiplication',
        'emoji': '✖️',
        'title': localizations.get('multiplication'),
        'subtitle': localizations.get('multiply_numbers'),
        'color': const Color(0xFF9B59B6),
        'stars': 2,
        'locked': false,
      },
      {
        'id': 'time',
        'emoji': '🕰',
        'title': 'Saat',
        'subtitle': 'Saati oku',
        'color': const Color(0xFF1ABC9C),
        'stars': 2,
        'locked': false,
      },
    ];

    if (age == GameMechanics.AgeGroupSelection.elementary) {
      return elementaryTopics;
    }

    return [
      ...elementaryTopics,
      {
        'id': 'division',
        'emoji': '➗',
        'title': localizations.get('division'),
        'subtitle': localizations.get('divide_numbers'),
        'color': const Color(0xFF34495E),
        'stars': 2,
        'locked': false,
      },
      {
        'id': 'fractions',
        'emoji': '½',
        'title': localizations.get('fractions'),
        'subtitle': localizations.get('learn_fractions'),
        'color': const Color(0xFFD35400),
        'stars': 3,
        'locked': false,
      },
      {
        'id': 'decimals',
        'emoji': '0️⃣',
        'title': localizations.get('decimals'),
        'subtitle': localizations.get('learn_decimals'),
        'color': const Color(0xFF8E44AD),
        'stars': 3,
        'locked': false,
      },
      {
        'id': 'algebra',
        'emoji': '🔤',
        'title': localizations.get('algebra'),
        'subtitle': localizations.get('basic_algebra'),
        'color': const Color(0xFF2C3E50),
        'stars': 3,
        'locked': false,
      },
    ];
  }

  void _selectTopic(Map<String, dynamic> topic) {
    if (topic['locked'] == true) {
      _showLockedDialog(topic);
      return;
    }

    if (_inventory.lives <= 0) {
      _showNoLivesDialog();
      return;
    }

    final gameSettings = _createGameSettings(topic);
    _showLevelSelectionDialog(topic, gameSettings);
  }

  void _showLockedDialog(Map<String, dynamic> topic) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 3),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${topic['title']} Kilitli!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bu konuyu açmak için daha fazla seviye tamamlamalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('TAMAM'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoLivesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Canın Kalmadı!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Yeni canlar için beklemeli veya can satın almalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('TAMAM'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _createGameSettings(Map<String, dynamic> topic) {
    int questionCount;
    int timeLimit;
    String difficulty;

    switch (widget.ageGroup) {
      case GameMechanics.AgeGroupSelection.preschool:
        questionCount = 5;
        timeLimit = 30;
        difficulty = 'Kolay';
        break;
      case GameMechanics.AgeGroupSelection.elementary:
        questionCount = 10;
        timeLimit = 45;
        difficulty = 'Orta';
        break;
      case GameMechanics.AgeGroupSelection.advanced:
        questionCount = 15;
        timeLimit = 60;
        difficulty = 'Zor';
        break;
      default:
        questionCount = 10;
        timeLimit = 45;
        difficulty = 'Orta';
    }

    return {
      'topicId': topic['id'],
      'topicName': topic['title'],
      'topicEmoji': topic['emoji'],
      'topicColor': topic['color'],
      'questionCount': questionCount,
      'timeLimit': timeLimit,
      'difficulty': difficulty,
      'baseScorePerQuestion': 100,
      'coinReward': questionCount * 10,
      'xpReward': questionCount * 5,
    };
  }

  void _showLevelSelectionDialog(Map<String, dynamic> topic, Map<String, dynamic> settings) {
    final levels = [
      {
        'level': 1,
        'name': 'Kolay',
        'emoji': '😊',
        'description': 'Başlangıç seviyesi',
        'questionCount': settings['questionCount'] as int,
        'timeLimit': settings['timeLimit'] as int,
        'rewardMultiplier': 1.0,
      },
      {
        'level': 2,
        'name': 'Orta',
        'emoji': '😐',
        'description': 'Orta seviye',
        'questionCount': (settings['questionCount'] as int) + 5,
        'timeLimit': (settings['timeLimit'] as int) - 10,
        'rewardMultiplier': 1.5,
      },
      {
        'level': 3,
        'name': 'Zor',
        'emoji': '😰',
        'description': 'Uzman seviyesi',
        'questionCount': (settings['questionCount'] as int) + 10,
        'timeLimit': (settings['timeLimit'] as int) - 20,
        'rewardMultiplier': 2.0,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: topic['color'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topic['emoji'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      topic['title'] as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seviyeler
              ...levels.map((level) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    elevation: 3,
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _startGame(topic, settings, level);
                      },
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (topic['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            level['emoji'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      title: Text(
                        '${level['name']} - Seviye ${level['level']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${level['questionCount']} soru • ${level['timeLimit']} saniye',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'x${level['rewardMultiplier']}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.play_arrow,
                            color: topic['color'] as Color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 10),

              // İptal butonu
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'İPTAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(Map<String, dynamic> topic, Map<String, dynamic> settings, Map<String, dynamic> level) {
    final topicType = _convertToTopicType(topic['id']);
    final topicSettings = GameMechanics.TopicGameManager.getTopicSettings()[topicType]!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecializedGameScreen(
          topicSettings: topicSettings,
          ageGroup: widget.ageGroup,
          difficulty: level['name'] as String,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  GameMechanics.TopicType _convertToTopicType(String topicId) {
    switch (topicId) {
      case 'geometry': return GameMechanics.TopicType.geometry;
      case 'fractions': return GameMechanics.TopicType.fractions;
      case 'decimals': return GameMechanics.TopicType.decimals;
      case 'time': return GameMechanics.TopicType.time;
      case 'shapes': return GameMechanics.TopicType.geometry;
      case 'counting': return GameMechanics.TopicType.counting;
      case 'addition': return GameMechanics.TopicType.addition;
      case 'subtraction': return GameMechanics.TopicType.subtraction;
      case 'multiplication': return GameMechanics.TopicType.multiplication;
      case 'division': return GameMechanics.TopicType.division;
      case 'algebra': return GameMechanics.TopicType.algebra;
      default: return GameMechanics.TopicType.addition;
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎮 OYUN KURALLARI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _ageTheme['accentColor'] as Color,
                ),
              ),
              const SizedBox(height: 15),
              _buildHelpItem('📊', 'Her konunun zorluk seviyesi var'),
              _buildHelpItem('⭐', 'Yıldız sayısı zorluğu gösterir'),
              _buildHelpItem('❤️', 'Canlar bittiğinde beklemelisin'),
              _buildHelpItem('🪙', 'Doğru cevaplarla altın kazan'),
              _buildHelpItem('🏆', 'Yüksek puanlarla liderlikte yer al'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ageTheme['accentColor'] as Color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text('ANLADIM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showPowerUps() {
    // Güçlendirme ekranı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Güçlendirme ekranı yakında!'),
        backgroundColor: _ageTheme['accentColor'] as Color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showLevelSelection() {
    // Seviye seçimi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Seviye seçimi ekranı yakında!'),
        backgroundColor: _ageTheme['accentColor'] as Color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Parçacık painter
class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _ParticlePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final angle = animationValue + (2 * math.pi * i / particleCount);
      final x = size.width / 2 + math.cos(angle) * 40;
      final y = size.height / 2 + math.sin(angle) * 15;

      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Desen painter
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final mathPattern = ['+', '-', '×', '÷'];
    final random = math.Random();

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final symbol = mathPattern[random.nextInt(mathPattern.length)];
      final fontSize = random.nextDouble() * 20 + 10;
      final opacity = random.nextDouble() * 0.1 + 0.05;

      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            color: color.withOpacity(opacity),
            fontSize: fontSize,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}