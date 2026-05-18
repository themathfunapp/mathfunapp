import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Konu başına seviye ilerlemesi (Kolay→Orta→Zor). Kullanıcı / yaş grubu bazlı saklanır.
class TopicLevelProgressService {
  static const String _prefsPrefix = 'topic_level_progress_v1';

  static String _storageKey({
    required String userId,
    required String ageGroupKey,
    required String topicId,
  }) =>
      '${_prefsPrefix}_${userId}_${ageGroupKey}_$topicId';

  static String _normalizeTopicId(String topicId) =>
      topicId == 'shapes' ? 'geometry' : topicId;

  /// Açılmış en yüksek seviye (1–3).
  Future<int> getUnlockedLevel({
    required String userId,
    required String ageGroupKey,
    required String topicId,
  }) async {
    final data = await _load(userId, ageGroupKey, topicId);
    return (data['unlockedLevel'] as int?)?.clamp(1, 3) ?? 1;
  }

  /// Son oynanan / devam edilecek seviye (1–3).
  Future<int> getContinueLevel({
    required String userId,
    required String ageGroupKey,
    required String topicId,
  }) async {
    final data = await _load(userId, ageGroupKey, topicId);
    final unlocked = (data['unlockedLevel'] as int?)?.clamp(1, 3) ?? 1;
    final last = (data['continueLevel'] as int?)?.clamp(1, 3) ?? 1;
    return last > unlocked ? unlocked : last;
  }

  /// Seviye geçildiğinde (%60+) bir sonraki seviyeyi aç.
  Future<void> markLevelCompleted({
    required String userId,
    required String ageGroupKey,
    required String topicId,
    required int completedLevel,
    required bool passed,
  }) async {
    if (!passed) return;
    final data = await _load(userId, ageGroupKey, topicId);
    var unlocked = (data['unlockedLevel'] as int?)?.clamp(1, 3) ?? 1;
    if (completedLevel >= unlocked && completedLevel < 3) {
      unlocked = completedLevel + 1;
    }
    final continueLevel = completedLevel < 3 ? completedLevel + 1 : 3;
    await _save(userId, ageGroupKey, topicId, {
      'unlockedLevel': unlocked,
      'continueLevel': continueLevel,
    });
  }

  /// Devam seviyesini kaydet (oyuna girerken seçilen seviye).
  Future<void> setContinueLevel({
    required String userId,
    required String ageGroupKey,
    required String topicId,
    required int level,
  }) async {
    final data = await _load(userId, ageGroupKey, topicId);
    final unlocked = (data['unlockedLevel'] as int?)?.clamp(1, 3) ?? 1;
    await _save(userId, ageGroupKey, topicId, {
      'unlockedLevel': unlocked,
      'continueLevel': level.clamp(1, unlocked),
    });
  }

  Future<void> resetProgress({
    required String userId,
    required String ageGroupKey,
    required String topicId,
  }) async {
    await _save(userId, ageGroupKey, topicId, {
      'unlockedLevel': 1,
      'continueLevel': 1,
    });
  }

  Future<Map<String, dynamic>> _load(
    String userId,
    String ageGroupKey,
    String topicId,
  ) async {
    final id = _normalizeTopicId(topicId);
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(_storageKey(
        userId: userId,
        ageGroupKey: ageGroupKey,
        topicId: id,
      ));
      if ((raw == null || raw.isEmpty) && topicId == 'geometry') {
        raw = prefs.getString(_storageKey(
          userId: userId,
          ageGroupKey: ageGroupKey,
          topicId: 'shapes',
        ));
      }
      if (raw == null || raw.isEmpty) return {};
      return jsonDecode(raw) as Map<String, dynamic>? ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(
    String userId,
    String ageGroupKey,
    String topicId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final id = _normalizeTopicId(topicId);
    await prefs.setString(
      _storageKey(userId: userId, ageGroupKey: ageGroupKey, topicId: id),
      jsonEncode(data),
    );
  }
}
