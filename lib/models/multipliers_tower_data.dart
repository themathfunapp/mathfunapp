/// Çarpanlar Kulesi - Ziki'nin Muz Adası'na yolculuğu
/// Sayı-nesne eşlemesi, seviyeler, şapkalar

/// 1-36 arası sayılar için nesne tanımları (nameKey: lokalizasyon anahtarı)
const Map<int, Map<String, dynamic>> stepObjects = {
  1: {'emoji': '🍌', 'nameKey': 'ziki_step_1'},
  2: {'emoji': '🍒', 'nameKey': 'ziki_step_2'},
  3: {'emoji': '🧀', 'nameKey': 'ziki_step_3'},
  4: {'emoji': '🍀', 'nameKey': 'ziki_step_4'},
  5: {'emoji': '⭐', 'nameKey': 'ziki_step_5'},
  6: {'emoji': '🐝', 'nameKey': 'ziki_step_6'},
  7: {'emoji': '🐞', 'nameKey': 'ziki_step_7'},
  8: {'emoji': '🐙', 'nameKey': 'ziki_step_8'},
  9: {'emoji': '☁️', 'nameKey': 'ziki_step_9'},
  10: {'emoji': '🐛', 'nameKey': 'ziki_step_10'},
  11: {'emoji': '⚽', 'nameKey': 'ziki_step_11'},
  12: {'emoji': '🥚', 'nameKey': 'ziki_step_12'},
  13: {'emoji': '🐱', 'nameKey': 'ziki_step_13'},
  14: {'emoji': '🍒', 'nameKey': 'ziki_step_14'},
  15: {'emoji': '🌙', 'nameKey': 'ziki_step_15'},
  16: {'emoji': '🕷️', 'nameKey': 'ziki_step_16'},
  17: {'emoji': '✨', 'nameKey': 'ziki_step_17'},
  18: {'emoji': '🧺', 'nameKey': 'ziki_step_18'},
  19: {'emoji': '🎈', 'nameKey': 'ziki_step_19'},
  20: {'emoji': '✋', 'nameKey': 'ziki_step_20'},
  21: {'emoji': '🎲', 'nameKey': 'ziki_step_21'},
  22: {'emoji': '🚲', 'nameKey': 'ziki_step_22'},
  23: {'emoji': '📖', 'nameKey': 'ziki_step_23'},
  24: {'emoji': '🕐', 'nameKey': 'ziki_step_24'},
  25: {'emoji': '🍬', 'nameKey': 'ziki_step_25'},
  26: {'emoji': '🔤', 'nameKey': 'ziki_step_26'},
  27: {'emoji': '🧊', 'nameKey': 'ziki_step_27'},
  28: {'emoji': '📅', 'nameKey': 'ziki_step_28'},
  29: {'emoji': '🌑', 'nameKey': 'ziki_step_29'},
  30: {'emoji': '🏅', 'nameKey': 'ziki_step_30'},
  31: {'emoji': '🍦', 'nameKey': 'ziki_step_31'},
  32: {'emoji': '♟️', 'nameKey': 'ziki_step_32'},
  33: {'emoji': '💿', 'nameKey': 'ziki_step_33'},
  34: {'emoji': '🎂', 'nameKey': 'ziki_step_34'},
  35: {'emoji': '🪜', 'nameKey': 'ziki_step_35'},
  36: {'emoji': '🥚', 'nameKey': 'ziki_step_36'},
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
