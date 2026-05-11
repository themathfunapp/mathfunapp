import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mathfun/localization/app_supported_locales.dart';

/// Flutter'ın [GlobalMaterialLocalizations] desteklemediği dil kodları (ör. `ku`)
/// için İngilizce Material etiketlerini yükler. Böylece AppBar, Dialog vb. çökmez;
/// uygulama metinleri yine [AppLocalizations] ile seçilen dilde kalır.
class MaterialLocalizationsFallbackDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const MaterialLocalizationsFallbackDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLanguageCodes.contains(locale.languageCode) &&
      !_globalMaterialSupports(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(MaterialLocalizationsFallbackDelegate old) => false;

  static bool _globalMaterialSupports(Locale locale) {
    return GlobalMaterialLocalizations.delegate.isSupported(locale);
  }
}
