import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app_local_notifications.dart';
import 'parent_notification_telemetry.dart';
import '../localization/parent_panel_l10n.dart';

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
  static const String prefLanguageCode = 'parent_notif_lang';
  static const String prefParentUid = 'parent_notif_parent_uid';

  static const String _prefLastInactivityShownAt = 'parent_notif_last_inactivity_shown_at';
  static const String _prefLastWeeklyShownAt = 'parent_notif_last_weekly_shown_at';
  static const String _prefBadgeCountPrefix = 'parent_notif_last_badge_count_';
  static const String _prefBadgeShownAtPrefix = 'parent_notif_last_badge_shown_at_';

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
  Future<void> syncFromDisk({String? languageCode}) async {
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
    final lc = (languageCode ?? prefs.getString(prefLanguageCode) ?? 'en').toLowerCase();
    final variantSeed = _variantSeedFromPrefs(prefs);
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

    if (dailyOn) {
      final when = _nextInstanceOfClock(h, m);
      try {
        final dailyIdx = _variantIndex(12, variantSeed + _daySeed());
        final dailyBody = _variantLine(lc, 'pp_notif_daily_body_', dailyIdx);
        await p.zonedSchedule(
          idDaily,
          ParentPanelL10n.of(lc, 'pp_notif_daily_title'),
          dailyBody,
          when,
          AppLocalNotifications.parentPanelReminderDetails(dailyBody),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: ParentNotificationTelemetry.buildPayload('daily', dailyIdx),
        );
        await ParentNotificationTelemetry.logScheduled(
          kind: 'daily',
          variant: dailyIdx,
          lang: lc,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler daily: $e');
      }
    }

    if (weeklyOn) {
      final when = _nextWeekdayTime(DateTime.monday, 9, 0);
      try {
        const weeklyVariant = 1;
        final weeklyBody = ParentPanelL10n.of(lc, 'pp_notif_weekly_body');
        await p.zonedSchedule(
          idWeekly,
          ParentPanelL10n.of(lc, 'pp_notif_weekly_title'),
          weeklyBody,
          when,
          AppLocalNotifications.parentPanelReminderDetails(weeklyBody),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: ParentNotificationTelemetry.buildPayload('weekly_sched', weeklyVariant),
        );
        await ParentNotificationTelemetry.logScheduled(
          kind: 'weekly_sched',
          variant: weeklyVariant,
          lang: lc,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler weekly: $e');
      }
    }

    if (successOn) {
      final when = _nextWeekdayTime(DateTime.wednesday, 15, 0);
      try {
        final successIdx = _variantIndex(10, variantSeed + _daySeed() + 11);
        final successBody = _variantLine(lc, 'pp_notif_success_body_', successIdx);
        await p.zonedSchedule(
          idSuccessTip,
          ParentPanelL10n.of(lc, 'pp_notif_success_title'),
          successBody,
          when,
          AppLocalNotifications.parentPanelReminderDetails(successBody),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: ParentNotificationTelemetry.buildPayload('success_tip', successIdx),
        );
        await ParentNotificationTelemetry.logScheduled(
          kind: 'success_tip',
          variant: successIdx,
          lang: lc,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler success: $e');
      }
    }

    if (inactivityOn) {
      // “Özleniyorsun” nudgesi: her gün belirli saatte (koşullu zekâ için ayrıca panel içi kontrol var).
      final when = _nextInstanceOfClock(11, 0);
      try {
        final inactIdx = _variantIndex(12, variantSeed + _daySeed() + 23);
        final inactBody = _variantLine(lc, 'pp_notif_inactivity_body_generic_', inactIdx);
        await p.zonedSchedule(
          idInactivityNudge,
          ParentPanelL10n.of(lc, 'pp_notif_inactivity_title'),
          inactBody,
          when,
          AppLocalNotifications.parentPanelReminderDetails(inactBody),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: ParentNotificationTelemetry.buildPayload('inactivity_sched', inactIdx),
        );
        await ParentNotificationTelemetry.logScheduled(
          kind: 'inactivity_sched',
          variant: inactIdx,
          lang: lc,
        );
      } catch (e) {
        debugPrint('ParentPanelNotificationScheduler inactivity: $e');
      }
    }
  }

  static int _daySeed() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  }

  static int _variantSeedFromPrefs(SharedPreferences prefs) {
    final uid = prefs.getString(prefParentUid) ?? '';
    if (uid.isEmpty) return 17;
    var sum = 0;
    for (final u in uid.codeUnits) {
      sum = (sum * 31 + u) & 0x7fffffff;
    }
    return sum;
  }

  static int _variantIndex(int count, int seed) {
    if (count <= 1) return 1;
    return (seed.abs() % count) + 1;
  }

  static String _variantLine(String languageCode, String keyBase, int index) {
    return ParentPanelL10n.of(languageCode, '$keyBase$index');
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

class ParentPanelFamilySnapshotEntry {
  final String userId;
  final String displayName;
  final DateTime? lastPlayedAt;
  final int earnedBadges;
  final bool isParent;

  const ParentPanelFamilySnapshotEntry({
    required this.userId,
    required this.displayName,
    required this.lastPlayedAt,
    required this.earnedBadges,
    required this.isParent,
  });
}

extension ParentPanelContextualNotifications on ParentPanelNotificationScheduler {
  Future<void> maybeShowContextualFromFamily({
    required String languageCode,
    required List<ParentPanelFamilySnapshotEntry> entries,
    String telemetrySource = 'panel',
  }) async {
    if (kIsWeb) return;
    if (!AppLocalNotifications.isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool(ParentPanelNotificationScheduler.prefMaster) ?? true;
    if (!master) return;

    final successOn = prefs.getBool(ParentPanelNotificationScheduler.prefSuccess) ?? true;
    final inactivityOn = prefs.getBool(ParentPanelNotificationScheduler.prefInactivity) ?? true;
    final weeklyOn = prefs.getBool(ParentPanelNotificationScheduler.prefWeekly) ?? true;

    final now = DateTime.now();
    final p = AppLocalNotifications.plugin;

    if (weeklyOn) {
      await _maybeShowWeeklySummaryOncePerWeek(
        prefs: prefs,
        plugin: p,
        languageCode: languageCode,
        now: now,
        telemetrySource: telemetrySource,
      );
    }

    if (inactivityOn) {
      await _maybeShowInactivityIfNeeded(
        prefs: prefs,
        plugin: p,
        languageCode: languageCode,
        now: now,
        entries: entries,
        telemetrySource: telemetrySource,
      );
    }

    if (successOn) {
      await _maybeShowBadgeEarnedIfNeeded(
        prefs: prefs,
        plugin: p,
        languageCode: languageCode,
        entries: entries,
        telemetrySource: telemetrySource,
      );
    }
  }

  Future<void> _maybeShowWeeklySummaryOncePerWeek({
    required SharedPreferences prefs,
    required FlutterLocalNotificationsPlugin plugin,
    required String languageCode,
    required DateTime now,
    required String telemetrySource,
  }) async {
    final lastMs = prefs.getInt(ParentPanelNotificationScheduler._prefLastWeeklyShownAt);
    final last = lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;

    final isMondayMorning = now.weekday == DateTime.monday && now.hour >= 8 && now.hour <= 20;
    final alreadyThisWeek = last != null && now.difference(last).inDays < 6;
    if (!isMondayMorning || alreadyThisWeek) return;

    final title = ParentPanelL10n.of(languageCode, 'pp_notif_weekly_title');
    final body = ParentPanelL10n.of(languageCode, 'pp_notif_weekly_body');
    try {
      const weeklyPopupVariant = 1;
      await plugin.show(
        ParentPanelNotificationScheduler.idWeekly + 100,
        title,
        body,
        AppLocalNotifications.parentPanelReminderDetails(body),
        payload: ParentNotificationTelemetry.buildPayload('weekly_popup', weeklyPopupVariant),
      );
      await prefs.setInt(ParentPanelNotificationScheduler._prefLastWeeklyShownAt, now.millisecondsSinceEpoch);
      await ParentNotificationTelemetry.logShown(
        kind: 'weekly_popup',
        variant: weeklyPopupVariant,
        lang: languageCode,
        src: telemetrySource,
      );
    } catch (e) {
      debugPrint('ParentPanelNotificationScheduler weekly show: $e');
    }
  }

  Future<void> _maybeShowInactivityIfNeeded({
    required SharedPreferences prefs,
    required FlutterLocalNotificationsPlugin plugin,
    required String languageCode,
    required DateTime now,
    required List<ParentPanelFamilySnapshotEntry> entries,
    required String telemetrySource,
  }) async {
    final children = entries.where((e) => !e.isParent).toList();
    if (children.isEmpty) return;

    ParentPanelFamilySnapshotEntry? worst;
    Duration worstGap = Duration.zero;
    for (final c in children) {
      final at = c.lastPlayedAt;
      if (at == null) continue;
      final gap = now.difference(at);
      if (gap > worstGap) {
        worstGap = gap;
        worst = c;
      }
    }

    if (worst == null) return;
    // 2+ gün oynamadıysa “özlendin” nudgesi (Duolingo tarzı).
    if (worstGap.inDays < 2) return;

    final lastMs = prefs.getInt(ParentPanelNotificationScheduler._prefLastInactivityShownAt);
    final last = lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;
    if (last != null && now.difference(last).inHours < 48) return;

    final title = ParentPanelL10n.of(languageCode, 'pp_notif_inactivity_title');
    final body = ParentPanelL10n.of(languageCode, 'pp_notif_inactivity_body')
        .replaceAll('{child}', worst.displayName.trim().isNotEmpty ? worst.displayName.trim() : '—')
        .replaceAll('{days}', '${worstGap.inDays}');

    final gapBucket = worstGap.inDays.clamp(2, 14);
    try {
      await plugin.show(
        ParentPanelNotificationScheduler.idInactivityNudge + 100,
        title,
        body,
        AppLocalNotifications.parentPanelReminderDetails(body),
        payload: ParentNotificationTelemetry.buildPayload('inactivity_gap', gapBucket),
      );
      await prefs.setInt(ParentPanelNotificationScheduler._prefLastInactivityShownAt, now.millisecondsSinceEpoch);
      await ParentNotificationTelemetry.logShown(
        kind: 'inactivity_gap',
        variant: gapBucket,
        lang: languageCode,
        src: telemetrySource,
      );
    } catch (e) {
      debugPrint('ParentPanelNotificationScheduler inactivity show: $e');
    }
  }

  Future<void> _maybeShowBadgeEarnedIfNeeded({
    required SharedPreferences prefs,
    required FlutterLocalNotificationsPlugin plugin,
    required String languageCode,
    required List<ParentPanelFamilySnapshotEntry> entries,
    required String telemetrySource,
  }) async {
    for (final e in entries) {
      if (e.isParent) continue;
      if (e.userId.isEmpty) continue;

      final keyCount = '${ParentPanelNotificationScheduler._prefBadgeCountPrefix}${e.userId}';
      final prev = prefs.getInt(keyCount);
      if (prev == null) {
        await prefs.setInt(keyCount, e.earnedBadges);
        continue;
      }
      if (e.earnedBadges <= prev) continue;

      final shownAtKey = '${ParentPanelNotificationScheduler._prefBadgeShownAtPrefix}${e.userId}';
      final shownAtMs = prefs.getInt(shownAtKey);
      final shownAt =
          shownAtMs != null ? DateTime.fromMillisecondsSinceEpoch(shownAtMs) : null;
      if (shownAt != null && DateTime.now().difference(shownAt).inHours < 12) {
        await prefs.setInt(keyCount, e.earnedBadges);
        continue;
      }

      final title = ParentPanelL10n.of(languageCode, 'pp_notif_badge_title');
      final body = ParentPanelL10n.of(languageCode, 'pp_notif_badge_body')
          .replaceAll('{child}', e.displayName.trim().isNotEmpty ? e.displayName.trim() : '—');

      const badgeVariant = 1;
      try {
        await plugin.show(
          ParentPanelNotificationScheduler.idSuccessTip + 100,
          title,
          body,
          AppLocalNotifications.parentPanelReminderDetails(body),
          payload: ParentNotificationTelemetry.buildPayload('badge', badgeVariant),
        );
        await prefs.setInt(shownAtKey, DateTime.now().millisecondsSinceEpoch);
        await ParentNotificationTelemetry.logShown(
          kind: 'badge',
          variant: badgeVariant,
          lang: languageCode,
          src: telemetrySource,
        );
      } catch (err) {
        debugPrint('ParentPanelNotificationScheduler badge show: $err');
      } finally {
        await prefs.setInt(keyCount, e.earnedBadges);
      }

      // Tek seferde en fazla 1 rozet bildirimi göster.
      return;
    }
  }
}
