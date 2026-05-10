// PDF haftalık öneri havuzları — 18 dil (ebeveyn paneli LocaleProvider ile uyumlu).
// Metinlerde emoji yok (Roboto PDF uyumu).

import 'pdf_weekly_report_tips_data_lists.dart';

/// İki harfli dil kodu (zh-TW → zh).
String pdfWeeklyReportNormalizeLang(String? languageCode) {
  final raw = (languageCode ?? 'en').trim().toLowerCase();
  if (raw.isEmpty) return 'en';
  if (raw.startsWith('zh')) return 'zh';
  final two = raw.length >= 2 ? raw.substring(0, 2) : raw;
  return two;
}

/// Güçlü hafta önerileri (25 madde).
List<String> pdfWeeklyTipsStrong(String languageCode) {
  switch (pdfWeeklyReportNormalizeLang(languageCode)) {
    case 'tr':
      return pdfTipsTrStrong;
    case 'de':
      return pdfTipsDeStrong;
    case 'es':
      return pdfTipsEsStrong;
    case 'fr':
      return pdfTipsFrStrong;
    case 'ar':
      return pdfTipsArStrong;
    case 'fa':
      return pdfTipsFaStrong;
    case 'zh':
      return pdfTipsZhStrong;
    case 'id':
      return pdfTipsIdStrong;
    case 'ku':
      return pdfTipsKuStrong;
    case 'ru':
      return pdfTipsRuStrong;
    case 'ja':
      return pdfTipsJaStrong;
    case 'ko':
      return pdfTipsKoStrong;
    case 'hi':
      return pdfTipsHiStrong;
    case 'ur':
      return pdfTipsUrStrong;
    case 'pt':
      return pdfTipsPtStrong;
    case 'it':
      return pdfTipsItStrong;
    case 'pl':
      return pdfTipsPlStrong;
    case 'en':
    default:
      return pdfTipsEnStrong;
  }
}

/// Gelişim haftası önerileri (25 madde).
List<String> pdfWeeklyTipsWeak(String languageCode) {
  switch (pdfWeeklyReportNormalizeLang(languageCode)) {
    case 'tr':
      return pdfTipsTrWeak;
    case 'de':
      return pdfTipsDeWeak;
    case 'es':
      return pdfTipsEsWeak;
    case 'fr':
      return pdfTipsFrWeak;
    case 'ar':
      return pdfTipsArWeak;
    case 'fa':
      return pdfTipsFaWeak;
    case 'zh':
      return pdfTipsZhWeak;
    case 'id':
      return pdfTipsIdWeak;
    case 'ku':
      return pdfTipsKuWeak;
    case 'ru':
      return pdfTipsRuWeak;
    case 'ja':
      return pdfTipsJaWeak;
    case 'ko':
      return pdfTipsKoWeak;
    case 'hi':
      return pdfTipsHiWeak;
    case 'ur':
      return pdfTipsUrWeak;
    case 'pt':
      return pdfTipsPtWeak;
    case 'it':
      return pdfTipsItWeak;
    case 'pl':
      return pdfTipsPlWeak;
    case 'en':
    default:
      return pdfTipsEnWeak;
  }
}
