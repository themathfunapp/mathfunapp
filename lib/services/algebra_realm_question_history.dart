import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cebir Diyarı — aynı gün ve 7 gün içinde aynı denklem tekrar sorulmasın.
class AlgebraRealmQuestionHistory {
  AlgebraRealmQuestionHistory._();

  static const String _prefsKey = 'algebra_realm_asked_v1';
  static const int historyDays = 7;

  /// Bölge + denklem metni + doğru cevap (ör. `1|x + 3 = 6|3`).
  static String fingerprint(int regionIndex, String display, int answer) =>
      '$regionIndex|$display|$answer';

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Son [historyDays] gün içinde sorulmuş parmak izleri.
  static Future<Set<String>> loadWithinDays(
    int days, {
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final cutoff = now.subtract(Duration(days: days));
      final cutoffDay = DateTime(cutoff.year, cutoff.month, cutoff.day);
      final excluded = <String>{};

      for (final entry in list) {
        if (entry is! Map) continue;
        final day = entry['date'] as String? ?? '';
        final fps = entry['fingerprints'];
        if (fps is! List) continue;

        final parts = day.split('-');
        if (parts.length != 3) continue;
        final entryDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (entryDate.isBefore(cutoffDay)) continue;
        for (final fp in fps) {
          if (fp is String) excluded.add(fp);
        }
      }
      return excluded;
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>> loadToday({DateTime? date}) =>
      loadWithinDays(1, date: date);

  static Future<void> record(String fingerprint, {DateTime? date}) async {
    final now = date ?? DateTime.now();
    final today = _dateKey(now);
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> history = [];

    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        history = (jsonDecode(raw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        history = [];
      }
    }

    final cutoff = now.subtract(const Duration(days: historyDays));
    history.removeWhere((entry) {
      final day = entry['date'] as String? ?? '';
      final parts = day.split('-');
      if (parts.length != 3) return true;
      final entryDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return entryDate.isBefore(
        DateTime(cutoff.year, cutoff.month, cutoff.day),
      );
    });

    final todayIndex = history.indexWhere((e) => e['date'] == today);
    final merged = <String>{};
    if (todayIndex >= 0) {
      final existing = history[todayIndex]['fingerprints'];
      if (existing is List) {
        for (final fp in existing) {
          if (fp is String) merged.add(fp);
        }
      }
    }
    merged.add(fingerprint);

    final todayEntry = {
      'date': today,
      'fingerprints': merged.toList(),
    };
    if (todayIndex >= 0) {
      history[todayIndex] = todayEntry;
    } else {
      history.add(todayEntry);
    }

    await prefs.setString(_prefsKey, jsonEncode(history));
  }
}
