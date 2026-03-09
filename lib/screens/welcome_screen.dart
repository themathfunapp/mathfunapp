import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/shiny_button.dart';
import '../localization/app_localizations.dart';
import '../models/app_user.dart';
import 'home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';



class WelcomeScreen extends StatefulWidget {
  final VoidCallback onSignInComplete;
  final VoidCallback onSkip;
  /// Profilde "Hesap Oluştur" tıklandığında true; giriş seçenekleri sayfasına (index 1) başlar
  final bool initialPageIsLoginOptions;

  const WelcomeScreen({
    super.key,
    required this.onSignInComplete,
    required this.onSkip,
    this.initialPageIsLoginOptions = false,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  bool _initialized = false;
  late int _currentPage;
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

  @override
  void initState() {
    super.initState();
    final initialPage = widget.initialPageIsLoginOptions ? 1 : 0;
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
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

    // E-posta ile kayıt
    options.add({
      'id': 'email',
      'title': AppLocalizations(_currentLocale).get('sign_in_email'),
      'icon': '✉️',
      'color': Colors.blue,
      'description': AppLocalizations(_currentLocale).get('email_signup_desc'),
    });

    return options;
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
          // Google Sign-In - auth service içinde hesap seçimi yönetilir
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
        // Dil tercihini kaydet
        await authService.updateUserLanguage(_currentLocale.languageCode);

        // Kullanıcı tipine göre yönlendirme
        if (user.isGuest) {
          _navigateToHomeScreen();
        } else {
          widget.onSignInComplete();
        }
      } else {
        // Kullanıcı giriş yapmadı (hesap seçmedi veya iptal etti)
        setState(() {
          _isLoading = false;
          _selectedOption = '';
        });
      }
    } catch (e) {
      _showErrorSnackbar('${AppLocalizations(_currentLocale).get('login_error')}: $e');
      setState(() {
        _isLoading = false;
        _selectedOption = '';
      });
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
    final localizations = AppLocalizations(_currentLocale);
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
    const imagePath = 'assets/images/welcome_illustration.png';

    return Stack(
      children: [
        // 1) ARKA PLAN: cover + blur + karartma (ekranı doldurur)
        Positioned.fill(
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover, // ekran dolsun
                alignment: Alignment.center,
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(color: Colors.black.withOpacity(0.25)),
              ),
            ],
          ),
        ),

        // 2) ÖN PLAN: görselin tamamı (kırpma yok)
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 100, 48, 140),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 60,
                        spreadRadius: -20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ShaderMask(
                      shaderCallback: (Rect rect) {
                        return RadialGradient(
                          center: Alignment.center,
                          radius: 0.75,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.85, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3) ÜSTTEKİ YAZILAR + BUTONLAR (senin mevcut content’in)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        localizations.get('app_name'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.get('app_motto'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    localizations.get('welcome_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    localizations.get('welcome_description'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black54,
                      ),
                      child: Text(
                        localizations.get('continue_button'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
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
          const SizedBox(height: 24),
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
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildWelcomePage(localizations), // 🔥 TAM EKRAN GÖRSEL
          _buildLoginOptions(localizations),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}