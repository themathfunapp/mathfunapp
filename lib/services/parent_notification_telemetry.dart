import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/parent_notif_ga4_params.dart';

/// Ebeveyn paneli yerel bildirimleri için hafif, kişisel veri içermeyen GA4 telemetrisi.
///
/// Sadece `kind` + `variant` indeksi + dil + kaynak gönderilir; çocuk adı / UID yok.
class ParentNotificationTelemetry {
  ParentNotificationTelemetry._();

  static const String payloadPrefix = 'ppn|';

  static String buildPayload(String kind, int variant) => '$payloadPrefix$kind|$variant';

  static bool isParentPayload(String? p) => p != null && p.startsWith(payloadPrefix);

  /// Yerel bildirime tıklanınca; `true` dönerse üst katman başka payload işlememeli.
  static bool maybeLogTap(String? rawPayload) {
    if (!isParentPayload(rawPayload)) return false;
    final parts = rawPayload!.split('|');
    if (parts.length < 3) return true;
    final kind = parts[1];
    final variant = int.tryParse(parts[2]) ?? 0;
    unawaited(Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('parent_notif_lang') ?? '';
        await logOpen(kind: kind, variant: variant, lang: lang, src: 'tap');
      } catch (e) {
        debugPrint('ParentNotificationTelemetry tap: $e');
      }
    }));
    return true;
  }

  static Future<void> logScheduled({
    required String kind,
    required int variant,
    required String lang,
    String src = 'scheduler',
  }) =>
      _log('parent_notif_scheduled', kind: kind, variant: variant, lang: lang, src: src);

  static Future<void> logShown({
    required String kind,
    required int variant,
    required String lang,
    String src = 'contextual',
  }) =>
      _log('parent_notif_shown', kind: kind, variant: variant, lang: lang, src: src);

  static Future<void> logOpen({
    required String kind,
    required int variant,
    String lang = '',
    String src = 'tap',
  }) =>
      _log('parent_notif_open', kind: kind, variant: variant, lang: lang, src: src);

  static Future<void> _log(
    String name, {
    required String kind,
    required int variant,
    required String lang,
    required String src,
  }) async {
    if (kIsWeb) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: <String, Object>{
          ParentNotifGa4Params.kind: kind,
          ParentNotifGa4Params.variant: variant,
          if (lang.isNotEmpty) ParentNotifGa4Params.lang: lang,
          if (src.isNotEmpty) ParentNotifGa4Params.src: src,
        },
      );
    } catch (e) {
      debugPrint('ParentNotificationTelemetry: $e');
    }
  }
}
