import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../settings/SettingsScreen.dart';
import '../widgets/animated_math_symbol.dart';
import '../widgets/shiny_button.dart';
import '../widgets/story_mode_button.dart';
import '../widgets/mini_games_button.dart';
import '../widgets/premium_button.dart';
import '../widgets/bottom_action_button.dart';
import '../widgets/kurdistan_flag.dart'; // KurtceFlag widget
import '../localization/app_localizations.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/parent_mode_service.dart';
import '../services/premium_service_export.dart';
import '../screens/profile_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/badges_screen.dart';
import '../screens/daily_rewards_screen.dart';
import '../screens/story_mode_screen.dart';
import '../screens/mini_games_screen.dart';
import '../screens/game_start_screen.dart';
import '../screens/parent_panel_screen.dart';
import '../screens/parent_mode_games_hub.dart';
import '../screens/ai_storyteller_screen.dart';
import '../screens/voice_commands_screen.dart';
import '../screens/learning_journey_screen.dart';
import '../screens/math_art_gallery_screen.dart';
import '../screens/virtual_math_lab_screen.dart';
import '../screens/avatar_customization_screen.dart';
import '../screens/pet_screen.dart';

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

  // Desteklenen diller listesi - Ekrandaki tüm diller
  final List<Map<String, dynamic>> _supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ar', 'name': 'العربية (Arapça)', 'flag': '🇸🇦'},
    {'code': 'fa', 'name': 'فارسی (Farsça)', 'flag': '🇮🇷'},
    {'code': 'zh', 'name': '中文 (Çince)', 'flag': '🇨🇳'},
    {'code': 'id', 'name': 'Bahasa (Endonezce)', 'flag': '🇮🇩'},
    {'code': 'ku', 'name': 'Kurdî (Kürtçe)', 'flag': '☀️'},
    {'code': 'es', 'name': 'Español (İspanyolca)', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français (Fransızca)', 'flag': '🇫🇷'},
    {'code': 'ru', 'name': 'Русский (Rusça)', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': '日本語 (Japonca)', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어 (Korece)', 'flag': '🇰🇷'},
    {'code': 'hi', 'name': 'हिन्दी (Hintçe)', 'flag': '🇮🇳'},
    {'code': 'ur', 'name': 'اردو (Urduca)', 'flag': '🇵🇰'},
    {'code': 'pt', 'name': 'Português (Portekizce)', 'flag': '🇧🇷'},
    {'code': 'it', 'name': 'Italiano (İtalyanca)', 'flag': '🇮🇹'},
    {'code': 'pl', 'name': 'Polski (Lehçe)', 'flag': '🇵🇱'},
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context);
    final parentMode = Provider.of<ParentModeService>(context);

    final useParentHome = parentMode.isLoaded &&
        parentMode.isParentMode &&
        authService.currentUser?.isGuest != true;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: primaryGradient),
        child: Stack(
          children: [
            // Dönen matematik sembolü - dokunma olaylarını engellemez
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedMathSymbol(),
              ),
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

                if (useParentHome)
                  ..._buildParentModeHome(context)
                else
                  ..._buildStandardHomeBody(context, localizations, authService),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParentModeHome(BuildContext context) {
    return [
      ParentModeGamesHub.forHome(
        onOpenParentPanel: () => _openParentPanelScreen(context),
      ),
      const SizedBox(height: 24),
    ];
  }

  Future<void> _confirmEnterParentMode(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ebeveyn modu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Ebeveyn moduna geçmek istediğinizden emin misiniz?\n\n'
          'Bu modda yalnızca aile oyunları ve ebeveyn paneline yönelik ekranlar gösterilir.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, geç'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await Provider.of<ParentModeService>(context, listen: false).setParentMode(true);
    }
  }

  List<Widget> _buildStandardHomeBody(
    BuildContext context,
    AppLocalizations localizations,
    AuthService authService,
  ) {
    return [
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

      Consumer<PremiumService>(
        builder: (context, premiumService, _) {
          if (premiumService.isPremium) {
            return const SizedBox.shrink();
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              PremiumButton(
                onPressed: widget.onPremium,
              ),
            ],
          );
        },
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

      // İkinci satır - Ebeveyn Paneli (şans çarkı Günlük Ödüller içinde)
      Row(
        children: [
          Expanded(
            child: BottomActionButton(
              text: localizations.parentPanel,
              emoji: '👨‍👩‍👧',
              onPressed: () => _openParentPanelScreen(context),
            ),
          ),
        ],
      ),

      if (authService.currentUser?.isGuest != true)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton(
            onPressed: () => _confirmEnterParentMode(context),
            child: Text(
              'Ebeveyn moduna geç (sadece aile özellikleri)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ),
        ),

      // TODO: Yayın sonrası güncellemede eklenecek özellikler (6-7 ay sonra)
      // İKİNCİ SATIĞA EKLENECEKLER:
      // - Hikaye (📖) - _openAIStorytellerScreen
      //
      // ÜÇÜNCÜ SATIR:
      // - Sesli (🎤) - _openVoiceCommandsScreen
      // - Avatar (👤) - _openAvatarScreen
      // - Evcil (🐱) - _openPetScreen
      //
      // DÖRDÜNCÜ SATIR:
      // - Yolculuk (🗺️) - _openLearningJourneyScreen
      // - Galeri (🎨) - _openMathArtGalleryScreen
      // - Laboratuvar (🧪) - _openVirtualMathLabScreen

      const SizedBox(height: 24),
    ];
  }

  // Dil değiştirme butonu
  Widget _buildLanguageButton(BuildContext context, AuthService authService) {
    final currentLocale = Localizations.localeOf(context);
    final isKurdish = currentLocale.languageCode == 'ku';
    
    return ElevatedButton(
      onPressed: () {
        debugPrint('Dil butonu tıklandı!');
        _showLanguageDialog(context, authService);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
        elevation: 4,
      ),
      child: isKurdish
          ? const KurtceFlag(size: 28)
          : Text(
              _getCurrentFlag(authService),
              style: const TextStyle(fontSize: 24),
            ),
    );
  }
  
  // Bayrak widget'ı oluştur (Kürtçe için özel widget)
  Widget _buildFlagWidget(String languageCode, String flagEmoji, {double size = 24}) {
    if (languageCode == 'ku') {
      return KurtceFlag(size: size);
    }
    return Text(
      flagEmoji,
      style: TextStyle(fontSize: size),
    );
  }

  // Dil seçim dialogu - DÜZELTİLDİ: Tüm diller görünür
  void _showLanguageDialog(BuildContext ctx, AuthService authService) {
    debugPrint('_showLanguageDialog çağrıldı');
    final currentLocale = Localizations.localeOf(ctx);
    
    showDialog(
      context: ctx,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.7, // Ekranın %70'i
              maxWidth: 400,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Row(
                    children: [
                      const Icon(Icons.language, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Dil Seçin',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dil listesi - Expanded ile tüm alanı kullan
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _supportedLanguages.length,
                      itemBuilder: (_, index) {
                        final lang = _supportedLanguages[index];
                        final isCurrent = currentLocale.languageCode == lang['code'];
                        
                        return InkWell(
                          onTap: () {
                            _changeLanguage(dialogContext, lang['code'] as String, authService);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCurrent 
                                  ? Colors.blue.withOpacity(0.2) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isCurrent 
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                _buildFlagWidget(
                                  lang['code'] as String,
                                  lang['flag'] as String,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    lang['name'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrent ? Colors.blue : Colors.white,
                                    ),
                                  ),
                                ),
                                if (isCurrent)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // İptal butonu
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
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

  // Dil değiştirme işlemi
  void _changeLanguage(BuildContext dialogContext, String languageCode, AuthService authService) async {
    // Önce dialog'u kapat
    Navigator.of(dialogContext).pop();
    
    try {
      // AuthService üzerinden dil güncelle
      await authService.updateUserLanguage(languageCode);

      // LocaleProvider üzerinden dil değiştir - anında değişiklik
      if (mounted) {
        context.read<LocaleProvider>().changeLanguage(Locale(languageCode));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(context, 'Dil değiştirilirken bir hata oluştu: $e');
      }
    }
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

  void _openProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          onBack: () => Navigator.pop(context),
          onSettings: () {
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
  }

  // Profil butonu
  Widget _buildProfileButton(BuildContext context, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () => _openProfileScreen(context),
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

  // Ekran açma metodları
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

  void _openParentPanelScreen(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.isGuest == true) {
      _showParentPanelGuestDialog(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentPanelScreen(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showParentPanelGuestDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Text(
              localizations.parentPanelLoginRequired,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          localizations.parentPanelLoginRequiredDesc,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.close, style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openProfileScreen(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            child: Text(localizations.createAccount),
          ),
        ],
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

  void _openStoryModeScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryModeScreen(),
      ),
    );
  }

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