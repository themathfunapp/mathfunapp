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
import 'package:mathfun/services/in_app_notification_service.dart';
import 'package:mathfun/services/family_remote_duel_service.dart';
import 'package:mathfun/services/friend_duel_service.dart';
import 'package:mathfun/services/family_story_invite_service.dart';
import 'package:mathfun/services/parent_mode_service.dart';
import 'package:mathfun/services/parent_pin_service.dart';
import 'package:mathfun/services/audio_service.dart';
import 'package:mathfun/services/push_notification_service.dart';
import 'package:mathfun/services/parent_panel_background_nudge_service.dart';
import 'package:mathfun/providers/locale_provider.dart';
import 'package:mathfun/localization/app_supported_locales.dart';
import 'package:mathfun/screens/app_screen_wrappers.dart';
import 'package:mathfun/screens/welcome_screen.dart';
import 'package:mathfun/localization/app_localizations.dart';
import 'package:mathfun/localization/material_localizations_fallback.dart';
import 'package:mathfun/app_navigator.dart';
import 'package:mathfun/widgets/global_remote_duel_invite_host.dart';
import 'package:mathfun/widgets/global_friend_duel_invite_host.dart';
import 'package:mathfun/widgets/background_music_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat - isolate kullanarak
  await _initializeFirebase();

  // AdMob'u başlat
  await AdService().initialize();
  await ParentPanelBackgroundNudgeService.initialize();

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
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Dil yönetimi (hesap bazlı senkron: web/mobil)
        ChangeNotifierProxyProvider<AuthService, LocaleProvider>(
          create: (_) => LocaleProvider(),
          update: (_, authService, localeProvider) {
            final locale = localeProvider ?? LocaleProvider();
            // ignore: discarded_futures
            locale.syncWithAuth(authService);
            return locale;
          },
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
            final u = authService.currentUser;
            premiumService!
              ..attachAuthService(authService)
              ..initialize(
                userId: u?.uid,
                userCode: u?.userCode,
              );
            return premiumService;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, PremiumService, InAppNotificationService>(
          create: (_) => InAppNotificationService(),
          update: (_, authService, premiumService, notifService) {
            final u = authService.currentUser;
            final premiumOk = u != null &&
                !u.isGuest &&
                u.uid.isNotEmpty &&
                premiumService.isPremium;
            notifService!.initialize(u, premiumActive: premiumOk);
            return notifService;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, PremiumService, GameMechanicsService>(
          create: (_) => GameMechanicsService(),
          update: (_, authService, premiumService, mechanicsService) {
            final m = mechanicsService!;
            // Firestore kullanıcı kaydı (Auth) ve mağaza (Premium) birlikte — yalnızca PremiumService yeterli değil.
            final premium = authService.currentUser != null &&
                !authService.isGuest &&
                (authService.isPremium || premiumService.isPremium);
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
        Provider<FriendDuelService>(
          create: (_) => FriendDuelService(),
        ),
        Provider<FamilyStoryInviteService>(
          create: (_) => FamilyStoryInviteService(),
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
          return _buildLoadingApp(localeProvider.locale);
        }

        final appName = AppLocalizations(localeProvider.locale).appName;
        return MaterialApp(
          navigatorKey: appRootNavigatorKey,
          title: appName,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            // Kurmanji metinler bu uygulamada Latin; Flutter bazen ku için RTL seçiyor,
            // karşılama dil şeridinde görsel/hit-test kayması oluyordu.
            // child null iken mor ColoredBox dolgu web’de rota itildikten sonra kalıcı
            // “boş ekran” yapıyordu (Navigator geçici null); sadece gerçek child kullan.
            Widget w = BackgroundMusicHost(
              child: GlobalFriendDuelInviteHost(
                child: GlobalRemoteDuelInviteHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
            if (localeProvider.locale.languageCode == 'ku') {
              w = Directionality(
                textDirection: TextDirection.ltr,
                child: w,
              );
            }
            // Tüm cihazlarda ve tüm dillerde (özellikle uzun RTL metinlerde)
            // sistem font ölçeklemesinden kaynaklanan taşmaları azalt.
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: w,
            );
          },
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
            MaterialLocalizationsFallbackDelegate(),
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: kAppSupportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == localeProvider.locale.languageCode) {
                return supportedLocale;
              }
            }
            return localeProvider.locale;
          },
          // locale: yeterli; ValueKey ile AuthWrapper sıfırlanınca dil değişiminde
          // auth stream yeniden beklemeye düşüp sonsuz yükleme ekranına takılabiliyordu.
          home: const AuthWrapper(),
        );
      },
    );
  }

  // Basit loading ekranı
  static Widget _buildLoadingApp(Locale locale) {
    final appName = AppLocalizations(locale).appName;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                appName,
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
            final user = authService.currentUser ?? snapshot.data;
            if (user != null) {
              return const HomeScreenWrapper();
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                if (authService.currentUser != null) {
                  return const HomeScreenWrapper();
                }
                return _AuthWrapperLoadingScreen();

              case ConnectionState.active:
              case ConnectionState.done:
                return WelcomeScreen(
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
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final appName = AppLocalizations(locale).appName;
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
                appName,
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
