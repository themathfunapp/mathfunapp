import 'package:flutter/material.dart';
import '../widgets/animated_math_symbol.dart';
import '../widgets/language_selector_button.dart';
import '../widgets/shiny_button.dart';
import '../widgets/story_mode_button.dart';
import '../widgets/mini_games_button.dart';
import '../widgets/premium_button.dart';
import '../widgets/bottom_action_button.dart';
import '../localization/app_localizations.dart';
import '../utils/constants.dart';
import '../widgets/bottom_action_button.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onGameSelection;
  final VoidCallback onProfile;
  final VoidCallback onDailyRewards;
  final VoidCallback onBadges;
  final VoidCallback onFriends;
  final VoidCallback onStoryMode;
  final VoidCallback onMiniGames;
  final VoidCallback onPremium;

  const HomeScreen({
    super.key,
    required this.onGameSelection,
    required this.onProfile,
    required this.onDailyRewards,
    required this.onBadges,
    required this.onFriends,
    required this.onStoryMode,
    required this.onMiniGames,
    required this.onPremium,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;
  String _currentLanguage = 'tr';

  @override
  void initState() {
    super.initState();

    // Başlık animasyonu
    _titleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _titleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
    // Burada dil değişimini uygulama genelinde yönetmek için
    // bir state management çözümü kullanabilirsiniz
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: primaryGradient),
        child: Stack(
          children: [
            // Dönen matematik sembolü
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: const AnimatedMathSymbol(),
            ),

            // Ana içerik
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Üst kısım: Dil + Profil
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LanguageSelectorButton(
                        currentLanguage: _currentLanguage,
                        onLanguageChanged: _changeLanguage,
                      ),
                      _buildProfileButton(localizations.profile),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Başlık
                  Column(
                    children: [
                      ScaleTransition(
                        scale: _titleAnimation,
                        child: Text(
                          localizations.homeTitle,
                          style: titleStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.homeSubtitle,
                        style: subtitleStyle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Orta içerik
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localizations.homeImproveSkills,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          localizations.homeLearnFun,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Ana butonlar
                        ShinyButton(
                          text: localizations.startGame,
                          onPressed: widget.onGameSelection,
                        ),

                        const SizedBox(height: 16),

                        StoryModeButton(
                          text: localizations.storyMode,
                          onPressed: widget.onStoryMode,
                        ),

                        const SizedBox(height: 8),

                        MiniGamesButton(
                          text: localizations.miniGames,
                          subText: localizations.miniGamesCount,
                          onPressed: widget.onMiniGames,
                        ),

                        const SizedBox(height: 16),

                        PremiumButton(
                          onPressed: widget.onPremium,
                        ),
                      ],
                    ),
                  ),

                  // Alt butonlar
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: BottomActionButton(
                          text: localizations.dailyRewards,
                          emoji: '🎁',
                          onPressed: widget.onDailyRewards,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BottomActionButton(
                          text: localizations.badges,
                          emoji: '🏆',
                          onPressed: widget.onBadges,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BottomActionButton(
                          text: localizations.friends,
                          emoji: '👥',
                          onPressed: widget.onFriends,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(String text) {
    return GestureDetector(
      onTap: widget.onProfile,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '👤',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}