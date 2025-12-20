import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/SettingsScreen.dart';
import '../widgets/animated_math_symbol.dart';
import '../widgets/shiny_button.dart';
import '../widgets/story_mode_button.dart';
import '../widgets/mini_games_button.dart';
import '../widgets/premium_button.dart';
import '../widgets/bottom_action_button.dart';
import '../localization/app_localizations.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/badges_screen.dart';
import '../screens/daily_rewards_screen.dart';
import '../screens/story_mode_screen.dart';
import '../screens/mini_games_screen.dart';
import '../screens/game_start_screen.dart';
import '../screens/spin_wheel_screen.dart';
import '../screens/parent_panel_screen.dart';
import '../screens/ai_storyteller_screen.dart';
import '../screens/voice_commands_screen.dart';
import '../screens/learning_journey_screen.dart';
import '../screens/math_art_gallery_screen.dart';
import '../screens/virtual_math_lab_screen.dart';
import '../screens/avatar_customization_screen.dart';
import '../screens/pet_screen.dart';
import '../screens/accessibility_screen.dart';


class HomeScreen extends StatefulWidget {
  final VoidCallback onGameSelection;
  final VoidCallback onDailyRewards;
  final VoidCallback onBadges;
  final VoidCallback onFriends;
  final VoidCallback onStoryMode;
  final VoidCallback onMiniGames;
  final VoidCallback onPremium;

  const HomeScreen({
    super.key,
    required this.onGameSelection,
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

  // Desteklenen diller listesi
  final List<Map<String, dynamic>> _supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context);

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
            ListView(
              padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0, bottom: 24.0),
              children: [
                // Üst kısım: Dil + Profil (Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dil seçici butonu
                    _buildLanguageButton(context, authService),

                    // Profil butonu
                    _buildProfileButton(context, localizations),
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

                // Orta içerik Metinleri
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
                  onPressed: () => _openGameStartScreen(context),
                ),

                const SizedBox(height: 16),

                StoryModeButton(
                  text: localizations.storyMode,
                  onPressed: () => _openStoryModeScreen(context),
                ),

                const SizedBox(height: 8),

                // MINI GAMES BUTONU
                MiniGamesButton(
                  text: localizations.miniGames,
                  subText: localizations.miniGamesCount,
                  onPressed: () => _openMiniGamesScreen(context),
                ),

                const SizedBox(height: 16),

                PremiumButton(
                  onPressed: widget.onPremium,
                ),

                // BottomActionButton'lar
                const SizedBox(height: 40),

                // Alt butonlar
                Row(
                  children: [
                    Expanded(
                      child: BottomActionButton(
                        text: localizations.dailyRewards,
                        emoji: '🎁',
                        onPressed: () => _openDailyRewardsScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: localizations.badges,
                        emoji: '🏆',
                        onPressed: () => _openBadgesScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: localizations.friends,
                        emoji: '👥',
                        onPressed: () => _openFriendsScreen(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // İkinci satır - Yeni özellikler
                Row(
                  children: [
                    Expanded(
                      child: BottomActionButton(
                        text: 'Şans Çarkı',
                        emoji: '🎰',
                        onPressed: () => _openSpinWheelScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: 'Ebeveyn',
                        emoji: '👨‍👩‍👧',
                        onPressed: () => _openParentPanelScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: 'Hikaye',
                        emoji: '📖',
                        onPressed: () => _openAIStorytellerScreen(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Üçüncü satır - Gelişmiş özellikler
                Row(
                  children: [
                    Expanded(
                      child: BottomActionButton(
                        text: 'Sesli',
                        emoji: '🎤',
                        onPressed: () => _openVoiceCommandsScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: 'Avatar',
                        emoji: '👤',
                        onPressed: () => _openAvatarScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: 'Evcil',
                        emoji: '🐱',
                        onPressed: () => _openPetScreen(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Dördüncü satır - Keşif özellikleri
                Row(
                  children: [
                    Expanded(
                      child: BottomActionButton(
                        text: 'Yolculuk',
                        emoji: '🗺️',
                        onPressed: () => _openLearningJourneyScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: 'Galeri',
                        emoji: '🎨',
                        onPressed: () => _openMathArtGalleryScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BottomActionButton(
                        text: 'Laboratuvar',
                        emoji: '🧪',
                        onPressed: () => _openVirtualMathLabScreen(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dil değiştirme butonu
  Widget _buildLanguageButton(BuildContext context, AuthService authService) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            _getCurrentFlag(authService),
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      offset: const Offset(0, 60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      onSelected: (String languageCode) {
        _changeLanguage(context, languageCode, authService);
      },
      itemBuilder: (BuildContext context) {
        return _supportedLanguages.map((lang) {
          final isCurrent = _isCurrentLanguage(lang['code'] as String, authService);

          return PopupMenuItem<String>(
            value: lang['code'] as String,
            child: Row(
              children: [
                Text(
                  lang['flag'] as String,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang['name'] as String,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.blue : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isCurrent)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 18,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  // Mevcut dilin bayrağını getir
  String _getCurrentFlag(AuthService authService) {
    final currentLocale = Localizations.localeOf(context);
    final lang = _supportedLanguages.firstWhere(
          (lang) => lang['code'] == currentLocale.languageCode,
      orElse: () => _supportedLanguages[0],
    );
    return lang['flag'] as String;
  }

  // Dilin şu anki dil olup olmadığını kontrol et
  bool _isCurrentLanguage(String languageCode, AuthService authService) {
    final currentLocale = Localizations.localeOf(context);
    return currentLocale.languageCode == languageCode;
  }

  // Dil değiştirme işlemi
  void _changeLanguage(BuildContext context, String languageCode, AuthService authService) async {
    try {
      // AuthService üzerinden dil güncelle
      await authService.updateUserLanguage(languageCode);

      // AppState'i güncelle
      final appState = context.findAncestorStateOfType<_MyAppState>();
      if (appState != null && appState.mounted) {
        appState.changeLanguage(Locale(languageCode));
      }

      // Snackbar ile bilgilendir
      _showLanguageChangedSnackbar(context, languageCode);

      // UI'ı yenile
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Dil değiştirilirken bir hata oluştu: $e');
    }
  }

  // Dil değişti snackbar'ı
  void _showLanguageChangedSnackbar(BuildContext context, String languageCode) {
    final langName = _supportedLanguages.firstWhere(
          (lang) => lang['code'] == languageCode,
      orElse: () => _supportedLanguages[0],
    )['name'] as String;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.language, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dil değiştirildi: $langName',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Hata snackbar'ı
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Profil butonu - DEĞİŞTİRİLDİ: Direkt ProfileScreen'i açıyor
  // HomeScreen'deki _buildProfileButton metodunu güncelleyin:
  Widget _buildProfileButton(BuildContext context, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () {
        // ProfileScreen'i aç
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              onBack: () => Navigator.pop(context),
              onSettings: () {
                // AYARLAR EKRANINA GİT - GÜNCELLENMİŞ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Arkadaşlar ekranını aç
  void _openFriendsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openSpinWheelScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpinWheelScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openParentPanelScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentPanelScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openAIStorytellerScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIStorytellerScreen(),
      ),
    );
  }

  void _openVoiceCommandsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceCommandsScreen(),
      ),
    );
  }

  void _openAvatarScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarCustomizationScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openPetScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openLearningJourneyScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningJourneyScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openMathArtGalleryScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MathArtGalleryScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openVirtualMathLabScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VirtualMathLabScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Rozetler ekranını aç
  void _openBadgesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BadgesScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Günlük ödüller ekranını aç
  void _openDailyRewardsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyRewardsScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Hikaye modu ekranını aç
  void _openStoryModeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryModeScreen(),
      ),
    );
  }

  // Mini oyunlar ekranını aç
  void _openMiniGamesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MiniGamesScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Oyun başlangıç ekranını aç
  void _openGameStartScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameStartScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// MyAppState sınıfına erişim için extension
// Bu, main.dart'daki _MyAppState sınıfına erişmek için kullanılır
extension MyAppStateExtension on BuildContext {
  _MyAppState? get _myAppState => findAncestorStateOfType<_MyAppState>();
}

// MyAppState sınıfı - main.dart'daki sınıfa referans
// Bu sadece tip güvenliği için, gerçek sınıf main.dart'da
abstract class _MyAppState extends State<MyApp> {
  void changeLanguage(Locale locale);
}

// MyApp sınıfı - main.dart'daki sınıfa referans
abstract class MyApp extends StatefulWidget {
  const MyApp({super.key});
}