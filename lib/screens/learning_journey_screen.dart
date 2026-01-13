import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_mechanics.dart' as GameMechanics;
import 'specialized_game_screen.dart';
import 'game_start_screen.dart';

/// Öğrenme Yolculuğu Haritası
/// Görsel ilerleme haritası, beceri ağacı, başarı duvarı
class LearningJourneyScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LearningJourneyScreen({super.key, required this.onBack});

  @override
  State<LearningJourneyScreen> createState() => _LearningJourneyScreenState();
}

class _LearningJourneyScreenState extends State<LearningJourneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Örnek veriler
  final List<JourneyRegion> _regions = [
    JourneyRegion(
      id: 'counting',
      name: 'Sayma Vadisi',
      emoji: '🔢',
      color: const Color(0xFF4CAF50),
      progress: 1.0,
      stars: 45,
      isUnlocked: true,
    ),
    JourneyRegion(
      id: 'addition',
      name: 'Toplama Ormanı',
      emoji: '➕',
      color: const Color(0xFF2196F3),
      progress: 0.8,
      stars: 38,
      isUnlocked: true,
    ),
    JourneyRegion(
      id: 'subtraction',
      name: 'Çıkarma Nehri',
      emoji: '➖',
      color: const Color(0xFF9C27B0),
      progress: 0.6,
      stars: 24,
      isUnlocked: true,
    ),
    JourneyRegion(
      id: 'multiplication',
      name: 'Çarpma Dağı',
      emoji: '✖️',
      color: const Color(0xFFFF9800),
      progress: 0.3,
      stars: 12,
      isUnlocked: true,
    ),
    JourneyRegion(
      id: 'division',
      name: 'Bölme Çölü',
      emoji: '➗',
      color: const Color(0xFFE91E63),
      progress: 0.0,
      stars: 0,
      isUnlocked: false,
    ),
    JourneyRegion(
      id: 'geometry',
      name: 'Geometri Şatosu',
      emoji: '🔺',
      color: const Color(0xFF00BCD4),
      progress: 0.0,
      stars: 0,
      isUnlocked: false,
    ),
  ];

  final List<SkillNode> _skills = [
    SkillNode(id: 'counting_basic', name: 'Temel Sayma', level: 3, maxLevel: 3, parent: null),
    SkillNode(id: 'counting_10', name: '10\'a Kadar', level: 3, maxLevel: 3, parent: 'counting_basic'),
    SkillNode(id: 'counting_100', name: '100\'e Kadar', level: 2, maxLevel: 3, parent: 'counting_10'),
    SkillNode(id: 'add_basic', name: 'Temel Toplama', level: 2, maxLevel: 3, parent: 'counting_basic'),
    SkillNode(id: 'add_carry', name: 'Elde ile Toplama', level: 1, maxLevel: 3, parent: 'add_basic'),
    SkillNode(id: 'sub_basic', name: 'Temel Çıkarma', level: 1, maxLevel: 3, parent: 'counting_basic'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Tab bar
              _buildTabBar(),

              // Tab içerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorldMap(),
                    _buildSkillTree(),
                    _buildAchievementWall(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗺️ Öğrenme Yolculuğu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Matematik dünyasını keşfet!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Toplam yıldız
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${_regions.fold(0, (sum, r) => sum + r.stars)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(icon: Icon(Icons.map), text: 'Dünya'),
          Tab(icon: Icon(Icons.account_tree), text: 'Beceriler'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Başarılar'),
        ],
      ),
    );
  }

  Widget _buildWorldMap() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Harita başlığı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Matematik Dünyası',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_regions.where((r) => r.isUnlocked).length} / ${_regions.length} bölge keşfedildi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bölgeler
          ..._regions.map((region) => _buildRegionCard(region)).toList(),
        ],
      ),
    );
  }

  Widget _buildRegionCard(JourneyRegion region) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Bağlantı çizgisi
          Container(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  color: region.isUnlocked 
                      ? region.color.withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.3),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: region.isUnlocked ? region.color : Colors.grey,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Container(
                  width: 3,
                  height: 40,
                  color: region.isUnlocked 
                      ? region.color.withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.3),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Bölge kartı
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (region.isUnlocked) {
                  _enterRegion(region);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu bölge henüz kilitli! Önceki bölgeleri tamamlayın.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: region.isUnlocked
                    ? LinearGradient(
                        colors: [
                          region.color.withOpacity(0.3),
                          region.color.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: region.isUnlocked ? null : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: region.isUnlocked 
                      ? region.color.withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    region.emoji,
                    style: TextStyle(
                      fontSize: 36,
                      color: region.isUnlocked ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: region.isUnlocked 
                                ? Colors.white 
                                : Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (region.isUnlocked) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: region.progress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(region.color),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${(region.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const Spacer(),
                              const Text('⭐', style: TextStyle(fontSize: 12)),
                              Text(
                                ' ${region.stars}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ] else
                          const Text(
                            '🔒 Kilitli',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  void _startRegionGame(JourneyRegion region) {
    // Region ID'sine göre TopicType belirle
    GameMechanics.TopicType topicType;
    switch (region.id) {
      case 'counting':
        topicType = GameMechanics.TopicType.counting;
        break;
      case 'addition':
        topicType = GameMechanics.TopicType.addition;
        break;
      case 'subtraction':
        topicType = GameMechanics.TopicType.subtraction;
        break;
      case 'multiplication':
        topicType = GameMechanics.TopicType.multiplication;
        break;
      case 'division':
        topicType = GameMechanics.TopicType.division;
        break;
      case 'geometry':
        topicType = GameMechanics.TopicType.geometry;
        break;
      default:
        topicType = GameMechanics.TopicType.addition;
    }

    // Topic ayarlarını al
    final topicSettings = GameMechanics.TopicGameManager.getTopicSettings()[topicType]!;

    // Oyun ekranına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecializedGameScreen(
          topicSettings: topicSettings,
          ageGroup: AgeGroupSelection.elementary,
          difficulty: 'Orta',
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _enterRegion(JourneyRegion region) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                region.color,
                region.color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                region.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                region.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${region.stars} ⭐ Yıldız',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '%${(region.progress * 100).toInt()} Tamamlandı',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'İPTAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Dialog kapatıldıktan sonra navigation yap
                        Future.microtask(() => _startRegionGame(region));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: region.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'BAŞLA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildSkillTree() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Beceri ağacı başlığı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('🌳', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beceri Ağacı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Yeteneklerini geliştir!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Beceri düğümleri
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _skills.map((skill) => _buildSkillNode(skill)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillNode(SkillNode skill) {
    final isMaxed = skill.level >= skill.maxLevel;
    
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMaxed
              ? [Colors.amber.withOpacity(0.4), Colors.amber.withOpacity(0.2)]
              : [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMaxed ? Colors.amber : Colors.white.withOpacity(0.2),
          width: isMaxed ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Beceri ikonu
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMaxed 
                  ? Colors.amber.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                isMaxed ? '⭐' : '📚',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            skill.name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          // Seviye göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(skill.maxLevel, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < skill.level 
                      ? Colors.amber 
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementWall() {
    final achievements = [
      Achievement(id: '1', name: 'İlk Adım', emoji: '👣', description: 'İlk soruyu çöz', earned: true),
      Achievement(id: '2', name: 'Hızlı Düşünür', emoji: '⚡', description: '5 saniyede cevapla', earned: true),
      Achievement(id: '3', name: 'Seri Yapıcı', emoji: '🔥', description: '10 combo yap', earned: true),
      Achievement(id: '4', name: 'Matematik Ustası', emoji: '🏆', description: 'Tüm bölümleri bitir', earned: false),
      Achievement(id: '5', name: 'Yıldız Toplayıcı', emoji: '⭐', description: '100 yıldız topla', earned: true),
      Achievement(id: '6', name: 'Boss Avcısı', emoji: '👾', description: 'İlk boss\'u yen', earned: false),
      Achievement(id: '7', name: 'Günlük Görev', emoji: '📅', description: '7 gün arka arkaya gir', earned: true),
      Achievement(id: '8', name: 'Mükemmeliyetçi', emoji: '💯', description: 'Hiç hata yapmadan bitir', earned: false),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: achievement.earned
            ? LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.3),
                  Colors.amber.withOpacity(0.1),
                ],
              )
            : null,
        color: achievement.earned ? null : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.earned 
              ? Colors.amber.withOpacity(0.5) 
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.earned ? achievement.emoji : '🔒',
            style: TextStyle(
              fontSize: 32,
              color: achievement.earned ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: achievement.earned ? Colors.white : Colors.white60,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          if (achievement.earned)
            const Text(
              '✓',
              style: TextStyle(
                fontSize: 16,
                color: Colors.amber,
              ),
            ),
        ],
      ),
    );
  }
}

class JourneyRegion {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final double progress;
  final int stars;
  final bool isUnlocked;

  JourneyRegion({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.progress,
    required this.stars,
    required this.isUnlocked,
  });
}

class SkillNode {
  final String id;
  final String name;
  final int level;
  final int maxLevel;
  final String? parent;

  SkillNode({
    required this.id,
    required this.name,
    required this.level,
    required this.maxLevel,
    this.parent,
  });
}

class Achievement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool earned;

  Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.earned,
  });
}

