import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'localization/app_localizations.dart';

void main() {
  runApp(const MathFunApp());
}

class MathFunApp extends StatefulWidget {
  const MathFunApp({super.key});

  @override
  State<MathFunApp> createState() => _MathFunAppState();
}

class _MathFunAppState extends State<MathFunApp> {
  Locale _locale = const Locale('tr');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matematik Macerası',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      home: HomeScreen(
        onGameSelection: () {
          print('Oyun seçimine git');
        },
        onProfile: () {
          print('Profile git');
        },
        onDailyRewards: () {
          print('Günlük ödüllere git');
        },
        onBadges: () {
          print('Rozetlere git');
        },
        onFriends: () {
          print('Arkadaşlara git');
        },
        onStoryMode: () {
          print('Hikaye moduna git');
        },
        onMiniGames: () {
          print('Mini oyunlara git');
        },
        onPremium: () {
          print('Premium ekrana git');
        },
      ),
    );
  }
}