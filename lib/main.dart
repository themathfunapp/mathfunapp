import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

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
import 'services/premium_service_export.dart';
import 'services/ad_service.dart';
import 'services/family_service.dart';
import 'services/parent_pin_service.dart';
import 'providers/locale_provider.dart';
import 'screens/app_screen_wrappers.dart';
import 'screens/welcome_screen.dart';
import 'localization/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat - isolate kullanarak
  await _initializeFirebase();

  // AdMob'u başlat
  await AdService().initialize();

  // Performans için debugPrint ayarları
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      assert(() {
        // ignore: avoid_print
        print(message);
        return true;
      }());
    }
  };

  runApp(
    MultiProvider(
      providers: [
        // Dil yönetimi
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(),
        ),
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
              mechanicsService!.initialize(
                authService.currentUser!.uid,
                isGuest: authService.currentUser!.isGuest,
              );
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
        ChangeNotifierProxyProvider<AuthService, PremiumService>(
          create: (_) => PremiumService(),
          update: (_, authService, premiumService) {
            premiumService!.initialize(userId: authService.currentUser?.uid);
            return premiumService;
          },
        ),
        ChangeNotifierProxyProvider<PremiumService, AdService>(
          create: (_) => AdService(),
          update: (_, premiumService, adService) {
            // Premium durumunu AdService ile senkronize et
            adService!.setPremiumUser(premiumService.isPremium);
            return adService;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, FamilyService>(
          create: (_) => FamilyService(),
          update: (_, authService, familyService) {
            if (authService.currentUser != null && !authService.currentUser!.isGuest) {
              familyService!.initialize(
                authService.currentUser!.uid,
                parentDisplayName: authService.currentUser!.displayName ?? authService.currentUser!.username,
              );
            } else {
              familyService!.initialize(null);
            }
            return familyService;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, ParentPinService>(
          create: (_) => ParentPinService(),
          update: (_, authService, pinService) {
            pinService!.initialize(
              authService.currentUser?.isGuest == true ? null : authService.currentUser?.uid,
            );
            return pinService;
          },
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
    
    // Web için oturum kalıcılığını ayarla (tarayıcı kapatılsa bile oturum açık kalsın)
    await AuthService.initializePersistence();
  } catch (e) {
    debugPrint("Firebase başlatma hatası: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        if (localeProvider.isLoading) {
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
          locale: localeProvider.locale,
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
            Locale('hi', 'IN'),
            Locale('ur', 'PK'),
            Locale('pt', 'BR'),
            Locale('it', 'IT'),
            Locale('pl', 'PL'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == localeProvider.locale.languageCode) {
                return supportedLocale;
              }
            }
            return localeProvider.locale;
          },
          home: const AuthWrapper(),
        );
      },
    );
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
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<AppUser?>(
          stream: authService.userStream,
          initialData: authService.currentUser,
          builder: (context, snapshot) {
            // currentUser öncelikli: misafir çıkışında stream güncellenmediği için
            // snapshot.data eski kalabilir; signOut sonrası WelcomeScreen göstermek için
            // currentUser tek kaynak (snapshot sadece stream'in çalışması için)
            final user = authService.currentUser;
            if (user != null) {
              return const HomeScreenWrapper();
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return _AuthWrapperLoadingScreen();

              case ConnectionState.active:
              case ConnectionState.done:
                return WelcomeScreen(
                  initialPageIsLoginOptions: authService.showLoginOptionsOnWelcome,
                  onSignInComplete: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreenWrapper(),
                      ),
                    );
                  },
                  onSkip: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreenWrapper(),
                      ),
                    );
                  },
                );

              default:
                return _AuthWrapperLoadingScreen();
            }
          },
        );
      },
    );
  }
}

class _AuthWrapperLoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
