import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathfun/config/legal_urls.dart';
import 'package:mathfun/localization/app_localizations.dart';
import 'package:mathfun/models/app_user.dart';
import 'package:mathfun/providers/locale_provider.dart';
import 'package:mathfun/screens/home_screen.dart';
import 'package:mathfun/services/auth_service.dart';



class WelcomeScreen extends StatefulWidget {
  final VoidCallback onSignInComplete;
  final VoidCallback onSkip;

  const WelcomeScreen({
    super.key,
    required this.onSignInComplete,
    required this.onSkip,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  String _selectedOption = '';

  // Platform kontrol fonksiyonları
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;
  bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;
  bool get _isWeb => kIsWeb;

  // Desteklenen diller listesi (LocaleProvider.kSupportedLanguageCodes ile uyumlu)
  static final List<Map<String, dynamic>> _supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'fa', 'name': 'فارسی', 'flag': '🇮🇷'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'ku', 'name': 'Kurdî', 'flag': '☀️'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ur', 'name': 'اردو', 'flag': '🇵🇰'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pl', 'name': 'Polski', 'flag': '🇵🇱'},
  ];

  String _platformTitle(Locale locale) {
    if (_isIOS || _isMacOS) return AppLocalizations(locale).get('apple_signin_title');
    if (_isAndroid) return AppLocalizations(locale).get('google_signin_title');
    return AppLocalizations(locale).get('welcome_title');
  }

  String _platformDescription(Locale locale) {
    if (_isIOS || _isMacOS) return AppLocalizations(locale).get('apple_signin_desc');
    if (_isAndroid) return AppLocalizations(locale).get('google_signin_desc');
    return AppLocalizations(locale).get('welcome_subtitle');
  }

  List<Map<String, dynamic>> _loginOptions(Locale locale) {
    return [
      {
        'id': 'google',
        'title': AppLocalizations(locale).get('sign_in_google'),
        'icon': 'G',
        'color': Colors.red,
        'description': AppLocalizations(locale).get('google_signin_desc'),
      },
      {
        'id': 'email',
        'title': AppLocalizations(locale).get('sign_in_email'),
        'icon': '✉️',
        'color': Colors.blue,
        'description': AppLocalizations(locale).get('email_signup_desc'),
      },
    ];
  }

// WelcomeScreen.dart içindeki _handleLogin metodunu güncelle

  void _handleLogin(String optionId) async {
    setState(() {
      _selectedOption = optionId;
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      AppUser? user;

      switch (optionId) {
        case 'google':
          user = await authService.signInWithGoogle();
          break;
        case 'email':
          await _showEmailDialog();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _selectedOption = '';
            });
          }
          return;
      }

      if (user != null) {
        if (!mounted) return;
        // Dil tercihini kaydet
        await authService.updateUserLanguage(Provider.of<LocaleProvider>(context, listen: false).locale.languageCode);
        if (!mounted) return;

        // Kullanıcı tipine göre yönlendirme
        if (user.isGuest) {
          _navigateToHomeScreen();
        } else {
          widget.onSignInComplete();
        }
      } else {
        // Kullanıcı giriş yapmadı (hesap seçmedi veya iptal etti)
        if (mounted) {
          setState(() {
            _isLoading = false;
            _selectedOption = '';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations(
        Provider.of<LocaleProvider>(context, listen: false).locale,
      );
      if (e is GoogleSignInShaNotRegisteredException) {
        _showErrorSnackbar(loc.googleSigninShaFirebaseShort);
      } else if (kIsWeb && AuthService.isGoogleWebOriginConfigError(e)) {
        _showErrorSnackbar(loc.googleSigninWebOriginMismatch);
      } else {
        _showErrorSnackbar('${loc.loginError}: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedOption = '';
        });
      }
    } finally {
      // Sadece hata durumunda değil, başarılı durumda da isLoading'i false yap
      // Ancak bu kısım zaten yönlendirme yapıldığı için çalışmayabilir
      if (mounted && _selectedOption.isEmpty) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          onGameSelection: () {},
          onDailyRewards: () {},
          onBadges: () {},
          onFriends: () {},
          onStoryMode: () {},
          onMiniGames: () {},
          onPremium: () {},
        ),
      ),
    );
  }

  Future<void> _showEmailDialog() async {
    final localizations = AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale);
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isSignUp = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isSignUp ? localizations.get('create_account') : localizations.get('sign_in')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: localizations.get('email'),
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: localizations.get('password'),
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignUp = !isSignUp;
                      });
                    },
                    child: Text(
                      isSignUp
                          ? localizations.get('already_have_account')
                          : localizations.get('no_account_signup'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isSignUp)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogin('guest');
                      },
                      child: Text(
                        localizations.get('continue_as_guest'),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.get('cancel'),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      _showErrorSnackbar(localizations.get('fill_all_fields'));
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      AppUser? user;

                      if (isSignUp) {
                        user = await authService.signUpWithEmail(email, password);
                      } else {
                        user = await authService.signInWithEmail(email, password);
                      }

                      if (user != null) {
                        await authService.updateUserLanguage(Provider.of<LocaleProvider>(context, listen: false).locale.languageCode);
                        Navigator.pop(context);

                        if (user.isGuest) {
                          _navigateToHomeScreen();
                        } else {
                          widget.onSignInComplete();
                        }
                      }
                    } catch (e) {
                      _showErrorSnackbar('${localizations.get('error')}: $e');
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    isSignUp ? localizations.get('sign_up') : localizations.get('sign_in'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    await localeProvider.changeLanguage(Locale(languageCode));

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.updateUserLanguage(languageCode);

    if (!mounted) return;
    final name = _supportedLanguages.firstWhere((lang) => lang['code'] == languageCode)['name'] as String;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations(localeProvider.locale).get('language_changed')} $name',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            _selectedOption = 'guest';
            _isLoading = true;
          });

          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            final guestUser = await authService.signInAsGuest();

            if (guestUser != null) {
              await authService.updateUserLanguage(Provider.of<LocaleProvider>(context, listen: false).locale.languageCode);
              _navigateToHomeScreen();
            }
          } catch (e) {
            _showErrorSnackbar('Misafir girişi hatası: $e');
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations(Provider.of<LocaleProvider>(context, listen: false).locale).get('continue_as_guest'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_isLoading && _selectedOption == 'guest')
              const SizedBox(width: 12),
            if (_isLoading && _selectedOption == 'guest')
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(Locale currentLocale) {
    final current = _supportedLanguages.firstWhere(
      (l) => l['code'] == currentLocale.languageCode,
      orElse: () => _supportedLanguages.first,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _showLanguageSheet(currentLocale),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, color: Colors.grey, size: 22),
              const SizedBox(width: 8),
              Text(
                current['flag'] as String,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                current['name'] as String,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: Colors.grey[700], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(Locale currentLocale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations(currentLocale).get('language_setting'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = _supportedLanguages[index];
                    final code = lang['code'] as String;
                    final isSelected = currentLocale.languageCode == code;
                    return ListTile(
                      leading: Text(lang['flag'] as String, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        lang['name'] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () {
                        Navigator.pop(context);
                        _changeLanguage(code);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginOptions(AppLocalizations localizations, Locale locale) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLanguageSelector(locale),
          Text(
            _platformTitle(locale),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _platformDescription(locale),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._loginOptions(locale).map((option) {
            final bool isSelected = _selectedOption == option['id'];
            final Color optionColor = option['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: optionColor, width: 2)
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handleLogin(option['id'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: optionColor.withOpacity(isSelected ? 0.15 : 0.1),
                    foregroundColor: optionColor,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: optionColor.withOpacity(isSelected ? 0.5 : 0.3),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (option['icon'] is String && (option['icon'] as String).length == 1)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: optionColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              option['icon'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                color: optionColor,
                              ),
                            ),
                          ),
                        )
                      else if (option['icon'] == 'G')
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: optionColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              option['icon'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: optionColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              option['icon'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_isLoading && _selectedOption == option['id'])
                        const SizedBox(width: 16),
                      if (_isLoading && _selectedOption == option['id'])
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: optionColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.get('to_start_now'),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGuestButton(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  localizations.get('privacy_terms_agreement'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => LegalUrls.openPrivacyPolicy(context, localizations),
                      child: Text(
                        localizations.privacyPolicy,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue[700],
                        ),
                      ),
                    ),
                    Text('|', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => LegalUrls.openTermsOfUse(context, localizations),
                      child: Text(
                        localizations.termsOfUse,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.get('guest_mode_info'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentLocale = localeProvider.locale;
        final localizations = AppLocalizations(currentLocale);

        return Scaffold(
          body: SafeArea(
            child: _buildLoginOptions(localizations, currentLocale),
          ),
        );
      },
    );
  }


}