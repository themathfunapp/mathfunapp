/// Meyve Toplama — OpenMoji / Twemoji PNG dosya eşlemesi.
///
/// PNG üretmek için: `dart run tool/download_fruit_icons.dart`
const Map<String, String> fruitIconHexById = {
  'apple': '1F34E',
  'green_apple': '1F34F',
  'orange': '1F34A',
  'tangerine': '1F34A',
  'mandarin': '1F34A',
  'clementine': '1F34A',
  'grapefruit': 'E0C0',
  'pomelo': '1F34A',
  'kumquat': '1F34B',
  'persimmon': '1F351',
  'lemon': '1F34B',
  'lime': '1F34B-200D-1F7E9',
  'banana': '1F34C',
  'plantain': '1F34C',
  'watermelon': '1F349',
  'grape': '1F347',
  'red_grape': '1F347',
  'strawberry': '1F353',
  'cherry': '1F352',
  'sweet_cherry': '1F352',
  'sour_cherry': '1F352',
  'peach': '1F351',
  'nectarine': '1F351',
  'apricot': '1F351',
  'plum': '1F352',
  'pear': '1F350',
  'quince': '1F350',
  'guava': '1F96D',
  'melon': '1F348',
  'cantaloupe': '1F348',
  'honeydew': '1F348',
  'kiwi': '1F95D',
  'mango': '1F96D',
  'papaya': '1F96D',
  'durian': '1F34D',
  'pineapple': '1F34D',
  'coconut': '1F965',
  'blueberry': '1FAD0',
  'blackberry': '1FAD0',
  'mulberry': '1FAD0',
  'gooseberry': '1FAD0',
  'tomato': '1F345',
  'avocado': '1F951',
  'olive': '1FAD2',
  'corn': '1F33D',
  'pepper': '1FAD1',
  'eggplant': '1F346',
  'walnut': '1F330',
  'hazelnut': '1F330',
  'almond': '1F95C',
  'pomegranate': 'E0C4',
  'fig': '1F36F',
  'date': '1F36A',
  'raspberry': '1F353',
  'cranberry': '1F353',
  'lychee': '1F353',
  'dragon_fruit': '1FAD0',
  'passion_fruit': '1F34D',
  'starfruit': '1F31F',
  'jackfruit': '1F34D',
  'longan': '1F353',
};

String fruitIconAssetPath(String fruitId) =>
    'assets/fruit_icons/$fruitId.png';

/// Aynı ikonu paylaşan meyveler (portakal / pomelo / mandarin vb.) tek grupta.
String fruitVisualKey(String fruitId) =>
    fruitIconHexById[fruitId] ?? fruitId;

bool fruitsMatchVisually(String a, String b) =>
    fruitVisualKey(a) == fruitVisualKey(b);
