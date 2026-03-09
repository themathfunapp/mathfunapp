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
  /// Lokalizasyon anahtarı (geometry_castle_door_*)
  String get localizationKey {
    switch (this) {
      case CastleDoorType.arched:
        return 'geometry_castle_door_arched';
      case CastleDoorType.rectangular:
        return 'geometry_castle_door_rectangular';
      case CastleDoorType.gothic:
        return 'geometry_castle_door_gothic';
      case CastleDoorType.wooden:
        return 'geometry_castle_door_wooden';
      case CastleDoorType.doubleLeaf:
        return 'geometry_castle_door_double_leaf';
      case CastleDoorType.medieval:
        return 'geometry_castle_door_medieval';
      case CastleDoorType.squareArch:
        return 'geometry_castle_door_square_arch';
      case CastleDoorType.roundTop:
        return 'geometry_castle_door_round_top';
    }
  }

  /// Kapı tipi için görüntülenebilir isim (lokalize edilmiş - loc.get(localizationKey) kullanın)
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
