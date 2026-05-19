import 'dart:math';

import 'fruit_icon_assets.dart';

/// Meyve Toplama — 60 çeşit; OpenMoji/Twemoji PNG ikonları ([fruit_icon_assets]).
class FruitCatalogEntry {
  final String id;

  const FruitCatalogEntry(this.id);
}

/// Unicode / sistem emoji (WhatsApp, iMessage vb. ile aynı stil).
String fruitEmoji(String fruitId) {
  return _fruitEmoji[fruitId] ?? '🍎';
}

const Map<String, String> _fruitEmoji = {
  'apple': '🍎',
  'green_apple': '🍏',
  'orange': '🍊',
  'tangerine': '🍊',
  'mandarin': '🍊',
  'clementine': '🍊',
  'grapefruit': '🍊',
  'pomelo': '🍊',
  'kumquat': '🍊',
  'persimmon': '🟠',
  'lemon': '🍋',
  'lime': '🍋\u200D🟩',
  'banana': '🍌',
  'plantain': '🍌',
  'watermelon': '🍉',
  'grape': '🍇',
  'red_grape': '🍇',
  'strawberry': '🍓',
  'cherry': '🍒',
  'sweet_cherry': '🍒',
  'sour_cherry': '🍒',
  'peach': '🍑',
  'nectarine': '🍑',
  'apricot': '🍑',
  'plum': '🟣',
  'pear': '🍐',
  'quince': '🍐',
  'guava': '🍐',
  'melon': '🍈',
  'cantaloupe': '🍈',
  'honeydew': '🍈',
  'kiwi': '🥝',
  'mango': '🥭',
  'papaya': '🥭',
  'durian': '🥭',
  'pineapple': '🍍',
  'coconut': '🥥',
  'blueberry': '🫐',
  'blackberry': '🫐',
  'mulberry': '🫐',
  'gooseberry': '🫐',
  'tomato': '🍅',
  'avocado': '🥑',
  'olive': '🫒',
  'corn': '🌽',
  'pepper': '🫑',
  'eggplant': '🍆',
  'walnut': '🌰',
  'hazelnut': '🌰',
  'almond': '🥜',
  'pomegranate': '🔴',
  'fig': '🟤',
  'date': '🟫',
  'raspberry': '🍓',
  'cranberry': '🔴',
  'lychee': '⚪',
  'dragon_fruit': '🩷',
  'passion_fruit': '💜',
  'starfruit': '⭐',
  'jackfruit': '🍈',
  'longan': '⚪',
};

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
  final seenVisual = <String>{};
  final picked = <FruitCatalogEntry>[];

  for (final entry in shuffled) {
    final visual = fruitVisualKey(entry.id);
    if (seenVisual.contains(visual)) continue;
    seenVisual.add(visual);
    picked.add(entry);
    if (picked.length >= count) break;
  }
  return picked;
}

FruitCatalogEntry randomDistractorFruit(
  Random random,
  Set<String> goalFruitIds,
) {
  final blockedVisual = goalFruitIds.map(fruitVisualKey).toSet();
  final pool = fruitCollectCatalog
      .where((e) => !blockedVisual.contains(fruitVisualKey(e.id)))
      .toList();
  if (pool.isEmpty) {
    return fruitCollectCatalog[random.nextInt(fruitCollectCatalog.length)];
  }
  return pool[random.nextInt(pool.length)];
}
