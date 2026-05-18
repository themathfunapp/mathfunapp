import 'dart:math';

/// Meyve Topanesi — her kimlik gerçek fotoğraf dosyasına bağlanır.
class FruitCatalogEntry {
  final String id;

  const FruitCatalogEntry(this.id);
}

/// Aynı fotoğrafı paylaşan çeşitler (isim metinde doğru kalır).
const Map<String, String> _fruitImageAlias = {
  'tangerine': 'orange',
  'mandarin': 'orange',
  'clementine': 'orange',
  'grapefruit': 'orange',
  'pomelo': 'orange',
  'kumquat': 'orange',
  'persimmon': 'orange',
  'red_grape': 'grape',
  'lime': 'lemon',
  'plantain': 'banana',
  'nectarine': 'peach',
  'apricot': 'peach',
  'plum': 'peach',
  'quince': 'pear',
  'guava': 'pear',
  'cantaloupe': 'melon',
  'honeydew': 'melon',
  'papaya': 'mango',
  'durian': 'mango',
  'blackberry': 'blueberry',
  'mulberry': 'blueberry',
  'gooseberry': 'blueberry',
  'sweet_cherry': 'cherry',
  'sour_cherry': 'cherry',
  'hazelnut': 'walnut',
  'cranberry': 'raspberry',
  'dragon_fruit': 'lychee',
  'longan': 'lychee',
};

String fruitImageAssetPath(String fruitId) {
  final file = _fruitImageAlias[fruitId] ?? fruitId;
  return 'assets/fruits/$file.png';
}

String fruitEmojiFallback(String fruitId) {
  const map = {
    'apple': '🍎',
    'green_apple': '🍏',
    'orange': '🍊',
    'tangerine': '🍊',
    'mandarin': '🍊',
    'lemon': '🍋',
    'lime': '🍋',
    'banana': '🍌',
    'watermelon': '🍉',
    'grape': '🍇',
    'strawberry': '🍓',
    'cherry': '🍒',
    'peach': '🍑',
    'pear': '🍐',
    'melon': '🍈',
    'kiwi': '🥝',
    'mango': '🥭',
    'pineapple': '🍍',
    'coconut': '🥥',
    'blueberry': '🫐',
    'tomato': '🍅',
    'avocado': '🥑',
    'olive': '🫒',
    'corn': '🌽',
    'pepper': '🫑',
    'eggplant': '🍆',
    'walnut': '🌰',
    'almond': '🥜',
    'pomegranate': '🍎',
    'fig': '🟤',
    'date': '🟫',
    'raspberry': '🍓',
    'lychee': '⚪',
    'passion_fruit': '💜',
    'starfruit': '⭐',
    'jackfruit': '🍈',
    'cranberry': '🔴',
  };
  return map[fruitId] ?? '🍎';
}

const List<FruitCatalogEntry> fruitCollectCatalog = [
  FruitCatalogEntry('apple'),
  FruitCatalogEntry('green_apple'),
  FruitCatalogEntry('orange'),
  FruitCatalogEntry('tangerine'),
  FruitCatalogEntry('mandarin'),
  FruitCatalogEntry('clementine'),
  FruitCatalogEntry('grapefruit'),
  FruitCatalogEntry('pomelo'),
  FruitCatalogEntry('kumquat'),
  FruitCatalogEntry('persimmon'),
  FruitCatalogEntry('lemon'),
  FruitCatalogEntry('lime'),
  FruitCatalogEntry('banana'),
  FruitCatalogEntry('plantain'),
  FruitCatalogEntry('watermelon'),
  FruitCatalogEntry('grape'),
  FruitCatalogEntry('red_grape'),
  FruitCatalogEntry('strawberry'),
  FruitCatalogEntry('cherry'),
  FruitCatalogEntry('sweet_cherry'),
  FruitCatalogEntry('peach'),
  FruitCatalogEntry('nectarine'),
  FruitCatalogEntry('apricot'),
  FruitCatalogEntry('plum'),
  FruitCatalogEntry('pear'),
  FruitCatalogEntry('quince'),
  FruitCatalogEntry('guava'),
  FruitCatalogEntry('melon'),
  FruitCatalogEntry('cantaloupe'),
  FruitCatalogEntry('honeydew'),
  FruitCatalogEntry('kiwi'),
  FruitCatalogEntry('mango'),
  FruitCatalogEntry('papaya'),
  FruitCatalogEntry('durian'),
  FruitCatalogEntry('pineapple'),
  FruitCatalogEntry('coconut'),
  FruitCatalogEntry('blueberry'),
  FruitCatalogEntry('blackberry'),
  FruitCatalogEntry('mulberry'),
  FruitCatalogEntry('gooseberry'),
  FruitCatalogEntry('tomato'),
  FruitCatalogEntry('avocado'),
  FruitCatalogEntry('olive'),
  FruitCatalogEntry('corn'),
  FruitCatalogEntry('pepper'),
  FruitCatalogEntry('eggplant'),
  FruitCatalogEntry('walnut'),
  FruitCatalogEntry('hazelnut'),
  FruitCatalogEntry('almond'),
  FruitCatalogEntry('pomegranate'),
  FruitCatalogEntry('fig'),
  FruitCatalogEntry('date'),
  FruitCatalogEntry('raspberry'),
  FruitCatalogEntry('cranberry'),
  FruitCatalogEntry('lychee'),
  FruitCatalogEntry('dragon_fruit'),
  FruitCatalogEntry('passion_fruit'),
  FruitCatalogEntry('starfruit'),
  FruitCatalogEntry('jackfruit'),
  FruitCatalogEntry('longan'),
];

List<FruitCatalogEntry> pickDistinctFruitGoals(Random random, int count) {
  final shuffled = List<FruitCatalogEntry>.from(fruitCollectCatalog)..shuffle(random);
  final seen = <String>{};
  final picked = <FruitCatalogEntry>[];

  for (final entry in shuffled) {
    if (seen.contains(entry.id)) continue;
    seen.add(entry.id);
    picked.add(entry);
    if (picked.length >= count) break;
  }
  return picked;
}

FruitCatalogEntry randomDistractorFruit(
  Random random,
  Set<String> excludeIds,
) {
  final pool =
      fruitCollectCatalog.where((e) => !excludeIds.contains(e.id)).toList();
  if (pool.isEmpty) {
    return fruitCollectCatalog[random.nextInt(fruitCollectCatalog.length)];
  }
  return pool[random.nextInt(pool.length)];
}
