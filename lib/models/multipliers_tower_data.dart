/// Çarpanlar Kulesi - Ziki'nin Muz Adası'na yolculuğu
/// Sayı-nesne eşlemesi, seviyeler, şapkalar

/// 1-36 arası sayılar için nesne tanımları
const Map<int, Map<String, dynamic>> stepObjects = {
  1: {'emoji': '🍌', 'name': 'Tek Muz'},
  2: {'emoji': '🍒', 'name': 'İkiz Kiraz'},
  3: {'emoji': '🧀', 'name': 'Üçgen Peynir'},
  4: {'emoji': '🍀', 'name': 'Dört Yapraklı Yonca'},
  5: {'emoji': '⭐', 'name': 'Denizyıldızı'},
  6: {'emoji': '🐝', 'name': 'Arı Kovanı'},
  7: {'emoji': '🐞', 'name': 'Uğur Böceği'},
  8: {'emoji': '🐙', 'name': 'Ahtapot'},
  9: {'emoji': '☁️', 'name': 'Bulut'},
  10: {'emoji': '🐛', 'name': 'Tırtıl'},
  11: {'emoji': '⚽', 'name': 'Futbol Takımı'},
  12: {'emoji': '🥚', 'name': 'Yumurta Kolis'},
  13: {'emoji': '🐱', 'name': 'Kedi'},
  14: {'emoji': '🍒', 'name': 'Kiraz Ağacı'},
  15: {'emoji': '🌙', 'name': 'Ay'},
  16: {'emoji': '🕷️', 'name': 'Örümcek'},
  17: {'emoji': '✨', 'name': 'Yıldız Kümesi'},
  18: {'emoji': '🧺', 'name': 'Muz Sepeti'},
  19: {'emoji': '🎈', 'name': 'Rakam Balonu'},
  20: {'emoji': '✋', 'name': 'Parmaklar'},
  21: {'emoji': '🎲', 'name': 'Zar'},
  22: {'emoji': '🚲', 'name': 'Bisiklet'},
  23: {'emoji': '📖', 'name': 'Kitap'},
  24: {'emoji': '🕐', 'name': 'Saat'},
  25: {'emoji': '🍬', 'name': 'Şeker'},
  26: {'emoji': '🔤', 'name': 'Alfabe'},
  27: {'emoji': '🧊', 'name': 'Küp Şeker'},
  28: {'emoji': '📅', 'name': 'Takvim'},
  29: {'emoji': '🌑', 'name': 'Ay Döngüsü'},
  30: {'emoji': '🏅', 'name': 'Gün Rozeti'},
  31: {'emoji': '🍦', 'name': 'Dondurma'},
  32: {'emoji': '♟️', 'name': 'Satranç'},
  33: {'emoji': '💿', 'name': 'Plak'},
  34: {'emoji': '🎂', 'name': 'Pasta'},
  35: {'emoji': '🪜', 'name': 'Merdiven'},
  36: {'emoji': '🥚', 'name': 'Yumurta Kolis'},
};

/// Sihirli sayı için kristal tasarımları (emoji + iç nesne)
const Map<int, String> crystalEmojis = {
  2: '🦋',
  3: '⭐',
  4: '🐞',
  5: '🐚',
  6: '🐝',
  7: '🎈',
  8: '❄️',
  9: '💧',
  10: '🍎',
  12: '🕐',
  15: '🌙',
  16: '♟️',
  18: '🕯️',
};

/// Her 5 muzda kazanılan şapkalar
const List<Map<String, String>> zikiHats = [
  {'muz': '5', 'emoji': '🏴‍☠️', 'name': 'Korsan'},
  {'muz': '10', 'emoji': '🎩', 'name': 'Sihirbaz'},
  {'muz': '15', 'emoji': '🪖', 'name': 'Astronot'},
  {'muz': '20', 'emoji': '🤡', 'name': 'Palyaço'},
  {'muz': '25', 'emoji': '👑', 'name': 'Kral'},
  {'muz': '30', 'emoji': '🎂', 'name': 'Doğum Günü'},
  {'muz': '35', 'emoji': '👨‍🍳', 'name': 'Şef'},
  {'muz': '40', 'emoji': '🔍', 'name': 'Dedektif'},
  {'muz': '45', 'emoji': '⛵', 'name': 'Viking'},
  {'muz': '50', 'emoji': '💎', 'name': 'Kristal Taç'},
];

/// Seviye tanımları
enum TowerLevel {
  katlarKoyu,      // 1: Katlar (2,3,4,5)
  ormanDerinlik,   // 2: Katlar (6,7,8,9)
  bolenlerMagara,  // 3: Bölenler
  ikizlerZirve,    // 4: Ortak Kat (EKOK)
  kardeslerVadi,   // 5: Ortak Bölen (EBOB)
  carpanlarAdasi,  // 6: Karma
}

const Map<TowerLevel, Map<String, dynamic>> levelData = {
  TowerLevel.katlarKoyu: {
    'nameKey': 'ziki_level_katlar',
    'numbers': [2, 3, 4, 5],
    'type': 'multiples',
  },
  TowerLevel.ormanDerinlik: {
    'nameKey': 'ziki_level_orman',
    'numbers': [6, 7, 8, 9],
    'type': 'multiples',
  },
  TowerLevel.bolenlerMagara: {
    'nameKey': 'ziki_level_bolenler',
    'numbers': [12, 15, 16, 18],
    'type': 'divisors',
  },
  TowerLevel.ikizlerZirve: {
    'nameKey': 'ziki_level_ortak_kat',
    'pairs': <List<int>>[[2, 3], [3, 4], [2, 5]],
    'type': 'lcm',
  },
  TowerLevel.kardeslerVadi: {
    'nameKey': 'ziki_level_ortak_bolen',
    'pairs': <List<int>>[[12, 18], [8, 12], [6, 9]],
    'type': 'gcd',
  },
  TowerLevel.carpanlarAdasi: {
    'nameKey': 'ziki_level_carpanlar',
    'type': 'mixed',
  },
};
