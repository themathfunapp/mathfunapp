import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/friend_duel_topics.dart';
import '../models/age_group_selection.dart';
import '../models/friend_duel_invite.dart';
import '../models/game_mechanics.dart';
import '../utils/family_duel_question_utils.dart';
import 'family_remote_duel_service.dart';

/// İki arkadaş: davet (90 sn), konu seçimi, 10 sn hazırlık, aynı 5 soru.
class FriendDuelService {
  FriendDuelService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String invitesCol = 'friendDuelInvites';
  static const String sessionsCol = 'friendDuelSessions';
  static const int inviteTtlSeconds = 90;
  static const int prepCountdownSeconds = 10;
  static const int roundCount = 5;
  static const int roundTimeMs = 15000;
  static const int timeoutWrongPick = FamilyRemoteDuelService.timeoutWrongPick;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInvitesStream(String userId) {
    return _db
        .collection(invitesCol)
        .where('toUserId', isEqualTo: userId)
        .snapshots();
  }

  /// Blaze / FCM gerekmez — Firestore + uygulama içi davet (90 sn).
  Stream<List<FriendDuelInvite>> incomingInvitesStream(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return pendingInvitesStream(userId).map(parsePendingInvitesFromSnapshot);
  }

  static List<FriendDuelInvite> parsePendingInvitesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final out = <FriendDuelInvite>[];
    for (final doc in snap.docs) {
      final invite = FriendDuelInvite.fromFirestore(doc);
      if (invite.status != 'pending') continue;
      if (invite.sessionId.isEmpty) continue;
      if (invite.expiresAtMs > 0 && now > invite.expiresAtMs) continue;
      out.add(invite);
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(String sessionId) {
    return _db.collection(sessionsCol).doc(sessionId).snapshots();
  }

  Future<String?> readSessionStatus(String sessionId) async {
    if (sessionId.isEmpty) return null;
    try {
      final d = await _db.collection(sessionsCol).doc(sessionId).get();
      return d.data()?['status'] as String?;
    } catch (e) {
      debugPrint('FriendDuel readSessionStatus: $e');
      return null;
    }
  }

  static List<String> participantIds(Map<String, dynamic> data) {
    final fromDoc = (data['participantUserIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (fromDoc.length >= 2) return fromDoc;
    final host = (data['hostUserId'] as String?) ?? '';
    final guest = (data['guestUserId'] as String?) ?? '';
    return [host, guest].where((e) => e.isNotEmpty).toList();
  }

  static TopicType? topicFromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final t in TopicType.values) {
      if (t.name == key) return t;
    }
    return null;
  }

  bool _isExpired(Map<String, dynamic> data) {
    final exp = (data['expiresAtMs'] as num?)?.toInt() ?? 0;
    return exp > 0 && _nowMs() > exp;
  }

  /// Davet belgesi süresi doldu mu (expiresAtMs yoksa createdAt + 90 sn).
  bool _isInviteExpiredMap(Map<String, dynamic> data) {
    if (_isExpired(data)) return true;
    final exp = (data['expiresAtMs'] as num?)?.toInt() ?? 0;
    if (exp > 0) return false;
    final created = data['createdAt'];
    if (created is Timestamp) {
      return _nowMs() - created.millisecondsSinceEpoch >
          inviteTtlSeconds * 1000;
    }
    return false;
  }

  /// Süresi dolmuş pending davetleri Firestore'da `expired` yapar.
  Future<void> _expireStalePendingInvitesBetween(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      final snap = await _db
          .collection(invitesCol)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final doc in snap.docs) {
        if (_isInviteExpiredMap(doc.data())) {
          await expirePendingInvite(doc.id);
        }
      }
    } catch (e) {
      debugPrint('FriendDuel _expireStalePendingInvitesBetween: $e');
    }
  }

  Future<bool> _hasActivePendingInvite(String fromUserId, String toUserId) async {
    await _expireStalePendingInvitesBetween(fromUserId, toUserId);
    final snap = await _db
        .collection(invitesCol)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .limit(5)
        .get();
    for (final doc in snap.docs) {
      if (!_isInviteExpiredMap(doc.data())) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> _generateUniqueQuestions({
    required TopicType topic,
    required int seed,
    required Set<String> usedFingerprints,
    required int count,
  }) {
    final out = <Map<String, dynamic>>[];
    final random = math.Random(seed);
    var attempts = 0;
    while (out.length < count && attempts < 400) {
      attempts++;
      final raw = TopicGameManager.generateTopicQuestion(
        topic,
        AgeGroupSelection.elementary,
        random,
        difficulty: 'Orta',
      );
      final answer = raw['correctAnswer'];
      final opts = raw['options'];
      if (answer is! int || opts is! List || opts.isEmpty) continue;
      final fp = questionFingerprint(raw);
      if (usedFingerprints.contains(fp)) continue;
      usedFingerprints.add(fp);
      out.add(sanitizeQuestionForStorage(Map<String, dynamic>.from(raw)));
    }
    while (out.length < count) {
      final raw = TopicGameManager.generateTopicQuestion(
        TopicType.addition,
        AgeGroupSelection.elementary,
        math.Random(seed + out.length * 7919),
      );
      out.add(sanitizeQuestionForStorage(Map<String, dynamic>.from(raw)));
    }
    return out;
  }

  /// Davet + oturum oluşturur.
  Future<({String sessionId, String inviteId})?> createInvite({
    required String hostUserId,
    required String hostDisplayName,
    String? hostUserCode,
    required String guestUserId,
    required String guestDisplayName,
  }) async {
    if (hostUserId.isEmpty || guestUserId.isEmpty || hostUserId == guestUserId) {
      return null;
    }

    if (await _hasActivePendingInvite(hostUserId, guestUserId)) return null;

    final sessionRef = _db.collection(sessionsCol).doc();
    final inviteRef = _db.collection(invitesCol).doc();
    final expiresAtMs = _nowMs() + inviteTtlSeconds * 1000;

    try {
      await _db.runTransaction((tx) async {
        tx.set(sessionRef, {
          'hostUserId': hostUserId,
          'guestUserId': guestUserId,
          'hostDisplayName': hostDisplayName,
          'guestDisplayName': guestDisplayName,
          'participantUserIds': [hostUserId, guestUserId],
          'status': 'waiting_accept',
          'topicKey': null,
          'topicPickedBy': null,
          'prepEndsAtMs': 0,
          'questions': <Map<String, dynamic>>[],
          'usedQuestionFingerprints': <String>[],
          'questionSeed': 0,
          'currentRoundIndex': 0,
          'hostScore': 0,
          'guestScore': 0,
          'roundAnswers': <String, dynamic>{},
          'roundStartedAtMs': 0,
          'roundDeadlineAtMs': 0,
          'expiresAtMs': expiresAtMs,
          'inviteId': inviteRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(inviteRef, {
          'fromUserId': hostUserId,
          'fromDisplayName': hostDisplayName,
          'fromUserCode': hostUserCode,
          'toUserId': guestUserId,
          'toDisplayName': guestDisplayName,
          'sessionId': sessionRef.id,
          'status': 'pending',
          'expiresAtMs': expiresAtMs,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return (sessionId: sessionRef.id, inviteId: inviteRef.id);
    } catch (e) {
      debugPrint('FriendDuel createInvite: $e');
      return null;
    }
  }

  Future<bool> acceptInvite({
    required String inviteId,
    required String acceptingUserId,
  }) async {
    final inviteRef = _db.collection(invitesCol).doc(inviteId);
    try {
      await _db.runTransaction((tx) async {
        final inv = await tx.get(inviteRef);
        if (!inv.exists) throw Exception('no_invite');
        final d = inv.data()!;
        if (d['toUserId'] != acceptingUserId) throw Exception('not_receiver');
        if (d['status'] != 'pending') throw Exception('not_pending');
        if (_isExpired(d)) {
          tx.update(inviteRef, {'status': 'expired'});
          throw Exception('expired');
        }
        final sessionId = d['sessionId'] as String? ?? '';
        if (sessionId.isEmpty) throw Exception('no_session');

        final sessionRef = _db.collection(sessionsCol).doc(sessionId);
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session_doc');
        final sd = s.data()!;
        if (sd['status'] != 'waiting_accept') throw Exception('bad_status');
        if (_isExpired(sd)) {
          tx.update(inviteRef, {'status': 'expired'});
          tx.update(sessionRef, {'status': 'expired'});
          throw Exception('session_expired');
        }

        tx.update(inviteRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        tx.update(sessionRef, {
          'status': 'topic_pick',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('FriendDuel acceptInvite: $e');
      return false;
    }
  }

  Future<void> declineInvite(String inviteId, String userId) async {
    final inviteRef = _db.collection(invitesCol).doc(inviteId);
    try {
      await _db.runTransaction((tx) async {
        final inv = await tx.get(inviteRef);
        if (!inv.exists) return;
        final d = inv.data()!;
        if (d['toUserId'] != userId || d['status'] != 'pending') return;
        final sessionId = d['sessionId'] as String? ?? '';
        tx.update(inviteRef, {
          'status': 'declined',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        if (sessionId.isNotEmpty) {
          tx.update(_db.collection(sessionsCol).doc(sessionId), {
            'status': 'cancelled',
            'cancelReason': 'declined',
          });
        }
      });
    } catch (e) {
      debugPrint('FriendDuel declineInvite: $e');
    }
  }

  Future<void> expirePendingInvite(String inviteId) async {
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      await _db.runTransaction((tx) async {
        final inv = await tx.get(ref);
        if (!inv.exists) return;
        final d = inv.data()!;
        if (d['status'] != 'pending') return;
        tx.update(ref, {'status': 'expired'});
        final sessionId = d['sessionId'] as String? ?? '';
        if (sessionId.isNotEmpty) {
          final sRef = _db.collection(sessionsCol).doc(sessionId);
          final s = await tx.get(sRef);
          if (s.exists && s.data()?['status'] == 'waiting_accept') {
            tx.update(sRef, {'status': 'expired'});
          }
        }
      });
    } catch (e) {
      debugPrint('FriendDuel expirePendingInvite: $e');
    }
  }

  /// Konu seçildi → 10 sn hazırlık, sorular üretilir.
  Future<bool> pickTopic({
    required String sessionId,
    required String userId,
    required TopicType topic,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session');
        final d = s.data()!;
        final status = d['status'] as String? ?? '';
        if (status != 'topic_pick') {
          throw Exception('bad_status');
        }
        if (!participantIds(d).contains(userId)) throw Exception('not_participant');

        final existing = d['topicKey'] as String?;
        if (existing != null && existing.isNotEmpty) {
          throw Exception('topic_already_picked');
        }

        final used = (d['usedQuestionFingerprints'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet();
        final seed = _nowMs() ^ sessionId.hashCode ^ topic.index;
        final questions = _generateUniqueQuestions(
          topic: topic,
          seed: seed,
          usedFingerprints: used,
          count: roundCount,
        );
        final prepEnds = _nowMs() + prepCountdownSeconds * 1000;

        tx.update(sessionRef, {
          'topicKey': topic.name,
          'topicPickedBy': userId,
          'questionSeed': seed,
          'questions': questions,
          'usedQuestionFingerprints': used.toList(),
          'status': 'prep',
          'prepEndsAtMs': prepEnds,
          'hostScore': 0,
          'guestScore': 0,
          'currentRoundIndex': 0,
          'roundAnswers': <String, dynamic>{},
        });
      });
      return true;
    } catch (e) {
      debugPrint('FriendDuel pickTopic: $e');
      return false;
    }
  }

  /// Hazırlık süresi bitti → oyunu başlat (ilk gelen istemci tetikler).
  Future<void> startPlayingIfPrepDone({
    required String sessionId,
    required String userId,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sessionRef);
        if (!s.exists) return;
        final d = s.data()!;
        if (d['status'] != 'prep') return;
        if (!participantIds(d).contains(userId)) return;
        final prepEnds = (d['prepEndsAtMs'] as num?)?.toInt() ?? 0;
        if (prepEnds > 0 && _nowMs() < prepEnds) return;

        final now = _nowMs();
        tx.update(sessionRef, {
          'status': 'playing',
          'currentRoundIndex': 0,
          'roundStartedAtMs': now,
          'roundDeadlineAtMs': now + roundTimeMs,
        });
      });
    } catch (e) {
      debugPrint('FriendDuel startPlayingIfPrepDone: $e');
    }
  }

  Future<bool> submitRoundAnswer({
    required String sessionId,
    required String userId,
    required int roundIndex,
    required dynamic pick,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session');
        final d = s.data()!;
        if (d['status'] != 'playing') throw Exception('not_playing');
        final current = (d['currentRoundIndex'] as num?)?.toInt() ?? 0;
        if (current != roundIndex) throw Exception('wrong_round');

        final hostId = d['hostUserId'] as String? ?? '';
        final guestId = d['guestUserId'] as String? ?? '';
        if (userId != hostId && userId != guestId) throw Exception('not_player');

        final questions = decodeQuestionsList(d['questions']);
        if (roundIndex >= questions.length) throw Exception('no_question');
        final q = questions[roundIndex];
        final correct = pick == timeoutWrongPick
            ? false
            : familyDuelIsCorrect(q, pick);

        final allAnswers = Map<String, dynamic>.from(
          (d['roundAnswers'] as Map<String, dynamic>?) ?? {},
        );
        final roundKey = '$roundIndex';
        final roundMap = Map<String, dynamic>.from(
          (allAnswers[roundKey] as Map<String, dynamic>?) ?? {},
        );
        if (roundMap.containsKey(userId)) return;

        roundMap[userId] = {
          'pick': pick,
          'correct': correct,
          'atMs': _nowMs(),
        };
        allAnswers[roundKey] = roundMap;

        var hostScore = (d['hostScore'] as num?)?.toInt() ?? 0;
        var guestScore = (d['guestScore'] as num?)?.toInt() ?? 0;
        if (correct) {
          if (userId == hostId) {
            hostScore += 10;
          } else {
            guestScore += 10;
          }
        }

        final updates = <String, dynamic>{
          'roundAnswers': allAnswers,
          'hostScore': hostScore,
          'guestScore': guestScore,
        };

        final answered = participantIds(d)
            .every((id) => roundMap.containsKey(id));
        final deadline = (d['roundDeadlineAtMs'] as num?)?.toInt() ?? 0;
        final pastDeadline = deadline > 0 && _nowMs() >= deadline;

        if (answered || pastDeadline) {
          _applyRoundAdvance(d, updates, roundIndex);
        }

        tx.update(sessionRef, updates);
      });
      return true;
    } catch (e) {
      debugPrint('FriendDuel submitRoundAnswer: $e');
      return false;
    }
  }

  void _applyRoundAdvance(
    Map<String, dynamic> d,
    Map<String, dynamic> updates,
    int roundIndex,
  ) {
    final next = roundIndex + 1;
    if (next >= roundCount) {
      updates['status'] = 'finished';
      updates['finishedAt'] = FieldValue.serverTimestamp();
    } else {
      final now = _nowMs();
      updates['currentRoundIndex'] = next;
      updates['roundStartedAtMs'] = now;
      updates['roundDeadlineAtMs'] = now + roundTimeMs;
    }
  }

  /// Süre dolduğunda eksik cevapları otomatik işler.
  Future<void> applyRoundTimeoutIfNeeded({
    required String sessionId,
    required String actingUserId,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sessionRef);
        if (!s.exists) return;
        final d = s.data()!;
        if (d['status'] != 'playing') return;
        if (!participantIds(d).contains(actingUserId)) return;

        final deadline = (d['roundDeadlineAtMs'] as num?)?.toInt() ?? 0;
        if (deadline <= 0 || _nowMs() < deadline) return;

        final roundIndex = (d['currentRoundIndex'] as num?)?.toInt() ?? 0;
        final hostId = d['hostUserId'] as String? ?? '';
        final guestId = d['guestUserId'] as String? ?? '';

        final allAnswers = Map<String, dynamic>.from(
          (d['roundAnswers'] as Map<String, dynamic>?) ?? {},
        );
        final roundKey = '$roundIndex';
        final roundMap = Map<String, dynamic>.from(
          (allAnswers[roundKey] as Map<String, dynamic>?) ?? {},
        );

        var changed = false;
        for (final id in [hostId, guestId]) {
          if (id.isEmpty || roundMap.containsKey(id)) continue;
          roundMap[id] = {
            'pick': timeoutWrongPick,
            'correct': false,
            'atMs': _nowMs(),
          };
          changed = true;
        }
        if (!changed && roundMap.length >= 2) {
          // Her iki cevap var ama raunt ilerlememiş olabilir
          changed = true;
        }
        if (!changed) return;

        allAnswers[roundKey] = roundMap;
        final updates = <String, dynamic>{'roundAnswers': allAnswers};
        _applyRoundAdvance(d, updates, roundIndex);
        tx.update(sessionRef, updates);
      });
    } catch (e) {
      debugPrint('FriendDuel applyRoundTimeoutIfNeeded: $e');
    }
  }

  /// Berabere / kazan / kaybet sonrası: aynı sorularla devam.
  Future<bool> rematchContinue({
    required String sessionId,
    required String userId,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session');
        final d = s.data()!;
        if (d['status'] != 'finished') throw Exception('not_finished');
        if (!participantIds(d).contains(userId)) throw Exception('not_player');

        final now = _nowMs();
        tx.update(sessionRef, {
          'status': 'playing',
          'hostScore': 0,
          'guestScore': 0,
          'currentRoundIndex': 0,
          'roundAnswers': <String, dynamic>{},
          'roundStartedAtMs': now,
          'roundDeadlineAtMs': now + roundTimeMs,
          'rematchMode': 'continue',
        });
      });
      return true;
    } catch (e) {
      debugPrint('FriendDuel rematchContinue: $e');
      return false;
    }
  }

  /// Yeni konu seçimi için topic_pick durumuna döner.
  Future<bool> rematchNewTopic({
    required String sessionId,
    required String userId,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session');
        final d = s.data()!;
        if (d['status'] != 'finished') throw Exception('not_finished');
        if (!participantIds(d).contains(userId)) throw Exception('not_player');

        tx.update(sessionRef, {
          'status': 'topic_pick',
          'topicKey': null,
          'topicPickedBy': null,
          'prepEndsAtMs': 0,
          'questions': <Map<String, dynamic>>[],
          'hostScore': 0,
          'guestScore': 0,
          'currentRoundIndex': 0,
          'roundAnswers': <String, dynamic>{},
          'rematchMode': 'topic_pick',
        });
      });
      return true;
    } catch (e) {
      debugPrint('FriendDuel rematchNewTopic: $e');
      return false;
    }
  }

  Future<void> abandonSession(String sessionId, String userId) async {
    try {
      await _db.collection(sessionsCol).doc(sessionId).update({
        'status': 'cancelled',
        'cancelledBy': userId,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FriendDuel abandonSession: $e');
    }
  }
}
