import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../localization/app_localizations.dart';
import '../models/game_manager.dart';

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

  @override
  void initState() {
    super.initState();
    // GameManager'ı Provider'dan veya direkt olarak alabilirsiniz
    _gameManager = GameManager();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
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
        child: Column(
          children: [
            // Üst Bar
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Eğlenceli Geri Butonu
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

                  // Denge için boş spacer
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
                    // Dil Ayarı
                    _buildLanguageSettingItem(context),

                    const Divider(color: Color(0xFFE0E0E0), height: 1),

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

                    // Bildirimler
                    _buildSettingItem(
                      context: context,
                      title: localizations.get('notifications'),
                      subtitle: localizations.get('notifications_subtitle'),
                      isEnabled: true,
                      onToggle: (value) {
                        // Bildirim ayarı
                      },
                      emoji: "⏰",
                    ),
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
                        subtitle: localizations.get('developer_name'),
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
              padding: const EdgeInsets.all(16.0),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
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
    required String flag,
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
            Text(
              flag,
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
  }) {
    return InkWell(
      onTap: () {
        onToggle(!isEnabled);
      },
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
              onChanged: onToggle,
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

// GameManager Model Sınıfı (Örnek)
class GameManager {
  bool soundEnabled = true;
  bool musicEnabled = true;

// Diğer game manager özellikleri...
}