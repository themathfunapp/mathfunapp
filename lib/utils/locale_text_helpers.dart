/// RTL dillerde İngilizce/Latin + rakam karışımlarında ünlem ve sayıların
/// ters görünmesini azaltmak için rakamları LTR embed eder.
class LocaleTextHelpers {
  LocaleTextHelpers._();

  static const Set<String> _rtlDigitIsolateLocales = {
    'ar',
    'fa',
    'ur',
    'ku',
    'hi',
  };

  static bool useLtrDigitIsolation(String languageCode) =>
      _rtlDigitIsolateLocales.contains(languageCode);

  /// ASCII rakam gruplarını LTR işaretleriyle sarar (\u200E).
  static String embedLtrForAsciiDigits(String s) {
    return s.replaceAllMapped(
      RegExp(r'[0-9]+'),
      (m) => '\u200E${m[0]}\u200E',
    );
  }

  /// Günlük ödül / bonus cümleleri için: RTL yerelde İngilizce düşünce bile
  /// okunabilir sıra korunur.
  static String rewardBannerText(String languageCode, String message) {
    if (!useLtrDigitIsolation(languageCode)) return message;
    return embedLtrForAsciiDigits(message);
  }

  /// Arapça / Farsça vb. RTL arayüzde `2 + 3 = ?` ifadesinin `? = 3 + 2` gibi
  /// bidi kurallarıyla ters görünmesini engeller (U+2066 LRI … U+2069 PDI).
  static String ltrMathIsolate(String expression) {
    if (expression.isEmpty) return expression;
    return '\u2066$expression\u2069';
  }
}
