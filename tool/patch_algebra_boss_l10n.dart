// ignore_for_file: avoid_print
// dart run tool/patch_algebra_boss_l10n.dart

import 'dart:io';

const _bossQuestion = <String, String>{
  'hi': 'बॉस सवाल!',
  'ur': 'باس سوال!',
  'pt': 'Pergunta de chefe!',
  'it': 'Domanda del boss!',
  'pl': 'Pytanie bossa!',
};

const _howManySuffix = <String, String>{
  'hi': ' कितने?',
  'ur': ' کتنے؟',
  'pt': ' quantos?',
  'it': ' quanti?',
  'pl': ' ile?',
};

void main() {
  const path = 'lib/localization/app_localizations.dart';
  var text = File(path).readAsStringSync();
  var n = 0;

  for (final entry in _bossQuestion.entries) {
    n += _patch(text, entry.key, 'algebra_boss_question', entry.value)
        ? 1
        : 0;
    text = File(path).readAsStringSync();
  }
  for (final entry in _howManySuffix.entries) {
    n += _patch(text, entry.key, 'algebra_how_many_suffix', entry.value)
        ? 1
        : 0;
    text = File(path).readAsStringSync();
  }

  print('Patched $n entries');
}

bool _patch(String text, String lang, String key, String value) {
  final marker = "'$lang': {";
  final blockStart = text.indexOf(marker);
  if (blockStart < 0) return false;
  final contentStart = blockStart + marker.length;
  final blockEnd = _findMapBlockEnd(text, contentStart);
  final block = text.substring(blockStart, blockEnd);
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  final pattern = RegExp("(\\s*'$key':\\s*)'(?:\\\\'|[^'])*'");
  if (!pattern.hasMatch(block)) return false;
  final newBlock = block.replaceFirstMapped(
    pattern,
    (m) => "${m.group(1)}'$escaped'",
  );
  File('lib/localization/app_localizations.dart').writeAsStringSync(
    text.substring(0, blockStart) + newBlock + text.substring(blockEnd),
  );
  return true;
}

int _findMapBlockEnd(String text, int start) {
  var depth = 1;
  var i = start;
  while (i < text.length && depth > 0) {
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
