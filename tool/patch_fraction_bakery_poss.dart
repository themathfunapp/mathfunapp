// ignore_for_file: avoid_print
// dart run tool/patch_fraction_bakery_poss.dart

import 'dart:io';

/// Countable pastry nouns for fraction bakery questions ({1} / {0} slots).
const _possByLang = <String, Map<String, String>>{
  'tr': {
    'fraction_bakery_poss_pasta': 'pasta',
    'fraction_bakery_poss_kurabiye': 'kurabiye',
    'fraction_bakery_poss_pizza': 'pizza',
    'fraction_bakery_poss_turta': 'turta',
    'fraction_bakery_poss_croissant': 'kruvasan',
    'fraction_bakery_poss_donut': 'donut',
  },
  'en': {
    'fraction_bakery_poss_pasta': 'cakes',
    'fraction_bakery_poss_kurabiye': 'cookies',
    'fraction_bakery_poss_pizza': 'pizzas',
    'fraction_bakery_poss_turta': 'pies',
    'fraction_bakery_poss_croissant': 'croissants',
    'fraction_bakery_poss_donut': 'donuts',
  },
  'de': {
    'fraction_bakery_poss_pasta': 'Kuchen',
    'fraction_bakery_poss_kurabiye': 'Kekse',
    'fraction_bakery_poss_pizza': 'Pizzas',
    'fraction_bakery_poss_turta': 'Torten',
    'fraction_bakery_poss_croissant': 'Croissants',
    'fraction_bakery_poss_donut': 'Donuts',
  },
  'ar': {
    'fraction_bakery_poss_pasta': 'كعكات',
    'fraction_bakery_poss_kurabiye': 'بسكويت',
    'fraction_bakery_poss_pizza': 'بيتزا',
    'fraction_bakery_poss_turta': 'فطائر',
    'fraction_bakery_poss_croissant': 'كرواسون',
    'fraction_bakery_poss_donut': 'دونات',
  },
  'fa': {
    'fraction_bakery_poss_pasta': 'کیک',
    'fraction_bakery_poss_kurabiye': 'کلوچه',
    'fraction_bakery_poss_pizza': 'پیتزا',
    'fraction_bakery_poss_turta': 'پای',
    'fraction_bakery_poss_croissant': 'کروسان',
    'fraction_bakery_poss_donut': 'دونات',
  },
  'zh': {
    'fraction_bakery_poss_pasta': '蛋糕',
    'fraction_bakery_poss_kurabiye': '饼干',
    'fraction_bakery_poss_pizza': '披萨',
    'fraction_bakery_poss_turta': '馅饼',
    'fraction_bakery_poss_croissant': '羊角面包',
    'fraction_bakery_poss_donut': '甜甜圈',
  },
  'id': {
    'fraction_bakery_poss_pasta': 'kue',
    'fraction_bakery_poss_kurabiye': 'kue kering',
    'fraction_bakery_poss_pizza': 'pizza',
    'fraction_bakery_poss_turta': 'pai',
    'fraction_bakery_poss_croissant': 'croissant',
    'fraction_bakery_poss_donut': 'donat',
  },
  'ku': {
    'fraction_bakery_poss_pasta': 'kek',
    'fraction_bakery_poss_kurabiye': 'biskêvî',
    'fraction_bakery_poss_pizza': 'pîzza',
    'fraction_bakery_poss_turta': 'pay',
    'fraction_bakery_poss_croissant': 'kruvasan',
    'fraction_bakery_poss_donut': 'donut',
  },
  'es': {
    'fraction_bakery_poss_pasta': 'pasteles',
    'fraction_bakery_poss_kurabiye': 'galletas',
    'fraction_bakery_poss_pizza': 'pizzas',
    'fraction_bakery_poss_turta': 'tartas',
    'fraction_bakery_poss_croissant': 'croissants',
    'fraction_bakery_poss_donut': 'donas',
  },
  'fr': {
    'fraction_bakery_poss_pasta': 'gâteaux',
    'fraction_bakery_poss_kurabiye': 'biscuits',
    'fraction_bakery_poss_pizza': 'pizzas',
    'fraction_bakery_poss_turta': 'tartes',
    'fraction_bakery_poss_croissant': 'croissants',
    'fraction_bakery_poss_donut': 'donuts',
  },
  'ru': {
    'fraction_bakery_poss_pasta': 'торты',
    'fraction_bakery_poss_kurabiye': 'печенье',
    'fraction_bakery_poss_pizza': 'пиццы',
    'fraction_bakery_poss_turta': 'пироги',
    'fraction_bakery_poss_croissant': 'круассаны',
    'fraction_bakery_poss_donut': 'пончики',
  },
  'ja': {
    'fraction_bakery_poss_pasta': 'ケーキ',
    'fraction_bakery_poss_kurabiye': 'クッキー',
    'fraction_bakery_poss_pizza': 'ピザ',
    'fraction_bakery_poss_turta': 'パイ',
    'fraction_bakery_poss_croissant': 'クロワッサン',
    'fraction_bakery_poss_donut': 'ドーナツ',
  },
  'ko': {
    'fraction_bakery_poss_pasta': '케이크',
    'fraction_bakery_poss_kurabiye': '쿠키',
    'fraction_bakery_poss_pizza': '피자',
    'fraction_bakery_poss_turta': '파이',
    'fraction_bakery_poss_croissant': '크루아상',
    'fraction_bakery_poss_donut': '도넛',
  },
  'hi': {
    'fraction_bakery_poss_pasta': 'केक',
    'fraction_bakery_poss_kurabiye': 'बिस्कुट',
    'fraction_bakery_poss_pizza': 'पिज़्ज़ा',
    'fraction_bakery_poss_turta': 'पाई',
    'fraction_bakery_poss_croissant': 'क्रोइसान',
    'fraction_bakery_poss_donut': 'डोनट',
  },
  'ur': {
    'fraction_bakery_poss_pasta': 'کیک',
    'fraction_bakery_poss_kurabiye': 'بسکٹ',
    'fraction_bakery_poss_pizza': 'پیزا',
    'fraction_bakery_poss_turta': 'پائی',
    'fraction_bakery_poss_croissant': 'کرویسان',
    'fraction_bakery_poss_donut': 'ڈونٹ',
  },
  'pt': {
    'fraction_bakery_poss_pasta': 'bolos',
    'fraction_bakery_poss_kurabiye': 'biscoitos',
    'fraction_bakery_poss_pizza': 'pizzas',
    'fraction_bakery_poss_turta': 'tortas',
    'fraction_bakery_poss_croissant': 'croissants',
    'fraction_bakery_poss_donut': 'donuts',
  },
  'it': {
    'fraction_bakery_poss_pasta': 'torte',
    'fraction_bakery_poss_kurabiye': 'biscotti',
    'fraction_bakery_poss_pizza': 'pizze',
    'fraction_bakery_poss_turta': 'crostate',
    'fraction_bakery_poss_croissant': 'croissant',
    'fraction_bakery_poss_donut': 'ciambelle',
  },
  'pl': {
    'fraction_bakery_poss_pasta': 'ciasta',
    'fraction_bakery_poss_kurabiye': 'ciasteczka',
    'fraction_bakery_poss_pizza': 'pizze',
    'fraction_bakery_poss_turta': 'tarty',
    'fraction_bakery_poss_croissant': 'rogaliki',
    'fraction_bakery_poss_donut': 'pączki',
  },
};

void main() {
  const path = 'lib/localization/app_localizations.dart';
  var text = File(path).readAsStringSync();
  var inserted = 0;
  var updated = 0;

  for (final entry in _possByLang.entries) {
    final lang = entry.key;
    final marker = "'$lang': {";
    final blockStart = text.indexOf(marker);
    if (blockStart < 0) {
      print('SKIP $lang');
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
        updated++;
        continue;
      }

      final anchor = RegExp(
        r"(\s*'fraction_bakery_tech_donut':\s*'(?:\\'|[^'])*',)",
      );
      if (!anchor.hasMatch(block)) {
        print('WARN $lang: no donut anchor for $key');
        continue;
      }
      block = block.replaceFirstMapped(
        anchor,
        (m) => "${m.group(1)}\n      '$key': '$value',",
      );
      inserted++;
    }

    text = text.substring(0, blockStart) + block + text.substring(blockEnd);
  }

  File(path).writeAsStringSync(text);
  print('Inserted $inserted, updated $updated keys');
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
