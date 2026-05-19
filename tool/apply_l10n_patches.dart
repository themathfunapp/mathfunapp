// ignore_for_file: avoid_print
//
// JSON patch: tool/l10n_patches/<lang>.json  { "key": "translated value", ... }
// Applies replacements inside each language block in app_localizations.dart.
//
//   dart run tool/apply_l10n_patches.dart

import 'dart:convert';
import 'dart:io';

const _langs = [
  'de', 'ar', 'fa', 'zh', 'id', 'ku', 'es', 'fr', 'ru', 'ja', 'ko', 'hi', 'ur',
  'pt', 'it', 'pl', 'tr', 'en',
];

void main() {
  const path = 'lib/localization/app_localizations.dart';
  var text = File(path).readAsStringSync();
  var total = 0;

  for (final lang in _langs) {
    final patchFile = File('tool/l10n_patches/$lang.json');
    if (!patchFile.existsSync()) continue;
    final patches =
        (jsonDecode(patchFile.readAsStringSync()) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String));

    for (final entry in patches.entries) {
      final key = entry.key;
      final value = _escapeDartString(entry.value);
      final oldPattern = RegExp(
        "(\\s*'$key':\\s*)'(?:\\\\'|[^'])*'",
      );
      final marker = "'$lang': {";
      final blockStart = text.indexOf(marker);
      if (blockStart < 0) continue;
      final blockEnd = _findMapBlockEnd(text, blockStart + marker.length);
      final before = text.substring(0, blockStart);
      final block = text.substring(blockStart, blockEnd);
      final after = text.substring(blockEnd);

      if (!oldPattern.hasMatch(block)) {
        print('SKIP $lang.$key (not in block)');
        continue;
      }
      final newBlock = block.replaceFirst(
        oldPattern,
        "\$1'$value'",
      );
      if (newBlock == block) continue;
      text = before + newBlock + after;
      total++;
    }
    print('$lang: ${patches.length} patches loaded');
  }

  File(path).writeAsStringSync(text);
  print('\nApplied $total replacements -> $path');
}

String _escapeDartString(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

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
