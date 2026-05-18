import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Günün görevi soru havuzu — oturum içi ve son 5 gün tekrar engeli.
class DailyChallengeQuestionPool {
  DailyChallengeQuestionPool._();

  static const int questionCount = 10;
  static const int historyDays = 5;
  static const String _prefsKey = 'daily_challenge_question_history_v1';

  static const List<String> topics = [
    'addition',
    'subtraction',
    'multiplication',
    'division',
  ];

  static String fingerprint(String topic, int n1, String operator, int n2) =>
      '$topic|$n1|$operator|$n2';

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _daySeed(String userId, DateTime date) =>
      Object.hash(userId, date.year, date.month, date.day);

  /// Son [historyDays] gün + bugünün önceki oturumları hariç 10 benzersiz soru.
  static Future<List<DailyChallengeQuestionData>> generateSession({
    required String storageUserId,
    required DateTime date,
  }) async {
    final excluded = await _loadExcludedFingerprints(storageUserId, date);
    final sessionExcluded = <String>{...excluded};
    final result = <DailyChallengeQuestionData>[];

    var seed = _daySeed(storageUserId, date);
    var random = Random(seed);

    for (var round = 0; round < 8 && result.length < questionCount; round++) {
      var attempts = 0;
      while (result.length < questionCount && attempts < 2500) {
        attempts++;
        final topic = topics[random.nextInt(topics.length)];
        final q = _buildQuestion(topic, random, date);
        if (sessionExcluded.contains(q.fingerprint)) continue;
        sessionExcluded.add(q.fingerprint);
        result.add(q);
      }
      if (result.length >= questionCount) break;
      seed += 7919 + round * 104729;
      random = Random(seed);
    }

    while (result.length < questionCount) {
      final topic = topics[result.length % topics.length];
      final q = _buildQuestion(topic, Random(seed + result.length * 31), date);
      if (!sessionExcluded.contains(q.fingerprint)) {
        sessionExcluded.add(q.fingerprint);
        result.add(q);
      } else {
        seed++;
      }
    }

    await _recordSessionFingerprints(
      storageUserId,
      date,
      result.map((e) => e.fingerprint).toList(),
    );
    return result;
  }

  static DailyChallengeQuestionData _buildQuestion(
    String topic,
    Random random,
    DateTime date,
  ) {
    final dayMix = date.day + date.month * 31 + date.year % 100;
    int num1, num2, answer;
    String operator;

    switch (topic) {
      case 'addition':
        operator = '+';
        final max = 12 + (dayMix % 18);
        num1 = random.nextInt(max) + 1;
        num2 = random.nextInt(max) + 1;
        answer = num1 + num2;
        break;
      case 'subtraction':
        operator = '-';
        final max = 12 + (dayMix % 18);
        num1 = random.nextInt(max) + 2;
        num2 = random.nextInt(num1 - 1) + 1;
        answer = num1 - num2;
        break;
      case 'multiplication':
        operator = '×';
        final max = 9 + (dayMix % 4);
        num1 = random.nextInt(max) + 1;
        num2 = random.nextInt(max) + 1;
        answer = num1 * num2;
        break;
      case 'division':
        operator = '÷';
        final maxDiv = 9 + (dayMix % 4);
        num2 = random.nextInt(maxDiv) + 1;
        answer = random.nextInt(maxDiv) + 1;
        num1 = num2 * answer;
        break;
      default:
        operator = '+';
        num1 = random.nextInt(10) + 1;
        num2 = random.nextInt(10) + 1;
        answer = num1 + num2;
    }

    final options = <int>{answer};
    var guard = 0;
    while (options.length < 4 && guard < 40) {
      final wrong = answer + random.nextInt(11) - 5;
      if (wrong > 0) options.add(wrong);
      guard++;
    }
    final optionsList = options.toList()..shuffle(random);

    return DailyChallengeQuestionData(
      topic: topic,
      num1: num1,
      num2: num2,
      operator: operator,
      correctAnswer: answer,
      options: optionsList,
      fingerprint: fingerprint(topic, num1, operator, num2),
    );
  }

  static Future<Set<String>> _loadExcludedFingerprints(
    String userId,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_prefsKey}_$userId');
    if (raw == null || raw.isEmpty) return {};

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final cutoff = date.subtract(const Duration(days: historyDays));
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

  static Future<void> _recordSessionFingerprints(
    String userId,
    DateTime date,
    List<String> newFingerprints,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_prefsKey}_$userId';
    final today = _dateKey(date);
    List<Map<String, dynamic>> history = [];

    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        history = (jsonDecode(raw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        history = [];
      }
    }

    final cutoff = date.subtract(const Duration(days: historyDays));
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
    merged.addAll(newFingerprints);

    final todayEntry = {
      'date': today,
      'fingerprints': merged.toList(),
    };
    if (todayIndex >= 0) {
      history[todayIndex] = todayEntry;
    } else {
      history.add(todayEntry);
    }

    await prefs.setString(key, jsonEncode(history));
  }
}

class DailyChallengeQuestionData {
  final String topic;
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;
  final List<int> options;
  final String fingerprint;

  const DailyChallengeQuestionData({
    required this.topic,
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
    required this.options,
    required this.fingerprint,
  });
}
