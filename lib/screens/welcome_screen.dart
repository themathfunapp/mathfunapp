import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/shiny_button.dart';
import '../localization/app_localizations.dart';
import '../models/app_user.dart';
import 'home_screen.dart';
import 'package:firebase_core/firebase_core.dart';

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
  final PageController _pageController = PageController();
  bool _initialized = false;
  int _currentPage = 0;
  bool _isLoading = false;
  String _selectedOption = '';
  Locale _currentLocale = const Locale('tr');

  // Platform kontrol fonksiyonları
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;
  bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;
  bool get _isWeb => kIsWeb;

  // Desteklenen diller listesi
  final List<Map<String, dynamic>> _supportedLanguages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp();
    setState(() {
      _initialized = true;
    });
  }

  // Platforma göre başlık ve açıklama
  String get _platformTitle {
    if (_isIOS || _isMacOS) {
      return AppLocalizations(_currentLocale).get('apple_signin_title');
    }
    if (_isAndroid) {
      return AppLocalizations(_currentLocale).get('google_signin_title');
    }
    return AppLocalizations(_currentLocale).get('welcome_title');
  }

  String get _platformDescription {
    if (_isIOS || _isMacOS) {
      return AppLocalizations(_currentLocale).get('apple_signin_desc');
    }
    if (_isAndroid) {
      return AppLocalizations(_currentLocale).get('google_signin_desc');
    }
    return AppLocalizations(_currentLocale).get('welcome_subtitle');
  }

  List<Map<String, dynamic>> get _loginOptions {
    List<Map<String, dynamic>> options = [];

    // Google tüm platformlar için
    options.add({
      'id': 'google',
      'title': AppLocalizations(_currentLocale).get('sign_in_google'),
      'icon': 'G',
      'color': Colors.red,
      'description': AppLocalizations(_currentLocale).get('google_signin_desc'),
    });

    // Diğer seçenekler
    options.addAll([
      {
        'id': 'email',
        'title': AppLocalizations(_currentLocale).get('sign_in_email'),
        'icon': '✉️',
        'color': Colors.blue,
        'description': AppLocalizations(_currentLocale).get('email_signup_desc'),
      },
      {
        'id': 'guest',
        'title': AppLocalizations(_currentLocale).get('sign_in_guest'),
        'icon': '👤',
        'color': Colors.grey,
        'description': AppLocalizations(_currentLocale).get('guest_signin_desc'),
      },
      {
        'id': 'skip',
        'title': AppLocalizations(_currentLocale).get('sign_in_later'),
        'icon': '➡️',
        'color': Colors.orange,
        'description': AppLocalizations(_currentLocale).get('skip_description'),
      },
    ]);

    return options;
  }

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
          _showEmailDialog();
          return;
        case 'guest':
          user = await authService.signInAsGuest();
          break;
        case 'skip':
          widget.onSkip();
          return;
      }

      if (user != null) {
        // Dil tercihini kaydet
        await authService.updateUserLanguage(_currentLocale.languageCode);

        // Kullanıcı tipine göre yönlendirme
        if (user.isGuest) {
          _navigateToHomeScreen();
        } else {
          widget.onSignInComplete();
        }
      }
    } catch (e) {
      _showErrorSnackbar('${AppLocalizations(_currentLocale).get('login_error')}: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showEmailDialog() {
    final localizations = AppLocalizations(_currentLocale);
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isSignUp = false;

    showDialog(
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
                        await authService.updateUserLanguage(_currentLocale.languageCode);
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
    setState(() {
      _currentLocale = Locale(languageCode);
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.updateUserLanguage(languageCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Dil değiştirildi: ${_supportedLanguages.firstWhere((lang) => lang['code'] == languageCode)['name']}',
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
              await authService.updateUserLanguage(_currentLocale.languageCode);
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
                AppLocalizations(_currentLocale).get('continue_as_guest'),
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

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomePage(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(110),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.school,
                size: 100,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            localizations.get('welcome_title'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.get('welcome_description'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeatureItem(
            icon: Icons.star,
            color: Colors.amber,
            text: localizations.get('personalized_learning'),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.track_changes,
            color: Colors.green,
            text: localizations.get('progress_tracking'),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.cloud_upload,
            color: Colors.blue,
            text: localizations.get('cloud_backup'),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.games,
            color: Colors.purple,
            text: 'Eğlenceli Oyunlar',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.emoji_events,
            color: Colors.orange,
            text: 'Rozetler ve Başarılar',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.person_outline,
            color: Colors.grey,
            text: 'Misafir Modu - Hemen Başla',
          ),
        ],
      ),
    );
  }

  Widget _buildLoginOptions(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _platformTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _platformDescription,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._loginOptions.map((option) {
            final bool isSelected = _selectedOption == option['id'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: option['color'], width: 2)
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handleLogin(option['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: option['color'].withOpacity(isSelected ? 0.15 : 0.1),
                    foregroundColor: option['color'],
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: option['color'].withOpacity(isSelected ? 0.5 : 0.3),
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
                            color: option['color'].withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              option['icon'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                color: option['color'],
                              ),
                            ),
                          ),
                        )
                      else if (option['icon'] == 'G')
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: option['color'],
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
                            color: option['color'],
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
                            color: option['color'],
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
                  'Hemen başlamak için:',
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
                const SizedBox(height: 8),
                Text(
                  'Misafir modunda, geçici bir hesap ile uygulamayı kullanabilirsiniz. '
                      'Daha sonra hesap oluşturarak verilerinizi kaydedebilirsiniz.',
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
          const SizedBox(height: 16),
          if (!_isLoading)
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Üyelik Olmadan Demo Modu',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final localizations = AppLocalizations(_currentLocale);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // SAĞ ÜSTE DİL SEÇİCİ
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language, color: Colors.blue, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _supportedLanguages.firstWhere(
                                  (lang) => lang['code'] == _currentLocale.languageCode,
                              orElse: () => _supportedLanguages[0],
                            )['flag'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: _changeLanguage,
                    itemBuilder: (BuildContext context) {
                      return _supportedLanguages.map((lang) {
                        return PopupMenuItem<String>(
                          value: lang['code'],
                          child: Row(
                            children: [
                              Text(
                                lang['flag'] as String,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                lang['name'] as String,
                                style: TextStyle(
                                  fontWeight: _currentLocale.languageCode == lang['code']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _currentLocale.languageCode == lang['code']
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                                ),
                              ),
                              if (_currentLocale.languageCode == lang['code'])
                                const SizedBox(width: 8),
                              if (_currentLocale.languageCode == lang['code'])
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '📚 ${localizations.get('app_name')}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.get('app_motto'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildWelcomePage(localizations),
                    _buildLoginOptions(localizations),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (_currentPage == 0)
                ShinyButton(
                  text: localizations.get('continue_button'),
                  onPressed: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}