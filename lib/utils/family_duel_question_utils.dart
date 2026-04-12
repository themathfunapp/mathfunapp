import 'dart:convert';

/// Tek/çift cihaz aile düellosu için ortak soru metni ve doğrulama.
String familyDuelQuestionLine(Map<String, dynamic>? q) {
  if (q == null) return '';
  final text = q['question'];
  if (text is String && text.isNotEmpty) return text;

  final type = q['type'] as String?;
  switch (type) {
    case 'count_objects':
      final emoji = q['emoji'] as String? ?? '🎯';
      final cnt = ((q['count'] as int?) ?? 3).clamp(1, 16);
      return '${List.filled(cnt, emoji).join(' ')}\nKaç tane?';
    case 'find_missing':
      final seq = q['sequence'] as String? ?? '';
      return 'Hangi sayı eksik: $seq';
    case 'whats_next':
      final seq = q['sequence'] as String? ?? '';
      return 'Sonraki sayı: $seq';
    case 'before_after':
      final params = q['questionParams'];
      final n = params is Map ? '${params['number'] ?? '?'}' : '?';
      final key = q['questionKey'] as String? ?? '';
      if (key == 'question_before_number') {
        return "$n'den önce hangi sayı gelir?";
      }
      return "$n'den sonra hangi sayı gelir?";
    default:
      break;
  }
  return 'Soru';
}

List<dynamic> familyDuelOptionList(Map<String, dynamic>? q) {
  final o = q?['options'];
  if (o is List) return o;
  return [];
}

bool familyDuelIsCorrect(Map<String, dynamic>? q, dynamic pick) {
  final c = q?['correctAnswer'];
  if (pick == null || c == null) return false;
  if (pick == c) return true;
  if (pick is num && c is num) {
    return pick.toDouble() == c.toDouble();
  }
  return pick.toString() == c.toString();
}

/// Firestore / JSON için soru haritasını güvenli tiplere indirger.
Map<String, dynamic> sanitizeQuestionForStorage(Map<String, dynamic> raw) {
  final out = <String, dynamic>{};
  for (final e in raw.entries) {
    out[e.key] = _sanitizeValue(e.value);
  }
  return out;
}

dynamic _sanitizeValue(dynamic v) {
  if (v == null || v is String || v is int || v is double || v is bool) {
    return v;
  }
  if (v is num) return v;
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), _sanitizeValue(val)));
  }
  if (v is List) {
    return v.map(_sanitizeValue).toList();
  }
  return v.toString();
}

List<Map<String, dynamic>> decodeQuestionsList(dynamic raw) {
  if (raw is! List) return [];
  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      out.add(Map<String, dynamic>.from(item));
    } else if (item is Map) {
      out.add(Map<String, dynamic>.from(item.cast<String, dynamic>()));
    } else if (item is String) {
      try {
        final m = jsonDecode(item) as Map<String, dynamic>?;
        if (m != null) out.add(m);
      } catch (_) {}
    }
  }
  return out;
}
