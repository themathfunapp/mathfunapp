import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'services/friend_service.dart';
import 'services/badge_service.dart';
import 'services/daily_reward_service.dart';
import 'services/story_service.dart';
import 'services/mini_game_service.dart';
import 'services/game_mechanics_service.dart';
import 'services/offline_service.dart';
import 'services/ai_storyteller_service.dart';
import 'services/voice_command_service.dart';
import 'screens/home_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/daily_rewards_screen.dart';
import 'screens/story_mode_screen.dart';
import 'localization/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat - isolate kullanarak
  await _initializeFirebase();

  // Performans için debugPrint ayarları
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      // Sadece debug modda log göster
      assert(() {
        print(message);
        return true;
      }());
    }
  };

  runApp(
    MultiProvider(
      providers: [
        // Lazy loading'i aç - sadece ihtiyaç duyulunca oluştur
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProxyProvider<AuthService, FriendService>(
          create: (_) => FriendService(),
          update: (_, authService, friendService) {
            friendService!.initialize(authService.currentUser);
            return friendService;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, BadgeService>(
          create: (_) => BadgeService(),
          update: (_, authService, badgeService) {
            badgeService!.initialize(authService.currentUser);
            return badgeService;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, DailyRewardService>(
          create: (_) => DailyRewardService(),
          update: (_, authService, rewardService) {
            rewardService!.initialize(authService.currentUser);
            return rewardService;
          },
        ),
        ChangeNotifierProvider<StoryService>(
          create: (_) => StoryService(),
        ),
        ChangeNotifierProvider<MiniGameService>(
          create: (_) => MiniGameService(),
        ),
        ChangeNotifierProxyProvider<AuthService, GameMechanicsService>(
          create: (_) => GameMechanicsService(),
          update: (_, authService, mechanicsService) {
            if (authService.currentUser != null) {
              mechanicsService!.initialize(authService.currentUser!.uid);
            }
            return mechanicsService!;
          },
        ),
        ChangeNotifierProvider<OfflineService>(
          create: (_) {
            final service = OfflineService();
            service.initialize();
            return service;
          },
        ),
        ChangeNotifierProvider<AIStorytellerService>(
          create: (_) => AIStorytellerService(),
        ),
        ChangeNotifierProvider<VoiceCommandService>(
          create: (_) => VoiceCommandService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Firebase'i arka planda başlat
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase başlatma hatası: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Locale>(
      future: _getInitialLocale(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingApp();
        }

        return MaterialApp(
          title: 'Matematik Macerası',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          themeMode: ThemeMode.light,
          locale: snapshot.data ?? const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
            Locale('de', 'DE'),
            Locale('ar', 'SA'),
            Locale('fa', 'IR'),
            Locale('zh', 'CN'),
            Locale('id', 'ID'),
            Locale('ku', 'IQ'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            Locale('ru', 'RU'),
            Locale('ja', 'JP'),
            Locale('ko', 'KR'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            // Basitleştirilmiş dil çözümleme
            final savedLocale = snapshot.data ?? const Locale('tr');
            if (savedLocale != const Locale('tr')) {
              return savedLocale;
            }

            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }

            return const Locale('tr');
          },
          home: const AuthWrapper(),
        );
      },
    );
  }

  // Başlangıç dili al
  static Future<Locale> _getInitialLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('user_language') ?? 'tr';
      return Locale(savedLanguage);
    } catch (e) {
      return const Locale('tr');
    }
  }

  // Basit loading ekranı
  static Widget _buildLoadingApp() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Matematik Macerası',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AppUser?>(
      stream: authService.userStream,
      initialData: authService.currentUser, // İlk veriyi kullan
      builder: (context, snapshot) {
        // İlk veri varsa hemen göster
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreenWrapper();
        }

        // Bağlantı durumu
        // Bağlantı durumu
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return _buildLoadingScreen();

          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasData && snapshot.data != null) {
              return const HomeScreenWrapper();
            } else {
              return WelcomeScreen(
                onSignInComplete: () {
                  // giriş tamamlandıktan sonra ana ekrana geç
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreenWrapper(),
                    ),
                  );
                },
                onSkip: () {
                  // misafir / atla
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreenWrapper(),
                    ),
                  );
                },
              );
            }

          default:
            return _buildLoadingScreen();
        }

      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Matematik Macerası',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      onPremium: () {},
    );
  }
}