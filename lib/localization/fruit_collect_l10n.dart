import 'app_supported_locales.dart';

/// Meyve Toplama — meyve adları ve görev cümlesi (18 dil).
String fruitCollectName(String languageCode, String fruitId) {
  final lang = _normLang(languageCode);
  if (lang == 'tr') {
    return _trNames[fruitId] ?? _enNames[fruitId] ?? fruitId;
  }
  return _enNames[fruitId] ?? fruitId;
}

String _normLang(String? code) {
  final raw = (code ?? 'en').trim().toLowerCase();
  if (raw.isEmpty) return 'en';
  final two = raw.length >= 2 ? raw.substring(0, 2) : raw;
  if (kSupportedLanguageCodes.contains(two)) return two;
  return 'en';
}

String fruitCollectGoal(String languageCode, int count, String fruitId) {
  return fruitCollectMultiGoal(
    languageCode,
    [(count: count, fruitId: fruitId)],
  );
}

/// Örn. "1 portakal ve 2 elma topla" / "Collect 1 orange and 2 apples"
String fruitCollectMultiGoal(
  String languageCode,
  List<({int count, String fruitId})> parts,
) {
  if (parts.isEmpty) return '';
  final lang = _normLang(languageCode);
  final segments = <String>[];
  for (final part in parts) {
    final name = fruitCollectName(languageCode, part.fruitId);
    if (lang == 'tr') {
      segments.add('${part.count} $name');
    } else if (part.count == 1) {
      segments.add('1 $name');
    } else {
      segments.add('${part.count} ${name}s');
    }
  }
  final joined = segments.join(_fruitJoiner[lang] ?? _fruitJoiner['en']!);
  if (lang == 'tr') return '$joined topla';
  final prefix = _fruitCollectPrefix[lang] ?? _fruitCollectPrefix['en']!;
  return '$prefix $joined';
}

/// Liste birleştirici (meyve1 X meyve2).
const Map<String, String> _fruitJoiner = {
  'tr': ' ve ',
  'en': ' and ',
  'de': ' und ',
  'ar': ' و ',
  'fa': ' و ',
  'zh': '、',
  'id': ' dan ',
  'ku': ' û ',
  'es': ' y ',
  'fr': ' et ',
  'ru': ' и ',
  'ja': ' と ',
  'ko': ' 그리고 ',
  'hi': ' और ',
  'ur': ' اور ',
  'pt': ' e ',
  'it': ' e ',
  'pl': ' i ',
};

/// Tekil görev öneki (Collect / Sammle / …).
const Map<String, String> _fruitCollectPrefix = {
  'tr': '',
  'en': 'Collect',
  'de': 'Sammle',
  'ar': 'اجمع',
  'fa': 'جمع کن',
  'zh': '收集',
  'id': 'Kumpulkan',
  'ku': 'Berhev bike',
  'es': 'Recoge',
  'fr': 'Collecte',
  'ru': 'Собери',
  'ja': '集めて',
  'ko': '모아',
  'hi': 'इकट्ठा करो',
  'ur': 'جمع کرو',
  'pt': 'Colete',
  'it': 'Raccogli',
  'pl': 'Zbierz',
};

const Map<String, String> _trNames = {
  'apple': 'elma',
  'green_apple': 'yeşil elma',
  'orange': 'portakal',
  'tangerine': 'mandalina',
  'mandarin': 'mandarin',
  'clementine': 'klementin',
  'lemon': 'limon',
  'lime': 'misket limonu',
  'banana': 'muz',
  'plantain': 'muz',
  'watermelon': 'karpuz',
  'grape': 'üzüm',
  'red_grape': 'kırmızı üzüm',
  'strawberry': 'çilek',
  'cherry': 'kiraz',
  'sweet_cherry': 'kiraz',
  'sour_cherry': 'vişne',
  'peach': 'şeftali',
  'nectarine': 'nektarin',
  'apricot': 'kayısı',
  'plum': 'erik',
  'pear': 'armut',
  'melon': 'kavun',
  'cantaloupe': 'kavun',
  'honeydew': 'kavun',
  'kiwi': 'kivi',
  'mango': 'mango',
  'pineapple': 'ananas',
  'coconut': 'hindistan cevizi',
  'blueberry': 'yaban mersini',
  'tomato': 'domates',
  'avocado': 'avokado',
  'olive': 'zeytin',
  'corn': 'mısır',
  'pepper': 'biber',
  'eggplant': 'patlıcan',
  'pomegranate': 'nar',
  'fig': 'incir',
  'date': 'hurma',
  'papaya': 'papaya',
  'guava': 'guava',
  'passion_fruit': 'çarkıfelek',
  'dragon_fruit': 'ejder meyvesi',
  'lychee': 'liçi',
  'raspberry': 'ahududu',
  'blackberry': 'böğürtlen',
  'cranberry': 'kızılcık',
  'mulberry': 'dut',
  'persimmon': 'trabzon hurması',
  'quince': 'ayva',
  'pomelo': 'pomelo',
  'grapefruit': 'greyfurt',
  'kumquat': 'kamkat',
  'starfruit': 'yıldız meyvesi',
  'jackfruit': 'jackfruit',
  'durian': 'durian',
  'longan': 'longan',
  'gooseberry': 'bektaşi üzümü',
  'walnut': 'ceviz',
  'hazelnut': 'fındık',
  'almond': 'badem',
};

const Map<String, String> _enNames = {
  'apple': 'apple',
  'green_apple': 'green apple',
  'orange': 'orange',
  'tangerine': 'tangerine',
  'mandarin': 'mandarin',
  'clementine': 'clementine',
  'lemon': 'lemon',
  'lime': 'lime',
  'banana': 'banana',
  'plantain': 'plantain',
  'watermelon': 'watermelon',
  'grape': 'grape',
  'red_grape': 'red grape',
  'strawberry': 'strawberry',
  'cherry': 'cherry',
  'sweet_cherry': 'sweet cherry',
  'peach': 'peach',
  'nectarine': 'nectarine',
  'apricot': 'apricot',
  'plum': 'plum',
  'pear': 'pear',
  'melon': 'melon',
  'cantaloupe': 'cantaloupe',
  'honeydew': 'honeydew',
  'kiwi': 'kiwi',
  'mango': 'mango',
  'pineapple': 'pineapple',
  'coconut': 'coconut',
  'blueberry': 'blueberry',
  'tomato': 'tomato',
  'avocado': 'avocado',
  'olive': 'olive',
  'corn': 'corn',
  'pepper': 'pepper',
  'eggplant': 'eggplant',
  'pomegranate': 'pomegranate',
  'fig': 'fig',
  'date': 'date',
  'papaya': 'papaya',
  'guava': 'guava',
  'passion_fruit': 'passion fruit',
  'dragon_fruit': 'dragon fruit',
  'lychee': 'lychee',
  'raspberry': 'raspberry',
  'blackberry': 'blackberry',
  'cranberry': 'cranberry',
  'mulberry': 'mulberry',
  'persimmon': 'persimmon',
  'quince': 'quince',
  'pomelo': 'pomelo',
  'grapefruit': 'grapefruit',
  'kumquat': 'kumquat',
  'starfruit': 'star fruit',
  'jackfruit': 'jackfruit',
  'durian': 'durian',
  'longan': 'longan',
  'gooseberry': 'gooseberry',
  'walnut': 'walnut',
  'hazelnut': 'hazelnut',
  'almond': 'almond',
};
