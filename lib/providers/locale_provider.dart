import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın desteklediği dil kodları (main.dart supportedLocales ile uyumlu)
const List<String> kSupportedLanguageCodes = [
  'tr', 'en', 'de', 'ar', 'fa', 'zh', 'id', 'ku', 'es', 'fr', 'ru', 'ja', 'ko', 'hi', 'ur', 'pt', 'it', 'pl',
];

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr');
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedLanguage = prefs.getString('user_language');

      if (savedLanguage != null && kSupportedLanguageCodes.contains(savedLanguage)) {
        _locale = Locale(savedLanguage);
      } else {
        // İlk açılış: cihaz dilini algıla
        final deviceLocale = ui.PlatformDispatcher.instance.locale;
        final deviceCode = deviceLocale.languageCode.toLowerCase();
        if (kSupportedLanguageCodes.contains(deviceCode)) {
          _locale = Locale(deviceCode);
          await prefs.setString('user_language', deviceCode);
        } else {
          _locale = const Locale('en');
          await prefs.setString('user_language', 'en');
        }
      }
    } catch (e) {
      _locale = const Locale('en');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
      
      // Dil tercihini kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_language', newLocale.languageCode);
      } catch (e) {
        debugPrint('Dil kaydedilirken hata: $e');
      }
    }
  }
}
