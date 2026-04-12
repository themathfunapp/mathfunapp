import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app_local_notifications.dart';

/// Ebeveyn paneli → Ayarlar: SharedPreferences tercihlerine göre yerel zamanlanmış bildirimler.
///
/// Ana anahtar kapalıysa tüm zamanlamalar iptal edilir. Ağ / FCM gerektirmez.
class ParentPanelNotificationScheduler {
  ParentPanelNotificationScheduler._();
  static final instance = ParentPanelNotificationScheduler._();

  static const int idDaily = 93001;
  static const int idWeekly = 93002;
  static const int idSuccessTip = 93003;
  static const int idInactivityNudge = 93004;

  static const String prefMaster = 'parent_notif_master';
  static const String prefDaily = 'parent_notif_daily_reminder';
  static const String prefDailyHour = 'parent_notif_daily_hour';
  static const String prefDailyMin = 'parent_notif_daily_min';
  static const String prefSuccess = 'parent_notif_success_messages';
  static const String prefWeekly = 'parent_notif_weekly_summary';
  static const String prefInactivity = 'parent_notif_inactivity_warning';

  bool _tzReady = false;

  Future<void> _ensureTz() async {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('ParentPanelNotificationScheduler TZ: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
    _tzReady = true;
  }

  Future<void> _requestIosPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await AppLocalNotifications.plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('ParentPanelNotificationScheduler iOS perm: $e');
    }
  }

  /// [SharedPreferences] diskten okunur (panel yüklendikten veya tercih kaydından sonra).
  Future<void> syncFromDisk() async {
    if (kIsWeb) return;
    if (!AppLocalNotifications.isInitialized) {
      debugPrint('ParentPanelNotificationScheduler: bildirim eklentisi henüz hazır değil');
      return;
    }

    await _ensureTz();
    await _requestIosPermissions();
    try {
      await AppLocalNotifications.plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('ParentPanelNotificationScheduler Android perm: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool(prefMaster) ?? true;
    final dailyOn = prefs.getBool(prefDaily) ?? true;
    final h = prefs.getInt(prefDailyHour) ?? 18;
    final m = prefs.getInt(prefDailyMin) ?? 0;
    final weeklyOn = prefs.getBool(prefWeekly) ?? true;
    final successOn = prefs.getBool(prefSuccess) ?? true;
    final inactivityOn = prefs.getBool(prefInactivity) ?? true;

    final p = AppLocalNotifications.plugin;
    await p.cancel(idDaily);
    await p.cancel(idWeekly);
    await p.cancel(idSuccessTip);
    await p.cancel(idInactivityNudge);

    if (!master) {
      return;
    }

    const android = AndroidNotificationDetails(
      'parent_panel_reminders',
      'Ebeveyn hatırlatmaları',
      channelDescription: 'Günlük ve haftalık hatırlatmalar',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    if (dailyOn) {
      final when = _nextInstanceOfClock(h, m);
      try {
        await p.zonedSchedule(
          idDaily,
          'MathFun — hatırlatma',
          'Bugün çocuğunuzla kısa bir matematik pratiği zamanı.',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler daily: $e');
      }
    }

    if (weeklyOn) {
      final when = _nextWeekdayTime(DateTime.monday, 9, 0);
      try {
        await p.zonedSchedule(
          idWeekly,
          'MathFun — haftalık özet',
          'Haftalık ilerlemeyi Ebeveyn Paneli → Gelişim sekmesinden gözden geçirebilirsiniz.',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler weekly: $e');
      }
    }

    if (successOn) {
      final when = _nextWeekdayTime(DateTime.wednesday, 15, 0);
      try {
        await p.zonedSchedule(
          idSuccessTip,
          'MathFun — başarılar',
          'Yeni rozet veya seri olduysa çocuğunuzla kutlamayı unutmayın.',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler success: $e');
      }
    }

    if (inactivityOn) {
      final when = _nextWeekdayTime(DateTime.sunday, 11, 0);
      try {
        await p.zonedSchedule(
          idInactivityNudge,
          'MathFun — pratik',
          'Son günlerde oyun açıldı mı? Kısa bir seans çocuğunuzu motive eder.',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler inactivity: $e');
      }
    }
  }

  tz.TZDateTime _nextInstanceOfClock(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Bir sonraki [weekday] (DateTime.monday=1 …) [hour]:[minute] anı.
  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var dayCursor = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    for (var i = 0; i < 14; i++) {
      final at = tz.TZDateTime(
        tz.local,
        dayCursor.year,
        dayCursor.month,
        dayCursor.day,
        hour,
        minute,
      );
      if (at.weekday == weekday && at.isAfter(now)) {
        return at;
      }
      dayCursor = dayCursor.add(const Duration(days: 1));
    }
    return now.add(const Duration(days: 7));
  }
}
