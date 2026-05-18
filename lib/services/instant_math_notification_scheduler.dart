import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../localization/app_localizations.dart';
import 'app_local_notifications.dart';

/// Ayarlar / PushNotificationService ile aynı anahtar.
const String _prefNotificationsEnabled = 'notifications_enabled';

/// İlk Anında Matematik oturumundan 5 saat sonra hatırlatma (günlük ödül tamamlanmadıysa).
class InstantMathNotificationScheduler {
  InstantMathNotificationScheduler._();

  static const int notificationId = 94021;
  static const Duration reminderDelay = Duration(hours: 5);

  static bool _tzReady = false;

  static Future<void> _ensureTz() async {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('InstantMathNotificationScheduler TZ: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {}
    }
    _tzReady = true;
  }

  static Future<bool> _notificationsEnabledInSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotificationsEnabled) ?? true;
  }

  /// iOS: izin diyaloğu. Android 13+ (API 33+): POST_NOTIFICATIONS.
  /// Android 12 ve altı: sistem izni gerekmez; kanal açıksa bildirim gider.
  static Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await AppLocalNotifications.plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      if (defaultTargetPlatform != TargetPlatform.android) {
        return true;
      }
      final android = AppLocalNotifications.plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;

      final requested = await android.requestNotificationsPermission();
      if (requested == true) return true;

      final enabled = await android.areNotificationsEnabled();
      if (enabled == false) return false;
      if (enabled == true) return true;

      // API 32 ve altı: requestNotificationsPermission null döner; bildirimler varsayılan açık.
      return true;
    } catch (e) {
      debugPrint('InstantMathNotificationScheduler.requestPermission: $e');
      return false;
    }
  }

  static NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_math_reminders',
        'Anında Matematik',
        channelDescription: 'Günlük Anında Matematik görev hatırlatmaları',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_stat_notification',
        color: const Color(0xFFFF6B6B),
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<void> scheduleReminder({
    required DateTime firstSessionAt,
    required String languageCode,
  }) async {
    if (kIsWeb) return;
    final fireAt = firstSessionAt.add(reminderDelay);
    if (!fireAt.isAfter(DateTime.now())) return;
    if (!await _notificationsEnabledInSettings()) return;

    try {
      await AppLocalNotifications.initialize();
      await _ensureTz();

      final permitted = await requestNotificationPermissions();
      if (!permitted) {
        debugPrint(
          'InstantMathNotificationScheduler: bildirim izni verilmedi, yalnızca uygulama içi hatırlatma kullanılacak',
        );
        return;
      }

      final loc = AppLocalizations(Locale(languageCode));
      final title = loc.get('instant_math_reminder_title');
      final body = loc.get('instant_math_reminder_body');

      final androidImpl = AppLocalNotifications.plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'instant_math_reminders',
          'Anında Matematik',
          description: 'Günlük Anında Matematik görev hatırlatmaları',
          importance: Importance.high,
        ),
      );

      await AppLocalNotifications.plugin.cancel(notificationId);
      final scheduleMode = defaultTargetPlatform == TargetPlatform.android
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      try {
        await AppLocalNotifications.plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(fireAt, tz.local),
          _details(body),
          androidScheduleMode: scheduleMode,
          payload: 'instant_math_reminder',
        );
      } on Exception catch (e) {
        debugPrint('InstantMathNotificationScheduler exact schedule fallback: $e');
        await AppLocalNotifications.plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(fireAt, tz.local),
          _details(body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'instant_math_reminder',
        );
      }
    } catch (e) {
      debugPrint('InstantMathNotificationScheduler.schedule: $e');
    }
  }

  static Future<void> cancelReminder() async {
    if (kIsWeb) return;
    try {
      await AppLocalNotifications.plugin.cancel(notificationId);
    } catch (e) {
      debugPrint('InstantMathNotificationScheduler.cancel: $e');
    }
  }
}
