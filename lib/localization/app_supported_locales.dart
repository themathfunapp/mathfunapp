import 'package:flutter/material.dart';

/// Uygulamanın desteklediği 18 dil (tek kaynak).
///
/// Türkçe, İngilizce, Almanca, Arapça, Farsça, Çince, Endonezce, Kürtçe,
/// İspanyolca, Fransızca, Rusça, Japonca, Korece, Hintçe, Urduca,
/// Portekizce (BR), İtalyanca, Lehçe.
///
/// [AppLocalizations] içindeki `_localizedValues` anahtarları bu kodlarla eşleşmeli;
/// [MaterialApp.supportedLocales] ve [AppLocalizationsDelegate.isSupported] burayı kullanır.
const List<String> kSupportedLanguageCodes = [
  'tr',
  'en',
  'de',
  'ar',
  'fa',
  'zh',
  'id',
  'ku',
  'es',
  'fr',
  'ru',
  'ja',
  'ko',
  'hi',
  'ur',
  'pt',
  'it',
  'pl',
];

/// [MaterialApp.supportedLocales] ile aynı sıra ve ülke/bölge kodları (RTL eşlemesi için).
const List<Locale> kAppSupportedLocales = [
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
];

Locale resolveAppLocale(String languageCode) {
  switch (languageCode) {
    case 'tr':
      return const Locale('tr', 'TR');
    case 'en':
      return const Locale('en', 'US');
    case 'de':
      return const Locale('de', 'DE');
    case 'ar':
      return const Locale('ar', 'SA');
    case 'fa':
      return const Locale('fa', 'IR');
    case 'zh':
      return const Locale('zh', 'CN');
    case 'id':
      return const Locale('id', 'ID');
    case 'ku':
      return const Locale('ku', 'IQ');
    case 'es':
      return const Locale('es', 'ES');
    case 'fr':
      return const Locale('fr', 'FR');
    case 'ru':
      return const Locale('ru', 'RU');
    case 'ja':
      return const Locale('ja', 'JP');
    case 'ko':
      return const Locale('ko', 'KR');
    case 'hi':
      return const Locale('hi', 'IN');
    case 'ur':
      return const Locale('ur', 'PK');
    case 'pt':
      return const Locale('pt', 'BR');
    case 'it':
      return const Locale('it', 'IT');
    case 'pl':
      return const Locale('pl', 'PL');
    default:
      return Locale(languageCode);
  }
}

/// Dil seçici listeleri: [WelcomeScreen], [HomeScreen] ile ortak.
/// Kürtçe için Unicode bayrağı yok; `flag` boş, arayüzde [KurtceFlag] kullanılır.
const List<Map<String, dynamic>> kLanguagePickerEntries = [
  {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
  {'code': 'fa', 'name': 'فارسی', 'flag': '🇮🇷'},
  {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
  {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
  {'code': 'ku', 'name': 'Kurdî', 'flag': ''},
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
