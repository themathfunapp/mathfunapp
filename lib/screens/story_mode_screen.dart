import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';
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
    final authService = Provider.of<AuthService>(context);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

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
          child: Consumer<StoryService>(
            builder: (context, storyService, child) {
              if (storyService.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (_showAgeSelection) {
                return _buildAgeSelection(localizations, storyService);
              }

              return _buildMainContent(localizations, storyService);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSelection(AppLocalizations localizations, StoryService storyService) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  localizations.get('story_mode'),
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

        // Floating mascot
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: const Text(
                '🦸',
                style: TextStyle(fontSize: 80),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        Text(
          localizations.get('choose_your_adventure'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            localizations.get('age_selection_subtitle'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 40),

        // Age group cards
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildAgeCard(
                localizations: localizations,
                ageGroup: AgeGroup.preschool,
                title: localizations.get('age_group_preschool'),
                subtitle: localizations.get('age_group_preschool_subtitle'),
                ageRange: '3-5',
                emoji: '🧒',
                colors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                storyService: storyService,
              ),
              const SizedBox(height: 16),
              _buildAgeCard(
                localizations: localizations,
                ageGroup: AgeGroup.earlyElementary,
                title: localizations.get('age_group_early'),
                subtitle: localizations.get('age_group_early_subtitle'),
                ageRange: '6-8',
                emoji: '🚀',
                colors: [const Color(0xFF2196F3), const Color(0xFF03A9F4)],
                storyService: storyService,
              ),
              const SizedBox(height: 16),
              _buildAgeCard(
                localizations: localizations,
                ageGroup: AgeGroup.lateElementary,
                title: localizations.get('age_group_late'),
                subtitle: localizations.get('age_group_late_subtitle'),
                ageRange: '9-11',
                emoji: '🏰',
                colors: [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
                storyService: storyService,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeCard({
    required AppLocalizations localizations,
    required AgeGroup ageGroup,
    required String title,
    required String subtitle,
    required String ageRange,
    required String emoji,
    required List<Color> colors,
    required StoryService storyService,
  }) {
    return GestureDetector(
      onTap: () async {
        await storyService.selectAgeGroup(ageGroup);
        
        // Avatar oluşturma ekranına git
        if (mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AvatarCreatorScreen(ageGroup: ageGroup),
            ),
          );

          if (result == true) {
            setState(() {
              _showAgeSelection = false;
            });
          }
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
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$ageRange ${localizations.get('years_old')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
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

  Widget _buildMainContent(AppLocalizations localizations, StoryService storyService) {
    final progress = storyService.progress;

    return Column(
      children: [
        // Top Bar
        _buildTopBar(localizations, progress),

        // World Map
        Expanded(
          child: WorldMapScreen(
            worlds: storyService.worlds,
            progress: progress,
          ),
        ),

        // Bottom Navigation
        _buildBottomNav(localizations, storyService),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations localizations, StoryProgress? progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AvatarCreatorScreen(
                    ageGroup: progress?.selectedAgeGroup ?? AgeGroup.preschool,
                    isEditing: true,
                  ),
                ),
              );
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
                  progress?.avatar.odername ?? 'Kahraman',
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

          // Stars
          _buildStatItem('⭐', '${progress?.totalStars ?? 0}'),
          const SizedBox(width: 12),
          // Coins
          _buildStatItem('💰', '${progress?.totalCoins ?? 0}'),
        ],
      ),
    );
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

  Widget _buildBottomNav(AppLocalizations localizations, StoryService storyService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: '🗺️',
            label: localizations.get('worlds'),
            isSelected: true,
            onTap: () {},
          ),
          _buildNavItem(
            icon: '📋',
            label: localizations.get('quests'),
            isSelected: false,
            onTap: () => _showQuestsSheet(localizations, storyService),
          ),
          _buildNavItem(
            icon: '🎒',
            label: localizations.get('inventory'),
            isSelected: false,
            onTap: () {},
          ),
          _buildNavItem(
            icon: '🏆',
            label: localizations.get('achievements'),
            isSelected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
                      localizations.get(quest.nameKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      localizations.get(quest.descriptionKey),
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

