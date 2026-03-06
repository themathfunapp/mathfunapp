/// Platforma göre PremiumService export - Web'de in_app_purchase kullanılmaz
export 'premium_service_web.dart' if (dart.library.io) 'premium_service.dart';
