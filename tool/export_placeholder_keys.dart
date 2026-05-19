// ignore_for_file: avoid_print
// dart run tool/export_placeholder_keys.dart ku

import 'dart:io';

const _langs = [
  'tr', 'en', 'de', 'ar', 'fa', 'zh', 'id', 'ku', 'es', 'fr', 'ru', 'ja',
  'ko', 'hi', 'ur', 'pt', 'it', 'pl',
];

void main(List<String> args) {
  final lang = args.isEmpty ? 'ku' : args.first;
  final text = File('lib/localization/app_localizations.dart').readAsStringSync();
  final en = _parseBlock(text, 'en');
  final tr = _parseBlock(text, 'tr');
  final target = _parseBlock(text, lang);
  final keys = <String>[];
  for (final k in target.keys) {
    if (target[k] == en[k] && tr[k] != en[k]) keys.add(k);
  }
  keys.sort();
  final out = File('tool/placeholders_$lang.txt');
  out.writeAsStringSync(keys.join('\n'));
  print('${keys.length} keys -> ${out.path}');
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
