// ignore_for_file: avoid_print
// dart run tool/patch_settings_legal_all.dart

import 'dart:io';

/// Settings / legal / web notification strings — proper 18-language text.
const _patches = <String, Map<String, String>>{
  'tr': {
    'notifications_web_disabled': 'Web sürümünde kapalı',
    'settings_legal_section': 'Gizlilik ve yasal',
    'settings_legal_privacy': 'Gizlilik politikası',
    'settings_legal_privacy_sub': 'Tarayıcıda veya uygulama içi özet',
    'settings_legal_terms': 'Kullanım şartları',
    'settings_legal_terms_sub': 'Tarayıcıda veya uygulama içi özet',
    'settings_ad_privacy': 'Reklam gizliliği seçenekleri',
    'settings_ad_privacy_sub': 'Kişiselleştirilmiş reklamlar (Google UMP)',
    'legal_open_in_browser': 'Web\'de aç',
    'legal_link_open_failed': 'Bağlantı açılamadı',
  },
  'en': {
    'notifications_web_disabled': 'Unavailable on web',
    'settings_legal_section': 'Privacy & legal',
    'settings_legal_privacy': 'Privacy policy',
    'settings_legal_privacy_sub': 'In browser or in-app summary',
    'settings_legal_terms': 'Terms of use',
    'settings_legal_terms_sub': 'In browser or in-app summary',
    'settings_ad_privacy': 'Ad privacy choices',
    'settings_ad_privacy_sub': 'Personalized ads (Google UMP)',
    'legal_open_in_browser': 'Open in browser',
    'legal_link_open_failed': 'Could not open link',
  },
  'de': {
    'notifications_web_disabled': 'In der Web-Version nicht verfügbar',
    'settings_legal_section': 'Datenschutz und Rechtliches',
    'settings_legal_privacy': 'Datenschutzerklärung',
    'settings_legal_privacy_sub': 'Im Browser oder als App-Übersicht',
    'settings_legal_terms': 'Nutzungsbedingungen',
    'settings_legal_terms_sub': 'Im Browser oder als App-Übersicht',
    'settings_ad_privacy': 'Werbe-Datenschutzeinstellungen',
    'settings_ad_privacy_sub': 'Personalisierte Werbung (Google UMP)',
    'legal_open_in_browser': 'Im Browser öffnen',
    'legal_link_open_failed': 'Link konnte nicht geöffnet werden',
  },
  'ar': {
    'notifications_web_disabled': 'غير متاح في نسخة الويب',
    'settings_legal_section': 'الخصوصية والقانونية',
    'settings_legal_privacy': 'سياسة الخصوصية',
    'settings_legal_privacy_sub': 'في المتصفح أو ملخص داخل التطبيق',
    'settings_legal_terms': 'شروط الاستخدام',
    'settings_legal_terms_sub': 'في المتصفح أو ملخص داخل التطبيق',
    'settings_ad_privacy': 'خيارات خصوصية الإعلانات',
    'settings_ad_privacy_sub': 'إعلانات مخصصة (Google UMP)',
    'legal_open_in_browser': 'فتح في المتصفح',
    'legal_link_open_failed': 'تعذر فتح الرابط',
  },
  'fa': {
    'notifications_web_disabled': 'در نسخه وب در دسترس نیست',
    'settings_legal_section': 'حریم خصوصی و حقوقی',
    'settings_legal_privacy': 'سیاست حریم خصوصی',
    'settings_legal_privacy_sub': 'در مرورگر یا خلاصه درون برنامه',
    'settings_legal_terms': 'شرایط استفاده',
    'settings_legal_terms_sub': 'در مرورگر یا خلاصه درون برنامه',
    'settings_ad_privacy': 'گزینه‌های حریم خصوصی تبلیغات',
    'settings_ad_privacy_sub': 'تبلیغات شخصی‌سازی‌شده (Google UMP)',
    'legal_open_in_browser': 'باز کردن در مرورگر',
    'legal_link_open_failed': 'پیوند باز نشد',
  },
  'zh': {
    'notifications_web_disabled': '网页版不可用',
    'settings_legal_section': '隐私与法律',
    'settings_legal_privacy': '隐私政策',
    'settings_legal_privacy_sub': '在浏览器或应用内摘要中查看',
    'settings_legal_terms': '使用条款',
    'settings_legal_terms_sub': '在浏览器或应用内摘要中查看',
    'settings_ad_privacy': '广告隐私选项',
    'settings_ad_privacy_sub': '个性化广告 (Google UMP)',
    'legal_open_in_browser': '在浏览器中打开',
    'legal_link_open_failed': '无法打开链接',
  },
  'id': {
    'notifications_web_disabled': 'Tidak tersedia di versi web',
    'settings_legal_section': 'Privasi & hukum',
    'settings_legal_privacy': 'Kebijakan privasi',
    'settings_legal_privacy_sub': 'Di browser atau ringkasan dalam aplikasi',
    'settings_legal_terms': 'Ketentuan penggunaan',
    'settings_legal_terms_sub': 'Di browser atau ringkasan dalam aplikasi',
    'settings_ad_privacy': 'Pilihan privasi iklan',
    'settings_ad_privacy_sub': 'Iklan dipersonalisasi (Google UMP)',
    'legal_open_in_browser': 'Buka di browser',
    'legal_link_open_failed': 'Tautan tidak dapat dibuka',
  },
  'ku': {
    'notifications_web_disabled': 'Di guhertoya webê de girtî ye',
    'settings_legal_section': 'Taybetî û qanûnî',
    'settings_legal_privacy': 'Siyaseta taybetîtiyê',
    'settings_legal_privacy_sub': 'Di gerokê an kurteya nav sepanê de',
    'settings_legal_terms': 'Mercên bikaranînê',
    'settings_legal_terms_sub': 'Di gerokê an kurteya nav sepanê de',
    'settings_ad_privacy': 'Vebijarkên taybetîtiya reklamê',
    'settings_ad_privacy_sub': 'Reklamên kesane (Google UMP)',
    'legal_open_in_browser': 'Di gerokê de veke',
    'legal_link_open_failed': 'Girêdan nehat vekirin',
  },
  'es': {
    'notifications_web_disabled': 'No disponible en la versión web',
    'settings_legal_section': 'Privacidad y legal',
    'settings_legal_privacy': 'Política de privacidad',
    'settings_legal_privacy_sub': 'En el navegador o resumen en la app',
    'settings_legal_terms': 'Términos de uso',
    'settings_legal_terms_sub': 'En el navegador o resumen en la app',
    'settings_ad_privacy': 'Opciones de privacidad de anuncios',
    'settings_ad_privacy_sub': 'Anuncios personalizados (Google UMP)',
    'legal_open_in_browser': 'Abrir en el navegador',
    'legal_link_open_failed': 'No se pudo abrir el enlace',
  },
  'fr': {
    'notifications_web_disabled': 'Indisponible sur la version web',
    'settings_legal_section': 'Confidentialité et mentions légales',
    'settings_legal_privacy': 'Politique de confidentialité',
    'settings_legal_privacy_sub': 'Dans le navigateur ou résumé dans l\'app',
    'settings_legal_terms': 'Conditions d\'utilisation',
    'settings_legal_terms_sub': 'Dans le navigateur ou résumé dans l\'app',
    'settings_ad_privacy': 'Choix de confidentialité des annonces',
    'settings_ad_privacy_sub': 'Annonces personnalisées (Google UMP)',
    'legal_open_in_browser': 'Ouvrir dans le navigateur',
    'legal_link_open_failed': 'Impossible d\'ouvrir le lien',
  },
  'ru': {
    'notifications_web_disabled': 'Недоступно в веб-версии',
    'settings_legal_section': 'Конфиденциальность и правовая информация',
    'settings_legal_privacy': 'Политика конфиденциальности',
    'settings_legal_privacy_sub': 'В браузере или кратко в приложении',
    'settings_legal_terms': 'Условия использования',
    'settings_legal_terms_sub': 'В браузере или кратко в приложении',
    'settings_ad_privacy': 'Настройки конфиденциальности рекламы',
    'settings_ad_privacy_sub': 'Персонализированная реклама (Google UMP)',
    'legal_open_in_browser': 'Открыть в браузере',
    'legal_link_open_failed': 'Не удалось открыть ссылку',
  },
  'ja': {
    'notifications_web_disabled': 'Web版では利用できません',
    'settings_legal_section': 'プライバシーと法的情報',
    'settings_legal_privacy': 'プライバシーポリシー',
    'settings_legal_privacy_sub': 'ブラウザまたはアプリ内の概要',
    'settings_legal_terms': '利用規約',
    'settings_legal_terms_sub': 'ブラウザまたはアプリ内の概要',
    'settings_ad_privacy': '広告のプライバシー設定',
    'settings_ad_privacy_sub': 'パーソナライズ広告 (Google UMP)',
    'legal_open_in_browser': 'ブラウザで開く',
    'legal_link_open_failed': 'リンクを開けませんでした',
  },
  'ko': {
    'notifications_web_disabled': '웹 버전에서는 사용할 수 없음',
    'settings_legal_section': '개인정보 및 법적 고지',
    'settings_legal_privacy': '개인정보 처리방침',
    'settings_legal_privacy_sub': '브라우저 또는 앱 내 요약',
    'settings_legal_terms': '이용 약관',
    'settings_legal_terms_sub': '브라우저 또는 앱 내 요약',
    'settings_ad_privacy': '광고 개인정보 선택',
    'settings_ad_privacy_sub': '맞춤형 광고 (Google UMP)',
    'legal_open_in_browser': '브라우저에서 열기',
    'legal_link_open_failed': '링크를 열 수 없습니다',
  },
  'hi': {
    'notifications_web_disabled': 'वेब संस्करण में उपलब्ध नहीं',
    'settings_legal_section': 'गोपनीयता और कानूनी',
    'settings_legal_privacy': 'गोपनीयता नीति',
    'settings_legal_privacy_sub': 'ब्राउज़र या ऐप में सारांश',
    'settings_legal_terms': 'उपयोग की शर्तें',
    'settings_legal_terms_sub': 'ब्राउज़र या ऐप में सारांश',
    'settings_ad_privacy': 'विज्ञापन गोपनीयता विकल्प',
    'settings_ad_privacy_sub': 'व्यक्तिगत विज्ञापन (Google UMP)',
    'legal_open_in_browser': 'ब्राउज़र में खोलें',
    'legal_link_open_failed': 'लिंक नहीं खुल सका',
  },
  'ur': {
    'notifications_web_disabled': 'ویب ورژن میں دستیاب نہیں',
    'settings_legal_section': 'رازداری اور قانونی',
    'settings_legal_privacy': 'رازداری کی پالیسی',
    'settings_legal_privacy_sub': 'براؤزر یا ایپ میں خلاصہ',
    'settings_legal_terms': 'استعمال کی شرائط',
    'settings_legal_terms_sub': 'براؤزر یا ایپ میں خلاصہ',
    'settings_ad_privacy': 'اشتہار کی رازداری کے اختیارات',
    'settings_ad_privacy_sub': 'ذاتی نوعیت کے اشتہارات (Google UMP)',
    'legal_open_in_browser': 'براؤزر میں کھولیں',
    'legal_link_open_failed': 'لنک نہیں کھل سکا',
  },
  'pt': {
    'notifications_web_disabled': 'Indisponível na versão web',
    'settings_legal_section': 'Privacidade e jurídico',
    'settings_legal_privacy': 'Política de privacidade',
    'settings_legal_privacy_sub': 'No navegador ou resumo no app',
    'settings_legal_terms': 'Termos de uso',
    'settings_legal_terms_sub': 'No navegador ou resumo no app',
    'settings_ad_privacy': 'Opções de privacidade de anúncios',
    'settings_ad_privacy_sub': 'Anúncios personalizados (Google UMP)',
    'legal_open_in_browser': 'Abrir no navegador',
    'legal_link_open_failed': 'Não foi possível abrir o link',
  },
  'it': {
    'notifications_web_disabled': 'Non disponibile nella versione web',
    'settings_legal_section': 'Privacy e note legali',
    'settings_legal_privacy': 'Informativa sulla privacy',
    'settings_legal_privacy_sub': 'Nel browser o riepilogo nell\'app',
    'settings_legal_terms': 'Termini di utilizzo',
    'settings_legal_terms_sub': 'Nel browser o riepilogo nell\'app',
    'settings_ad_privacy': 'Scelte privacy degli annunci',
    'settings_ad_privacy_sub': 'Annunci personalizzati (Google UMP)',
    'legal_open_in_browser': 'Apri nel browser',
    'legal_link_open_failed': 'Impossibile aprire il link',
  },
  'pl': {
    'notifications_web_disabled': 'Niedostępne w wersji internetowej',
    'settings_legal_section': 'Prywatność i informacje prawne',
    'settings_legal_privacy': 'Polityka prywatności',
    'settings_legal_privacy_sub': 'W przeglądarce lub podsumowanie w aplikacji',
    'settings_legal_terms': 'Warunki użytkowania',
    'settings_legal_terms_sub': 'W przeglądarce lub podsumowanie w aplikacji',
    'settings_ad_privacy': 'Ustawienia prywatności reklam',
    'settings_ad_privacy_sub': 'Spersonalizowane reklamy (Google UMP)',
    'legal_open_in_browser': 'Otwórz w przeglądarce',
    'legal_link_open_failed': 'Nie udało się otworzyć linku',
  },
};

void main() {
  const path = 'lib/localization/app_localizations.dart';
  var text = File(path).readAsStringSync();
  var total = 0;
  var inserted = 0;

  for (final entry in _patches.entries) {
    final lang = entry.key;
    final marker = "'$lang': {";
    final blockStart = text.indexOf(marker);
    if (blockStart < 0) {
      print('SKIP lang $lang');
      continue;
    }
    final contentStart = blockStart + marker.length;
    final blockEnd = _findMapBlockEnd(text, contentStart);
    var block = text.substring(blockStart, blockEnd);

    for (final kv in entry.value.entries) {
      final key = kv.key;
      final value = _escape(kv.value);
      final pattern = RegExp(
        "(\\s*'$key':\\s*)'(?:\\\\'|[^'])*'",
      );
      if (pattern.hasMatch(block)) {
        block = block.replaceFirstMapped(
          pattern,
          (m) => "${m.group(1)}'$value'",
        );
        total++;
      } else if (key == 'notifications_web_disabled') {
        final anchor = RegExp(
          r"(\s*'notifications_subtitle':\s*'(?:\\'|[^'])*',)",
        );
        if (anchor.hasMatch(block)) {
          block = block.replaceFirstMapped(
            anchor,
            (m) => "${m.group(1)}\n      '$key': '$value',",
          );
          inserted++;
        } else {
          print('WARN $lang: no anchor for $key');
        }
      } else {
        print('WARN $lang: missing $key');
      }
    }

    text = text.substring(0, blockStart) + block + text.substring(blockEnd);
  }

  File(path).writeAsStringSync(text);
  print('Updated $total keys, inserted $inserted new keys');
}

String _escape(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

int _findMapBlockEnd(String text, int start) {
  var depth = 1;
  var i = start;
  while (i < text.length && depth > 0) {
    if (text.startsWith("'''", i)) {
      final end = text.indexOf("'''", i + 3);
      i = end < 0 ? text.length : end + 3;
      continue;
    }
    if (text[i] == "'") {
      i++;
      while (i < text.length) {
        final c = text[i];
        if (c == r'\') {
          i += 2;
          continue;
        }
        if (c == "'") {
          i++;
          if (i < text.length && text[i] == "'") {
            i++;
            continue;
          }
          break;
        }
        i++;
      }
      continue;
    }
    if (text[i] == '{') depth++;
    if (text[i] == '}') depth--;
    i++;
  }
  return i;
}
