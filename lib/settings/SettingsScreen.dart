import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathfun/config/legal_urls.dart';
import 'package:mathfun/localization/app_localizations.dart';
import 'package:mathfun/models/game_manager.dart';
import 'package:mathfun/services/ad_service.dart';
import 'package:mathfun/services/auth_service.dart';
import 'package:mathfun/services/push_notification_service.dart';
import 'package:mathfun/widgets/kurdistan_flag.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameManager _gameManager;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _gameManager = GameManager();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kIsWeb || !mounted) return;
      final v = await PushNotificationService.instance.notificationsEnabled();
      if (mounted) setState(() => _notificationsEnabled = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final currentUser = authService.currentUser;
    final localizations = AppLocalizations(Locale(currentLocale));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Üst Bar
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: FunBackButton(
                          onPressed: widget.onBack,
                          emoji: "🎮",
                          scale: 1.0,
                        ),
                      ),

                      Text(
                        localizations.get('settings_title'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 60),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Ayarlar Listesi Kartı
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                child: Column(
                  children: [
                    // Dil Ayarı - Ana ekrana taşındı
                    // _buildLanguageSettingItem(context),
                    // const Divider(color: Color(0xFFE0E0E0), height: 1),

                    // Ses Efektleri
                    _buildSettingItem(
                      context: context,
                      title: localizations.get('sound_effects'),
                      subtitle: localizations.get('sound_effects_subtitle'),
                      isEnabled: _gameManager.soundEnabled,
                      onToggle: (value) {
                        setState(() {
                          _gameManager.soundEnabled = value;
                        });
                      },
                      emoji: "🔊",
                    ),

                    const Divider(color: Color(0xFFE0E0E0), height: 1),

                    // Müzik
                    _buildSettingItem(
                      context: context,
                      title: localizations.get('music'),
                      subtitle: localizations.get('music_subtitle'),
                      isEnabled: _gameManager.musicEnabled,
                      onToggle: (value) {
                        setState(() {
                          _gameManager.musicEnabled = value;
                        });
                      },
                      emoji: "🎹",
                    ),

                    const Divider(color: Color(0xFFE0E0E0), height: 1),

                    // Bildirimler (mobil: FCM tercihi; web: devre dışı)
                    _buildSettingItem(
                      context: context,
                      title: localizations.get('notifications'),
                      subtitle: kIsWeb
                          ? '${localizations.get('notifications_subtitle')} (Web sürümünde kapalı)'
                          : localizations.get('notifications_subtitle'),
                      isEnabled: kIsWeb ? false : _notificationsEnabled,
                      interactive: !kIsWeb,
                      onToggle: (value) async {
                        await PushNotificationService.instance.setNotificationsEnabled(value);
                        if (mounted) {
                          setState(() => _notificationsEnabled = value);
                        }
                      },
                      emoji: "⏰",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (currentUser != null && !currentUser.isGuest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Text('📧', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.get('email'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2d3436),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUser.email ?? '-',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
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

            if (currentUser != null && !currentUser.isGuest) const SizedBox(height: 16),

            // Gizlilik, şartlar, reklam tercihleri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              localizations.get('settings_legal_section'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2d3436),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildLegalNavTile(
                      context: context,
                      emoji: '📄',
                      title: localizations.get('settings_legal_privacy'),
                      subtitle: localizations.get('settings_legal_privacy_sub'),
                      onTap: () => LegalUrls.openPrivacyPolicy(context, localizations),
                    ),
                    const Divider(color: Color(0xFFE0E0E0), height: 1),
                    _buildLegalNavTile(
                      context: context,
                      emoji: '📜',
                      title: localizations.get('settings_legal_terms'),
                      subtitle: localizations.get('settings_legal_terms_sub'),
                      onTap: () => LegalUrls.openTermsOfUse(context, localizations),
                    ),
                    if (!kIsWeb) ...[
                      const Divider(color: Color(0xFFE0E0E0), height: 1),
                      _buildLegalNavTile(
                        context: context,
                        emoji: '🎯',
                        title: localizations.get('settings_ad_privacy'),
                        subtitle: localizations.get('settings_ad_privacy_sub'),
                        onTap: () => AdService.showPrivacyOptionsFormIfAvailable(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hakkında Kartı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "🌟",
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localizations.get('about'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3436),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _buildAboutItem(
                        emoji: "📱",
                        title: localizations.get('app_version'),
                        subtitle: localizations.get('app_motto'),
                      ),

                      _buildAboutItem(
                        emoji: "👨‍💻",
                        title: localizations.get('developer'),
                        subtitle: localizations.get('TheMathFunApp'),
                      ),

                      _buildAboutItem(
                        emoji: "🎯",
                        title: localizations.get('goal'),
                        subtitle: localizations.get('goal_subtitle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Eğlenceli Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    localizations.get('footer_motto'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dil Ayarı Widget'ı
  Widget _buildLanguageSettingItem(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    String getCurrentLangName(String code) {
      switch (code) {
        case 'tr': return localizations.get('language_tr');
        case 'en': return localizations.get('language_en');
        case 'de': return localizations.get('language_de');
        case 'ar': return localizations.get('language_ar');
        case 'fa': return localizations.get('language_fa');
        case 'zh': return localizations.get('language_zh');
        case 'id': return localizations.get('language_id');
        case 'ku': return localizations.get('language_ku');
        case 'es': return localizations.get('language_es');
        case 'fr': return localizations.get('language_fr');
        case 'ru': return localizations.get('language_ru');
        case 'ja': return localizations.get('language_ja');
        case 'ko': return localizations.get('language_ko');
        default: return code.toUpperCase();
      }
    }

    return InkWell(
      onTap: () {
        _showLanguageDialog(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "🌐",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.get('language_setting'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2d3436),
                      ),
                    ),
                    Text(
                      localizations.get('language_setting_subtitle'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              children: [
                Text(
                  getCurrentLangName(currentLocale),
                  style: const TextStyle(
                    color: Color(0xFF5A4FCF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF5A4FCF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dil Seçim Dialog'u
  void _showLanguageDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.get('select_language')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildLanguageOption(
                  context: context,
                  code: 'tr',
                  name: localizations.get('language_tr'),
                  flag: '🇹🇷',
                  isSelected: currentLocale == 'tr',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'en',
                  name: localizations.get('language_en'),
                  flag: '🇺🇸',
                  isSelected: currentLocale == 'en',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'de',
                  name: localizations.get('language_de'),
                  flag: '🇩🇪',
                  isSelected: currentLocale == 'de',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'ar',
                  name: localizations.get('language_ar'),
                  flag: '🇸🇦',
                  isSelected: currentLocale == 'ar',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'fa',
                  name: localizations.get('language_fa'),
                  flag: '🇮🇷',
                  isSelected: currentLocale == 'fa',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'zh',
                  name: localizations.get('language_zh'),
                  flag: '🇨🇳',
                  isSelected: currentLocale == 'zh',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'id',
                  name: localizations.get('language_id'),
                  flag: '🇮🇩',
                  isSelected: currentLocale == 'id',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'ku',
                  name: localizations.get('language_ku'),
                  flagWidget: const KurdistanFlag(size: 24),
                  isSelected: currentLocale == 'ku',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'es',
                  name: localizations.get('language_es'),
                  flag: '🇪🇸',
                  isSelected: currentLocale == 'es',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'fr',
                  name: localizations.get('language_fr'),
                  flag: '🇫🇷',
                  isSelected: currentLocale == 'fr',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'ru',
                  name: localizations.get('language_ru'),
                  flag: '🇷🇺',
                  isSelected: currentLocale == 'ru',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'ja',
                  name: localizations.get('language_ja'),
                  flag: '🇯🇵',
                  isSelected: currentLocale == 'ja',
                ),
                _buildLanguageOption(
                  context: context,
                  code: 'ko',
                  name: localizations.get('language_ko'),
                  flag: '🇰🇷',
                  isSelected: currentLocale == 'ko',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(localizations.get('cancel')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required String name,
    String? flag,
    Widget? flagWidget,
    required bool isSelected,
  }) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return InkWell(
      onTap: () async {
        await authService.updateUserLanguage(code);
        Navigator.pop(context);
        // Yenilemek için
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A4FCF).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (flagWidget != null)
              flagWidget
            else
              Text(
                flag ?? '',
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF5A4FCF) : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF5A4FCF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Ayar Öğesi Widget'ı
  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required Function(bool) onToggle,
    required String emoji,
    bool interactive = true,
  }) {
    return InkWell(
      onTap: interactive
          ? () {
              onToggle(!isEnabled);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2d3436),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Switch(
              value: isEnabled,
              onChanged: interactive ? onToggle : null,
              activeColor: const Color(0xFF5A4FCF),
              activeTrackColor: const Color(0xFF5A4FCF).withOpacity(0.5),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalNavTile({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2d3436),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5A4FCF)),
          ],
        ),
      ),
    );
  }

  // Hakkında Öğesi Widget'ı
  Widget _buildAboutItem({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2d3436),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Eğlenceli Geri Butonu Widget'ı
class FunBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String emoji;
  final double scale;

  const FunBackButton({
    super.key,
    required this.onPressed,
    this.emoji = "🎮",
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5A4FCF),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "←",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Alternatif Geri Butonu Seçenekleri
class FunBackButtonOption2 extends StatelessWidget {
  final VoidCallback onPressed;

  const FunBackButtonOption2({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5A4FCF),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🐢",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              localizations.get('back'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "←",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FunBackButtonOption3 extends StatelessWidget {
  final VoidCallback onPressed;

  const FunBackButtonOption3({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "🚀",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "←",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

