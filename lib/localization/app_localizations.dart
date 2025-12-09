import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'home_title': 'Matematik Macerası',
      'home_subtitle': 'Eğlenerek Öğren',
      'home_improve_skills': 'Matematik Becerilerini Geliştir!',
      'home_learn_fun': 'Matematik öğrenmek hiç bu kadar eğlenceli olmamıştı!',
      'start_game': 'Oyuna Başla! 🚀',
      'story_mode': 'Hikaye Modu',
      'mini_games': 'Mini Oyunlar',
      'mini_games_count': '10+ oyun',
      'daily_rewards': 'Günlük Ödüller',
      'badges': 'Rozetlerim',
      'friends': 'Arkadaşlar',
      'profile': 'Profil',
      'upgrade_to_premium': "Premium'a Yükselt",
    },
    'en': {
      'home_title': 'Math Adventure',
      'home_subtitle': 'Learn with Fun',
      'home_improve_skills': 'Improve Math Skills!',
      'home_learn_fun': 'Learning math has never been this fun!',
      'start_game': 'Start Game! 🚀',
      'story_mode': 'Story Mode',
      'mini_games': 'Mini Games',
      'mini_games_count': '10+ games',
      'daily_rewards': 'Daily Rewards',
      'badges': 'My Badges',
      'friends': 'Friends',
      'profile': 'Profile',
      'upgrade_to_premium': 'Upgrade to Premium',
    },
  };

  String get homeTitle => _localizedValues[locale.languageCode]?['home_title'] ?? 'Matematik Macerası';
  String get homeSubtitle => _localizedValues[locale.languageCode]?['home_subtitle'] ?? 'Eğlenerek Öğren';
  String get homeImproveSkills => _localizedValues[locale.languageCode]?['home_improve_skills'] ?? 'Matematik Becerilerini Geliştir!';
  String get homeLearnFun => _localizedValues[locale.languageCode]?['home_learn_fun'] ?? 'Matematik öğrenmek hiç bu kadar eğlenceli olmamıştı!';
  String get startGame => _localizedValues[locale.languageCode]?['start_game'] ?? 'Oyuna Başla! 🚀';
  String get storyMode => _localizedValues[locale.languageCode]?['story_mode'] ?? 'Hikaye Modu';
  String get miniGames => _localizedValues[locale.languageCode]?['mini_games'] ?? 'Mini Oyunlar';
  String get miniGamesCount => _localizedValues[locale.languageCode]?['mini_games_count'] ?? '10+ oyun';
  String get dailyRewards => _localizedValues[locale.languageCode]?['daily_rewards'] ?? 'Günlük Ödüller';
  String get badges => _localizedValues[locale.languageCode]?['badges'] ?? 'Rozetlerim';
  String get friends => _localizedValues[locale.languageCode]?['friends'] ?? 'Arkadaşlar';
  String get profile => _localizedValues[locale.languageCode]?['profile'] ?? 'Profil';
  String get upgradeToPremium => _localizedValues[locale.languageCode]?['upgrade_to_premium'] ?? "Premium'a Yükselt";
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}