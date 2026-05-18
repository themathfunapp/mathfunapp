import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Kesir Pastanesi — aynı gün içinde aynı soru tekrar sorulmasın.
class FractionBakeryQuestionHistory {
  FractionBakeryQuestionHistory._();

  static const String _prefsKey = 'fraction_bakery_asked_today_v1';

  static String fingerprint(
    String pastryEmoji,
    int total,
    int eaten,
    int remaining,
    int partCount,
  ) =>
      '$pastryEmoji|$total|$eaten|$remaining|$partCount';

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<Set<String>> loadToday({DateTime? date}) async {
    final today = _dateKey(date ?? DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['date'] != today) return {};
      final list = map['fingerprints'];
      if (list is! List) return {};
      return list.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> record(String fingerprint, {DateTime? date}) async {
    final today = _dateKey(date ?? DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final asked = await loadToday(date: date);
    asked.add(fingerprint);
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'date': today,
        'fingerprints': asked.toList(),
      }),
    );
  }
}
