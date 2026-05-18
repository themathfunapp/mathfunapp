import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'parent_notification_telemetry.dart';

/// Uygulama genelinde tek [FlutterLocalNotificationsPlugin] (FCM ön plan + ebeveyn zamanlaması).
class AppLocalNotifications {
  AppLocalNotifications._();

  static const Color _brandNotificationColor = Color(0xFF6A11CB);

  /// Android: beyaz silüet küçük ikon + marka rengi + renkli büyük logo.
  static NotificationDetails parentPanelReminderDetails(String expandedBody) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'parent_panel_reminders',
        'Ebeveyn hatırlatmaları',
        channelDescription: 'Günlük ve haftalık hatırlatmalar',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_stat_notification',
        color: _brandNotificationColor,
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
        styleInformation: BigTextStyleInformation(expandedBody),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Ön planda gelen FCM arkadaş düellosu bildirimi.
  static NotificationDetails friendDuelForegroundDetails(String expandedBody) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'friend_duel',
        'Arkadaş düellosu',
        channelDescription: 'Arkadaş düello davetleri',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_stat_notification',
        color: _brandNotificationColor,
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
        styleInformation: BigTextStyleInformation(expandedBody),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Ön planda gelen FCM aile düellosu bildirimi.
  static NotificationDetails familyRemoteDuelForegroundDetails(String expandedBody) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'family_remote_duel',
        'Aile düellosu',
        channelDescription: 'Uzaktan düello davetleri',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_stat_notification',
        color: _brandNotificationColor,
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
        styleInformation: BigTextStyleInformation(expandedBody),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// İkinci bir `initialize` çağrısında da güncellenir (Workmanager önce, Push sonra senaryosu).
  static void Function(NotificationResponse response)? _onNotificationTap;

  static bool get isInitialized => _initialized;

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (ParentNotificationTelemetry.maybeLogTap(response.payload)) {
      return;
    }
    _onNotificationTap?.call(response);
  }

  /// [onSelect] FCM / yerel bildirim tıklanınca (ör. aile düellosu payload).
  static Future<void> initialize({
    void Function(NotificationResponse response)? onSelect,
  }) async {
    if (onSelect != null) {
      _onNotificationTap = onSelect;
    }
    if (kIsWeb || _initialized) return;
    try {
      await plugin.initialize(
        InitializationSettings(
          android: const AndroidInitializationSettings('@drawable/ic_stat_notification'),
          iOS: const DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
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
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'instant_math_reminders',
            'Anında Matematik',
            description: 'Günlük Anında Matematik görev hatırlatmaları',
            importance: Importance.high,
          ),
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('AppLocalNotifications.initialize: $e');
    }
  }
}
