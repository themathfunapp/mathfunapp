import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final savedLanguage = prefs.getString('user_language') ?? 'tr';
      _locale = Locale(savedLanguage);
    } catch (e) {
      _locale = const Locale('tr');
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
