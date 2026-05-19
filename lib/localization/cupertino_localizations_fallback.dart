import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mathfun/localization/app_supported_locales.dart';

/// Flutter [GlobalCupertinoLocalizations] desteklemediği diller (ör. `ku`) için
/// İngilizce Cupertino etiketleri; uygulama metinleri [AppLocalizations] ile kalır.
class CupertinoLocalizationsFallbackDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CupertinoLocalizationsFallbackDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLanguageCodes.contains(locale.languageCode) &&
      !GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(CupertinoLocalizationsFallbackDelegate old) => false;
}
