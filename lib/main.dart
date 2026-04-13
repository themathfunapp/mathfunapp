import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:mathfun/firebase_options.dart';
import 'package:mathfun/models/app_user.dart';
import 'package:mathfun/services/auth_service.dart';
import 'package:mathfun/services/friend_service.dart';
import 'package:mathfun/services/badge_service.dart';
import 'package:mathfun/services/daily_reward_service.dart';
import 'package:mathfun/services/story_service.dart';
import 'package:mathfun/services/mini_game_service.dart';
import 'package:mathfun/services/game_mechanics_service.dart';
import 'package:mathfun/services/offline_service.dart';
import 'package:mathfun/services/ai_storyteller_service.dart';
import 'package:mathfun/services/voice_command_service.dart';
import 'package:mathfun/services/premium_service_export.dart';
import 'package:mathfun/services/ad_service.dart';
import 'package:mathfun/services/family_service.dart';
import 'package:mathfun/services/family_remote_duel_service.dart';
import 'package:mathfun/services/parent_mode_service.dart';
import 'package:mathfun/services/parent_pin_service.dart';
import 'package:mathfun/services/audio_service.dart';
import 'package:mathfun/services/push_notification_service.dart';
import 'package:mathfun/providers/locale_provider.dart';
import 'package:mathfun/screens/app_screen_wrappers.dart';
import 'package:mathfun/screens/welcome_screen.dart';
import 'package:mathfun/localization/app_localizations.dart';

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
        ChangeNotifierProvider<AudioService>(
          lazy: false,
          create: (_) {
            final audio = AudioService();
            audio.initialize();
            return audio;
          },
        ),
        ChangeNotifierProvider<ParentModeService>(
          create: (_) => ParentModeService(),
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
        // Web DDC: modülü ilk karede yükle; hot reload sonrası "Library not defined" riskini azaltır.
        ChangeNotifierProxyProvider<AuthService, BadgeService>(
          lazy: false,
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
        ChangeNotifierProxyProvider<AuthService, PremiumService>(
          create: (_) => PremiumService(),
          update: (_, authService, premiumService) {
            premiumService!.initialize(userId: authService.currentUser?.uid);
            return premiumService;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, PremiumService, GameMechanicsService>(
          create: (_) => GameMechanicsService(),
          update: (_, authService, premiumService, mechanicsService) {
            final m = mechanicsService!;
            final premium = authService.currentUser != null && premiumService.isPremium;
            m.setPremiumUnlimited(premium);
            if (authService.currentUser != null) {
              final u = authService.currentUser!;
              if (m.shouldReloadForUser(u.uid, u.isGuest)) {
                m.initialize(u.uid, isGuest: u.isGuest);
              }
            } else {
              m.setPremiumUnlimited(false);
            }
            return m;
          },
        ),
        ChangeNotifierProxyProvider<GameMechanicsService, StoryService>(
          create: (_) => StoryService(),
          update: (_, mechanics, previous) {
            final story = previous!;
            story.attachMechanicsWallet(mechanics);
            return story;
          },
        ),
        ChangeNotifierProxyProvider<GameMechanicsService, MiniGameService>(
          create: (_) => MiniGameService(),
          update: (_, mechanics, previous) {
            final mini = previous!;
            mini.attachMechanicsWallet(mechanics);
            return mini;
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
        Provider<FamilyRemoteDuelService>(
          create: (_) => FamilyRemoteDuelService(),
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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.initialize();
  });
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
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
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
