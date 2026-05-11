import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathfun/localization/app_supported_locales.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = resolveAppLocale('tr');
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
        _locale = resolveAppLocale(savedLanguage);
      } else {
        // İlk açılış: cihaz dilini algıla
        final deviceLocale = ui.PlatformDispatcher.instance.locale;
        final deviceCode = deviceLocale.languageCode.toLowerCase();
        if (kSupportedLanguageCodes.contains(deviceCode)) {
          _locale = resolveAppLocale(deviceCode);
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
    final resolved =
        kSupportedLanguageCodes.contains(newLocale.languageCode)
            ? resolveAppLocale(newLocale.languageCode)
            : newLocale;
    if (_locale != resolved) {
      _locale = resolved;
      notifyListeners();
      
      // Dil tercihini kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_language', resolved.languageCode);
      } catch (e) {
        debugPrint('Dil kaydedilirken hata: $e');
      }
    }
  }
}
