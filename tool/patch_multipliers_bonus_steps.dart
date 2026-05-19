// ignore_for_file: avoid_print
// dart run tool/patch_multipliers_bonus_steps.dart

import 'dart:io';

const _translations = <String, String>{
  'tr': '{count} basamak bonus!',
  'en': '{count} step bonus!',
  'de': '{count} Stufen-Bonus!',
  'ar': 'مكافأة {count} خطوات!',
  'fa': 'پاداش {count} مرحله!',
  'zh': '{count} 步奖励！',
  'id': 'Bonus {count} langkah!',
  'ku': 'Bonusa {count} gavan!',
  'es': '¡Bonus de {count} pasos!',
  'fr': 'Bonus de {count} étapes !',
  'ru': 'Бонус {count} шагов!',
  'ja': '{count}ステップボーナス！',
  'ko': '{count}단계 보너스!',
  'hi': '{count} कदम बोनस!',
  'ur': '{count} قدموں کا بونس!',
  'pt': 'Bônus de {count} passos!',
  'it': 'Bonus {count} passi!',
  'pl': 'Bonus {count} kroków!',
};

void main() {
  const path = 'lib/localization/app_localizations.dart';
  var text = File(path).readAsStringSync();
  var n = 0;

  for (final entry in _translations.entries) {
    final lang = entry.key;
    final value = _escape(entry.value);
    final marker = "'$lang': {";
    final blockStart = text.indexOf(marker);
    if (blockStart < 0) {
      print('SKIP $lang');
      continue;
    }
    final contentStart = blockStart + marker.length;
    final blockEnd = _findMapBlockEnd(text, contentStart);
    final block = text.substring(blockStart, blockEnd);
    final pattern = RegExp(
      r"(\s*'multipliers_bonus_steps':\s*)'(?:\\'|[^'])*'",
    );
    if (!pattern.hasMatch(block)) {
      print('WARN $lang: key not found');
      continue;
    }
    final newBlock = block.replaceFirstMapped(
      pattern,
      (m) => "${m.group(1)}'$value'",
    );
    text = text.substring(0, blockStart) + newBlock + text.substring(blockEnd);
    n++;
  }

  File(path).writeAsStringSync(text);
  print('Patched $n languages');
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
