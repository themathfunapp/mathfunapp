import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Uygulama genelinde tek [FlutterLocalNotificationsPlugin] (FCM ön plan + ebeveyn zamanlaması).
class AppLocalNotifications {
  AppLocalNotifications._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// [onSelect] FCM / yerel bildirim tıklanınca (ör. aile düellosu payload).
  static Future<void> initialize({
    void Function(NotificationResponse response)? onSelect,
  }) async {
    if (kIsWeb || _initialized) return;
    try {
      await plugin.initialize(
        InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: const DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: onSelect,
      );

      final androidImpl =
          plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'family_remote_duel',
            'Aile düellosu',
            description: 'Uzaktan düello davetleri',
            importance: Importance.high,
          ),
        );
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'parent_panel_reminders',
            'Ebeveyn hatırlatmaları',
            description: 'Günlük ve haftalık hatırlatmalar',
            importance: Importance.defaultImportance,
          ),
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('AppLocalNotifications.initialize: $e');
    }
  }
}
