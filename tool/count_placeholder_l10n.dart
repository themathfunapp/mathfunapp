// ignore_for_file: avoid_print
// dart run tool/count_placeholder_l10n.dart

import 'dart:io';

const _langs = [
  'tr', 'en', 'de', 'ar', 'fa', 'zh', 'id', 'ku', 'es', 'fr', 'ru', 'ja',
  'ko', 'hi', 'ur', 'pt', 'it', 'pl',
];

void main() {
  final text = File('lib/localization/app_localizations.dart').readAsStringSync();
  final blocks = <String, Map<String, String>>{};
  for (final lang in _langs) {
    blocks[lang] = _parseBlock(text, lang);
  }
  final en = blocks['en']!;
  final tr = blocks['tr']!;

  for (final lang in _langs) {
    if (lang == 'en' || lang == 'tr') continue;
    final m = blocks[lang]!;
    var n = 0;
    for (final k in m.keys) {
      if (m[k] == en[k] && tr[k] != en[k]) n++;
    }
    print('$lang: $n keys still English (tr translated)');
  }
}

Map<String, String> _parseBlock(String text, String lang) {
  final marker = "'$lang': {";
  final idx = text.indexOf(marker);
  if (idx < 0) return {};
  var i = idx + marker.length;
  var depth = 1;
  while (i < text.length && depth > 0) {
    final c = text[i];
    if (c == '{') depth++;
    if (c == '}') depth--;
    i++;
  }
  final block = text.substring(idx + marker.length, i - 1);
  final map = <String, String>{};
  final re = RegExp(r"'([^']+)':\s*'((?:\\'|[^'])*)'");
  for (final match in re.allMatches(block)) {
    map[match.group(1)!] =
        match.group(2)!.replaceAll(r"\'", "'");
  }
  return map;
}
