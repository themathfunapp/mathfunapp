import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'daily_rewards_screen.dart';
import 'badges_screen.dart';
import 'friends_screen.dart';
import 'story_mode_screen.dart';
import 'mini_games_screen.dart';
import 'premium_screen.dart';

/// Ana ekran sarmalayıcısı - AuthWrapper ve Hesap Oluştur yönlendirmesinde kullanılır
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onGameSelection: () {},
      onDailyRewards: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyRewardsScreen(
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      onBadges: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgesScreen(
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      onFriends: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendsScreen(
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      onStoryMode: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StoryModeScreen(),
          ),
        );
      },
      onMiniGames: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MiniGamesScreen(
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      onPremium: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PremiumScreen(
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}
