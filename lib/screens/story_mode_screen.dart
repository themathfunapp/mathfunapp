import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../services/daily_reward_service.dart';
import '../services/game_mechanics_service.dart';
import '../services/ad_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'world_map_screen.dart';
import 'avatar_creator_screen.dart';

class StoryModeScreen extends StatefulWidget {
  const StoryModeScreen({super.key});

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool _showAgeSelection = true;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Post-frame callback ile Provider'a erişim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStoryMode();
    });
  }

  Future<void> _initStoryMode() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storyService = Provider.of<StoryService>(context, listen: false);

      if (authService.currentUser != null) {
        await storyService.loadProgress(authService.currentUser!.uid);

        if (mounted && storyService.progress != null &&
            storyService.progress!.avatar.odername != 'Kahraman') {
          setState(() {
            _showAgeSelection = false;
          });
          await storyService.loadWorlds(storyService.progress!.selectedAgeGroup);
        }
      }
    } catch (e) {
      debugPrint('Story mode init error: $e');
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final localizations = AppLocalizations(localeProvider.locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer2<StoryService, DailyRewardService>(
            builder: (context, storyService, dailyRewardService, child) {
              if (storyService.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (_showAgeSelection) {
                return _buildAgeSelection(localizations, storyService);
              }

              return _buildMainContent(localizations, storyService, dailyRewardService);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSelection(AppLocalizations localizations, StoryService storyService) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      localizations.storyMode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: const Center(
                        child: Text(
                          '🦸',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                localizations.get('choose_adventure'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                localizations.get('age_appropriate_adventure'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAgeCard(
                  title: localizations.get('number_adventures'),
                  subtitle: localizations.get('colorful_animals_discovery'),
                  ageRange: '3-5',
                  yearsOld: localizations.get('years_old'),
                  emoji: '🧒',
                  colors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                  storyService: storyService,
                  ageGroup: AgeGroup.preschool,
                ),
                const SizedBox(height: 16),
                _buildAgeCard(
                  title: localizations.get('math_explorers'),
                  subtitle: localizations.get('time_space_journey'),
                  ageRange: '6-8',
                  yearsOld: localizations.get('years_old'),
                  emoji: '🚀',
                  colors: [const Color(0xFF2196F3), const Color(0xFF03A9F4)],
                  storyService: storyService,
                  ageGroup: AgeGroup.earlyElementary,
                ),
                const SizedBox(height: 16),
                _buildAgeCard(
                  title: localizations.get('math_kingdom'),
                  subtitle: localizations.get('kingdom_rescue_mission'),
                  ageRange: '9-11',
                  yearsOld: localizations.get('years_old'),
                  emoji: '🏰',
                  colors: [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
                  storyService: storyService,
                  ageGroup: AgeGroup.lateElementary,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeCard({
    required String title,
    required String subtitle,
    required String ageRange,
    required String yearsOld,
    required String emoji,
    required List<Color> colors,
    required StoryService storyService,
    required AgeGroup ageGroup,
  }) {
    return GestureDetector(
      onTap: () async {
        await storyService.selectAgeGroup(ageGroup);

        // TODO: Avatar özelliği yayın sonrası güncellemede aktif edilecek
        // Avatar oluşturma ekranını atlayıp direkt devam et
        // if (mounted) {
        //   final result = await Navigator.push<bool>(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => AvatarCreatorScreen(ageGroup: ageGroup),
        //     ),
        //   );
        //
        //   if (result == true) {
        //     setState(() {
        //       _showAgeSelection = false;
        //     });
        //   }
        // }
        
        // Varsayılan avatar ile direkt devam et
        if (mounted) {
          setState(() {
            _showAgeSelection = false;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$ageRange $yearsOld',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    AppLocalizations localizations,
    StoryService storyService,
    DailyRewardService dailyRewardService,
  ) {
    final progress = storyService.progress;

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _showAgeSelection = true;
        });
        return false;
      },
      child: Column(
        children: [
          // Top Bar
          _buildTopBar(localizations, progress, dailyRewardService),

          // World Map
          Expanded(
            child: WorldMapScreen(
              worlds: storyService.worlds,
              progress: progress,
            ),
          ),

          // Banner reklam (Premium olmayan kullanıcılar için)
          const BannerAdWidget(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),

          // Alt 6 öğe — Sayı Maceraları ve Matematik Krallığı'nda gizli; sadece Matematik Gezginleri (6-8).
          if (progress?.selectedAgeGroup == AgeGroup.earlyElementary)
            _buildBottomNav(localizations, storyService, dailyRewardService),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    AppLocalizations localizations,
    StoryProgress? progress,
    DailyRewardService dailyRewardService,
  ) {
    final bonusStars = dailyRewardService.profileBonusStars;
    final displayStars = (progress?.totalStars ?? 0) + bonusStars;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              setState(() {
                _showAgeSelection = true;
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
          ),

          // Avatar
          // TODO: Avatar düzenleme yayın sonrası güncellemede aktif edilecek
          GestureDetector(
            onTap: () {
              // Avatar düzenleme geçici olarak devre dışı
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${localizations.get('avatar_coming_soon')} 🎨'),
                  backgroundColor: Colors.purple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => AvatarCreatorScreen(
              //       ageGroup: progress?.selectedAgeGroup ?? AgeGroup.preschool,
              //       isEditing: true,
              //     ),
              //   ),
              // );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🦸', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Level & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(progress?.avatar.odername, localizations),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Lv.${progress?.avatar.level ?? 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: ((progress?.avatar.experience ?? 0) % 100) / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stars (hikâye + günlük ödül / çark yıldızları)
          _buildStatItem('⭐', '$displayStars'),
          const SizedBox(width: 12),
          // Coins
          _buildStatItem('💰', '${progress?.totalCoins ?? 0}'),
        ],
      ),
    );
  }

  /// Varsayılan "Kahraman" adı seçili dilde gösterilir
  String _getDisplayName(String? odername, AppLocalizations localizations) {
    if (odername == null || odername.isEmpty || odername == 'Kahraman') {
      return localizations.get('hero');
    }
    return odername;
  }

  Widget _buildStatItem(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    AppLocalizations localizations,
    StoryService storyService,
    DailyRewardService dailyRewardService,
  ) {
    final progress = storyService.progress;
    final mechanicsService = Provider.of<GameMechanicsService>(context, listen: true);

    // Gerçek veriler
    final totalStars = (progress?.totalStars ?? 0) + dailyRewardService.profileBonusStars;
    final totalCoins = (progress?.totalCoins ?? 0) > mechanicsService.inventory.coins
        ? (progress?.totalCoins ?? 0) : mechanicsService.inventory.coins;
    final totalGems = (progress?.totalGems ?? 0) > mechanicsService.inventory.gems
        ? (progress?.totalGems ?? 0) : mechanicsService.inventory.gems;
    final earnedBadges = progress?.earnedBadges.length ?? 0;
    final completedQuests = storyService.activeQuests.where((q) => q.currentValue >= q.targetValue).length;
    final totalQuests = storyService.activeQuests.length;
    final completedWorlds = progress?.worldProgress.values.where((w) => w.totalStars > 0).length ?? 0;
    final totalWorlds = storyService.worlds.isEmpty ? 1 : storyService.worlds.length;
    final currentLives = mechanicsService.currentLives;
    final maxLives = mechanicsService.maxLives;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: '🏆',
              label: localizations.get('achievements'),
              value: '$earnedBadges',
              isSelected: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: '📋',
              label: localizations.get('quests'),
              value: '$completedQuests/$totalQuests',
              isSelected: false,
              onTap: () => _showQuestsSheet(localizations, storyService),
            ),
            _buildNavItem(
              icon: '🎒',
              label: localizations.get('inventory'),
              value: '$totalCoins',
              isSelected: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: '🗺️',
              label: localizations.get('worlds'),
              value: '$completedWorlds/$totalWorlds',
              isSelected: true,
              onTap: () {},
            ),
            _buildNavItem(
              icon: '⚡',
              label: localizations.get('energy'),
              value: '$currentLives/$maxLives',
              isSelected: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: '📊',
              label: localizations.get('statistics'),
              value: '⭐$totalStars',
              isSelected: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.7)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestsSheet(AppLocalizations localizations, StoryService storyService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    localizations.get('daily_quests'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: storyService.activeQuests.length,
                itemBuilder: (context, index) {
                  final quest = storyService.activeQuests[index];
                  return _buildQuestCard(quest, localizations);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(StoryQuest quest, AppLocalizations localizations) {
    String questName = '';
    String questDesc = '';

    // Quest isimlerini lokalizasyondan al
    switch (quest.nameKey) {
      case 'quest_complete_levels':
        questName = localizations.get('complete_3_levels');
        questDesc = localizations.get('complete_3_levels_desc');
        break;
      case 'quest_earn_stars':
        questName = localizations.get('earn_5_stars');
        questDesc = localizations.get('earn_5_stars_desc');
        break;
      case 'quest_correct_answers':
        questName = localizations.get('correct_20_answers');
        questDesc = localizations.get('correct_20_answers_desc');
        break;
      default:
        questName = quest.nameKey;
        questDesc = quest.descriptionKey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quest.isCompleted
              ? const Color(0xFF4CAF50)
              : Colors.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: quest.isCompleted
                      ? const Color(0xFF4CAF50).withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  quest.isCompleted ? '✅' : '🎯',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      questDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: quest.progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                quest.isCompleted ? const Color(0xFF4CAF50) : Colors.orange,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quest.currentValue}/${quest.targetValue}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: quest.rewards.map((reward) {
                  String emoji = '';
                  switch (reward.type) {
                    case RewardType.coins:
                      emoji = '💰';
                      break;
                    case RewardType.gems:
                      emoji = '💎';
                      break;
                    case RewardType.experience:
                      emoji = '⭐';
                      break;
                    default:
                      emoji = '🎁';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 2),
                        Text(
                          '+${reward.amount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}