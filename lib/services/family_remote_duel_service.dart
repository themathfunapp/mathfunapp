import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game_mechanics.dart';
import '../models/age_group_selection.dart';
import '../utils/family_duel_question_utils.dart';

/// Uzaktan aile düellosu: Firestore üzerinden aynı soru seti, iki cihaz.
///
/// Güvenlik: Üretimde Firestore kurallarında yalnızca `hostUserId` / `guestUserId`
/// olan kullanıcıların ilgili oturum ve davet belgelerini okuyup yazmasına izin verin.
class FamilyRemoteDuelService {
  FamilyRemoteDuelService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String invitesCol = 'familyRemoteDuelInvites';
  static const String sessionsCol = 'familyRemoteDuelSessions';

  /// Çocuk hesabı: davetler (istemci tarafında `status == pending` süzülür; ek indeks gerekmez).
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingInvitesStream(String userId) {
    return _db.collection(invitesCol).where('toUserId', isEqualTo: userId).snapshots();
  }

  Future<bool> readUserPremiumFlag(String uid) async {
    if (uid.isEmpty) return false;
    try {
      final d = await _db.collection('users').doc(uid).get();
      return d.data()?['isPremium'] == true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel readUserPremiumFlag: $e');
      return false;
    }
  }

  /// `users/{hostUid}/family/members` → `childUserIds` içinde çocuk var mı? (Firestore kuralları ile uyumlu.)
  Future<bool> hostHasLinkedChildOnAccount(String hostUid, String childUid) async {
    if (hostUid.isEmpty || childUid.isEmpty) return false;
    try {
      final doc = await _db
          .collection('users')
          .doc(hostUid)
          .collection('family')
          .doc('members')
          .get();
      if (!doc.exists) return false;
      final raw = doc.data()?['childUserIds'];
      if (raw is! List) return false;
      for (final e in raw) {
        if (e?.toString() == childUid) return true;
      }
      return false;
    } catch (e) {
      debugPrint('FamilyRemoteDuel hostHasLinkedChildOnAccount: $e');
      return false;
    }
  }

  /// `childUserIds` kümesi (boş olabilir).
  Future<Set<String>> linkedChildUserIdsForHost(String hostUid) async {
    if (hostUid.isEmpty) return {};
    try {
      final doc = await _db
          .collection('users')
          .doc(hostUid)
          .collection('family')
          .doc('members')
          .get();
      if (!doc.exists) return {};
      final raw = doc.data()?['childUserIds'];
      if (raw is! List) return {};
      return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
    } catch (e) {
      debugPrint('FamilyRemoteDuel linkedChildUserIdsForHost: $e');
      return {};
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> sessionStream(String sessionId) {
    return _db.collection(sessionsCol).doc(sessionId).snapshots();
  }

  List<Map<String, dynamic>> _generateQuestions(TopicType topic, int seed) {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < 5; i++) {
      final r = math.Random(seed + i * 1000003);
      final q = TopicGameManager.generateTopicQuestion(
        topic,
        AgeGroupSelection.elementary,
        r,
      );
      out.add(sanitizeQuestionForStorage(Map<String, dynamic>.from(q)));
    }
    return out;
  }

  /// Premium ebeveyn çocuğa davet oluşturur; sorular sunucuda tek sefer üretilir.
  Future<({String sessionId, String inviteId})?> createInvite({
    required String hostUserId,
    required String hostDisplayName,
    required String guestUserId,
    required String guestDisplayName,
    required TopicType topic,
  }) async {
    if (hostUserId.isEmpty || guestUserId.isEmpty || hostUserId == guestUserId) {
      return null;
    }

    final hostPremium = await readUserPremiumFlag(hostUserId);
    final guestPremium = await readUserPremiumFlag(guestUserId);
    if (!hostPremium || !guestPremium) {
      debugPrint('FamilyRemoteDuel: her iki hesapta da Premium (Firestore isPremium) gerekli.');
      return null;
    }

    final seed = DateTime.now().millisecondsSinceEpoch ^ hostUserId.hashCode ^ guestUserId.hashCode;
    final questions = _generateQuestions(topic, seed);
    final sessionRef = _db.collection(sessionsCol).doc();
    final inviteRef = _db.collection(invitesCol).doc();

    try {
      await _db.runTransaction((tx) async {
        tx.set(sessionRef, {
          'hostUserId': hostUserId,
          'guestUserId': guestUserId,
          'hostDisplayName': hostDisplayName,
          'guestDisplayName': guestDisplayName,
          'topicKey': topic.name,
          'questionSeed': seed,
          'questions': questions,
          'status': 'waiting_accept',
          'currentRoundIndex': 0,
          'roundHostAnswered': false,
          'roundGuestAnswered': false,
          'hostCorrectCount': 0,
          'guestCorrectCount': 0,
          'leaderboardSynced': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(inviteRef, {
          'fromUserId': hostUserId,
          'fromDisplayName': hostDisplayName,
          'toUserId': guestUserId,
          'toDisplayName': guestDisplayName,
          'topicKey': topic.name,
          'sessionId': sessionRef.id,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return (sessionId: sessionRef.id, inviteId: inviteRef.id);
    } catch (e) {
      debugPrint('FamilyRemoteDuel createInvite: $e');
      return null;
    }
  }

  Future<bool> acceptInvite({
    required String inviteId,
    required String acceptingUserId,
  }) async {
    if (!await readUserPremiumFlag(acceptingUserId)) return false;
    final inviteRef = _db.collection(invitesCol).doc(inviteId);

    try {
      await _db.runTransaction((tx) async {
        final inv = await tx.get(inviteRef);
        if (!inv.exists) throw Exception('no_invite');
        final d = inv.data()!;
        if (d['toUserId'] != acceptingUserId) throw Exception('not_receiver');
        if (d['status'] != 'pending') throw Exception('not_pending');
        final sessionId = d['sessionId'] as String? ?? '';
        if (sessionId.isEmpty) throw Exception('no_session');

        final sessionRef = _db.collection(sessionsCol).doc(sessionId);
        final s = await tx.get(sessionRef);
        if (!s.exists) throw Exception('no_session_doc');
        final sd = s.data()!;
        if (sd['status'] != 'waiting_accept') throw Exception('bad_session_status');

        tx.update(inviteRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        tx.update(sessionRef, {
          'status': 'active',
          'startedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel acceptInvite: $e');
      return false;
    }
  }

  Future<void> declineInvite(String inviteId, String userId) async {
    try {
      final ref = _db.collection(invitesCol).doc(inviteId);
      await _db.runTransaction((tx) async {
        final inv = await tx.get(ref);
        if (!inv.exists) return;
        final d = inv.data()!;
        if (d['toUserId'] != userId) return;
        if (d['status'] != 'pending') return;
        final sessionId = d['sessionId'] as String?;
        tx.update(ref, {
          'status': 'declined',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        if (sessionId != null && sessionId.isNotEmpty) {
          tx.update(_db.collection(sessionsCol).doc(sessionId), {
            'status': 'cancelled',
            'cancelReason': 'declined',
          });
        }
      });
    } catch (e) {
      debugPrint('FamilyRemoteDuel declineInvite: $e');
    }
  }

  /// Cevabı işler; doğruluk sunucu tarafında sorudan hesaplanır.
  Future<bool> submitAnswer({
    required String sessionId,
    required String userId,
    required dynamic pickedValue,
  }) async {
    final sessionRef = _db.collection(sessionsCol).doc(sessionId);

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(sessionRef);
        if (!snap.exists) return;
        final data = snap.data()!;
        if (data['status'] != 'active') return;

        final hostUid = data['hostUserId'] as String? ?? '';
        final guestUid = data['guestUserId'] as String? ?? '';
        final isHost = userId == hostUid;
        final isGuest = userId == guestUid;
        if (!isHost && !isGuest) return;

        final roundIdx = (data['currentRoundIndex'] as num?)?.toInt() ?? 0;
        final questionsRaw = data['questions'];
        final questions = decodeQuestionsList(questionsRaw);
        if (questions.isEmpty || roundIdx >= questions.length) return;

        final hostDone = data['roundHostAnswered'] == true;
        final guestDone = data['roundGuestAnswered'] == true;

        if (isHost && hostDone) return;
        if (isGuest && guestDone) return;

        final q = questions[roundIdx];
        final correct = familyDuelIsCorrect(q, pickedValue);

        var hostCorrect = (data['hostCorrectCount'] as num?)?.toInt() ?? 0;
        var guestCorrect = (data['guestCorrectCount'] as num?)?.toInt() ?? 0;
        var hostAnswered = hostDone;
        var guestAnswered = guestDone;

        if (isHost) {
          if (correct) hostCorrect++;
          hostAnswered = true;
        } else {
          if (correct) guestCorrect++;
          guestAnswered = true;
        }

        var nextRound = roundIdx;
        var resetHost = hostAnswered;
        var resetGuest = guestAnswered;

        if (hostAnswered && guestAnswered) {
          if (roundIdx >= questions.length - 1) {
            tx.update(sessionRef, {
              'roundHostAnswered': true,
              'roundGuestAnswered': true,
              'hostCorrectCount': hostCorrect,
              'guestCorrectCount': guestCorrect,
              'status': 'finished',
              'finishedAt': FieldValue.serverTimestamp(),
            });
            return;
          }
          nextRound = roundIdx + 1;
          resetHost = false;
          resetGuest = false;
        }

        tx.update(sessionRef, {
          'roundHostAnswered': resetHost,
          'roundGuestAnswered': resetGuest,
          'hostCorrectCount': hostCorrect,
          'guestCorrectCount': guestCorrect,
          'currentRoundIndex': nextRound,
        });
      });

      return true;
    } catch (e) {
      debugPrint('FamilyRemoteDuel submitAnswer: $e');
      return false;
    }
  }

  Future<void> markLeaderboardSynced(String sessionId) async {
    try {
      await _db.collection(sessionsCol).doc(sessionId).update({'leaderboardSynced': true});
    } catch (e) {
      debugPrint('FamilyRemoteDuel markLeaderboardSynced: $e');
    }
  }

  /// Ebeveyn beklemeden vazgeçerse.
  Future<void> cancelPendingSession(String sessionId, String hostUserId) async {
    try {
      final ref = _db.collection(sessionsCol).doc(sessionId);
      await _db.runTransaction((tx) async {
        final s = await tx.get(ref);
        if (!s.exists) return;
        final d = s.data()!;
        if (d['hostUserId'] != hostUserId) return;
        if (d['status'] != 'waiting_accept') return;
        tx.update(ref, {
          'status': 'cancelled',
          'cancelReason': 'host_cancelled',
        });
      });

      final inv = await _db
          .collection(invitesCol)
          .where('sessionId', isEqualTo: sessionId)
          .limit(20)
          .get();
      for (final doc in inv.docs) {
        final st = doc.data()['status'] as String?;
        if (st != 'pending') continue;
        await doc.reference.update({
          'status': 'cancelled',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('FamilyRemoteDuel cancelPendingSession: $e');
    }
  }
}
