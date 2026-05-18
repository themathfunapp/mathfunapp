// ignore_for_file: avoid_print
//
// 18 dil eksik anahtar denetimi:
//   dart run tool/audit_l10n.dart
//
// Eksikleri İngilizce bloğundan doldurma:
//   dart run tool/audit_l10n.dart --fill

import 'dart:io';

const _langs = [
  'tr',
  'en',
  'de',
  'ar',
  'fa',
  'zh',
  'id',
  'ku',
  'es',
  'fr',
  'ru',
  'ja',
  'ko',
  'hi',
  'ur',
  'pt',
  'it',
  'pl',
];

void main(List<String> args) {
  final fill = args.contains('--fill');
  const path = 'lib/localization/app_localizations.dart';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Dosya bulunamadı: $path');
    exit(1);
  }

  var text = file.readAsStringSync();
  final blocks = <String, Set<String>>{};
  final blockRanges = <String, ({int start, int end})>{};

  for (final lang in _langs) {
    final marker = "'$lang': {";
    final idx = text.indexOf(marker);
    if (idx < 0) {
      print('EKSİK BLOK: $lang');
      continue;
    }
    final contentStart = idx + marker.length;
    final contentEnd = _findMapBlockEnd(text, contentStart);
    blockRanges[lang] = (start: contentStart, end: contentEnd);
    final block = text.substring(contentStart, contentEnd);
    blocks[lang] = RegExp(r"'([^']+)':\s*")
        .allMatches(block)
        .map((m) => m.group(1)!)
        .toSet();
  }

  final ref = blocks['tr'] ?? blocks['en']!;
  print('Referans (tr): ${ref.length} anahtar\n');

  for (final lang in _langs) {
    final keys = blocks[lang];
    if (keys == null) continue;
    print(
      '$lang: ${keys.length} anahtar, tr\'ye göre eksik: ${ref.difference(keys).length}',
    );
  }

  if (!fill) {
    print('\nEksik anahtarları İngilizce metinle doldurmak için:');
    print('  dart run tool/audit_l10n.dart --fill');
    return;
  }

  final enRange = blockRanges['en'];
  if (enRange == null) {
    stderr.writeln('en bloğu bulunamadı.');
    exit(1);
  }
  final enBlock = text.substring(enRange.start, enRange.end);

  var filled = 0;
  var skipped = 0;
  for (final lang in _langs) {
    if (lang == 'tr') continue;
    final keys = blocks[lang];
    final range = blockRanges[lang];
    if (keys == null || range == null) continue;

    final missing = ref.difference(keys);
    if (missing.isEmpty) continue;

    final inserts = <String>[];
    for (final key in missing) {
      final entry = _extractMapEntry(enBlock, key);
      if (entry == null) {
        print('UYARI: $lang için "$key" en bloğunda okunamadı, atlandı.');
        skipped++;
        continue;
      }
      inserts.add('      $entry');
      filled++;
    }
    if (inserts.isEmpty) continue;

    final patch = '\n${inserts.join('\n')}\n';
    final insertAt = range.end;
    text = text.substring(0, insertAt) + patch + text.substring(insertAt);

    final delta = patch.length;
    for (final l in _langs) {
      final r = blockRanges[l];
      if (r == null) continue;
      var start = r.start;
      var end = r.end;
      if (end >= insertAt) end += delta;
      if (start > insertAt) start += delta;
      blockRanges[l] = (start: start, end: end);
    }
    print('$lang: ${inserts.length} anahtar eklendi.');
  }

  file.writeAsStringSync(text);
  print('\nToplam $filled anahtar eklendi, $skipped atlandı → $path');
  print('Doğrulama: dart analyze lib/localization/app_localizations.dart');
}

/// `'anahtar': değer,` — çok satırlı değerleri de destekler.
String? _extractMapEntry(String block, String key) {
  final marker = "'$key':";
  final idx = block.indexOf(marker);
  if (idx < 0) return null;

  var i = idx + marker.length;
  final valueBuf = StringBuffer();

  while (i < block.length) {
    i = _skipWs(block, i);
    if (i >= block.length) break;

    if (block[i] == "'" || block.startsWith("'''", i)) {
      final start = i;
      final end = _readDartStringEnd(block, i);
      if (end <= start) return null;
      valueBuf.write(block.substring(start, end));
      i = end;
      i = _skipWs(block, i);
      // Bitişik string birleştirme: 'a' 'b'
      if (i < block.length && block[i] == "'") continue;
      break;
    }
    return null;
  }

  if (valueBuf.isEmpty) return null;

  i = _skipWs(block, i);
  final hasComma = i < block.length && block[i] == ',';
  if (hasComma) i++;

  return "'$key': ${valueBuf.toString()}${hasComma ? ',' : ','}";
}

int _skipWs(String s, int i) {
  while (i < s.length && ' \t\n\r'.contains(s[i])) {
    i++;
  }
  return i;
}

/// Dil haritasının kapanış `}` indeksini bulur (string içindeki `{}` sayılmaz).
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
    if (text[i] == '{') {
      depth++;
    } else if (text[i] == '}') {
      depth--;
    }
    i++;
  }
  return i - 1;
}

int _readDartStringEnd(String s, int i) {
  if (s.startsWith("'''", i)) {
    final end = s.indexOf("'''", i + 3);
    return end < 0 ? s.length : end + 3;
  }
  if (s[i] != "'") return i;
  i++;
  while (i < s.length) {
    final c = s[i];
    if (c == r'\') {
      i += 2;
      continue;
    }
    if (c == "'") {
      i++;
      if (i < s.length && s[i] == "'") {
        i++;
        continue;
      }
      return i;
    }
    i++;
  }
  return s.length;
}
