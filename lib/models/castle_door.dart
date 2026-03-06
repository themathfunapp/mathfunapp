/// Şato kapı çeşitleri - Flaticon Castle Door stillerine uygun
/// Her kapı tipi farklı çerçeve/çerçeve şekli ile çizilir
enum CastleDoorType {
  /// Klasik kemerli kapı (arched)
  arched,
  /// Dikdörtgen kapı
  rectangular,
  /// Gotik kemerli kapı
  gothic,
  /// Ahşap şato kapısı (çerçeveli)
  wooden,
  /// Çift kanatlı kapı
  doubleLeaf,
  /// Metal çerçeveli ortaçağ kapısı
  medieval,
  /// Kare kemerli kapı
  squareArch,
  /// Yuvarlak pencere kemerli
  roundTop,
}

extension CastleDoorTypeExtension on CastleDoorType {
  /// Kapı tipi için görüntülenebilir isim
  String get displayName {
    switch (this) {
      case CastleDoorType.arched:
        return 'Kemerli';
      case CastleDoorType.rectangular:
        return 'Dikdörtgen';
      case CastleDoorType.gothic:
        return 'Gotik';
      case CastleDoorType.wooden:
        return 'Ahşap';
      case CastleDoorType.doubleLeaf:
        return 'Çift Kanat';
      case CastleDoorType.medieval:
        return 'Ortaçağ';
      case CastleDoorType.squareArch:
        return 'Kare Kemer';
      case CastleDoorType.roundTop:
        return 'Yuvarlak';
    }
  }
}
